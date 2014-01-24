#
# Cryptsy Market Data
#
#


######################################################################
##########           nothing to edit below this line        ##########
##########           use config.tcl for setting options     ##########
######################################################################


# key bindings
#
bind pub - !price price_info

# info for specific market set in config
#

proc price_info {nick host hand chan arg} {
 	global help_blocktime help_blocked channels debug debugoutput usehttps output marketapi activemarket vircurex_querycoin cryptsy_marketid onlyallowregisteredusers
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

 	set mask [string trimleft $host ~]
 	regsub -all {@([^\.]*)\.} $mask {@*.} mask	 	
 	set mask *!$mask
 
  	if {[info exists help_blocked($mask)]} {
    	  putquick "NOTICE $nick :You have been blocked for $help_blocktime Seconds, please be patient..."
    	  return
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

    if {[string match "*https*" [string tolower $marketapi]]} {
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
    
    set results [::json::json2dict $data]
    
    #putlog "DATA: $results"
    
	if {$activemarket eq "1"} {
		market_coinse $chan $results
	} elseif {$activemarket eq "2"} { 
		market_vircurex $chan $results
	} elseif {$activemarket eq "3"} { 
		market_cryptsy $chan $results
	} else {
		return
	}

	set help_blocked($mask) 1
	utimer $help_blocktime [ list unset help_blocked($mask) ]
	
}



proc market_coinse {chan marketdataresult} {
	global channels debug debugoutput output coinse_querycoin
	
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
							set altcoin "Coin: $elem_val"
						}						

						foreach {elem2 elem_val2} $elem_val {
							#putlog "DATA: $elem2"

							if {$elem2 eq "24h"} {
								foreach {elem3 elem_val3} $elem_val2 {
									#putlog "DATA: $elem3 - $elem_val3"
									if {$elem3 eq "volume"} { set trade_volume "Volume: $elem_val3" }
									if {$elem3 eq "h"} { set trade_high "High: $elem_val3" }
									if {$elem3 eq "l"} { set trade_low "Low: $elem_val3" }
									if {$elem3 eq "avg_rate"} { set trade_avg "AVG: $elem_val3" }
								}
							}
						}
					}
				}
			}
		}
	}

	if {$output eq "CHAN"} {
		putquick "PRIVMSG $chan :Market: Coins-E | $altcoin | $trade_high $basecoin | $trade_low $basecoin | $trade_avg $basecoin | $trade_volume"
	} elseif {$output eq "NOTICE"} {
		putquick "NOTICE $nick :Market: Coins-E | $altcoin | $trade_high $basecoin | $trade_low $basecoin | $trade_avg $basecoin | $trade_volume"
	} else {
		putquick "PRIVMSG $chan :please set output in config file"
	}
}


proc market_vircurex {chan marketdataresult} {
	global channels debug debugoutput output
	
	if {$marketdataresult eq "Unknown currency"} {
		putquick "PRIVMSG $chan :Unknown currency, please check api settings"
		return
	}
	
	foreach {key value} $marketdataresult {
		#putlog "Key: $key - $value"
		if {$key eq "base"} { set trade_base "Coin: $value" }
		if {$key eq "alt"} { set trade_alt $value }
		if {$key eq "value"} { set trade_price "Latest Price: $value" }
	}
	
	if {$output eq "CHAN"} {
		putquick "PRIVMSG $chan :Market: Vircurex | $trade_base | $trade_price $trade_alt"
	} elseif {$output eq "NOTICE"} {
		putquick "NOTICE $nick :Market: Vircurex | $trade_base | $trade_price $trade_alt"
	} else {
		putquick "PRIVMSG $chan :please set output in config file"
	}
}


proc market_cryptsy {chan marketdataresult} {
	global channels debug debugoutput output
	
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
											
						if {$elem2 eq "lasttradeprice"} { set trade_price "Latest Price: $elem_val2" }
						if {$elem2 eq "lasttradetime"} { set trade_trime "Last Trade: $elem_val2" }
						if {$elem2 eq "label"} { set trade_label "$elem_val2" }
						if {$elem2 eq "volume"} { set trade_volume "Volume: $elem_val2" }
					
					}
				}
			}
		}
	}

	if {$output eq "CHAN"} {
		putquick "PRIVMSG $chan :Market: Cryptsy | $trade_price $trade_label | $trade_trime | $trade_volume"
	} elseif {$output eq "NOTICE"} {
		putquick "NOTICE $nick :Market: Cryptsy | $trade_price $trade_label | $trade_trime | $trade_volume"
	} else {
		putquick "PRIVMSG $chan :please set output in config file"
	}
	
	return
	
}




putlog "===>> Market Data - Version $scriptversion loaded"