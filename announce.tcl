#
# Coin Announce / Pool Announce
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
# Allowing commands for Coins in Channel
#
proc channel_commands {nick uhost hand chan arg} {
	global debug sqlite_commands sqlite_announce
	sqlite3 poolcommands $sqlite_commands
	sqlite3 announcecoins $sqlite_announce

	if {$debug eq "1"} { putlog "running proc [dict get [info frame 0] proc]" }
	
	if {[matchattr $nick +n]} {
		if {$debug eq "1"} { putlog "$nick is botowner" }
	} else {
		if {$debug eq "1"} { putlog "$nick tried to add $arg to pools" }
		return
	}

	if {[llength $arg] == 4} {
		set command_name [string tolower [lindex $arg 0]]
		set command_coin [string toupper [lindex $arg 1]]
		set command_channel [string tolower [lindex $arg 2]]
		regsub "#" $command_channel "" command_channel
		set command_action [string tolower [lindex $arg 3]]
		if {$debug eq "1"} { putlog "$command_name - $command_channel - $command_action" }
	} else {
		putquick "PRIVMSG $chan :wrong arguments, should be !command COMMAND COIN CHANNEL enable/disable/delete"
		return
	}
	
	if {$command_action eq "enable" || $command_action eq "true" || $command_action eq "1"} {
		if {[llength [announcecoins eval {SELECT announce_id FROM announce WHERE channel=$command_channel}]] == 0} {
			if {$debug eq "1"} { putlog "-> #$command_channel not found in Database " }
		} else {
			if {[llength [poolcommands eval {SELECT command_id FROM commands WHERE command=$command_name AND coin=$command_coin AND channel=$command_channel}]] == 0} {
				if {$debug eq "1"} { putlog "-> INSERT: activating command $command_name in #$command_channel" }
				putquick "PRIVMSG $chan :activating command $command_name in #$command_channel"
				poolcommands eval {INSERT INTO commands (command,coin,channel,activated) VALUES ($command_name,$command_coin,$command_channel,1)}
			} else {
				if {$debug eq "1"} { putlog "-> UPDATE: activating command $command_name in #$command_channel" }
				putquick "PRIVMSG $chan :activating command $command_name in #$command_channel"
				poolcommands eval {UPDATE commands SET activated=1 WHERE command=$command_name AND channel=$command_channel}
			}
		}
	} elseif {$command_action eq "disable" || $command_action eq "false" || $command_action eq "0"} {
		if {[llength [announcecoins eval {SELECT announce_id FROM announce WHERE channel=$command_channel}]] == 0} {
			if {$debug eq "1"} { putlog "-> #$command_channel not found in Database " }
		} else {
			if {[llength [poolcommands eval {SELECT command_id FROM commands WHERE command=$command_name AND coin=$command_coin AND channel=$command_channel}]] == 0} {
				if {$debug eq "1"} { putlog "-> INSERT: deactivating command $command_name in #$command_channel" }
				putquick "PRIVMSG $chan :deactivating command $command_name in #$command_channel"
				poolcommands eval {INSERT INTO commands (command,coin,channel,activated) VALUES ($command_name,$command_coin,$command_channel,0)}
			} else {
				if {$debug eq "1"} { putlog "-> UPDATE: deactivating command $command_name in #$command_channel" }
				putquick "PRIVMSG $chan :deactivating command $command_name in #$command_channel"
				poolcommands eval {UPDATE commands SET activated=0 WHERE command=$command_name AND channel=$command_channel}
			}
		}
	} elseif {$command_action eq "delete"} {
		if {[llength [poolcommands eval {SELECT command_id FROM commands WHERE command=$command_name AND coin=$command_coin AND channel=$command_channel}]] == 0} {
			if {$debug eq "1"} { putlog "-> command $command_name for #$command_channel not found in Database " }
		} else {
			if {$debug eq "1"} { putlog "-> deleting command $command_name in #$command_channel" }
			putquick "PRIVMSG $chan :deleting command $command_name in #$command_channel"
			poolcommands eval {DELETE FROM commands WHERE command=$command_name AND channel=$command_channel}
		}
	} else {
		if {$debug eq "1"} { putlog "-> something went wrong..." }
	}

	announcecoins close
	poolcommands close
}

