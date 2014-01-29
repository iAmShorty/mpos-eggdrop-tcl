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

# Pool Stats
#
proc pool_info {nick host hand chan arg} {
    global help_blocktime help_blocked channels debug debugoutput output onlyallowregisteredusers shownethashrate showpoolhashrate
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
    	putquick "PRIVMSG $chan :Access to Poolinfo denied"
    	return 0
    }
    
    set results [::json::json2dict $data]

	foreach {key value} $results {
		foreach {sub_key sub_value} $value {
			#putlog "Sub: $sub_key - $sub_value"
			if {$sub_key eq "data"} {
				#putlog "Sub: $sub_value"
				foreach {elem elem_val} $sub_value {
					#putlog "Ele: $elem - Val: $elem_val"
				
      				if {$elem eq "hashrate"} {
      					if {[string toupper $showpoolhashrate] eq "KH"} {
      						set pooldivider 1
      						set poolhashratevalue "KH/s"
      					} elseif {[string toupper $showpoolhashrate] eq "MH"} {
      						set pooldivider 1000
      						set poolhashratevalue "MH/s"
      					} elseif {[string toupper $showpoolhashrate] eq "GH"} {
      						set pooldivider 1000000
      						set poolhashratevalue "GH/s"
      					} else {
      						set pooldivider 1
      						set poolhashratevalue "KH/s"
      					}
      					set pool_hashrate [format "%.2f" [expr {double(double($elem_val)/double($pooldivider))}]]
      				}
      				if {$elem eq "efficiency"} { set pool_efficiency "Efficiency: $elem_val %" } 
      				if {$elem eq "workers"} { set pool_workers "Workers: $elem_val" } 
      				if {$elem eq "nethashrate"} {
      					if {[string toupper $shownethashrate] eq "KH"} {
      						set netdivider 1000
      						set nethashratevalue "KH/s"
      					} elseif {[string toupper $shownethashrate] eq "MH"} {
      						set netdivider 1000000
      						set nethashratevalue "MH/s"
      					} elseif {[string toupper $shownethashrate]eq "GH"} {
      						set netdivider 1000000000
      						set nethashratevalue "GH/s"
      					} else {
      						set netdivider 1
      						set nethashratevalue "H/s"
      					}
      					set pool_nethashrate [format "%.2f" [expr {double(double($elem_val)/double($netdivider))}]]
      				} 
				
				}
			}
		}
	}
	
 	if {$output eq "CHAN"} {
		putquick "PRIVMSG $chan :Pool Stats: [string toupper [lindex $arg 0]]"
		putquick "PRIVMSG $chan :Hashrate: $pool_hashrate $poolhashratevalue | $pool_efficiency | $pool_workers | Net Hashrate: $pool_nethashrate $nethashratevalue"	
	} elseif {$output eq "NOTICE"} {
		putquick "NOTICE $nick :Pool Stats: [string toupper [lindex $arg 0]]"
		putquick "NOTICE $nick :Hashrate: $pool_hashrate $poolhashratevalue | $pool_efficiency | $pool_workers | Net Hashrate: $pool_nethashrate $nethashratevalue"	
	} else {
		putquick "PRIVMSG $chan :please set output in config file"
	}
	
}

putlog "===>> Mining-Pool-Poolstats - Version $scriptversion loaded"