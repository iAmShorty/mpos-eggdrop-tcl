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

bind pub - !price price_info
bind pub - !coinchoose coinchoose_info
bind pub - !request user_request
bind pub - ?help printUsage
bind pub - !help printUsage

bind pub - !hashrate pool_hashrate
bind pub - !diff pool_diff
bind pub - !calc calc_income

bind pub no|- !adduser user_add
bind pub no|- !deluser user_del
bind pub no|- !addpool pool_add
bind pub no|- !delpool pool_del
bind pub no|- !pools pool_list
bind pub no|- !blockfinder announce_blockfinder
bind pub no|- !announce announce_channel
bind pub no|- !command channel_commands

bind msg no|- !apikey pool_apikey

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
	
	if {$debug eq "1"} { putlog "running proc [dict get [info frame 0] proc]" }
	
	set pool_found "false"
	if {[llength [registeredpools eval {SELECT apikey FROM pools WHERE coin=$coinname}]] != 0} {
		set poolscount [registeredpools eval {SELECT COUNT(1) FROM pools WHERE apikey != 0 AND coin == $coinname}]
		if {$debug eq "1"} { putlog "Number of Pools: $poolscount" }
		foreach {apiurl poolcoin apikey} [registeredpools eval {SELECT url,coin,apikey FROM pools WHERE apikey != 0 AND coin == $coinname} ] {
			if {[string toupper $poolcoin] eq [string toupper $coinname]} {
				set pool_found "true"
				set apiurl [string trimright $apiurl "/"]
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
# getting the user status
#
proc check_userrights {nick} {

	if {$debug eq "1"} { putlog "running proc [dict get [info frame 0] proc]" }
	
	if {[matchattr $nick +n]} {
		putlog "$nick is botowner"
		return "true"
	} else {
		return "false"
	}
}

#
# getting the user status
#
proc check_registereduser {chan nick} {

	if {$debug eq "1"} { putlog "running proc [dict get [info frame 0] proc]" }
	
	set hostmask "$nick!*[getchanhost $nick $chan]"
	if {[check_mpos_user $nick $hostmask] eq "false"} {
		return "false"
	} else {
		return "true"
	}
}

#
# checking http data
#
proc check_httpdata {url} {
	global debug debugoutput http_query_timeout

	if {$debug eq "1"} { putlog "running proc [dict get [info frame 0] proc]" }
	
	set returnvalue ""
	
	if {[string match "*https*" [string tolower $url]]} {
		set usehttps 1
	} else {
		set usehttps 0
	}

	if {$usehttps eq "1"} {
		::http::register https 443 tls::socket
	}
	
	if {[catch { set token [http::geturl $url -timeout $http_query_timeout]} error] == 1} {
		if {$debug eq "1"} { putlog "$error" }
		if {[info exists $token]} {
 			http::cleanup $token
		}
		set returnvalue "error - $error"
	} elseif {[http::ncode $token] == "404"} {
		if {$debug eq "1"} { putlog "Error: [http::code $token]" }
		if {[info exists $token]} {
 			http::cleanup $token
		}
		set returnvalue "error - [http::code $token]"
	} elseif {[http::status $token] == "ok"} {
		set data [http::data $token]
		if {[info exists $token]} {
 			http::cleanup $token
		}
		set returnvalue "success $data"
	} elseif {[http::status $token] == "timeout"} {
		if {$debug eq "1"} { putlog "Timeout occurred" }
		if {[info exists $token]} {
 			http::cleanup $token
		}
		set returnvalue "error - Timeout occurred"
	} elseif {[http::status $token] == "error"} {
		if {$debug eq "1"} { putlog "Error: [http::error $token]" }
		if {[info exists $token]} {
 			http::cleanup $token
		}
		set returnvalue "error - [http::error $token]"
	}

	if {$usehttps eq "1"} {
		::http::unregister https
	}
	
	return $returnvalue
}

#
# ACL Command Check
#
proc channel_command_acl {channel command} {
	global protected_commands sqlite_commands debug
	sqlite3 poolcommands $sqlite_commands

	if {$debug eq "1"} { putlog "running proc [dict get [info frame 0] proc]" }
	
	if {[lsearch $protected_commands $command] > 0 } {
		regsub "#" $channel "" command_channel
		if {[llength [poolcommands eval {SELECT command_id FROM commands WHERE channel=$command_channel AND command="$command" AND activated=1}]] != 0} {
			if {$debug eq "1"} { putlog "-> command !balance found" }
			return "True"
		} elseif {[llength [poolcommands eval {SELECT command_id FROM commands WHERE channel=$command_channel AND command="all" AND activated=1}]] != 0} {
			if {$debug eq "1"} { putlog "-> command ALL found" }
			return "True"
		} else {
			if {$debug eq "1"} { putlog "-> protected" }
			return "False"
		}
    } else {
    	if {$debug eq "1"} { putlog "-> not protected" }
    	return "True"
    }
    
}

#
# replace variables
#
proc replacevar {string cookie value} {

	if {$debug eq "1"} { putlog "running proc [dict get [info frame 0] proc]" }

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

	if {$debug eq "1"} { putlog "running proc [dict get [info frame 0] proc]" }
	
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
