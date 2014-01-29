#
# Checking for new blocks
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

# start timer if set
# and check if started when bot rehashes
# prevent from double timers
#
if {$blockchecktime ne "0"} {
	# check if timer is running
	# else a rehash starts a new timer
	if {![info exists checknewblocks_running]} {
		if {$debug eq "1"} { putlog "Timer active" }
		
 	   	utimer $blockchecktime checknewblocks
	    set checknewblocks_running 1
	}
}

# checking for new blocks
#
proc checknewblocks {} {
	global blockchecktime channels debug debugoutput confirmations scriptpath lastblockfile poolstocheck pools
	package require http
	package require json
	package require tls
	
 	set action "index.php?page=api&action=getblocksfound&api_key="
 	set advertise_block 0
 	set writeblockfile "no"
 	
 	set last_block "null"
 	set last_shares "null"
 	set last_finder "null"
 	set last_status "null"
 	set last_confirmations "null"
   	set last_estshares "null"
 
	dict for {id info} $pools {

		foreach {poolcoin} $poolstocheck {
			if {[string toupper $id] eq [string toupper $poolcoin]} {
				if {$debug eq "1"} { putlog "checking for new blocks on [string toupper $id] Pool" }
				
   	 			#putlog "Pool: [string toupper $id]"
    			dict with info {
       				set pool_info "[string toupper $id] $apiurl $apikey"
       		
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
  			
  					# setting logfile to right path
  					set logfilepath $scriptpath
  					append logfilepath "[string tolower [lindex $pool_info 0]]/"
  					if {![file isdirectory $logfilepath]} {
  						file mkdir $logfilepath
					}
  					append logfilepath $lastblockfile
  			
  					putlog "File $logfilepath"
  	
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
    					foreach advert $channels {
    						putquick "PRIVMSG $advert :Access to Newblockdata denied"
    					}
   					} elseif {$data eq ""} {
    					if {$debug eq "1"} { putlog "no data: $data" }
   					} else {

						if {[catch { set results [ [::json::json2dict $data] ]
 	  		 				if {$debug eq "1"} { putlog "no data: $data" }
  	  						utimer $blockchecktime checknewblocks
   	 						return 0
						}]} {
   			 				if {$debug eq "1"} { putlog "data found" }
						}

  	  					set results [::json::json2dict $data]
  	  	
  	  					set blocklist {}
  	  	
						foreach {key value} $results {
							#putlog "Key: $key - $value"
							foreach {sub_key sub_value} $value {
								#putlog "Sub1: $sub_key - $sub_value"
								if {$sub_key eq "data"} {
									#putlog "Sub2: $sub_value"
									foreach {elem} $sub_value {
										#putlog "Ele1: $elem"
										foreach {elem2 elem_val2} $elem {
											#putlog "Ele2: $elem2 - Val: $elem_val2"
      										if {$elem2 eq "height"} { 
      											set last_block "$elem_val2" 
      											if {$debug eq "1"} { putlog "Block: $elem_val2" }
      										}
      										if {$elem2 eq "shares"} { set last_shares "$elem_val2" } 
      										if {$elem2 eq "estshares"} { set last_estshares "$elem_val2" }
											if {$elem2 eq "finder"} { set last_finder "$elem_val2" }
											if {$elem2 eq "difficulty"} { set last_diff "$elem_val2" }
											if {$elem2 eq "is_anonymous"} { set last_anon "$elem_val2" }
											if {$elem2 eq "worker_name"} { set last_worker "$elem_val2" }
											if {$elem2 eq "amount"} { set last_amount "$elem_val2" }
											if {$elem2 eq "confirmations"} {
												#if {$debug eq "1"} { putlog "Confirmation: $elem_val2" }
												set last_confirmations "$elem_val2"
												if {$elem_val2 eq "-1"} {
													set last_status "Orphan"
												} else {
													set last_status "Valid"
												}
											}
										}
										
										#if {$debug eq "1"} { putlog "check values: [string tolower [lindex $pool_info 0]] - $last_block - $last_confirmations" }
										
										 if {$last_shares eq "null"} {
											#if {$debug eq "1"} {
											#	putlog "skipping block because last shares has a value of null"
											#	putlog "last shares: $last_shares"
											#}
										} else {
											set advertise_block [check_block [string tolower [lindex $pool_info 0]] $last_block $last_confirmations]
										
											#if {$debug eq "1"} { putlog "advertise_block: $advertise_block"}
											#if {$debug eq "1"} { putlog "values: $last_block - $last_status - $last_estshares - $last_shares - $last_finder"}
										
											if {$advertise_block eq "0"} {
												#if {$debug eq "1"} { putlog "No New Block: $last_block" }
												lappend blocklist $last_block
											} elseif {$advertise_block eq "notconfirmed"} {
												#if {$debug eq "1"} { putlog "Block not confirmed" }
											} else {
												set writeblockfile "yes"
												advertise_block [string toupper [lindex $pool_info 0]] $last_block $last_status $last_estshares $last_shares $last_finder $last_confirmations $last_diff $last_anon $last_worker $last_amount
												lappend blocklist $last_block
											}
										}
									}
								}
							}
						}
					}
	
					if {$writeblockfile eq "yes"} {
						set fh [open $logfilepath w]
						foreach arr_elem $blocklist {
    						#putlog "arr: $arr_elem"
    						puts $fh [join $arr_elem "\n"]
						}
						close $fh
					} else {
						set lastblock [FileTextReadLine $logfilepath 0 0]
						putlog "No New [string toupper [lindex $pool_info 0]] Block found - $lastblock"
					}
    			}
			}
		}
	}

	utimer $blockchecktime checknewblocks
}                                      

