#
# Altcoin Market Data
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
# info for specific market set in config
#
proc price_info {nick host hand chan arg} {
	global help_blocktime help_blocked channels debug debugoutput usehttps output marketapi activemarket vircurex_querycoin cryptsy_marketid onlyallowregisteredusers output_marketdata command_protect

	if {$onlyallowregisteredusers eq "1"} {
		if {[check_registereduser $chan $nick] eq "false"} {
			putquick "NOTICE $nick :you are not allowed to use this command"
			putquick "NOTICE $nick :please use !request command to get access to the bot"
			return
		}
	}

	set mask [string trimleft $host ~]
	regsub -all {@([^\.]*)\.} $mask {@*.} mask	 	
	set mask *!$mask

	if {[info exists help_blocked($mask)]} {
		putquick "NOTICE $nick :You have been blocked for $help_blocktime Seconds, please be patient..."
		return
	}

	if {$command_protect eq "1"} {
		if {[channel_command_acl $chan "price"] eq "False"} {
			putquick "PRIVMSG $chan :command !price not allowed in $chan"
			return
		}
	}

	if {$arg eq "" || [llength $arg] != 2} {
		if {$debug eq "1"} { putlog "wrong arguments, must be !price coin exchange" }
		return
	}
	
	set query_coin [string toupper [lindex $arg 0]]
	set query_exchange [string toupper [lindex $arg 1]]
	set newurl $marketapi

	set trade_price "0"
	set trade_trime "0"
	set trade_label "0"
	set trade_volume "0"

	if {$activemarket eq "1"} {
		set market_name "Coins-E"
	} elseif {$activemarket eq "2"} {
		set market_name "Vircurex"
		append newurl "?base=$query_exchange&alt=$query_coin" 
	} elseif {$activemarket eq "3"} {
		set market_name "Cryptsy"
	} elseif {$activemarket eq "4"} {
		set market_name "MintPal"
		append newurl "$query_coin/$query_exchange"
	} else {
		if {$output eq "CHAN"} {
			putquick "PRIVMSG $chan :No active Market"
		} elseif {$output eq "NOTICE"} {
			putquick "NOTICE $nick :No active Market"
		} else {
			putquick "PRIVMSG $chan :No active Market"
		}
		return
	}

	set data [check_httpdata $newurl]
	if { [regexp -nocase {error} $data] } {
		putlog $data
		return
	}

	if {$debugoutput eq "1"} { putlog "xml: $data" }

	set results [::json::json2dict $data]

	#putlog "DATA: $results"

	if {$activemarket eq "1"} {
		market_coinse $nick $chan $results $query_coin $query_exchange
	} elseif {$activemarket eq "2"} { 
		market_vircurex $nick $chan $results $query_coin $query_exchange
	} elseif {$activemarket eq "3"} { 
		market_cryptsy $nick $chan $results $query_coin $query_exchange
	} elseif {$activemarket eq "4"} { 
		market_mintpal $nick $chan $results $query_coin $query_exchange
	} else {
		return
	}

	set help_blocked($mask) 1
	utimer $help_blocktime [ list unset help_blocked($mask) ]
	
}

