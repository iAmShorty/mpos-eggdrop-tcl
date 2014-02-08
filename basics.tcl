#
# Basic TCL Commands used in MPOS Api Scripts
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
# key bindings
#
bind pub - !pool pool_info
bind pub - !block block_info
bind pub - !last last_info
bind pub - !user user_info
bind pub - !round round_info
bind pub - !worker worker_info
bind pub - !balance balance_info
bind pub - !coinchoose coinchoose_info
bind pub - ?help printUsage
bind pub - !help printUsage
bind pub - !adduser user_add
bind pub - !deluser user_del
bind pub - !request user_request
bind pub - !addpool pool_add
bind pub - !delpool pool_del
bind pub - !pools pool_list
bind pub - !blockfinder pool_blockfinder
bind msg - !apikey pool_apikey

#
# unset arrays for userdefined ouput when rehashing the bot, otherwise the
# array variables are always present, even if they are commented out. arrays are set
# again if output.tcl is loaded and variables are not commented out
#
if {[array exists output_balance_percoin]} { unset output_balance_percoin }
if {[array exists output_blockinfo_percoin]} { unset output_blockinfo_percoin }
if {[array exists output_lastblock_percoin]} { unset output_lastblock_percoin }
if {[array exists output_findblocks_percoin]} { unset output_findblocks_percoin }
if {[array exists output_poolstats_percoin]} { unset output_poolstats_percoin }
if {[array exists output_roundstats_percoin]} { unset output_roundstats_percoin }
if {[array exists output_userstats_percoin]} { unset output_userstats_percoin }
if {[array exists output_workerinfo_percoin]} { unset output_workerinfo_percoin }
if {[array exists output_worker_offline_percoin]} { unset output_worker_offline_percoin }
if {[array exists output_worker_online_percoin]} { unset output_worker_online_percoin }
#
# getting the pool vars from dictionary
# set in config for specific pool
#
proc pool_vars {coinname} {
	global pools
	set pool_found "false"
	#putlog "Number of Pools: [dict size $pools]"
	dict for {id info} $pools {
		if {[string toupper $id] eq [string toupper $coinname]} {
			set pool_found "true"
			#putlog "Pool: [string toupper $id]"
			dict with info {
				set pool_data "[string toupper $id] $apiurl $apikey"
			}
		}
	}
	
	if {$pool_found eq "true"} {
		return $pool_data
	} else {
		return "0"
	}
}

#
# replace variables
#
proc replacevar {string cookie value} {
	variable zeroconvert
	if {[string length $value] == 0 && [info exists zeroconvert($cookie)]} {
		set value $zeroconvert($cookie)
	}
	return [string map [list $cookie $value] $string]
}

#
# wordwrap proc that accepts multiline data 
# (empty lines will be stripped because there's no way to relay them via irc) 
#
proc wordwrap {data len} { 
	set out {} 
	foreach line [split [string trim $data] \n] { 
		set curr {} 
		set i 0 
		foreach word [split [string trim $line]] { 
			if {[incr i [string len $word]]>$len} { 
				lappend out [join $curr] 
				set curr [list $word] 
				set i [string len $word] 
			} { 
				lappend curr $word 
			} 
			incr i 
		} 
		if {[llength $curr]} { 
			lappend out [join $curr] 
		} 
	} 
	set out 
}

#
# character filter
#
proc charfilter {arg} { return [string map {"\\" "\\\\" "\{" "\\\{" "\}" "\\\}" "\[" "\\\[" "\]" "\\\]" "\'" "\\\'" "\"" "\\\""} $arg] }

putlog "===>> Mining-Pool-Basics - Version $scriptversion loaded"
