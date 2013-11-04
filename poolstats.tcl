#
# MPOS eggdrop Calls
#
#
set scriptversion "v0.3"

# time to wait before next command in seconds
#
set help_blocktime "5"

# interval to check for new blocks in seconds
# if set to 0, the bot will do no automatic
# check for new blocks in seconds
#
set blockchecktime "60"

# debug mode
# set to 1 to display debug messages
#
set debug "1"

# debug output
# set to 1 to display json output
# beware, lots of data
#
set debugoutput "0"

# confirmations before a block will be advertised
#
#
set confirmations "20"

# file to write last found block
# no entry will put the file in eggdrops root folder
# file and folder needs to be writeable by the bot user
#
set lastblocksfile "./scripts/news/lastblock"

# channels to advertise new block information
#
set channels "#firstchannel #secondchannel #thirdchannel"

# url where mpos is installed
#
set apiurl "http://yourdomain.tld/"

# api key from mpos
#
set apikey "YOURAPIKEYFROMMPOS"





######################################################################
##########           nothing to edit below this line        ##########
######################################################################




# key bindings
#
bind pub - !pool pool_info
bind pub - !block block_info
bind pub - !last last_info
bind pub - !user user_info
bind pub - !round round_info
bind pub - !help printUsage


# start timer if set
# and check if started when bot rehashes
# prevent from double timers
#
if {$blockchecktime ne "0"} {
	# check if timer is running
	# else a rehash starts a new timer
	if {![info exists checknewblocks_running]} {
		if {$debug eq "1"} { putlog "Timer aktiviert" }
		
 	   	utimer $blockchecktime checknewblocks
	    set checknewblocks_running 1
	}
}


# print bot usage info
#

proc printUsage {nick host hand chan arg} {
    putquick "NOTICE $nick :Usage: !block       - Blockstats"
    putquick "NOTICE $nick :       !pool        - Pool Information"
    putquick "NOTICE $nick :       !round       - Round Information"
    putquick "NOTICE $nick :       !last        - Information about last found Block"
    putquick "NOTICE $nick :       !user <user> - Information about a specific User"
    putquick "NOTICE $nick :       !help        - This help text"
}


# basic file operations
#

proc file_write {blocknumber} {
    set FILE [open lastblock w]
    # write buffer
    puts -nonewline $FILE $blocknumber
    # release and return 1 for OK
    close $FILE
    return 1
}

proc file_read {} {
    # check exists and readable
    if {[file exists lastblock] && [file readable lastblock]} then {
        # open for readmode
        set FILE [open lastblock r]
     	set READ [read -nonewline $FILE]
        # release and return
        close $FILE
        return $READ
    } else {
    	return 0
    }
}

proc FileCheck {FILENAME} {
    # check file exists
    if [file exists $FILENAME] then {
        # file exists
        return 1
    } else {
        # file not exists
        return "0"
    }
}


# checking for new blocks
#

proc checknewblocks {} {
	global blockchecktime channels apiurl apikey channels debug debugoutput confirmations
	package require http
	package require json
	
 	set action "index.php?page=api&action=getblocksfound&limit=1&api_key="
 	set advertise_block 0
 	
  	set newurl $apiurl
  	append newurl $action
  	append newurl $apikey
  	
    set token [::http::geturl "$newurl"]
    set data [::http::data $token]
    ::http::cleanup $token
    if {$debugoutput eq "1"} { putlog "xml: $data" }
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

      					if {$elem2 eq "height"} { set last_block "$elem_val2" }
      					if {$elem2 eq "shares"} { set last_shares "Shares: $elem_val2" } 
						if {$elem2 eq "finder"} { set last_finder "Finder: $elem_val2" }
						if {$elem2 eq "confirmations"} {
							set last_confirmations $elem_val2
							if {$elem_val2 eq "-1"} {
								set last_status "Status: Orphaned"
							} else {
								set last_status "Status: Valid | Confirmations: $elem_val2"
							}
						}
					}
					break
				}
			}
		}
	}

	if { [file_read] eq "0" } {
		if {$debug eq "1"} { putlog "can't read file" }
	} else {
		set lastarchivedblock [file_read]
		if {"$lastarchivedblock" eq "$last_block"} {
			if {$debug eq "1"} { putlog "No New Block" }
		} else {
			if {$debug eq "1"} { putlog "New / Last: $last_block - $lastarchivedblock" }
			
			if {$last_confirmations eq "-1"} {
				set advertise_block 1
			} elseif {$last_confirmations > $confirmations} {
				set advertise_block 1
			} else {
				set advertise_block 0
			}
		}
	}

	if {$advertise_block eq "1"} {
		foreach advert $channels {
			putquick "PRIVMSG $advert :New Block Found"
			putquick "PRIVMSG $advert :New Block: #$last_block | Last Block: #$lastarchivedblock | $last_status | $last_shares | $last_finder"
		}
		#write new block to file
		if {[file_write $last_block] eq "1" } { putlog "Block saved" }
	}

	utimer $blockchecktime checknewblocks

  }                                      
  

# info for specific user
#

