#
# Pool Informations
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
# add pools from database
#
proc pool_add {nick uhost hand chan arg} {
	global debug sqlite_poolfile
	sqlite3 registeredpools $sqlite_poolfile

	if {[check_userrights $chan $nick] eq "false"} {
		if {$debug eq "1"} { putlog "$nick tried to add $arg to pools" }
		return
	}

	set userarg [charfilter $nick]
	set hostmask "$userarg!*[getchanhost $userarg $chan]"
	
	if {[llength $arg] != "4"} {
		putquick "PRIVMSG $chan :wrong arguments, should be !addpool POOLURL COINNAME PAYOUTSYSTEM FEE"
		return
	}
	
	set pool_url [string tolower [lindex $arg 0]]
	set pool_coin [string toupper [lindex $arg 1]]
	set pool_payout [string toupper [lindex $arg 2]]
	set pool_fee [lindex $arg 3]
	set actualtime [unixtime]
	
	set data [check_httpdata $pool_url]
	if { [regexp -nocase {error} $data] } {
		putlog $data
		return
	}
	
	if {[llength [registeredpools eval {SELECT coin FROM pools WHERE coin=$pool_coin}]] == 0} {
		if {[llength [registeredpools eval {SELECT url FROM pools WHERE url=$pool_url}]] == 0} {
			if {$debug eq "1"} { putlog "adding pool" }
			putquick "PRIVMSG $chan :pool $pool_url added"
			registeredpools eval {INSERT INTO pools (url,coin,payoutsys,fees,user,timestamp) VALUES ($pool_url,$pool_coin,$pool_payout,$pool_fee,$userarg,$actualtime)}
		} else {
			if {$debug eq "1"} { putlog "updating pool" }
			putquick "PRIVMSG $chan :pool $pool_url updated"
			registeredpools eval {UPDATE pools SET url=$pool_url, coin=$pool_coin, payoutsys=$pool_payout, fees=$pool_fee, user=$userarg WHERE url=$pool_url}
		}
	} else {
		if {$debug eq "1"} { putlog "Pool for Coin $pool_coin already exists" }
		putquick "PRIVMSG $chan :Pool for Coin $pool_coin already exists"
	}

	registeredpools close
}

#
# delete pools from database
#
proc pool_del {nick uhost hand chan arg} {
	global debug sqlite_poolfile
	sqlite3 registeredpools $sqlite_poolfile
	
	if {[check_userrights $chan $nick] eq "false"} {
		if {$debug eq "1"} { putlog "$nick tried to delete $arg to pools" }
		return
	}

	if {[llength $arg] != "1"} {
		putquick "PRIVMSG $chan :wrong arguments, should be !delpool POOLURL"
		return
	}
	
	set pool_url [string tolower $arg]
	
	if {[llength [registeredpools eval {SELECT user FROM pools WHERE url=$pool_url}]] == 0} {
		puthelp "PRIVMSG $chan :\002$pool_url\002 is not in the database."
	} {
		registeredpools eval {DELETE FROM pools WHERE url=$pool_url}
		puthelp "PRIVMSG $chan :\002$pool_url\002 deleted."
	}
	registeredpools close
}

#
# add apikey to pool
#
proc pool_apikey {nick uhost hand arg} {
	global debug sqlite_poolfile
	sqlite3 registeredpools $sqlite_poolfile
	
	if {[check_userrights $chan $nick] eq "false"} {
		if {$debug eq "1"} { putlog "$nick tried to add api key $arg to pools" }
		return
	}

	if {[llength $arg] != "2"} {
		putquick "NOTICE $nick :wrong arguments, should be /msg BOTNICK !apikey POOLURL APIKEY"
		return
	}
	
	set pool_url [string tolower [lindex $arg 0]]
	set api_key [lindex $arg 1]
	if {[llength [registeredpools eval {SELECT url FROM pools WHERE url=$pool_url}]] != 0} {
		if {$debug eq "1"} { putlog "-> adding api key" }
		putquick "NOTICE $nick :added api key for $pool_url"
		registeredpools eval {UPDATE pools SET apikey=$api_key WHERE url=$pool_url}
	}
	registeredpools close
}


#
# list pools from database
#
proc pool_list {nick uhost hand chan arg} {
	global debug sqlite_poolfile
	sqlite3 registeredpools $sqlite_poolfile
	
	if {[check_userrights $chan $nick] eq "false"} {
		if {$debug eq "1"} { putlog "$nick tried to list $arg to pools" }
		return
	}
	
	if {$arg eq ""} {
		set scount [registeredpools eval {SELECT COUNT(1) FROM pools}]
		foreach {url coin payout_sys fees} [registeredpools eval {SELECT url,coin,payoutsys,fees FROM pools} ] {
			append outvar "\002Coin:\002 $coin -> \002URL:\002 $url -> \002Payout:\002 $payout_sys | \002Poolfee:\002 $fees %\n"
		}
	} elseif {[string tolower $arg] eq "enabled" || [string tolower $arg] eq "true" || [string tolower $arg] eq "1"} {
		set scount [registeredpools eval {SELECT COUNT(1) FROM pools WHERE blockfinder = 1}]
		foreach {url coin payout_sys fees} [registeredpools eval {SELECT url,coin,payoutsys,fees FROM pools WHERE blockfinder = 1} ] {
			append outvar "\002Coin:\002 $coin -> \002URL:\002 $url -> \002Payout:\002 $payout_sys | \002Poolfee:\002 $fees %\n"
		}
	} elseif {[string tolower $arg] eq "disabled" || [string tolower $arg] eq "false" || [string tolower $arg] eq "0"} {
		set scount [registeredpools eval {SELECT COUNT(1) FROM pools WHERE blockfinder = 0}]
		foreach {url coin payout_sys fees} [registeredpools eval {SELECT url,coin,payoutsys,fees FROM pools WHERE blockfinder = 0} ] {
			append outvar "\002Coin:\002 $coin -> \002URL:\002 $url -> \002Payout:\002 $payout_sys | \002Poolfee:\002 $fees %\n"
		}
	} else {
		set poolcoin [string toupper $arg]
		set scount [registeredpools eval {SELECT COUNT(1) FROM pools WHERE coin=$poolcoin}]
		foreach {url coin payout_sys fees} [registeredpools eval {SELECT url,coin,payoutsys,fees FROM pools WHERE coin=$poolcoin} ] {
			append outvar "\002Coin:\002 $poolcoin -> \002URL:\002 $url -> \002Payout:\002 $payout_sys | \002Poolfee:\002 $fees %\n"
		}
	}

	putquick "PRIVMSG $chan :Number of Pools: $scount"
	if {$scount != 0} {
		set records [split $outvar "\n"]
		foreach rec $records {
			putquick "PRIVMSG $chan :$rec"
		}
	}
	registeredpools close
}

putlog "===>> Mining-Pool-Pools - Version $scriptversion loaded"
