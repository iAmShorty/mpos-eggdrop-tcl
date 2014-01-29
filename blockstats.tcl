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

# Block Stats
#
proc block_info {nick host hand chan arg} {
    global help_blocktime help_blocked channels debug debugoutput output onlyallowregisteredusers
	package require http
	package require json
	package require tls

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
	
	set action "index.php?page=api&action=getpoolstatus&api_key="
	
 	set mask [string trimleft $host ~]
 	regsub -all {@([^\.]*)\.} $mask {@*.} mask	 	
 	set mask *!$mask
 
  	if {[info exists help_blocked($mask)]} {
    	  putquick "NOTICE $nick : You have been blocked for $help_blocktime Seconds, please be patient..."
    	  return
  	}
  	
  	set pool_info [regexp -all -inline {\S+} [pool_vars $arg]]
  	
  	if {$pool_info ne "0"} {
  		if {$debug eq "1"} { putlog "COIN: [lindex $pool_info 0]" }
  		if {$debug eq "1"} { putlog "URL: [lindex $pool_info 1]" }
  		if {$debug eq "1"} { putlog "KEY: [lindex $pool_info 2]" }
  	} else {
  		if {$debug eq "1"} { putlog "no pool data" }
  		return
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
    set token [::http::geturl "$newurl"]
    set data [::http::data $token]
    ::http::cleanup $token
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

      				if {$elem eq "currentnetworkblock"} { set block_current "Current Block: #$elem_val" } 
      				if {$elem eq "nextnetworkblock"} { set block_next "Next Block: #$elem_val" } 
      				if {$elem eq "lastblock"} { set block_last "Last Block: #$elem_val" }
      				if {$elem eq "networkdiff"} { set block_diff "Difficulty: $elem_val" } 
      				if {$elem eq "esttime"} {
      					#set timediff [expr {$elem_val / 60}]
      					set timediff [expr {double(round(100*[expr {$elem_val / 60}]))/100}]
      					set block_time "Est. Time to resolve: $timediff minutes" 
      				} 
      				if {$elem eq "estshares"} { set block_shares "Est. Shares to resolve: $elem_val" } 
      				if {$elem eq "timesincelast"} { 
      					#set timediff [expr {$elem_val / 60}]
      					set timediff [expr {double(round(100*[expr {$elem_val / 60}]))/100}]
      					#set timediff $elem_val
      					set block_timelast "Time since last Block: $timediff minutes"
      				}
				
				}
			}
		}
	}
	
 	if {$output eq "CHAN"} {
  		putquick "PRIVMSG $chan :Block Stats: [string toupper [lindex $arg 0]]"
		putquick "PRIVMSG $chan :$block_current | $block_next | $block_last | $block_diff | $block_time | $block_shares | $block_timelast"	
	} elseif {$output eq "NOTICE"} {
  		putquick "NOTICE $nick :Block Stats: [string toupper [lindex $arg 0]]"
		putquick "NOTICE $nick :$block_current | $block_next | $block_last | $block_diff | $block_time | $block_shares | $block_timelast"	
	} else {
		putquick "PRIVMSG $chan :please set output in config file"
	}
	
}

# last block found
#
proc last_info {nick host hand chan arg } {
 	global help_blocktime help_blocked channels debug debugoutput output onlyallowregisteredusers
	package require http
	package require json
	package require tls

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
	
 	set action "index.php?page=api&action=getblocksfound&limit=1&api_key="
 	
 	set mask [string trimleft $host ~]
 	regsub -all {@([^\.]*)\.} $mask {@*.} mask	 	
 	set mask *!$mask
 
  	if {[info exists help_blocked($mask)]} {
    	  putquick "NOTICE $nick : You have been blocked for $help_blocktime Seconds, please be patient..."
    	  return
  	}

 	set last_block "null"
 	set last_confirmed "null"
 	set last_difficulty "null"
 	set last_shares "null"
 	set last_finder "null"
 	set last_estshares "null"
 	set last_timefound "null"
 	
  	set pool_info [regexp -all -inline {\S+} [pool_vars $arg]]
  	
  	if {$pool_info ne "0"} {
  		if {$debug eq "1"} { putlog "COIN: [lindex $pool_info 0]" }
  		if {$debug eq "1"} { putlog "URL: [lindex $pool_info 1]" }
  		if {$debug eq "1"} { putlog "KEY: [lindex $pool_info 2]" }
  	} else {
  		if {$debug eq "1"} { putlog "no pool data" }
  		return
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
    set token [::http::geturl "$newurl"]
    set data [::http::data $token]
    ::http::cleanup $token
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

      					if {$elem2 eq "height"} { set last_block "Last Block: #$elem_val2" }
      					if {$elem2 eq "confirmations"} {
      						if {"$elem_val2" eq "-1"} {
      							set last_confirmed "Status: Orphaned"
      						} else {
      							set last_confirmed "Status: Valid | Confirmations: $elem_val2"
      						}
      					} 
      					if {$elem2 eq "difficulty"} { set last_difficulty "Difficulty: $elem_val2" }
      					if {$elem2 eq "time"} {
      						set converttimestamp [strftime "%d.%m.%Y - %T" $elem_val2]
      						set last_timefound "Time found: $converttimestamp" 
      					}
      					if {$elem2 eq "shares"} { set last_shares "Shares: $elem_val2" } 
						if {$elem2 eq "finder"} { set last_finder "Finder: $elem_val2" } 
						if {$elem2 eq "estshares"} { set last_estshares "Est. Shares: $elem_val2" } 
						
					}
					break
				}
			}
		}
	}
	
 	if {$output eq "CHAN"} {
 		putquick "PRIVMSG $chan :Last Block on [string toupper [lindex $arg 0]] Pool"
		putquick "PRIVMSG $chan :$last_block | $last_confirmed | $last_difficulty | $last_timefound | $last_shares | $last_estshares | $last_finder"
	} elseif {$output eq "NOTICE"} {
		putquick "NOTICE $nick :Last Block on [string toupper [lindex $arg 0]] Pool"
		putquick "NOTICE $nick :$last_block | $last_confirmed | $last_difficulty | $last_timefound | $last_shares | $last_estshares | $last_finder"
	} else {
		putquick "PRIVMSG $chan :please set output in config file"
	}
	
	set help_blocked($mask) 1
	utimer $help_blocktime [ list unset help_blocked($mask) ]

}

putlog "===>> Mining-Pool-Blockstats - Version $scriptversion loaded"