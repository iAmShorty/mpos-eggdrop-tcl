#
# Account Balance
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
# Account Balance
#
proc balance_info {nick host hand chan arg} {
	global help_blocktime help_blocked channels debug debugoutput output onlyallowregisteredusers ownersbalanceonly output_balance output_balance_percoin protected_commands sqlite_commands
	sqlite3 poolcommands $sqlite_commands

	# only allow bot owners to get balances for 
	# specified users
	#
	if {$ownersbalanceonly eq "1"} {
		if {[check_userrights $chan $nick] eq "false"} {
			putlog "$nick tried to get balance for user $arg"
			putquick "PRIVMSG $chan :Access to Balance denied, only Botowners can check balances"
			return
		}
	} else {
		if {$onlyallowregisteredusers eq "1"} {
			if {[check_registereduser $chan $nick] eq "false"} {
				putquick "NOTICE $nick :you are not allowed to use this command"
				putquick "NOTICE $nick :please use !request command to get access to the bot"
				return
			}
		}
	}

	if {$arg eq "" || [llength $arg] != 2} {
		if {$debug eq "1"} { putlog "wrong arguments, must be !balance poolname username" }
		return
	}
	
	set action "/index.php?page=api&action=getuserbalance&id=[lindex $arg 1]&api_key="
	
	set mask [string trimleft $host ~]
	regsub -all {@([^\.]*)\.} $mask {@*.} mask	 	
	set mask *!$mask
 
	if {[info exists help_blocked($mask)]} {
		putquick "NOTICE $nick : You have been blocked for $help_blocktime Seconds, please be patient..."
		return
	}
	
	set pool_info [regexp -all -inline {\S+} [pool_vars [string toupper [lindex $arg 0]]]]
	
	if {$pool_info ne "0"} {
		if {$debug eq "1"} { putlog "COIN: [lindex $pool_info 0]" }
		if {$debug eq "1"} { putlog "URL: [lindex $pool_info 1]" }
		if {$debug eq "1"} { putlog "KEY: [lindex $pool_info 2]" }
	} else {
		if {$debug eq "1"} { putlog "no pool data" }
		return
	}

	if {[lsearch $protected_commands "balance"] > 0 } {
		regsub "#" $chan "" command_channel
		if {[llength [poolcommands eval {SELECT command_id FROM commands WHERE channel=$command_channel AND command="balance" AND activated=1}]] != 0} {
			if {$debug eq "1"} { putlog "-> command !balance found" }
		} elseif {[llength [poolcommands eval {SELECT command_id FROM commands WHERE channel=$command_channel AND command="all" AND activated=1}]] != 0} {
			if {$debug eq "1"} { putlog "-> command ALL found" }
		} else {
			if {$debug eq "1"} { putlog "-> protected" }
			putquick "PRIVMSG $chan :command !balance not allowed in $chan"
			return
		}
    } else {
    	if {$debug eq "1"} { putlog "-> not protected" }
    }
    
	set newurl [lindex $pool_info 1]
	append newurl $action
	append newurl [lindex $pool_info 2]

	set data [check_httpdata $newurl]
	if { [regexp -nocase {error} $data] } {
		putlog $data
		return
	}

	if {$debugoutput eq "1"} { putlog "xml: $data" }

	if {$data eq "Access denied"} { 
		putquick "PRIVMSG $chan :Access to Blockinfo denied"
		return 0
	}

	set results [::json::json2dict $data]

	foreach {key value} $results {
		foreach {sub_key sub_value} $value {
			if {$sub_key eq "data"} {
				#putlog "Sub: $sub_value"
				foreach {elem elem_val} $sub_value {
					#putlog "Ele: $elem - Val: $elem_val"
					
					if {$elem eq "confirmed"} { set balance_confirmed "$elem_val" } 
					if {$elem eq "unconfirmed"} { set balance_unconfirmed "$elem_val" } 
					if {$elem eq "orphaned"} { set balance_orphan "$elem_val" } 

				}
			}
		}
	}

	if {[info exists output_balance_percoin([string tolower [string tolower [lindex $arg 0]]])]} {
		if {$debug eq "1"} { putlog "-> [string toupper [lindex $arg 0]] - $output_balance_percoin([string tolower [lindex $arg 0]])" }
		set lineoutput $output_balance_percoin([string tolower [lindex $arg 0]])
	} else {
		if {$debug eq "1"} { putlog "no special output!" }
		set lineoutput $output_balance
	}
	
	set lineoutput [replacevar $lineoutput "%balance_coin%" [string toupper [lindex $arg 0]]]
	set lineoutput [replacevar $lineoutput "%balance_user%" [lindex $arg 1]]
	set lineoutput [replacevar $lineoutput "%balance_confirmed%" $balance_confirmed]
	set lineoutput [replacevar $lineoutput "%balance_unconfirmed%" $balance_unconfirmed]
	set lineoutput [replacevar $lineoutput "%balance_orphan%" $balance_orphan]

	if {$output eq "CHAN"} {
		putquick "PRIVMSG $chan :$lineoutput"
	} elseif {$output eq "NOTICE"} {
		putquick "NOTICE $nick :$lineoutput"	
	} else {
		putquick "PRIVMSG $chan :please set output in config file"
	}
}

putlog "===>> Mining-Pool-Balanceinfo - Version $scriptversion loaded"
