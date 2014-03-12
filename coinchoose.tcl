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
	global help_blocktime help_blocked channels debug debugoutput output onlyallowregisteredusers output_coinchoose protected_commands sqlite_commands
	sqlite3 poolcommands $sqlite_commands

	if {$onlyallowregisteredusers eq "1"} {
		if {[check_registereduser $chan $nick] eq "false"} {
			putquick "NOTICE $nick :you are not allowed to use this command"
			putquick "NOTICE $nick :please use !request command to get access to the bot"
			return
		}
	}

	if {$arg eq "" || [llength $arg] < 1} {
		if {$debug eq "1"} { putlog "wrong arguments, must be !coininfo coinname" }
		return
	}
	
	set mask [string trimleft $host ~]
	regsub -all {@([^\.]*)\.} $mask {@*.} mask	 	
	set mask *!$mask

	if {[info exists help_blocked($mask)]} {
		putquick "NOTICE $nick :You have been blocked for $help_blocktime Seconds, please be patient..."
		return
	}

	if {[lsearch $protected_commands "coinchoose"] > 0 } {
		regsub "#" $chan "" command_channel
		if {[llength [poolcommands eval {SELECT command_id FROM commands WHERE channel=$command_channel AND command="coinchoose" AND activated=1}]] != 0} {
			if {$debug eq "1"} { putlog "-> command coinchoose found" }
		} elseif {[llength [poolcommands eval {SELECT command_id FROM commands WHERE channel=$command_channel AND command="all" AND activated=1}]] != 0} {
			if {$debug eq "1"} { putlog "-> command ALL found" }
		} else {
			if {$debug eq "1"} { putlog "-> protected" }
			putquick "PRIVMSG $chan :command !coinchoose not allowed in $chan"
			return
		}
    } else {
    	if {$debug eq "1"} { putlog "-> not protected" }
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

	if {[catch { set token [http::geturl $coinchoose_api -timeout 3000]} error] == 1} {
		if {$debug eq "1"} { putlog "$error" }
		http::cleanup $token
		return
	} elseif {[http::ncode $token] == "404"} {
		if {$debug eq "1"} { putlog "Error: [http::code $token]" }
		http::cleanup $token
		return
	} elseif {[http::status $token] == "ok"} {
		set data [http::data $token]
		http::cleanup $token
	} elseif {[http::status $token] == "timeout"} {
		if {$debug eq "1"} { putlog "Timeout occurred" }
		http::cleanup $token
		return
	} elseif {[http::status $token] == "error"} {
		if {$debug eq "1"} { putlog "Error: [http::error $token]" }
		http::cleanup $token
		return
	}

	if {$usehttps eq "1"} {
		::http::unregister https
	}

	if {$debugoutput eq "1"} { putlog "xml: $data" }

	set results [::json::json2dict $data]

	set coin_found "false"
	set coinchoose_name "0"
	set coinchoose_algo "0"
	set coinchoose_currentblocks "0"
	set coinchoose_diff "0"
	set coinchoose_exchange "0"
	set coinchoose_price "0"
	set coinchoose_reward "0"
	set coinchoose_networkhashrate "0"
	set coinchoose_avgprofit "0"
	set coinchoose_avghashrate "0"
	set coinchoose_nethashratevalue "0"
	set coinchoose_avgnethashratevalue "0"
	
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
			if {$value eq "exchange"} { 
				#set coinchoose_exchange "$sub_value" 
				#set coinchoose_networkhashrate "$sub_value"
				if {$sub_value eq "0" ||$sub_value eq "null" || $sub_value eq ""} {
					set coinchoose_exchange "n/a"
				} else {
					set coinchoose_exchange $sub_value
				}
			}
			if {$value eq "price"} {
				if {$sub_value eq "null"} {
					set coinchoose_price "0"
				} else {
					set coinchoose_price [format "%0.8f" $sub_value]
				}
			}
			if {$value eq "reward"} {
				if {$sub_value eq "null"} {
					set coinchoose_reward "0"
				} else {
					set coinchoose_reward [format "%0.2f" $sub_value]
				}
			}
			if {$value eq "networkhashrate"} {
				#set coinchoose_networkhashrate "$sub_value"
				if {$sub_value eq "0" || $sub_value eq "null"} {
					set coinchoose_nethashratedevider 0
					set coinchoose_nethashratevalue ""
					set coinchoose_networkhashrate "n/a"
				} else {

					if {[string match *.* $sub_value]} {
						set sub_value [format "%0.0f" $sub_value]
					}
					
					if {[string length $sub_value] <= 3 } {
						set coinchoose_nethashratedevider 1
						set coinchoose_nethashratevalue "H/s"
					} elseif {[string length $sub_value] <= 6 } {
						set coinchoose_nethashratedevider 1000
						set coinchoose_nethashratevalue "KH/s"
					} elseif {[string length $sub_value] <= 9 } {
						set coinchoose_nethashratedevider 1000000
						set coinchoose_nethashratevalue "MH/s"
					} elseif {[string length $sub_value] <= 12 } {
						set coinchoose_nethashratedevider 1000000000
						set coinchoose_nethashratevalue "GH/s"
					} elseif {[string length $sub_value] <= 15 } {
						set coinchoose_nethashratedevider 1000000000000
						set coinchoose_nethashratevalue "TH/s"
					} elseif {[string length $sub_value] <= 18 } {
						set coinchoose_nethashratedevider 1000000000000000
						set coinchoose_nethashratevalue "PH/s"
					} else {
						set coinchoose_nethashratedevider 1
						set coinchoose_nethashratevalue "H/s"
					}
					set coinchoose_networkhashrate [format "%.2f" [expr {double(double($sub_value)/double($coinchoose_nethashratedevider))}]]
				}
			}
			if {$value eq "avgProfit"} {
				if {$sub_value eq "null"} {
					set coinchoose_avgprofit "0"
				} else {
					set coinchoose_avgprofit [format "%0.2f" $sub_value]
				}
			}
			if {$value eq "avgHash"} {
				#set coinchoose_avghash "$sub_value"
				if {$sub_value eq "0" || $sub_value eq "null"} {
					set coinchoose_avghashrate "n/a"
					set coinchoose_avgnethashratedevider 0
					set coinchoose_avgnethashratevalue ""
				} else {
				
					if {[string match *.* $sub_value]} {
						set sub_value [format "%0.0f" $sub_value]
					}
					
					if {[string length $sub_value] <= 3 } {
						set coinchoose_avgnethashratedevider 1
						set coinchoose_avgnethashratevalue "H/s"
					} elseif {[string length $sub_value] <= 6 } {
						set coinchoose_avgnethashratedevider 1000
						set coinchoose_avgnethashratevalue "KH/s"
					} elseif {[string length $sub_value] <= 9 } {
						set coinchoose_avgnethashratedevider 1000000
						set coinchoose_avgnethashratevalue "MH/s"
					} elseif {[string length $sub_value] <= 12 } {
						set coinchoose_avgnethashratedevider 1000000000
						set coinchoose_avgnethashratevalue "GH/s"
					} elseif {[string length $sub_value] <= 15 } {
						set coinchoose_avgnethashratedevider 1000000000000
						set coinchoose_avgnethashratevalue "TH/s"
					} elseif {[string length $sub_value] <= 18 } {
						set coinchoose_avgnethashratedevider 1000000000000000
						set coinchoose_avgnethashratevalue "PH/s"
					} else {
						set coinchoose_avgnethashratedevider 1
						set coinchoose_avgnethashratevalue "H/s"
					}
					set coinchoose_avghashrate [format "%.2f" [expr {double(double($sub_value)/double($coinchoose_avgnethashratedevider))}]]
				}
			}
		}
		if {$coin_found eq "true"} {
			break
		}
	}
	
	if {$coin_found eq "true"} {
		set lineoutput $output_coinchoose
		set lineoutput [replacevar $lineoutput "%coinchoose_name%" $coinchoose_name]
		set lineoutput [replacevar $lineoutput "%coinchoose_algo%" $coinchoose_algo]
		set lineoutput [replacevar $lineoutput "%coinchoose_currentblocks%" $coinchoose_currentblocks]
		set lineoutput [replacevar $lineoutput "%coinchoose_diff%" $coinchoose_diff]
		set lineoutput [replacevar $lineoutput "%coinchoose_exchange%" $coinchoose_exchange]
		set lineoutput [replacevar $lineoutput "%coinchoose_price%" $coinchoose_price]
		set lineoutput [replacevar $lineoutput "%coinchoose_reward%" $coinchoose_reward]
		set lineoutput [replacevar $lineoutput "%coinchoose_networkhashrate%" $coinchoose_networkhashrate]
		set lineoutput [replacevar $lineoutput "%coinchoose_networkhashratevalue%" $coinchoose_nethashratevalue]
		set lineoutput [replacevar $lineoutput "%coinchoose_avgprofit%" $coinchoose_avgprofit]
		set lineoutput [replacevar $lineoutput "%coinchoose_avghashrate%" $coinchoose_avghashrate]
		set lineoutput [replacevar $lineoutput "%coinchoose_avghashvalue%" $coinchoose_avgnethashratevalue]
	} else {
		set lineoutput "cannot find coin -> [string toupper $arg]"
	}
	
	if {$output eq "CHAN"} {
		putquick "PRIVMSG $chan :$lineoutput"
	} elseif {$output eq "NOTICE"} {
		putquick "NOTICE $nick :$lineoutput"	
	} else {
		putquick "PRIVMSG $chan :please set output in config file"
	}
	
	set help_blocked($mask) 1
	utimer $help_blocktime [ list unset help_blocked($mask) ]

}

putlog "===>> Mining-Pool-Coinchoose - Version $scriptversion loaded"
