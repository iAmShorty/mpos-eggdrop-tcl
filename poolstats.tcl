# Pool Stats

set scriptversion "v0.1 ALPHA"
set help_blocktime "10"

set apiurl "http://yourdomain.td/"
set apikey "YOURAPIKEYFROMMPOS"


bind pub - !pool pool_info
bind pub - !block block_info
bind pub - !last last_info
bind pub - !user user_info
bind pub - !help printUsage


proc printUsage {nick host hand chan arg} {
    putquick "NOTICE $nick :Usage: !block       - Blockstats"
    putquick "NOTICE $nick :       !pool        - Pool Information"
    putquick "NOTICE $nick :       !last        - Information about last found Block"
    putquick "NOTICE $nick :       !user <user> - Information about a specific User"
    putquick "NOTICE $nick :       !help        - This help text"
}





proc user_info {nick host hand chan arg} {
 	global apiurl apikey help_blocktime help_blocked
 	
 	set action "index.php?page=api&action=getuserstatus&id=$arg&api_key="
 	
 	set mask [string trimleft $host ~]
 	regsub -all {@([^\.]*)\.} $mask {@*.} mask	 	
 	set mask *!$mask
 
  	if {[info exists help_blocked($mask)]} {
    	  putquick "NOTICE $nick :You have been blocked for $help_blocktime Seconds, please be patient..."
    	  sql disconnect
    	  return
  	}
  	
  	set newurl $apiurl
  	append newurl $action
  	append newurl $apikey
  	
    set token [::http::geturl "$newurl"]
    set data [::http::data $token]
    ::http::cleanup $token
    #putlog "xml: $data"
    set results [::json::json2dict $data]
    
    #putlog $results
    
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
					
					if {$elem eq "hashrate"} { set user_hashrate "Hashrate: $elem_val" }
					if {$elem eq "sharerate"} { set user_sharerate "Sharerate: $elem_val" }
				}
			}
		}
	}
	
	putquick "PRIVMSG $chan :Username: $arg | $user_hashrate kh/s | $user_validround | $user_invalidround | $user_sharerate"

	set help_blocked($mask) 1
	utimer $help_blocktime [ list unset help_blocked($mask) ]

}



proc last_info {nick host hand chan arg } {
 	global sqluser sqlpass sqlhost sqldb help_blocktime help_blocked
 	sql connect $sqlhost $sqluser $sqlpass
 	sql selectdb $sqldb

 	set mask [string trimleft $host ~]
 	regsub -all {@([^\.]*)\.} $mask {@*.} mask	 	
 	set mask *!$mask
 
  	if {[info exists help_blocked($mask)]} {
    	  putquick "NOTICE $nick : You have been blocked for $help_blocktime Seconds, please be patient..."
    	  return
  	}

	foreach row [sql query "SELECT height, confirmations, difficulty, shares, account_id from blocks ORDER BY id DESC LIMIT 1"] {
		set Block [lindex $row 0]
		set Confirmed [lindex $row 1]
		set Difficulty [lindex $row 2]
		set Shares [lindex $row 3]
		set AccID [lindex $row 4]
		set Founder [sql query "select username from accounts WHERE id = '$AccID'"]
		putquick "PRIVMSG $chan :Last Block: $Block | Shares: $Shares | Confirmations: $Confirmed | Solved By: $Founder"
 	}

 	sql disconnect

	set help_blocked($mask) 1
	utimer $help_blocktime [ list unset help_blocked($mask) ]

}



# Pool Stats
proc pool_info {nick host hand chan arg} {
    global apiurl apikey
	package require http
	package require json
	
	set action "index.php?page=api&action=getpoolstatus&api_key="
	
 	set mask [string trimleft $host ~]
 	regsub -all {@([^\.]*)\.} $mask {@*.} mask	 	
 	set mask *!$mask
 
  	if {[info exists help_blocked($mask)]} {
    	  putquick "NOTICE $nick : You have been blocked for $help_blocktime Seconds, please be patient..."
    	  return
  	}

  	set newurl $apiurl
  	append newurl $action
  	append newurl $apikey
  	
    set token [::http::geturl "$newurl"]
    set data [::http::data $token]
    ::http::cleanup $token
    #putlog "xml: $data"
    set results [::json::json2dict $data]

	foreach {key value} $results {
		foreach {sub_key sub_value} $value {
			putlog "Sub: $sub_key - $sub_value"
			if {$sub_key eq "runtime"} { set pool_runtime "Runtime: $sub_value" }
			
			if {$sub_key eq "data"} {
				#putlog "Sub: $sub_value"
				foreach {elem elem_val} $sub_value {
					#putlog "Ele: $elem - Val: $elem_val"
				
      				if {$elem eq "hashrate"} { set pool_hashrate "Hashrate: $elem_val" }
      				if {$elem eq "efficiency"} { set pool_efficiency "Efficiency: $elem_val" } 
      				if {$elem eq "workers"} { set pool_workers "Workers: $elem_val" } 
      				if {$elem eq "nethashrate"} { set pool_nethashrate "Net Hashrate: $elem_val khash" } 
				
				}
			}
		}
	}

    #putlog $results
    putquick "PRIVMSG $chan :$pool_runtime | $pool_hashrate khash | $pool_efficiency | $pool_workers | $pool_nethashrate"

}



# Block Stats
proc block_info {nick host hand chan arg} {
    global apiurl apikey
	package require http
	package require json
	
	set action "index.php?page=api&action=getpoolstatus&api_key="
	
 	set mask [string trimleft $host ~]
 	regsub -all {@([^\.]*)\.} $mask {@*.} mask	 	
 	set mask *!$mask
 
  	if {[info exists help_blocked($mask)]} {
    	  putquick "NOTICE $nick : You have been blocked for $help_blocktime Seconds, please be patient..."
    	  return
  	}
  	
  	set newurl $apiurl
  	append newurl $action
  	append newurl $apikey
  	
    set token [::http::geturl "$newurl"]
    set data [::http::data $token]
    ::http::cleanup $token
    #putlog "xml: $data"
    set results [::json::json2dict $data]
    
    #putlog $results
    
	foreach {key value} $results {
		foreach {sub_key sub_value} $value {
			if {$sub_key eq "data"} {
				#putlog "Sub: $sub_value"
				foreach {elem elem_val} $sub_value {
					#putlog "Ele: $elem - Val: $elem_val"

      				if {$elem eq "currentnetworkblock"} { set block_current "Current Block: $elem_val" } 
      				if {$elem eq "nextnetworkblock"} { set block_next "Next Block: $elem_val" } 
      				if {$elem eq "lastblock"} { set block_last "Last Block: $elem_val" }
      				if {$elem eq "networkdiff"} { set block_diff "Difficulty: $elem_val" } 
      				if {$elem eq "esttime"} { set block_time "Est. Time to resolve: $elem_val" } 
      				if {$elem eq "estshares"} { set block_shares "Est. Shares to resolve: $elem_val" } 
      				if {$elem eq "timesincelast"} { 
      					set timediff [expr {$elem_val / 60}]
      					#set timediff $elem_val
      					set block_timelast "Time since last Block: $timediff minutes"
      				}
				
				}
			}
		}
	}

    putquick "PRIVMSG $chan :$block_current | $block_next | $block_last | $block_diff | $block_time | $block_shares | $block_timelast | $block_last"
	#putquick "PRIVMSG $chan :$sub_value"
}








putlog "===>> Mining-Pool-Stats - Version $scriptversion - geladen"