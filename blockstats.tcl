#
# Block Statistics
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
# block information
#
proc block_info {nick host hand chan arg} {
	global help_blocktime help_blocked channels debug debugoutput output onlyallowregisteredusers output_blockinfo output_blockinfo_percoin protected_commands sqlite_commands
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
	
	set action "/index.php?page=api&action=getpoolstatus&api_key="
	
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

	if {[lsearch $protected_commands "block"] > 0 } {
		regsub "#" $chan "" command_channel
		if {[llength [poolcommands eval {SELECT command_id FROM commands WHERE channel=$command_channel AND command="block" AND activated=1}]] != 0} {
			if {$debug eq "1"} { putlog "-> command block found" }
		} elseif {[llength [poolcommands eval {SELECT command_id FROM commands WHERE channel=$command_channel AND command="all" AND activated=1}]] != 0} {
			if {$debug eq "1"} { putlog "-> command ALL found" }
		} else {
			if {$debug eq "1"} { putlog "-> protected" }
         	putquick "PRIVMSG $chan :command !block not allowed in $chan"
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
		putquick "PRIVMSG $chan :Access to Blockinfo denied"
		return 0
	}

	set results [::json::json2dict $data]

	foreach {key value} $results {
		foreach {sub_key sub_value} $value {
			if {$sub_key eq "data"} {
				#putlog "Sub: $sub_value"
				foreach {elem elem_val} $sub_value {
					#putlog "Ele: $elem - Val: $elem_val"

					if {$elem eq "currentnetworkblock"} { set blockstats_current "$elem_val" } 
					if {$elem eq "nextnetworkblock"} { set blockstats_next "$elem_val" } 
					if {$elem eq "lastblock"} { set blockstats_last "$elem_val" }
					if {$elem eq "networkdiff"} { set blockstats_diff "$elem_val" } 
					if {$elem eq "esttime"} {
						#set timediff [expr {$elem_val / 60}]
						set timediff [expr {double(round(100*[expr {$elem_val / 60}]))/100}]
						set blockstats_time "$timediff" 
					} 
					if {$elem eq "estshares"} { set blockstats_shares "$elem_val" } 
					if {$elem eq "timesincelast"} { 
						#set timediff [expr {$elem_val / 60}]
						set timediff [expr {double(round(100*[expr {$elem_val / 60}]))/100}]
						#set timediff $elem_val
						set blockstats_timelast "$timediff"
					}
				
				}
			}
		}
	}

	if {[info exists output_blockinfo_percoin([string tolower [lindex $arg 0]])]} {
		if {$debug eq "1"} { putlog "-> [string toupper [lindex $arg 0]] - $output_blockinfo_percoin([string tolower [lindex $arg 0]])" }
		set lineoutput $output_blockinfo_percoin([string tolower [lindex $arg 0]])
	} else {
		if {$debug eq "1"} { putlog "no special output!" }
		set lineoutput $output_blockinfo
	}
	
	set lineoutput [replacevar $lineoutput "%blockstats_coin%" [string toupper [lindex $arg 0]]]
	set lineoutput [replacevar $lineoutput "%blockstats_current%" $blockstats_current]
	set lineoutput [replacevar $lineoutput "%blockstats_next%" $blockstats_next]
	set lineoutput [replacevar $lineoutput "%blockstats_last%" $blockstats_last]
	set lineoutput [replacevar $lineoutput "%blockstats_diff%" $blockstats_diff]
	set lineoutput [replacevar $lineoutput "%blockstats_time%" $blockstats_time]
	set lineoutput [replacevar $lineoutput "%blockstats_shares%" $blockstats_shares]
	set lineoutput [replacevar $lineoutput "%blockstats_timelast%" $blockstats_timelast]
	
	if {$output eq "CHAN"} {
		putquick "PRIVMSG $chan :$lineoutput"
	} elseif {$output eq "NOTICE"} {
		putquick "NOTICE $nick :$lineoutput"	
	} else {
		putquick "PRIVMSG $chan :please set output in config file"
	}
	
}

#
# last block found
#
proc last_info {nick host hand chan arg } {
	global help_blocktime help_blocked channels debug debugoutput output onlyallowregisteredusers output_lastblock output_lastblock_percoin protected_commands sqlite_commands
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
	
	set action "/index.php?page=api&action=getblocksfound&limit=1&api_key="

	set mask [string trimleft $host ~]
	regsub -all {@([^\.]*)\.} $mask {@*.} mask	 	
	set mask *!$mask
 
	if {[info exists help_blocked($mask)]} {
		putquick "NOTICE $nick : You have been blocked for $help_blocktime Seconds, please be patient..."
		return
	}

	set blockstats_lastblock "null"
	set blockstats_lastconfirmed "null"
	set blockstats_lastconfirmations "null"
	set blockstats_lastdifficulty "null"
	set blockstats_lasttimefound "null"
	set blockstats_lastshares "null"
	set blockstats_lastfinder "null"
	set blockstats_lastestshares "null"

	set pool_info [regexp -all -inline {\S+} [pool_vars [string toupper $arg]]]

	if {$pool_info ne "0"} {
		if {$debug eq "1"} { putlog "COIN: [lindex $pool_info 0]" }
		if {$debug eq "1"} { putlog "URL: [lindex $pool_info 1]" }
		if {$debug eq "1"} { putlog "KEY: [lindex $pool_info 2]" }
	} else {
		if {$debug eq "1"} { putlog "no pool data" }
		return
	} 

	if {[lsearch $protected_commands "last"] > 0 } {
		regsub "#" $chan "" command_channel
		if {[llength [poolcommands eval {SELECT command_id FROM commands WHERE channel=$command_channel AND command="last" AND activated=1}]] != 0} {
			if {$debug eq "1"} { putlog "-> command last found" }
		} elseif {[llength [poolcommands eval {SELECT command_id FROM commands WHERE channel=$command_channel AND command="all" AND activated=1}]] != 0} {
			if {$debug eq "1"} { putlog "-> command ALL found" }
		} else {
			if {$debug eq "1"} { putlog "-> protected" }
			putquick "PRIVMSG $chan :command !last not allowed in $chan"
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
		putquick "PRIVMSG $chan :Access to Lastblocks denied"
		return 0 
	}

	set results [::json::json2dict $data]
	
	foreach {key value} $results {
		#putlog "Key: $key - $value"
		foreach {sub_key sub_value} $value {
			#putlog "Sub: $sub_key - $sub_value"
			if {$sub_key eq "data"} {
				#putlog "Sub: $sub_value"
				foreach {elem elem_val} $sub_value {
					#putlog "Ele: $elem - Val: $elem_val"
					foreach {elem2 elem_val2} $elem {
						#putlog "Ele: $elem2 - Val: $elem_val2"

						if {$elem2 eq "height"} { set blockstats_lastblock "$elem_val2" }
						if {$elem2 eq "confirmations"} {
							if {"$elem_val2" eq "-1"} {
								set blockstats_lastconfirmed "Orphan"
								set blockstats_lastconfirmations "$elem_val2"
							} else {
								set blockstats_lastconfirmed "Valid"
								set blockstats_lastconfirmations "$elem_val2"
							}
						} 
						if {$elem2 eq "difficulty"} { set blockstats_lastdifficulty "$elem_val2" }
						if {$elem2 eq "time"} {
							set converttimestamp [strftime "%d.%m.%Y - %T" $elem_val2]
							set blockstats_lasttimefound "$converttimestamp" 
						}
						if {$elem2 eq "shares"} { set blockstats_lastshares "$elem_val2" } 
						if {$elem2 eq "finder"} { set blockstats_lastfinder "$elem_val2" } 
						if {$elem2 eq "estshares"} { set blockstats_lastestshares "$elem_val2" } 
						
					}
					break
				}
			}
		}
	}

	if {[info exists output_lastblock_percoin([string tolower [lindex $arg 0]])]} {
		if {$debug eq "1"} { putlog "-> [string toupper [lindex $arg 0]] - $output_lastblock_percoin([string tolower [lindex $arg 0]])" }
		set lineoutput $output_lastblock_percoin([string tolower [lindex $arg 0]])
	} else {
		if {$debug eq "1"} { putlog "no special output!" }
		set lineoutput $output_lastblock
	}
	
	#set lineoutput $output_lastblock
	set lineoutput [replacevar $lineoutput "%blockstats_coin%" [string toupper [lindex $arg 0]]]
	set lineoutput [replacevar $lineoutput "%blockstats_lastblock%" $blockstats_lastblock]
	set lineoutput [replacevar $lineoutput "%blockstats_lastconfirmed%" $blockstats_lastconfirmed]
	set lineoutput [replacevar $lineoutput "%blockstats_lastconfirmations%" $blockstats_lastconfirmations]
	set lineoutput [replacevar $lineoutput "%blockstats_lastdifficulty%" $blockstats_lastdifficulty]
	set lineoutput [replacevar $lineoutput "%blockstats_lasttimefound%" $blockstats_lasttimefound]
	set lineoutput [replacevar $lineoutput "%blockstats_lastshares%" $blockstats_lastshares]
	set lineoutput [replacevar $lineoutput "%blockstats_lastestshares%" $blockstats_lastestshares]
	set lineoutput [replacevar $lineoutput "%blockstats_lastfinder%" $blockstats_lastfinder]
	
	if {$output eq "CHAN"} {
		putquick "PRIVMSG $chan :$lineoutput"
	} elseif {$output eq "NOTICE"} {
		putquick "NOTICE $nick :$lineoutput"
	} else {
		putquick "PRIVMSG $chan :please set output in config file"
	}
	
	set help_blocked($mask) 1
	utimer $help_blocktime [ list unset help_blocked($mask) ]

}

putlog "===>> Mining-Pool-Blockstats - Version $scriptversion loaded"