# checking the block
#
proc check_block {coinname blockheight blockconfirmations} {
	global debug debugoutput confirmations scriptpath lastblockfile
	
	#if {$debug eq "1"} { putlog "Checking Block: $blockheight" }

  	# setting logfile to right path
	set logfilepath $scriptpath
  	append logfilepath "[string tolower $coinname]/"
  	if {![file isdirectory $logfilepath]} {
  		file mkdir $logfilepath
	}
  	append logfilepath $lastblockfile
  	
  	set newblock "0"
  	
	if { [file_read $logfilepath] eq "0" } {
			
		# check if lastblocksfile exists
		#
		if { [file_check $logfilepath] eq "0" } {
			if {$debug eq "1"} { putlog "file $logfilepath does not exist" }
			if {[file_write $logfilepath new] eq "1" } { putlog "file $logfilepath created" }
		} else {
			if {$debug eq "1"} { putlog "can't read $logfilepath"}
		}

	} else {
	
		set blockfile [open $logfilepath]
		# Read until we find the start pattern
		while {[gets $blockfile line] >= 0} {
			#putlog "LINE: $line"
  	  		if { [string match "$blockheight" $line] } {
				set newblock "0"
				break
  	  		} else {
				set newblock $line
			}
		}
		close $blockfile
		
		if {$newblock ne "0"} {
			if {$blockconfirmations eq "-1"} {
				return $newblock
			} elseif {$blockconfirmations > $confirmations} {
				return $newblock
			} else {
				if {$debug eq "1"} { putlog "block not confirmed: $blockconfirmations - $confirmations" }
				return "notconfirmed"
			}
		} else {
			return "0"
		}

	}

}

# advertising the block
#
proc advertise_block {blockfinder_coinname blockfinder_newblock blockfinder_laststatus blockfinder_lastestshares blockfinder_lastshares blockfinder_lastfinder blockfinder_confirmations blockfinder_diff blockfinder_anon blockfinder_worker blockfinder_amount} {
	global channels debug debugoutput scriptpath lastblockfile output_findblocks

  	# setting logfile to right path
	set logfilepath $scriptpath
  	append logfilepath "[string tolower $blockfinder_coinname]/"
  	if {![file isdirectory $logfilepath]} {
  		file mkdir $logfilepath
	}
  	append logfilepath $lastblockfile
  	
  	set blockfinder_lastblock [FileTextReadLine $logfilepath 0 0]
  	
	if {$debug eq "1"} { putlog "New Block: $blockfinder_newblock" }
	if {$debug eq "1"} { putlog "New / Last: $blockfinder_newblock - $blockfinder_lastblock" }
	
	if {$debug eq "1"} { putlog "calc: [expr {double((double($blockfinder_lastshares)/double($blockfinder_lastestshares))*100)}]" }
	
	set blockfinder_percentage [format "%.2f" [expr {double((double($blockfinder_lastshares)/double($blockfinder_lastestshares))*100)}]]

	set lineoutput $output_findblocks
	set lineoutput [replacevar $lineoutput "%blockfinder_coinname%" $blockfinder_coinname]
	set lineoutput [replacevar $lineoutput "%blockfinder_newblock%" $blockfinder_newblock]
	set lineoutput [replacevar $lineoutput "%blockfinder_lastblock%" $blockfinder_lastblock]
	set lineoutput [replacevar $lineoutput "%blockfinder_laststatus%" $blockfinder_laststatus]
	set lineoutput [replacevar $lineoutput "%blockfinder_lastestshares%" $blockfinder_lastestshares]
	set lineoutput [replacevar $lineoutput "%blockfinder_lastshares%" $blockfinder_lastshares]
	set lineoutput [replacevar $lineoutput "%blockfinder_percentage%" $blockfinder_percentage]
	if {$blockfinder_anon eq "1"} {
		set lineoutput [replacevar $lineoutput "%blockfinder_lastfinder%" "anonymous"]
		set lineoutput [replacevar $lineoutput "%blockfinder_worker%" "anonymous"]
	} else {
		set lineoutput [replacevar $lineoutput "%blockfinder_lastfinder%" $blockfinder_lastfinder]
		set lineoutput [replacevar $lineoutput "%blockfinder_worker%" $blockfinder_worker]
	}
	set lineoutput [replacevar $lineoutput "%blockfinder_confirmations%" $blockfinder_confirmations]
	set lineoutput [replacevar $lineoutput "%blockfinder_diff%" $blockfinder_diff]
	set lineoutput [replacevar $lineoutput "%blockfinder_amount%" $blockfinder_amount]
	
	foreach advert $channels {
		putquick "PRIVMSG $advert :$lineoutput"
	}

}

putlog "===>> Mining-Pool-Findblocks - Version $scriptversion loaded"