#
# adding specific channels for advertising blockfinder stats
#
proc announce_channel {nick uhost hand chan arg} {
	global debug sqlite_announce sqlite_poolfile
	sqlite3 registeredpools $sqlite_poolfile
	sqlite3 announcecoins $sqlite_announce

	if {$debug eq "1"} { putlog "running proc [dict get [info frame 0] proc]" }
	
	if {[matchattr $nick +n]} {
		if {$debug eq "1"} { putlog "$nick is botowner" }
	} else {
		if {$debug eq "1"} { putlog "$nick tried to add $arg to pools" }
		return
	}

	if {[llength $arg] == 3} {
		set announce_coin [string toupper [lindex $arg 0]]
		set announce_channel [string tolower [lindex $arg 1]]
		regsub "#" $announce_channel "" announce_channel
		set announce_action [string tolower [lindex $arg 2]]
		if {$debug eq "1"} { putlog "$announce_coin - $announce_channel - $announce_action" }
	}
	
	if {$arg eq ""} {
		set scount [announcecoins eval {SELECT COUNT(1) FROM announce}]
		putquick "PRIVMSG $chan :Number of Announcements: $scount"
		if {$scount != 0} {
			foreach {coin channel advertise} [announcecoins eval {SELECT coin,channel,advertise FROM announce} ] {
				if {$advertise eq "1"} { 
					set announcement "active" 
				} else {
					set announcement "inactive" 
				}
				append outvar "\002Coin:\002 $coin -> \002Channel:\002 #$channel -> \002Announce:\002 $announcement\n"
			}
		}
		
		if {$scount != 0} {
			set records [split $outvar "\n"]
			foreach rec $records {
				putquick "PRIVMSG $chan :$rec"
			}
		}
	} elseif {$announce_action eq "enable" || $announce_action eq "true" || $announce_action eq "1"} {
		if {[llength [registeredpools eval {SELECT pool_id FROM pools WHERE coin=$announce_coin AND apikey != 0}]] != 0} {
			if {[llength [announcecoins eval {SELECT announce_id FROM announce WHERE coin=$announce_coin AND channel=$announce_channel}]] == 0} {
				if {$debug eq "1"} { putlog "-> activating announce for coin $announce_coin in #$announce_channel" }
				putquick "PRIVMSG $chan :activating announce for coin $announce_coin in #$announce_channel"
				announcecoins eval {INSERT INTO announce (coin,channel,advertise) VALUES ($announce_coin,$announce_channel,1)}
			} else {
				if {$debug eq "1"} { putlog "-> activating announce for coin $announce_coin in #$announce_channel" }
				putquick "PRIVMSG $chan :activating announce for coin $announce_coin in #$announce_channel"
				announcecoins eval {UPDATE announce SET advertise=1 WHERE coin=$announce_coin AND channel=$announce_channel}
			}
		} else {
			if {$debug eq "1"} { putlog "-> Pool URL or API Key for coin $announce_coin not found" }
		}
	} elseif {$announce_action eq "disable" || $announce_action eq "false" || $announce_action eq "0"} {
		if {[llength [announcecoins eval {SELECT announce_id FROM announce WHERE coin=$announce_coin AND channel=$announce_channel}]] != 0} {
			if {$debug eq "1"} { putlog "-> deactivating announce for coin $announce_coin in #$announce_channel" }
			putquick "PRIVMSG $chan :deactivating announce for coin $announce_coin in #$announce_channel"
			announcecoins eval {UPDATE announce SET advertise=0 WHERE coin=$announce_coin AND channel=$announce_channel}
		} else {
			if {$debug eq "1"} { putlog "-> No Anncounce for Coin $announce_coin in Database" }
		}
	} elseif {$announce_action eq "delete"} {
		if {[llength [announcecoins eval {SELECT announce_id FROM announce WHERE coin=$announce_coin AND channel=$announce_channel}]] != 0} {
			if {$debug eq "1"} { putlog "-> deleting announce for coin $announce_coin in #$announce_channel" }
			putquick "PRIVMSG $chan :deleting announce for coin $announce_coin in #$announce_channel"
			announcecoins eval {DELETE FROM announce WHERE coin=$announce_coin AND channel=$announce_channel}
		} else {
			if {$debug eq "1"} { putlog "-> No Anncounce for Coin $announce_coin in Database" }
		}
	} else {
		if {$debug eq "1"} { putlog "-> something went wrong..." }
	}
	announcecoins close
	registeredpools close
}

#
# activate/deactivate pool for block advertising
#
proc announce_blockfinder {nick uhost hand chan arg} {
	global debug sqlite_poolfile
	sqlite3 registeredpools $sqlite_poolfile

	if {$debug eq "1"} { putlog "running proc [dict get [info frame 0] proc]" }
	
	if {[matchattr $nick +n]} {
		if {$debug eq "1"} { putlog "$nick is botowner" }
	} else {
		if {$debug eq "1"} { putlog "$nick tried to add $arg to pools" }
		return
	}

	set userarg [charfilter $nick]
	set hostmask "$userarg!*[getchanhost $userarg $chan]"

	if {[llength $arg] != 2} {
		putquick "PRIVMSG $chan :wrong arguments, should be !blockfinder POOLURL enable/disable"
		return
	}

	set pool_url [string tolower [lindex $arg 0]]
	set pool_action [string tolower [lindex $arg 1]]

	if {$debug eq "1"} { putlog "$pool_url - $pool_action" }

	if {$pool_action eq "enable" || $pool_action eq "true" || $pool_action eq "1"} {
		if {[llength [registeredpools eval {SELECT url FROM pools WHERE url=$pool_url AND apikey != 0}]] != 0} {
			if {$debug eq "1"} { putlog "-> activating pool" }
			putquick "PRIVMSG $chan :pool $pool_url activated"
			registeredpools eval {UPDATE pools SET blockfinder=1 WHERE url=$pool_url}
		} else {
			if {$debug eq "1"} { putlog "-> Pool URL or API Key not found" }
		}
	} elseif {$pool_action eq "disable" || $pool_action eq "false" || $pool_action eq "0"} {
		if {[llength [registeredpools eval {SELECT url FROM pools WHERE url=$pool_url AND apikey != 0}]] != 0} {
			if {$debug eq "1"} { putlog "-> deactivating pool" }
			putquick "PRIVMSG $chan :pool $pool_url deactivating"
			registeredpools eval {UPDATE pools SET blockfinder=0 WHERE url=$pool_url}
		} else {
			if {$debug eq "1"} { putlog "-> Pool URL not found" }
		}
	} else {
		if {$debug eq "1"} { putlog "no value submitted" }
	}
	registeredpools close
}

putlog "===>> Mining-Pool-Announce - Version $scriptversion loaded"