#
# output for coins-e api
#
proc market_coinse {nick chan marketdataresult query_coin query_exchange} {
	global debug debugoutput output coinse_querycoin output_marketdata_coinse
	
	set querycoinpair "$query_coin"
	append querycoinpair "_"
	append querycoinpair "$query_exchange"
	
	if {$debug eq "1"} { putlog "QUERY: $querycoinpair" }

	set trade_volume "null"
	set trade_high "null"
	set trade_low "null"
	set trade_avg "null"
	
	foreach {key value} $marketdataresult {
		#putlog "DATA: $key"
		if {$key eq "markets"} {
			foreach {sub_key sub_value} $value {
				#putlog "DATA: $sub_key"
				if {$sub_key eq "$querycoinpair"} {
					#putlog "DATA: $sub_value"
					foreach {elem elem_val} $sub_value {
						#putlog "DATA: $elem"
						if {$elem eq "c2"} {
							set basecoin $elem_val
						}
						if {$elem eq "c1"} {
							set altcoin "$elem_val"
						}						

						foreach {elem2 elem_val2} $elem_val {
							#putlog "DATA: $elem2"

							if {$elem2 eq "24h"} {
								foreach {elem3 elem_val3} $elem_val2 {
									#putlog "DATA: $elem3 - $elem_val3"
									if {$elem3 eq "volume"} { set trade_volume "$elem_val3" }
									if {$elem3 eq "h"} { set trade_high "$elem_val3" }
									if {$elem3 eq "l"} { set trade_low "$elem_val3" }
									if {$elem3 eq "avg_rate"} { set trade_avg "$elem_val3" }
								}
							}
						}
					}
				}
			}
		}
	}

	if {$trade_volume eq "null" } { 
		putquick "PRIVMSG $chan :Unknown currency pair"
		return
	}

	set lineoutput $output_marketdata_coinse
	set lineoutput [replacevar $lineoutput "%marketdata_market%" "Coins-E"]
	set lineoutput [replacevar $lineoutput "%marketdata_altcoin%" $altcoin]
	set lineoutput [replacevar $lineoutput "%marketdata_tradehigh%" $trade_high]
	set lineoutput [replacevar $lineoutput "%marketdata_tradelow%" $trade_low]
	set lineoutput [replacevar $lineoutput "%marketdata_tradeavg%" $trade_avg]
	set lineoutput [replacevar $lineoutput "%marketdata_tradevolume%" $trade_volume]
	set lineoutput [replacevar $lineoutput "%marketdata_basecoin%" $basecoin]

	if {$output eq "CHAN"} {
		putquick "PRIVMSG $chan :$lineoutput"
	} elseif {$output eq "NOTICE"} {
		putquick "NOTICE $nick :$lineoutput"
	} else {
		putquick "PRIVMSG $chan :please set output in config file"
	}
}

#
# output for vircurex api
#
proc market_vircurex {nick chan marketdataresult query_coin query_exchange} {
	global debug debugoutput output output_marketdata_vircurex
	
	if {$debug eq "1"} { putlog "QUERY: $query_coin\/$query_exchange" }

	set trade_base "null"
	set trade_price "null"
	set trade_alt "null"
	set error_status "null"
	set error_message "null"
	
	foreach {key value} $marketdataresult {
		#putlog "Key: $key - $value"
		if {$key eq "status"} { set error_status $value }
		if {$key eq "status_text"} { set error_message $value }
		if {$key eq "base"} { set trade_base $value }
		if {$key eq "alt"} { set trade_alt $value }
		if {$key eq "value"} { set trade_price $value }
	}

	if {$error_status eq "8"} { 
		putquick "PRIVMSG $chan :Unknown currency pair"
		return
	}

	set lineoutput $output_marketdata_vircurex
	set lineoutput [replacevar $lineoutput "%marketdata_market%" "Vircurex"]
	set lineoutput [replacevar $lineoutput "%trade_base%" $trade_base]
	set lineoutput [replacevar $lineoutput "%trade_price%" $trade_price]
	set lineoutput [replacevar $lineoutput "%trade_alt%" $trade_alt]
	
	if {$output eq "CHAN"} {
		putquick "PRIVMSG $chan :$lineoutput"
	} elseif {$output eq "NOTICE"} {
		putquick "NOTICE $nick :$lineoutput"
	} else {
		putquick "PRIVMSG $chan :please set output in config file"
	}
}

