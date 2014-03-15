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
	global help_blocktime help_blocked channels debug debugoutput usehttps output marketapi activemarket vircurex_querycoin cryptsy_marketid onlyallowregisteredusers output_marketdata protected_commands sqlite_commands
	sqlite3 poolcommands $sqlite_commands

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
    
	set newurl $marketapi

	set trade_price "0"
	set trade_trime "0"
	set trade_label "0"
	set trade_volume "0"

	if {$activemarket eq "1"} {
		set market_name "Coins-E"
	} elseif {$activemarket eq "2"} {
		set market_name "Vircurex"
		append newurl "?base=$vircurex_querycoin&alt=BTC" 
	} elseif {$activemarket eq "3"} {
		set market_name "Cryptsy"
		append newurl $cryptsy_marketid
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
		market_coinse $nick $chan $results
	} elseif {$activemarket eq "2"} { 
		market_vircurex $nick $chan $results
	} elseif {$activemarket eq "3"} { 
		market_cryptsy $nick $chan $results
	} else {
		return
	}

	set help_blocked($mask) 1
	utimer $help_blocktime [ list unset help_blocked($mask) ]
	
}

#
# output for coins-e api
#
proc market_coinse {nick chan marketdataresult} {
	global debug debugoutput output coinse_querycoin output_marketdata_coinse
	
	foreach {key value} $marketdataresult {
		#putlog "DATA: $key"
		if {$key eq "markets"} {
			foreach {sub_key sub_value} $value {
				#putlog "DATA: $sub_key"
				if {$sub_key eq "$coinse_querycoin"} {
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
proc market_vircurex {nick chan marketdataresult} {
	global debug debugoutput output output_marketdata_vircurex
	
	if {$marketdataresult eq "Unknown currency"} {
		putquick "PRIVMSG $chan :Unknown currency, please check api settings"
		return
	}
	
	foreach {key value} $marketdataresult {
		#putlog "Key: $key - $value"
		if {$key eq "base"} { set trade_base "Coin: $value" }
		if {$key eq "alt"} { set trade_alt $value }
		if {$key eq "value"} { set trade_price "$value" }
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
proc market_cryptsy {nick chan marketdataresult} {
	global debug debugoutput output output_marketdata_cryptsy
	
	foreach {key value} $marketdataresult {
		#putlog "Key: $key - $value"
		foreach {sub_key sub_value} $value {
			#putlog "Subkey: $sub_key - $sub_value"	
			if {$sub_key eq "markets"} {
				foreach {elem elem_val} $sub_value {
					#putlog "Coin: $elem"
					#putlog "Ele: $elem - Val: $elem_val"
					foreach {elem2 elem_val2} $elem_val {
						#putlog "Key: $elem2"
						#putlog "Subkey: $elem_val2"
											
						if {$elem2 eq "lasttradeprice"} { set marketdata_tradeprice "$elem_val2" }
						if {$elem2 eq "lasttradetime"} { set marketdata_tradetrime "$elem_val2" }
						if {$elem2 eq "label"} { set marketdata_tradelabel "$elem_val2" }
						if {$elem2 eq "volume"} { set marketdata_tradevolume "$elem_val2" }
					
					}
				}
			}
		}
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

putlog "===>> Mining-Pool-Marketdata - Version $scriptversion loaded"
