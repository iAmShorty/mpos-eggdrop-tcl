#
# MPOS eggdrop Calls
# 
# User Statistics
#

######################################################################
##########           nothing to edit below this line        ##########
##########           use config.tcl for setting options     ##########
######################################################################

# info for specific user
#
proc user_info {nick host hand chan arg} {
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

	if {$arg eq "" || [llength $arg] < 2} {
		if {$debug eq "1"} { putlog "wrong arguments, must be !user poolname username" }
		return
	}
	
 	set action "index.php?page=api&action=getuserstatus&id=[lindex $arg 1]&api_key="
 	
 	set mask [string trimleft $host ~]
 	regsub -all {@([^\.]*)\.} $mask {@*.} mask	 	
 	set mask *!$mask
 
  	if {[info exists help_blocked($mask)]} {
    	  putquick "NOTICE $nick :You have been blocked for $help_blocktime Seconds, please be patient..."
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
    	putquick "PRIVMSG $chan :Access to Userdata denied"
    	return 0
    }
    
    set results [::json::json2dict $data]
    
	foreach {key value} $results {
		foreach {sub_key sub_value} $value {
			if {$sub_key eq "data"} {
				#putlog "Sub: $sub_value"
				foreach {elem elem_val} $sub_value {
					#putlog "Ele: $elem - Val: $elem_val"
					
					foreach {subelem subelem_val} $elem_val {
						#putlog "SubEle: $subelem - SubVal: $subelem_val"
						
						if {$subelem eq "valid"} { set user_validround "Valid this round: $subelem_val" }
						if {$subelem eq "invalid"} { set user_invalidround "Invalid this round: $subelem_val" }
						
					}
					
					if {$elem eq "hashrate"} { set user_hashrate "Hashrate: $elem_val kh/s" }
					if {$elem eq "sharerate"} { set user_sharerate "Sharerate: $elem_val S/s" }
				}
			}
		}
	}
	
	if {$output eq "CHAN"} {
		putquick "PRIVMSG $chan :User Info for [string tolower [lindex $arg 1]] on [string toupper [lindex $arg 0]] Pool"
		putquick "PRIVMSG $chan :$user_hashrate | $user_validround | $user_invalidround | $user_sharerate"
	} elseif {$output eq "NOTICE"} {
		putquick "NOTICE $nick :User Info for [string tolower [lindex $arg 1]] on [string toupper [lindex $arg 0]] Pool"
		putquick "NOTICE $nick :$user_hashrate | $user_validround | $user_invalidround | $user_sharerate"
	} else {
		putquick "PRIVMSG $chan :please set output in config file"
	}

	set help_blocked($mask) 1
	utimer $help_blocktime [ list unset help_blocked($mask) ]

}

putlog "===>> Mining-Pool-Userstats - Version $scriptversion loaded"