#
# output for cryptsy api
#
proc market_cryptsy {nick chan marketdataresult query_coin query_exchange} {
	global debug debugoutput output output_marketdata_cryptsy
	
	if {$debug eq "1"} { putlog "QUERY: $query_coin\/$query_exchange" }
	
	set marketdata_tradeprice "null"
	set marketdata_tradetrime "null"
	set marketdata_tradelabel "null"
	set marketdata_tradevolume "null"
	
	foreach {key value} $marketdataresult {
		#putlog "Key: $key - $value"
		foreach {sub_key sub_value} $value {
			#putlog "Subkey: $sub_key - $sub_value"	
			if {$sub_key eq "markets"} {
				foreach {elem elem_val} $sub_value {
					#putlog "Coin: $elem"
					#putlog "Ele: $elem - Val: $elem_val"
					if {$elem eq "$query_coin\/$query_exchange"} {
						putlog "DATA FOUND"
						foreach {elem2 elem_val2} $elem_val {
							#putlog "Key: $elem2"
							#putlog "Subkey: $elem_val2"

							if {$elem2 eq "lasttradeprice"} { set marketdata_tradeprice "$elem_val2" }
							if {$elem2 eq "lasttradetime"} { set marketdata_tradetrime "$elem_val2" }
							if {$elem2 eq "label"} { set marketdata_tradelabel "$elem_val2" }
							if {$elem2 eq "volume"} { set marketdata_tradevolume "$elem_val2" }
					
						}
						break
					}
				}
			}
		}
	}
	
	if {$marketdata_tradeprice eq "null"} { 
		putquick "PRIVMSG $chan :Unknown currency pair"
		return
	}
	
	set lineoutput $output_marketdata_cryptsy
	set lineoutput [replacevar $lineoutput "%marketdata_market%" "Cryptsy"]
	set lineoutput [replacevar $lineoutput "%marketdata_tradeprice%" $marketdata_tradeprice]
	set lineoutput [replacevar $lineoutput "%marketdata_tradelabel%" $marketdata_tradelabel]
	set lineoutput [replacevar $lineoutput "%marketdata_tradetrime%" $marketdata_tradetrime]
	set lineoutput [replacevar $lineoutput "%marketdata_tradevolume%" $marketdata_tradevolume]
	
	if {$output eq "CHAN"} {
		putquick "PRIVMSG $chan :$lineoutput"
	} elseif {$output eq "NOTICE"} {
		putquick "NOTICE $nick :$lineoutput"
	} else {
		putquick "PRIVMSG $chan :please set output in config file"
	}
	
	return
	
}

#
# output for mintpal api
#
proc market_mintpal {nick chan marketdataresult query_coin query_exchange} {
	global debug debugoutput output output_marketdata_vircurex
	
	if {$debug eq "1"} { putlog "QUERY: $query_coin\/$query_exchange" }

	set trade_last "null"
	set trade_high "null"
	set trade_low "null"
	set trade_vol "null"
	set error_status "null"
	set error_message "null"
	
	#putlog "DATA: $marketdataresult"
	
	foreach {key value} $marketdataresult {
		#putlog "Key: $key - $value"
		foreach {sub_key sub_value} $key {
			#putlog "Key: $sub_key - $sub_value"
			if {$sub_key eq "code"} { set error_status $sub_value }
			if {$sub_key eq "message"} { set error_message $sub_value }
			if {$sub_key eq "24hhigh"} { set trade_high $sub_value }
			if {$sub_key eq "24hlow"} { set trade_low $sub_value }
			if {$sub_key eq "24hvol"} { set trade_vol $sub_value }
			if {$sub_key eq "last_price"} { set trade_last $sub_value }
		}

	}

	if {$error_status eq "404" || $error_message eq "Not Found"} {
		putquick "PRIVMSG $chan :Unknown currency pair"
		return
	}

	set lineoutput $output_marketdata_vircurex
	set lineoutput [replacevar $lineoutput "%marketdata_market%" "MintPal"]
	set lineoutput [replacevar $lineoutput "%trade_base%" $query_exchange]
	set lineoutput [replacevar $lineoutput "%trade_alt%" $query_coin]
	set lineoutput [replacevar $lineoutput "%trade_last%" $trade_last]
	set lineoutput [replacevar $lineoutput "%trade_high%" $trade_high]
	set lineoutput [replacevar $lineoutput "%trade_low%" $trade_low]
	set lineoutput [replacevar $lineoutput "%trade_vol%" $trade_vol]
	
	if {$output eq "CHAN"} {
		putquick "PRIVMSG $chan :$lineoutput"
	} elseif {$output eq "NOTICE"} {
		putquick "NOTICE $nick :$lineoutput"
	} else {
		putquick "PRIVMSG $chan :please set output in config file"
	}
}

putlog "===>> Mining-Pool-Marketdata - Version $scriptversion loaded"
