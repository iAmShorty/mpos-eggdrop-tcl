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

#
# start timer if set
# and check if started when bot rehashes
# prevent from double timers
#
if {$blockchecktime ne "0"} {
	# loop through the timers
	# and check if timer exists
	# if timer exists, kill the timer
	# and start a new timer
	foreach timer "[utimers]" {
		if {$debug eq "1"} { putlog "Timer: [lindex $timer 1]" }
		if {"[lindex $timer 1]" == "checknewblocks"} {
			if {[catch {killutimer "[lindex $timer 2]"} error]} {
				if {$debug eq "1"} { putlog "\[FINDBLOCKS\] Warning : Unable to kill findblock timer ($error)." }
				if {$debug eq "1"} { putlog "\[FINDBLOCKS\] Warning : You should .restart the bot to be safe." }
			} else {
				if {$debug eq "1"} { putlog "\[FINDBLOCKS\] NOTE : Timer killed." }
			}
		} else {
			if {$debug eq "1"} { putlog "\[FINDBLOCKS\] NOTE : no timer found." }
		}
	}
	set checknewblocks_running [utimer $blockchecktime checknewblocks]
}

#
# checking for new blocks
#
proc checknewblocks {} {
	global blockchecktime channels debug debugoutput confirmations sqlite_blockfile sqlite_poolfile blockdeletetime blockstokeep
	sqlite3 advertiseblocks $sqlite_blockfile
	sqlite3 registeredpools $sqlite_poolfile
	
	package require http
	package require json
	package require tls
	
	set action "/index.php?page=api&action=getblocksfound&api_key="
	set advertise_block 0
	set writeblockfile "no"

	set last_block "null"
	set last_shares "null"
	set last_finder "null"
	set last_status "null"
	set last_confirmations "null"
	set last_estshares "null"
	set insertedtime [unixtime]

	set poolscount [registeredpools eval {SELECT COUNT(1) FROM pools WHERE blockfinder != 0 AND apikey != 0}]
	if {$poolscount == 0} {
		putlog "\[BLOCKFINDER\] -> no active pools found"
	} else {
		putlog "\[BLOCKFINDER\] -> active Pools: $poolscount"
		foreach {apiurl poolcoin apikey} [registeredpools eval {SELECT url,coin,apikey FROM pools WHERE blockfinder != 0 AND apikey != 0} ] {
			if {$debug eq "1"} { putlog "checking for new blocks on [string toupper $poolcoin] Pool" }
			if {$debug eq "1"} { putlog "COIN: $poolcoin" }
			if {$debug eq "1"} { putlog "URL: $apiurl" }
			if {$debug eq "1"} { putlog "KEY: $apikey" }

			set newurl $apiurl
			append newurl $action
			append newurl $apikey

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
					set checknewblocks_running [utimer $blockchecktime checknewblocks]
					return 0
				}]} {
					if {$debug eq "1"} { putlog "data found" }
				}

				set results [::json::json2dict $data]

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
										#if {$debug eq "1"} { putlog "Block: $elem_val2" }
									}
									if {$elem2 eq "time"} { set last_timestamp "$elem_val2" } 
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
										
								if {$last_shares ne "null"} {
									set blockindatabase [llength [advertiseblocks eval {SELECT last_block FROM blocks WHERE last_block=$last_block AND poolcoin = $poolcoin}]]
									if {$blockindatabase == 0} {
										if {$debug eq "1"} { putlog "$poolcoin -> insert block #$last_block" }
										advertiseblocks eval {INSERT INTO blocks (poolcoin,last_block,last_status,last_estshares,last_shares,last_finder,last_confirmations,last_diff,last_anon,last_worker,last_amount,last_confirmations,posted,timestamp) VALUES ($poolcoin,$last_block,$last_status,$last_estshares,$last_shares,$last_finder,$last_confirmations,$last_diff,$last_anon,$last_worker,$last_amount,$last_confirmations,'N',$last_timestamp)}
									} else {
										if {$debug eq "1"} { putlog "$poolcoin -> updating block confirmations for block #$last_block" }
										advertiseblocks eval {UPDATE blocks SET last_confirmations=$last_confirmations, last_status=$last_status WHERE last_block=$last_block AND poolcoin = $poolcoin}
									}
								}
							}
						}
					}
				}
						
				# delete old blocks if set in config
				if {$blockdeletetime ne "0"} {
					#set deletetimeframe [expr {$insertedtime-($blockdeletetime*60)}]
					set deletetimeframe [expr {$insertedtime-$blockdeletetime}]
	
					if {$debug eq "1"} { putlog "actual Time: [clock format $insertedtime -format "%D %T"] - delete blocks before: [clock format $deletetimeframe -format "%D %T"] - keeping last $blockstokeep blocks" }
	
					if {[llength [advertiseblocks eval {SELECT block_id FROM blocks WHERE posted = 'Y' AND timestamp <= $deletetimeframe AND poolcoin = $poolcoin ORDER BY block_id DESC LIMIT $blockstokeep, 1000}]] == 0} {
						if {$debug eq "1"} { putlog "-> no blocks to delete" }
					} else {
						# workaround to delete
						# shares except the last $blockstokeep -> ORDER BY block_id DESC LIMIT $blockstokeep, 100000
						foreach {block_id last_block timestamp} [advertiseblocks eval {SELECT block_id,last_block,timestamp FROM blocks WHERE posted = 'Y' AND timestamp <= $deletetimeframe AND poolcoin = $poolcoin ORDER BY block_id DESC LIMIT $blockstokeep, 100000}] {
							if {$debug eq "1"} { putlog "delete block -> $last_block - [clock format $timestamp -format "%D %T"]" }
							advertiseblocks eval {DELETE FROM blocks WHERE block_id = $block_id AND poolcoin = $poolcoin}
						}
						if {$debug eq "1"} { putlog "-> old blocks deleted" }
					}
				}
			}
		}
	}
	
	# check sqlite for blocks
	if {[llength [advertiseblocks eval {SELECT * FROM blocks WHERE posted = 'N' AND last_confirmations >= 10}]] == 0} {
		if {$debug eq "1"} { putlog "-> no blocks to advertise" }
	} else {
		foreach {block_id poolcoin last_block last_status last_estshares last_shares last_finder last_confirmations last_diff last_anon last_worker last_amount posted last_timestamp} [advertiseblocks eval {SELECT * FROM blocks WHERE posted = 'N' AND (last_confirmations >= 10 OR last_confirmations = '-1') ORDER BY last_block ASC}] {
			if {$debug eq "1"} { putlog "$block_id - $poolcoin - $last_block - $last_status - $last_estshares - $last_shares - $last_finder - $last_confirmations - $last_diff - $last_anon - $last_worker - $last_amount" }
			advertise_block $block_id $poolcoin $last_block $last_status $last_estshares $last_shares $last_finder $last_confirmations $last_diff $last_anon $last_worker $last_amount $last_timestamp
			advertiseblocks eval {UPDATE blocks SET posted="Y" WHERE block_id=$block_id}
		}
	}
	
	advertiseblocks close
	registeredpools close
	set checknewblocks_running [utimer $blockchecktime checknewblocks]
}

