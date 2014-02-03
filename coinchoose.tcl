#
# Coinchoose Informations
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
# info for specific coin form coinchoose
#
proc coinchoose_info {nick host hand chan arg} {
 	global help_blocktime help_blocked channels debug debugoutput output onlyallowregisteredusers output_coinchoose
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

	if {$arg eq "" || [llength $arg] < 1} {
		if {$debug eq "1"} { putlog "wrong arguments, must be !coininfo coin" }
		return
	}
	
 	set mask [string trimleft $host ~]
 	regsub -all {@([^\.]*)\.} $mask {@*.} mask	 	
 	set mask *!$mask
 
  	if {[info exists help_blocked($mask)]} {
    	  putquick "NOTICE $nick :You have been blocked for $help_blocktime Seconds, please be patient..."
    	  return
  	}
  	
  	set coinchoose_api "http://www.coinchoose.com/api.php?base=BTC"
  	
    if {[string match "*https*" [string tolower $coinchoose_api]]} {
  		set usehttps 1
    } else {
    	set usehttps 0
    }
    
  	if {$usehttps eq "1"} {
  		::http::register https 443 tls::socket
  	}
    set token [::http::geturl "$coinchoose_api"]
    set data [::http::data $token]
    ::http::cleanup $token
    if {$usehttps eq "1"} {
    	::http::unregister https
    }
    
    if {$debugoutput eq "1"} { putlog "xml: $data" }
    
    set results [::json::json2dict $data]

  	set coin_found "false"
  	if {$debug eq "1"} { putlog "Search on coinchoose for [string toupper $arg]" }

	foreach key $results {
		foreach {value sub_value} $key {
			#putlog "value: $value - sub_value: $sub_value"
			if {$value eq "0" && $sub_value eq [string toupper $arg]} {
				#putlog "--> coin found"
				set coin_found "true"
			}
			if {$value eq "name"} { set coinchoose_name "$sub_value" }
			if {$value eq "algo"} { set coinchoose_algo "$sub_value" }
			if {$value eq "currentBlocks"} { set coinchoose_currentblocks "$sub_value" }
			if {$value eq "difficulty"} { set coinchoose_diff "$sub_value" }
			if {$value eq "exchange"} { set coinchoose_exchange "$sub_value" }
			if {$value eq "price"} { set coinchoose_price "$sub_value" }
			if {$value eq "reward"} { set coinchoose_reward "$sub_value" }
			if {$value eq "networkhashrate"} {
				#set coinchoose_networkhashrate "$sub_value"
				if {$sub_value eq "0"} {
					set coinchoose_networkhashrate "???"
				} else {
					set coinchoose_networkhashrate $sub_value
				}
			}
			if {$value eq "avgProfit"} { set coinchoose_avgprofit "$sub_value" }
			if {$value eq "avgHash"} {
				#set coinchoose_avghash "$sub_value"
				if {$sub_value eq "0"} {
					set coinchoose_avghash "???"
				} else {
					set coinchoose_avghash $sub_value
				}
			}
		}
		if {$coin_found eq "true"} {
			break
		}
	}

	set lineoutput $output_coinchoose

	set lineoutput [replacevar $lineoutput "%coinchoose_name%" $coinchoose_name]
	set lineoutput [replacevar $lineoutput "%coinchoose_algo%" $coinchoose_algo]
	set lineoutput [replacevar $lineoutput "%coinchoose_currentblocks%" $coinchoose_currentblocks]
	set lineoutput [replacevar $lineoutput "%coinchoose_diff%" $coinchoose_diff]
	set lineoutput [replacevar $lineoutput "%coinchoose_exchange%" $coinchoose_exchange]
	set lineoutput [replacevar $lineoutput "%coinchoose_price%" $coinchoose_price]
	set lineoutput [replacevar $lineoutput "%coinchoose_reward%" $coinchoose_reward]
	set lineoutput [replacevar $lineoutput "%coinchoose_networkhashrate%" $coinchoose_networkhashrate]
	set lineoutput [replacevar $lineoutput "%coinchoose_avgprofit%" $coinchoose_avgprofit]
	set lineoutput [replacevar $lineoutput "%coinchoose_avghash%" $coinchoose_avghash]
	
 	if {$output eq "CHAN"} {
 		foreach advert $channels {
 			if {$advert eq $chan} {
 				putquick "PRIVMSG $chan :$lineoutput"
 			}
		}
	} elseif {$output eq "NOTICE"} {
		putquick "NOTICE $nick :$lineoutput"	
	} else {
		putquick "PRIVMSG $chan :please set output in config file"
	}
	
	set help_blocked($mask) 1
	utimer $help_blocktime [ list unset help_blocked($mask) ]

}

putlog "===>> Mining-Pool-Coinchoose - Version $scriptversion loaded"
