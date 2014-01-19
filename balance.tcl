#
# MPOS eggdrop Calls
# 
# Account Balance
#

######################################################################
##########           nothing to edit below this line        ##########
##########           use config.tcl for setting options     ##########
######################################################################

# Account balance
#
proc balance_info {nick host hand chan arg} {
    global help_blocktime help_blocked channels debug debugoutput output
	package require http
	package require json
	package require tls

	if {$arg eq "" || [llength $arg] < 2} {
		if {$debug eq "1"} { putlog "wrong arguments, must be !balance poolname username" }
		return
	}
	
	set action "index.php?page=api&action=getuserbalance&id=[lindex $arg 1]&api_key="
	
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
					
      				if {$elem eq "confirmed"} { set balance_confirmed "Confirmed: $elem_val [string toupper [lindex $arg 0]]" } 
      				if {$elem eq "unconfirmed"} { set balance_unconfirmed "Unconfirmed: $elem_val [string toupper [lindex $arg 0]]" } 
      				if {$elem eq "orphaned"} { set balance_orphaned "Orphan: $elem_val [string toupper [lindex $arg 0]]" } 

				}
			}
		}
	}
	
 	if {$output eq "CHAN"} {
  		putquick "PRIVMSG $chan :[string toupper [lindex $arg 0]] Account Balance for User [lindex $arg 1]"
		putquick "PRIVMSG $chan :$balance_confirmed | $balance_unconfirmed | $balance_orphaned"	
	} elseif {$output eq "NOTICE"} {
  		putquick "NOTICE $nick :[string toupper [lindex $arg 0]] Account Balance for User [lindex $arg 1]"
		putquick "NOTICE $nick :$balance_confirmed | $balance_unconfirmed | $balance_orphaned"	
	} else {
		putquick "PRIVMSG $chan :please set output in config file"
	}
	
}

putlog "===>> Mining-Pool-Balanceinfo - Version $scriptversion loaded"