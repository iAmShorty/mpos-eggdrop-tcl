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
bind pub - !hashrate pool_hashrate
bind pub - !diff pool_diff
bind pub - !price price_info
bind pub - !coinchoose coinchoose_info
bind pub - !request user_request
bind pub - ?help printUsage
bind pub - !help printUsage

bind pub no|- !adduser user_add
bind pub no|- !deluser user_del
bind pub no|- !addpool pool_add
bind pub no|- !delpool pool_del
bind pub no|- !pools pool_list
bind pub no|- !blockfinder announce_blockfinder
bind pub no|- !announce announce_channel
bind pub no|- !command channel_commands

bind msg no|- !apikey pool_apikey

bind msg - !pool pool_info
bind msg - !block block_info
bind msg - !last last_info
bind msg - !user user_info
bind msg - !round round_info
bind msg - !worker worker_info
bind msg - !balance balance_info
bind msg - !hashrate pool_hashrate
bind msg - !diff pool_diff
bind msg - !price price_info
bind msg - !coinchoose coinchoose_info
bind msg - !request user_request
bind msg - ?help printUsage
bind msg - !help printUsage

bind msg no|- !adduser user_add
bind msg no|- !deluser user_del
bind msg no|- !addpool pool_add
bind msg no|- !delpool pool_del
bind msg no|- !pools pool_list
bind msg no|- !blockfinder announce_blockfinder
bind msg no|- !announce announce_channel
bind msg no|- !command channel_commands

#
# check for required packages
#
if {[catch {package require http 2.5}]} { 
	if {$debug eq "1"} { putlog "Eggdrop: package http 2.5 or above required" }
	die "Eggdrop: package http 2.5 or above required"
}
if {[catch {package require json}]} { 
	if {$debug eq "1"} { putlog "Eggdrop: package json required" }
	die "Eggdrop: package json required"
}
if {[catch {package require tls}]} { 
	if {$debug eq "1"} { putlog "Eggdrop: package tls required" }
	die "Eggdrop: package tls required"
}
if {[catch {package require sqlite3}]} { 
	if {$debug eq "1"} { putlog "Eggdrop: package sqlite3 required" }
	die "Eggdrop: package sqlite3 required"
}

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
	global sqlite_poolfile debug
	sqlite3 registeredpools $sqlite_poolfile
	
	set pool_found "false"
	if {[llength [registeredpools eval {SELECT apikey FROM pools WHERE coin=$coinname}]] != 0} {
		set poolscount [registeredpools eval {SELECT COUNT(1) FROM pools WHERE apikey != 0 AND coin == $coinname}]
		if {$debug eq "1"} { putlog "Number of Pools: $poolscount" }
		foreach {apiurl poolcoin apikey} [registeredpools eval {SELECT url,coin,apikey FROM pools WHERE apikey != 0 AND coin == $coinname} ] {
			if {[string toupper $poolcoin] eq [string toupper $coinname]} {
				set pool_found "true"
				set pool_data "[string toupper $poolcoin] $apiurl $apikey"
			}
		}
	} else {
		if {$debug eq "1"} { putlog "API Key for Pool not found" }
	}

	registeredpools close
	
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
