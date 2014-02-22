#
# MPOS Pool Stats
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
# pool information
#
proc pool_info {nick host hand chan arg} {
	global help_blocktime help_blocked channels debug debugoutput output onlyallowregisteredusers shownethashrate showpoolhashrate output_poolstats output_poolstats_percoin protected_commands sqlite_commands
	sqlite3 poolcommands $sqlite_commands

	if {$onlyallowregisteredusers eq "1"} {
		set hostmask "$nick!*[getchanhost $nick $chan]"
		if {[check_mpos_user $nick $hostmask] eq "false"} {
			putquick "NOTICE $nick :you are not allowed to use this command"
			putquick "NOTICE $nick :please use !request command to get access to the bot"
			return
		}
	}

	if {$arg eq ""} {
		if {$debug eq "1"} { putlog "no pool submitted" }
		return
	}
	
	set action "/index.php?page=api&action=getdashboarddata&api_key="
	
	set mask [string trimleft $host ~]
	regsub -all {@([^\.]*)\.} $mask {@*.} mask	 	
	set mask *!$mask

	if {[info exists help_blocked($mask)]} {
		putquick "NOTICE $nick : You have been blocked for $help_blocktime Seconds, please be patient..."
		return
	}

	set pool_info [regexp -all -inline {\S+} [pool_vars [string toupper $arg]]]

	if {$pool_info ne "0"} {
		if {$debug eq "1"} { putlog "COIN: [lindex $pool_info 0]" }
		if {$debug eq "1"} { putlog "URL: [lindex $pool_info 1]" }
		if {$debug eq "1"} { putlog "KEY: [lindex $pool_info 2]" }
	} else {
		if {$debug eq "1"} { putlog "no pool data" }
		return
	} 

	if {[lsearch $protected_commands "pool"] > 0 } {
		regsub "#" $chan "" command_channel
		if {[llength [poolcommands eval {SELECT command_id FROM commands WHERE channel=$command_channel AND command="pool" AND activated=1}]] != 0} {
			if {$debug eq "1"} { putlog "-> command pool found" }
		} elseif {[llength [poolcommands eval {SELECT command_id FROM commands WHERE channel=$command_channel AND command="all" AND activated=1}]] != 0} {
			if {$debug eq "1"} { putlog "-> command ALL found" }
		} else {
			if {$debug eq "1"} { putlog "-> protected" }
			putquick "PRIVMSG $chan :command !pool not allowed in $chan"
			return
		}
    } else {
    	if {$debug eq "1"} { putlog "-> not protected" }
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
		putquick "PRIVMSG $chan :Access to Poolinfo denied"
		return 0
	}

	set results [::json::json2dict $data]


	foreach {key value} $results {
		#putlog "Key: $key - $value"
		foreach {sub_key sub_value} $value {
			#putlog "Sub: $sub_key - $sub_value"
			foreach {elem elem_val} $sub_value {
				#putlog "Ele: $elem - Val: $elem_val"
				
				if {$elem eq "error" && $elem_val eq "disabled" } {
					putlog "Dashboard API disabled"
					return
				}
				
				if {$elem eq "network"} {
					#putlog "Ele: $elem - Val: $elem_val"
					foreach {elem2 elem_val2} $elem_val {
						#putlog "Ele: $elem2 - Val: $elem_val2"
						if {$elem2 eq "block"} { set poolstats_block "$elem_val2" }
						if {$elem2 eq "blocksuntildiffchange"} { set poolstats_blocksuntildiffchange "$elem_val2" }
						if {$elem2 eq "difficulty"} { set poolstats_diff "$elem_val2" }
						if {$elem2 eq "nextdifficulty"} { set poolstats_nextdiff "$elem_val2" }
						if {$elem2 eq "esttimeperblock"} {
							#set timediff [expr {$elem_val / 60}]
							set timediff [expr {double(round(100*[expr {$elem_val2 / 60}]))/100}]
							set poolstats_esttime "$timediff" 
						} 
					}
				}

				if {$elem eq "pool"} {
					#putlog "Ele: $elem - Val: $elem_val"
					foreach {elem2 elem_val2} $elem_val {
						#putlog "Ele: $elem2 - Val: $elem_val2"
						if {$elem2 eq "shares"} {
							foreach {elem3 elem_val3} $elem_val2 {
								#putlog "Ele: $elem3 - Val: $elem_val3"
								if {$elem3 eq "valid"} { set poolstats_sharesvalid "$elem_val3" }
								if {$elem3 eq "invalid"} { set poolstats_sharesinvalid "$elem_val3" }
								if {$elem3 eq "estimated"} { set poolstats_sharesestimated "$elem_val3" }
								if {$elem3 eq "progress"} { set poolstats_sharesprogress "$elem_val3" }
							}
						}
						if {$elem2 eq "workers"} { set poolstats_poolworkers "$elem_val2" }
					}				
				}
				
				if {$elem eq "raw"} {
					foreach {elem2 elem_val2} $elem_val {
						#putlog "Ele: $elem2 - Val: $elem_val2"
						
						if {$elem2 eq "network"} {
							foreach {elem3 elem_val3} $elem_val2 {
								if {$elem3 eq "hashrate"} {
									#putlog "Nethashrate - $elem_val3"
									if {[string toupper $shownethashrate] eq "KH"} {
										set netdivider 1
										set nethashratevalue "KH/s"
									} elseif {[string toupper $shownethashrate] eq "MH"} {
										set netdivider 1000
										set nethashratevalue "MH/s"
									} elseif {[string toupper $shownethashrate]eq "GH"} {
										set netdivider 1000000
										set nethashratevalue "GH/s"
									} elseif {[string toupper $shownethashrate]eq "TH"} {
										set netdivider 1000000000
										set nethashratevalue "TH/s"
									} else {
										set netdivider 1
										set nethashratevalue "KH/s"
									}
									set poolstats_nethashrate [format "%.2f" [expr {double(double($elem_val3)/double($netdivider))}]]
								}
							}
						}
						
						if {$elem2 eq "pool"} {
							foreach {elem3 elem_val3} $elem_val2 {
								if {$elem3 eq "hashrate"} {
									#putlog "Poolhashrate - $elem_val3"
									if {[string toupper $showpoolhashrate] eq "KH"} {
										set pooldivider 1
										set poolhashratevalue "KH/s"
									} elseif {[string toupper $showpoolhashrate] eq "MH"} {
										set pooldivider 1000
										set poolhashratevalue "MH/s"
									} elseif {[string toupper $showpoolhashrate] eq "GH"} {
										set pooldivider 1000000
										set poolhashratevalue "GH/s"
									} elseif {[string toupper $showpoolhashrate] eq "TH"} {
										set pooldivider 1000000000
										set poolhashratevalue "TH/s"
									} else {
										set pooldivider 1
										set poolhashratevalue "KH/s"
									}
									set poolstats_poolhashrate [format "%.2f" [expr {double(double($elem_val3)/double($pooldivider))}]]
								}
							}
						}
					}
				}			
			}
		}
	}

	if {[info exists output_poolstats_percoin([string tolower [lindex $arg 0]])]} {
		if {$debug eq "1"} { putlog "-> [string toupper [lindex $arg 0]] - $output_poolstats_percoin([string tolower [lindex $arg 0]])" }
		set lineoutput $output_poolstats_percoin([string tolower [lindex $arg 0]])
	} else {
		if {$debug eq "1"} { putlog "no special output!" }
		set lineoutput $output_poolstats
	}

	set lineoutput [replacevar $lineoutput "%poolstats_coin%" [string toupper [lindex $arg 0]]]
	set lineoutput [replacevar $lineoutput "%poolstats_block%" $poolstats_block]
	set lineoutput [replacevar $lineoutput "%poolstats_blocksuntildiffchange%" $poolstats_blocksuntildiffchange]
	set lineoutput [replacevar $lineoutput "%poolstats_diff%" $poolstats_diff]
	set lineoutput [replacevar $lineoutput "%poolstats_nextdiff%" $poolstats_nextdiff]
	set lineoutput [replacevar $lineoutput "%poolstats_esttime%" $poolstats_esttime]
	set lineoutput [replacevar $lineoutput "%poolstats_nethashratevalue%" $nethashratevalue]
	set lineoutput [replacevar $lineoutput "%poolstats_nethashrate%" $poolstats_nethashrate]
	set lineoutput [replacevar $lineoutput "%poolstats_sharesvalid%" $poolstats_sharesvalid]
	set lineoutput [replacevar $lineoutput "%poolstats_sharesinvalid%" $poolstats_sharesinvalid]
	set lineoutput [replacevar $lineoutput "%poolstats_sharesestimated%" $poolstats_sharesestimated]
	set lineoutput [replacevar $lineoutput "%poolstats_sharesprogress%" $poolstats_sharesprogress]
	set lineoutput [replacevar $lineoutput "%poolstats_poolhashratevalue%" $poolhashratevalue]
	set lineoutput [replacevar $lineoutput "%poolstats_poolhashrate%" $poolstats_poolhashrate]
	set lineoutput [replacevar $lineoutput "%poolstats_poolworkers%" $poolstats_poolworkers]
	set lineoutput [replacevar $lineoutput "%poolstats_efficiency%" [format "%.2f" [expr {100 - double(double($poolstats_sharesinvalid)/double($poolstats_sharesvalid)*100)}]]]
	
	if {$output eq "CHAN"} {
		putquick "PRIVMSG $chan :$lineoutput"
	} elseif {$output eq "NOTICE"} {
		putquick "NOTICE $nick :$lineoutput"	
	} else {
		putquick "PRIVMSG $chan :please set output in config file"
	}
	
}

putlog "===>> Mining-Pool-Poolstats - Version $scriptversion loaded"
