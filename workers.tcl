#
# Worker Information
#
# Copyright: 2014, iAmShorty
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
# http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
######################################################################
##########           nothing to edit below this line        ##########
##########           use config.tcl for setting options     ##########
######################################################################

#
# get worker information
#
proc worker_info {nick host hand chan arg} {
	global help_blocktime help_blocked channels debug debugoutput output onlyallowregisteredusers ownersworkeronly output_workerinfo output_worker_online output_worker_offline protected_commands sqlite_commands
	sqlite3 poolcommands $sqlite_commands
	package require http
	package require json
	package require tls

	# only allow bot owners to get workers for 
	# specified users
	#
	if {$ownersworkeronly eq "1"} {
		if {[matchattr $nick +n]} {
			putlog "$nick is botowner"
		} else {
			putlog "$nick tried to get worker for user $arg"
			putquick "PRIVMSG $chan :Access to Workers denied, only Botowners can check workers"
			return
		}
	} else {
		if {$onlyallowregisteredusers eq "1"} {
			set hostmask "$nick!*[getchanhost $nick $chan]"
			if {[check_mpos_user $nick $hostmask] eq "false"} {
				putquick "NOTICE $nick :you are not allowed to use this command"
				putquick "NOTICE $nick :please use !request command to get access to the bot"
				return
			}
		}
	}

	if {$arg eq "" || [llength $arg] < 2} {
		if {$debug eq "1"} { putlog "wrong arguments, must be !worker poolname username" }
		return
	}
	
	set action "/index.php?page=api&action=getuserworkers&id=[lindex $arg 1]&api_key="
	
	set mask [string trimleft $host ~]
	regsub -all {@([^\.]*)\.} $mask {@*.} mask	 	
	set mask *!$mask

	if {[info exists help_blocked($mask)]} {
		putquick "NOTICE $nick : You have been blocked for $help_blocktime Seconds, please be patient..."
		return
	}

	set pool_info [regexp -all -inline {\S+} [pool_vars [string toupper [lindex $arg 0]]]]

	if {$pool_info ne "0"} {
		if {$debug eq "1"} { putlog "COIN: [lindex $pool_info 0]" }
		if {$debug eq "1"} { putlog "URL: [lindex $pool_info 1]" }
		if {$debug eq "1"} { putlog "KEY: [lindex $pool_info 2]" }
	} else {
		if {$debug eq "1"} { putlog "no pool data" }
		return
	}

	if {[lsearch $protected_commands "worker"] > 0 } {
		regsub "#" $chan "" command_channel
		if {[llength [poolcommands eval {SELECT command_id FROM commands WHERE channel=$command_channel AND command="worker" AND activated=1}]] != 0} {
			putlog "-> command worker found"
		} elseif {[llength [poolcommands eval {SELECT command_id FROM commands WHERE channel=$command_channel AND command="all" AND activated=1}]] != 0} {
			putlog "-> command ALL found"
		} else {
			putlog "-> protected"
			putquick "PRIVMSG $chan :command !worker not allowed in $chan"
			return
		}
    } else {
    	putlog "-> not protected"
    }
    
	set newurl [lindex $pool_info 1]
	append newurl $action
	append newurl [lindex $pool_info 2]

	if {[string match "*https*" [string tolower $newurl]]} {
		set usehttps 1
	} else {
		set usehttps 0
	}

	if {$usehttps eq "1"} {
		::http::register https 443 tls::socket
	}

	if {[catch { set token [http::geturl $newurl -timeout 3000]} error] == 1} {
		if {$debug eq "1"} { putlog "$error" }
		http::cleanup $token
		return
	} elseif {[http::ncode $token] == "404"} {
		if {$debug eq "1"} { putlog "Error: [http::code $token]" }
		http::cleanup $token
		return
	} elseif {[http::status $token] == "ok"} {
		set data [http::data $token]
		http::cleanup $token
	} elseif {[http::status $token] == "timeout"} {
		if {$debug eq "1"} { putlog "Timeout occurred" }
		http::cleanup $token
		return
	} elseif {[http::status $token] == "error"} {
		if {$debug eq "1"} { putlog "Error: [http::error $token]" }
		http::cleanup $token
		return
	}

	if {$usehttps eq "1"} {
		::http::unregister https
	}

	if {$debugoutput eq "1"} { putlog "xml: $data" }

	if {$data eq "Access denied"} { 
		putquick "PRIVMSG $chan :Access to Workers denied"
		return 0
	}

	set results [::json::json2dict $data]

	foreach {key value} $results {
		foreach {sub_key sub_value} $value {
			if {$sub_key eq "data"} {
				#putlog "Sub: $sub_value"
				foreach {elem} $sub_value {
					#putlog "Ele: $elem"
					foreach {elem2 elem_val2} $elem {
						#putlog "Ele: $elem2 - Val: $elem_val2"
						if {$elem2 eq "username"} {
							set worker_name "$elem_val2"
						}
						if {$elem2 eq "hashrate"} {
							if {$elem_val2 eq "0"} {
								set offlineWorkers($worker_name) $elem_val2
							} else {
								set onlineWorkers($worker_name) $elem_val2
							}
						} 						
					}
				}
			}
		}
	}
	
	if {$debug eq "1"} { putlog "onlineWorkers has [array size onlineWorkers] records" }
	if {$debug eq "1"} { putlog "offlineWorkers has [array size offlineWorkers] records" }
	
	if {[lindex $arg 2] eq "active"} {
		if {[array exists onlineWorkers]} {
			foreach key [array names onlineWorkers] {
				if {$debug eq "1"} { putlog "${key}=$onlineWorkers($key)" }
				if {![info exists worker_name]} {
					set lineoutput "${key} - $onlineWorkers($key) KH/s | " 
				} else {
					append lineoutput "${key} - $onlineWorkers($key) KH/s | "
				}
			}
		}
	} elseif {[lindex $arg 2] eq "inactive"} {
		if {[array exists offlineWorkers]} {
			foreach key [array names offlineWorkers] {
				if {$debug eq "1"} { putlog "${key}=$offlineWorkers($key)" }
				if {![info exists worker_name]} {
					set lineoutput "${key} - $offlineWorkers($key) KH/s | " 
				} else {
					append lineoutput "${key} - $offlineWorkers($key) KH/s | "
				}
			}
		}
	} else {
	
		if {[info exists output_workerinfo_percoin([string tolower [lindex $arg 0]])]} {
			if {$debug eq "1"} { putlog "-> [string toupper [lindex $arg 0]] - $output_workerinfo_percoin([string tolower [lindex $arg 0]])" }
				set lineoutput $output_workerinfo_percoin([string tolower [lindex $arg 0]])
			} else {
				if {$debug eq "1"} { putlog "no special output!" }
				set lineoutput $output_workerinfo
		}
		
		set lineoutput [replacevar $lineoutput "%workers_username%" [lindex $arg 1]]
		set lineoutput [replacevar $lineoutput "%workers_coinname%" [string toupper [lindex $pool_info 0]]]
		set lineoutput [replacevar $lineoutput "%workers_online_count%" [array size onlineWorkers]]
		set lineoutput [replacevar $lineoutput "%workers_offline_count%" [array size offlineWorkers]]
	}
	
	# split message if buffer is to big
	#
	set len [expr {512-[string len ":$::botname PRIVMSG $chan :\r\n"]}] 
	foreach line [wordwrap $lineoutput $len] { 
		if {$output eq "CHAN"} {
			putquick "PRIVMSG $chan :$line"
		} elseif {$output eq "NOTICE"} {
			putquick "NOTICE $nick :$line"
		} else {
			putquick "PRIVMSG $chan :please set output in config file"
			return 0
		}
	}
}

putlog "===>> Mining-Pool-Workers - Version $scriptversion loaded"