#
# advertising the block
#
proc advertise_block {blockid blockfinder_coinname blockfinder_newblock blockfinder_laststatus blockfinder_lastestshares blockfinder_lastshares blockfinder_lastfinder blockfinder_confirmations blockfinder_diff blockfinder_anon blockfinder_worker blockfinder_amount blockfinder_time} {
	global channels debug debugoutput output_findblocks output_findblocks_percoin sqlite_blockfile
	sqlite3 advertiseblocks $sqlite_blockfile

	set blockfinder_lastblock [advertiseblocks eval {SELECT last_block FROM blocks WHERE posted = 'Y' AND poolcoin = $blockfinder_coinname ORDER BY last_block DESC LIMIT 1}]

	if {$debug eq "1"} { putlog "New Block: $blockfinder_newblock" }
	if {$debug eq "1"} { putlog "New / Last: $blockfinder_newblock - $blockfinder_lastblock" }
	
	if {$debug eq "1"} { putlog "calc: [expr {double((double($blockfinder_lastshares)/double($blockfinder_lastestshares))*100)}]" }
	
	set blockfinder_percentage [format "%.2f" [expr {double((double($blockfinder_lastshares)/double($blockfinder_lastestshares))*100)}]]

	if {[info exists output_findblocks_percoin([string tolower $blockfinder_coinname])]} {
		if {$debug eq "1"} { putlog "-> $blockfinder_coinname - $output_findblocks_percoin([string tolower $blockfinder_coinname])" }
		set lineoutput $output_findblocks_percoin([string tolower $blockfinder_coinname])
	} else {
		if {$debug eq "1"} { putlog "no special output!" }
		set lineoutput $output_findblocks
	}

	set lineoutput [replacevar $lineoutput "%blockfinder_coinname%" $blockfinder_coinname]
	set lineoutput [replacevar $lineoutput "%blockfinder_newblock%" $blockfinder_newblock]
	set lineoutput [replacevar $lineoutput "%blockfinder_lastblock%" $blockfinder_lastblock]
	if {$blockfinder_laststatus eq "Valid"} {
		set lineoutput [replacevar $lineoutput "%blockfinder_laststatus%" "\0039$blockfinder_laststatus\003"]
	} else {
		set lineoutput [replacevar $lineoutput "%blockfinder_laststatus%" "\0034$blockfinder_laststatus\003"]
	}
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
	set lineoutput [replacevar $lineoutput "%blockfinder_time%" [clock format $blockfinder_time -format "%D %T"]]
	
	foreach advert $channels {
		putquick "PRIVMSG $advert :$lineoutput"
	}
	
}

putlog "===>> Mining-Pool-Findblocks - Version $scriptversion loaded"