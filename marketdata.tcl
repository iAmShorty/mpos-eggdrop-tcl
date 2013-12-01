#
# Cryptsy Market Data
#
#
set scriptversion "v0.1"

# time to wait before next command in seconds
#
set help_blocktime "5"

# debug mode
# set to 1 to display debug messages
#
set debug "1"

# debug output
# set to 1 to display json output
# beware, lots of data
#
set debugoutput "0"

# setting the output style
#
# -> CHAN   - put all infos in channel
# -> NOTICE - sends notice to the user who triggered the command
#
set output "CHAN"

# channels to advertise new block information
#
set channels "#firstchannel #secondchannel #thirdchannel"

# cryptsy api url
#
set apiurl "http://pubapi.cryptsy.com/api.php?method=singlemarketdata&marketid="

# cryptsy market id
# 
# get market id from trade in cryptsy portal
#
# Litecoin = 3
# Fastcoin = 44
# Feathercoin = 5
#
set marketid "3"


######################################################################
##########           nothing to edit below this line        ##########
######################################################################

# key bindings
#
bind pub - !price price_info



# marketdata for specified market
#

proc price_info {nick host hand chan arg} {
 	global help_blocktime help_blocked channels debug debugoutput usehttps output marketapi marketid
	package require http
	package require json
	package require tls
	
 	set mask [string trimleft $host ~]
 	regsub -all {@([^\.]*)\.} $mask {@*.} mask	 	
 	set mask *!$mask
 
  	if {[info exists help_blocked($mask)]} {
    	  putquick "NOTICE $nick :You have been blocked for $help_blocktime Seconds, please be patient..."
    	  return
  	}
  	
  	set newurl $marketapi
  	append newurl $marketid
  	
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
    
    set trade_price "0"
    set trade_trime "0"
    set trade_label "0"
    set trade_volume "0"
        
	foreach {key value} $results {
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
		putquick "PRIVMSG $chan :$trade_price $trade_label | $trade_trime | $trade_volume"
	} elseif {$output eq "NOTICE"} {
		putquick "NOTICE $nick :$trade_price $trade_label | $trade_trime | $trade_volume"
	} else {
		putquick "PRIVMSG $chan :please set output in config file"
	}

	set help_blocked($mask) 1
	utimer $help_blocktime [ list unset help_blocked($mask) ]

}


putlog "===>> Cryptsy Market Data - Version $scriptversion loaded"