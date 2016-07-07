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
	global help_blocktime help_blocked channels debug debugoutput usehttps output onlyallowregisteredusers output_marketdata command_protect marketapi_coinse marketapi_vircurex marketapi_mintpal

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

	if {$arg eq "" || [llength $arg] != 3} {
		if {$debug eq "1"} { putlog "wrong arguments, must be !price altcoin basecoin exchange" }
		return
	}
	
	set query_altcoin [string toupper [lindex $arg 0]]
	set query_basecoin [string toupper [lindex $arg 1]]
	set query_exchange [string toupper [lindex $arg 2]]
	set newurl ""

	set trade_price "0"
	set trade_trime "0"
	set trade_label "0"
	set trade_volume "0"

	if {$query_exchange eq "COINS-E"} {
		set market_name "Coins-E"
		set newurl $marketapi_coinse
		putlog "URL: $newurl"
	} elseif {$query_exchange eq "VIRCUREX"} {
		set market_name "Vircurex"
		set newurl $marketapi_vircurex
		append newurl "?base=$query_basecoin&alt=$query_altcoin"
		putlog "URL: $newurl"
	} elseif {$query_exchange eq "MINTPAL"} {
		set market_name "MintPal"
		set newurl $marketapi_mintpal
		append newurl "$query_altcoin/$query_basecoin"
		putlog "URL: $newurl"
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

	if {$query_exchange eq "COINS-E"} {
		market_coinse $nick $chan $results $query_altcoin $query_basecoin
	} elseif {$query_exchange eq "VIRCUREX"} { 
		market_vircurex $nick $chan $results $query_altcoin $query_basecoin
	} elseif {$query_exchange eq "MINTPAL"} { 
		market_mintpal $nick $chan $results $query_altcoin $query_basecoin
	} else {
		return
	}

	set help_blocked($mask) 1
	utimer $help_blocktime [ list unset help_blocked($mask) ]
	
}

#
# output for coins-e api
#
proc market_coinse {nick chan marketdataresult query_altcoin query_basecoin} {
	global debug debugoutput output output_marketdata_coinse
	
	set querycoinpair "$query_altcoin"
	append querycoinpair "_"
	append querycoinpair "$query_basecoin"
	
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
	set lineoutput [replacevar $lineoutput "%marketdata_trade_basecoin%" $query_basecoin]
	set lineoutput [replacevar $lineoutput "%marketdata_trade_altcoin%" $query_altcoin]
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
proc market_vircurex {nick chan marketdataresult query_altcoin query_basecoin} {
	global debug debugoutput output output_marketdata_vircurex
	
	if {$debug eq "1"} { putlog "QUERY: $query_altcoin\/$query_basecoin" }

	set trade_base "null"
	set trade_price "null"
	set trade_alt "null"
	set error_status "null"
	set error_message "null"
	
	foreach {key value} $marketdataresult {
		#putlog "Key: $key - $value"
		if {$key eq "status"} { set error_status $value }
		if {$key eq "status_text"} { set error_message $value }
		if {$key eq "value"} { set trade_price $value }
	}

	if {$error_status eq "8"} { 
		putquick "PRIVMSG $chan :Unknown currency pair"
		return
	}

	set lineoutput $output_marketdata_vircurex
	set lineoutput [replacevar $lineoutput "%marketdata_market%" "Vircurex"]
	set lineoutput [replacevar $lineoutput "%marketdata_trade_basecoin%" $query_basecoin]
	set lineoutput [replacevar $lineoutput "%marketdata_trade_altcoin%" $query_altcoin]
	set lineoutput [replacevar $lineoutput "%marketdata_trade_price%" $trade_price]
	set lineoutput [replacevar $lineoutput "%marketdata_trade_alt%" $trade_alt]
	
	if {$output eq "CHAN"} {
		putquick "PRIVMSG $chan :$lineoutput"
	} elseif {$output eq "NOTICE"} {
		putquick "NOTICE $nick :$lineoutput"
	} else {
		putquick "PRIVMSG $chan :please set output in config file"
	}
}

#
# output for mintpal api
#
proc market_mintpal {nick chan marketdataresult query_altcoin query_basecoin} {
	global debug debugoutput output output_marketdata_mintpal
	
	if {$debug eq "1"} { putlog "QUERY: $query_altcoin\/$query_basecoin" }

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

	set lineoutput $output_marketdata_mintpal
	set lineoutput [replacevar $lineoutput "%marketdata_market%" "MintPal"]
	set lineoutput [replacevar $lineoutput "%marketdata_trade_basecoin%" $query_basecoin]
	set lineoutput [replacevar $lineoutput "%marketdata_trade_altcoin%" $query_altcoin]
	set lineoutput [replacevar $lineoutput "%marketdata_trade_last%" $trade_last]
	set lineoutput [replacevar $lineoutput "%marketdata_trade_high%" $trade_high]
	set lineoutput [replacevar $lineoutput "%marketdata_trade_low%" $trade_low]
	set lineoutput [replacevar $lineoutput "%marketdata_trade_vol%" $trade_vol]
	
	if {$output eq "CHAN"} {
		putquick "PRIVMSG $chan :$lineoutput"
	} elseif {$output eq "NOTICE"} {
		putquick "NOTICE $nick :$lineoutput"
	} else {
		putquick "PRIVMSG $chan :please set output in config file"
	}
}

putlog "===>> Mining-Pool-Marketdata - Version $scriptversion loaded"