proc user_info {nick host hand chan arg} {
 	global apiurl apikey help_blocktime help_blocked channels debug debugoutput
 	
 	set action "index.php?page=api&action=getuserstatus&id=$arg&api_key="
 	
 	set mask [string trimleft $host ~]
 	regsub -all {@([^\.]*)\.} $mask {@*.} mask	 	
 	set mask *!$mask
 
  	if {[info exists help_blocked($mask)]} {
    	  putquick "NOTICE $nick :You have been blocked for $help_blocktime Seconds, please be patient..."
    	  return
  	}
  	
  	set newurl $apiurl
  	append newurl $action
  	append newurl $apikey
  	
    set token [::http::geturl "$newurl"]
    set data [::http::data $token]
    ::http::cleanup $token
    if {$debugoutput eq "1"} { putlog "xml: $data" }
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
	
	putquick "PRIVMSG $chan :User Info for $arg"
	putquick "PRIVMSG $chan :$user_hashrate | $user_validround | $user_invalidround | $user_sharerate"

	set help_blocked($mask) 1
	utimer $help_blocktime [ list unset help_blocked($mask) ]

}


# round info
#

proc round_info {nick host hand chan arg } {
 	global apiurl apikey help_blocktime help_blocked channels debug debugoutput
	package require http
	package require json
	
 	set action "index.php?page=api&action=getdashboarddata&api_key="
 	
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
    if {$debugoutput eq "1"} { putlog "xml: $data" }
    set results [::json::json2dict $data]
	
	foreach {key value} $results {
		#putlog "Key: $key - $value"
		foreach {sub_key sub_value} $value {
			#putlog "Sub: $sub_key - $sub_value"
			foreach {elem elem_val} $sub_value {
				#putlog "Ele: $elem - Val: $elem_val"
				if {$elem eq "pool"} {
					#putlog "Ele: $elem - Val: $elem_val"
					foreach {elem2 elem_val2} $elem_val {
						#putlog "Ele: $elem2 - Val: $elem_val2"
						if {$elem2 eq "shares"} {
							foreach {elem3 elem_val3} $elem_val2 {
								#putlog "Ele: $elem3 - Val: $elem_val3"
								
								if {$elem3 eq "valid"} { set shares_valid "$elem_val3" }
								if {$elem3 eq "invalid"} { set shares_invalid "$elem_val3" }
								if {$elem3 eq "estimated"} { set shares_estimated "Estimated Shares: $elem_val3" }
								if {$elem3 eq "progress"} { set shares_progress "Progress: $elem_val3 %" }
								
							}
						}
					}				
				}
			}
		}
	}
	
	set allshares [expr $shares_valid+$shares_invalid]

	putquick "PRIVMSG $chan :Actual Round"
 	putquick "PRIVMSG $chan :$shares_estimated | Sharecount: $allshares | Shares valid: $shares_valid | Shares invalid: $shares_invalid | $shares_progress"		

	set help_blocked($mask) 1
	utimer $help_blocktime [ list unset help_blocked($mask) ]

}


# last block found
#

proc last_info {nick host hand chan arg } {
 	global apiurl apikey help_blocktime help_blocked channels debug debugoutput
	package require http
	package require json
	
 	set action "index.php?page=api&action=getblocksfound&limit=1&api_key="
 	
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
    if {$debugoutput eq "1"} { putlog "xml: $data" }
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
	
 	putquick "PRIVMSG $chan :$last_block | $last_confirmed | $last_difficulty | $last_timefound | $last_shares | $last_estshares | $last_finder"
 	
	set help_blocked($mask) 1
	utimer $help_blocktime [ list unset help_blocked($mask) ]

}


# Pool Stats
#

proc pool_info {nick host hand chan arg} {
    global apiurl apikey help_blocktime help_blocked channels debug debugoutput
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
    if {$debugoutput eq "1"} { putlog "xml: $data" }
    set results [::json::json2dict $data]

	foreach {key value} $results {
		foreach {sub_key sub_value} $value {
			#putlog "Sub: $sub_key - $sub_value"
			if {$sub_key eq "data"} {
				#putlog "Sub: $sub_value"
				foreach {elem elem_val} $sub_value {
					#putlog "Ele: $elem - Val: $elem_val"
				
      				if {$elem eq "hashrate"} { set pool_hashrate "Hashrate: $elem_val kh/s" }
      				if {$elem eq "efficiency"} { set pool_efficiency "Efficiency: $elem_val %" } 
      				if {$elem eq "workers"} { set pool_workers "Workers: $elem_val" } 
      				if {$elem eq "nethashrate"} { set pool_nethashrate "Net Hashrate: $elem_val kh/s" } 
				
				}
			}
		}
	}
	
	putquick "PRIVMSG $chan :Pool Stats"
	putquick "PRIVMSG $chan :$pool_hashrate | $pool_efficiency | $pool_workers | $pool_nethashrate"		
    
}


# Block Stats
#

proc block_info {nick host hand chan arg} {
    global apiurl apikey help_blocktime help_blocked channels debug debugoutput
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
    if {$debugoutput eq "1"} { putlog "xml: $data" }
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
	
  	putquick "PRIVMSG $chan :Block Stats"
	putquick "PRIVMSG $chan :$block_current | $block_next | $block_last | $block_diff | $block_time | $block_shares | $block_timelast | $block_last"		
    
}


putlog "===>> Mining-Pool-Stats - Version $scriptversion loaded"