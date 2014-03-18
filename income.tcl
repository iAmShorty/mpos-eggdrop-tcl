#
# Income Calculator
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
# Income Calculator
#
proc calc_income {nick host hand chan arg} {
	global help_blocktime help_blocked channels debug debugoutput output onlyallowregisteredusers output_incomeinfo output_incomeinfo_percoin command_protect

	if {$arg eq "" || [llength $arg] != 3} {
		if {$debug eq "1"} { putlog "wrong arguments, must be !calc coin hashrate blockreward" }
		return
	}
	
	set income_hashrate [format "%.2f" [expr double(double([lindex $arg 1])/1000)]]
	set income_reward [lindex $arg 2]
	
	set action "/index.php?page=api&action=getdashboarddata&api_key="
	
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

	if {$command_protect eq "1"} {
		if {[channel_command_acl $chan "balance"] eq "False"} {
			putquick "PRIVMSG $chan :command !balance not allowed in $chan"
			return
		}
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
		putquick "PRIVMSG $chan :Access to Dashboarddata denied"
		return 0
	}

	set results [::json::json2dict $data]
	
	foreach {key value} $results {
		#putlog "Key: $key - $value"
		foreach {sub_key sub_value} $value {
			#putlog "Sub: $sub_key - $sub_value"
			foreach {elem elem_val} $sub_value {
				#putlog "Ele: $elem - Val: $elem_val"
				
				if {$elem eq "error" && $elem_val eq "disabled" } {
					putlog "Dashboard API disabled"
					return
				}
				
				if {$elem eq "network"} {
					#putlog "Ele: $elem - Val: $elem_val"
					foreach {elem2 elem_val2} $elem_val {
						#putlog "Ele: $elem2 - Val: $elem_val2"
						if {$elem2 eq "difficulty"} { set income_diff "$elem_val2" }
					}
				}		
			}
		}
	}

	if {[info exists output_incomeinfo_percoin([string tolower [lindex $arg 0]])]} {
		if {$debug eq "1"} { putlog "-> [string toupper [lindex $arg 0]] - $output_incomeinfo_percoin([string tolower [lindex $arg 0]])" }
		set lineoutput $output_incomeinfo_percoin([string tolower [lindex $arg 0]])
	} else {
		if {$debug eq "1"} { putlog "no special output!" }
		set lineoutput $output_incomeinfo
	}

	set lineoutput [replacevar $lineoutput "%income_coin%" [string toupper [lindex $arg 0]]]
	set lineoutput [replacevar $lineoutput "%income_hashrate%" "$income_hashrate MH/s"]
	set lineoutput [replacevar $lineoutput "%income_diff%" $income_diff]
	set lineoutput [replacevar $lineoutput "%income_hour%" [format "%.2f" [expr {double(double($income_hashrate)*double($income_reward)/double($income_diff))*double(60*60*24*65535*double(pow(10,6))/double(pow(2,48)))/24}]]]
	set lineoutput [replacevar $lineoutput "%income_day%" [format "%.2f" [expr {double(double($income_hashrate)*double($income_reward)/double($income_diff))*double(60*60*24*65535*double(pow(10,6))/double(pow(2,48)))}]]]
	
	if {$output eq "CHAN"} {
		putquick "PRIVMSG $chan :$lineoutput"
	} elseif {$output eq "NOTICE"} {
		putquick "NOTICE $nick :$lineoutput"	
	} else {
		putquick "PRIVMSG $chan :please set output in config file"
	}
	
}

putlog "===>> Mining-Pool-Incomeinfo - Version $scriptversion loaded"
