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

# Get Workers
#
proc worker_info {nick host hand chan arg} {
    global help_blocktime help_blocked channels debug debugoutput output onlyallowregisteredusers ownersworkeronly output_workers
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
	
	set action "index.php?page=api&action=getuserworkers&id=[lindex $arg 1]&api_key="
	
 	set mask [string trimleft $host ~]
 	regsub -all {@([^\.]*)\.} $mask {@*.} mask	 	
 	set mask *!$mask
 
  	if {[info exists help_blocked($mask)]} {
    	  putquick "NOTICE $nick : You have been blocked for $help_blocktime Seconds, please be patient..."
    	  return
  	}
  	
  	set pool_info [regexp -all -inline {\S+} [pool_vars [lindex $arg 0]]]
  	
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
      						#if {$elem_val2 ne $arg} {
      						#	putquick "PRIVMSG $chan :Access to user $elem_val2 denied"
      						#	return 0
      						#}
      						
      						if {![info exists worker_name]} {
      							set worker_name "$elem_val2"
      						} else {
      							append worker_name "$elem_val2"
      						}
      					} 
      					if {$elem2 eq "hashrate"} { 
      						if {![info exists worker_name]} {
      							set worker_name " - $elem_val2 KH/s | " 
      						} else {
      							append worker_name " - $elem_val2 KH/s | "
      						}
      					} 						
					}
				}
			}
		}
	}
	
    # split message if buffer is to big
	#
	set len [expr {512-[string len ":$::botname PRIVMSG $chan :\r\n"]}] 
	foreach line [wordwrap $worker_name $len] { 
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