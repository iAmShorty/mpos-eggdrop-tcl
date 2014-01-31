#
# Round Statistics
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

# round info
#
proc round_info {nick host hand chan arg } {
 	global help_blocktime help_blocked channels debug debugoutput output onlyallowregisteredusers output_roundstats output_roundstats_percoin
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
	
 	set action "index.php?page=api&action=getdashboarddata&api_key="
 	
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
    	putquick "PRIVMSG $chan :Access to Roundinfo denied"
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
				
				if {$elem eq "pool"} {
					#putlog "Ele: $elem - Val: $elem_val"
					foreach {elem2 elem_val2} $elem_val {
						#putlog "Ele: $elem2 - Val: $elem_val2"
						if {$elem2 eq "shares"} {
							foreach {elem3 elem_val3} $elem_val2 {
								#putlog "Ele: $elem3 - Val: $elem_val3"
								
								if {$elem3 eq "valid"} { set shares_valid "$elem_val3" }
								if {$elem3 eq "invalid"} { set shares_invalid "$elem_val3" }
								if {$elem3 eq "estimated"} { set shares_estimated "$elem_val3" }
								if {$elem3 eq "progress"} { set shares_progress "$elem_val3 %" }
								
							}
						}
					}				
				}
				
				if {$elem eq "network"} {
					#putlog "Ele: $elem - Val: $elem_val"
					foreach {elem2 elem_val2} $elem_val {

						if {$elem2 eq "block"} { set net_block "$elem_val2" }
						if {$elem2 eq "difficulty"} { set net_diff "$elem_val2" }

					}				
				}				
				
			}
		}
	}

	if {[info exists output_roundstats_percoin([string tolower [lindex $arg 0]])]} {
		if {$debug eq "1"} { putlog "-> [string toupper [lindex $arg 0]] - $output_roundstats_percoin([string tolower [lindex $arg 0]])" }
		set lineoutput $output_roundstats_percoin([string tolower [lindex $arg 0]])
	} else {
		if {$debug eq "1"} { putlog "no special output!" }
		set lineoutput $output_roundstats
	}
	
	#set lineoutput $output_roundstats
	set lineoutput [replacevar $lineoutput "%roundstats_coin%" [string toupper [lindex $arg 0]]]
	set lineoutput [replacevar $lineoutput "%roundstats_block%" $net_block]
	set lineoutput [replacevar $lineoutput "%roundstats_diff%" $net_diff]
	set lineoutput [replacevar $lineoutput "%roundstats_estshares%" $shares_estimated]
	set lineoutput [replacevar $lineoutput "%roundstats_allshares%" [expr $shares_valid+$shares_invalid]]
	set lineoutput [replacevar $lineoutput "%roundstats_validshares%" $shares_valid]
	set lineoutput [replacevar $lineoutput "%roundstats_invalidshares%" $shares_invalid]
	set lineoutput [replacevar $lineoutput "%roundstats_progress%" $shares_progress]	
	
	if {$output eq "CHAN"} {
 		foreach advert $channels {
 			if {$advert eq $chan} {
 				putquick "PRIVMSG $chan :$lineoutput"
 			}
		}
	} elseif {$output eq "NOTICE"} {
		putquick "NOTICE $nick :$lineoutput"	
	} else {
		putquick "PRIVMSG $chan :please set output in config file"
	}
	
	set help_blocked($mask) 1
	utimer $help_blocktime [ list unset help_blocked($mask) ]

}

putlog "===>> Mining-Pool-Roundstats - Version $scriptversion loaded"