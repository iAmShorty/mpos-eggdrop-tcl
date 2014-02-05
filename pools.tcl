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
	global debug allowpooladding sqlite_poolfile
	sqlite3 registeredpools $sqlite_poolfile
	
	if {[matchattr $nick +n]} {
		putlog "$nick is botowner"
	} else {
		putlog "$nick tried to add $arg to pools"
		return
	}

	set userarg [charfilter $nick]
	set hostmask "$userarg!*[getchanhost $userarg $chan]"
	
	set pool_url [lindex $arg 0]
	set pool_coin [lindex $arg 1]
	set pool_payout [lindex $arg 2]
	set pool_fee [lindex $arg 3]
	
    if {[llength [registeredpools eval {SELECT url FROM pools WHERE url=$pool_url}]] == 0} {
		putlog "adding pool"
		putquick "PRIVMSG $nick :pool $pool_url added"
		registeredpools eval {INSERT INTO pools (url,coin,payoutsys,fees,user) VALUES ($pool_url,[string toupper $pool_coin],$pool_payout,$pool_fee,$userarg)}
    } else {
    	putlog "updating pool"
    	putquick "PRIVMSG $nick :pool $pool_url updated"
    	registeredpools eval {UPDATE pools SET url=$pool_url, coin=$pool_coin, payoutsys=$pool_payout, fees=$pool_fee, user=$userarg WHERE url=$pool_url}
    }

	registeredpools close
}

#
# delete pools from database
#
proc pool_del {nick uhost hand chan arg} {
	global debug allowpooladding sqlite_poolfile
	sqlite3 pools $sqlite_poolfile
	
	if {[matchattr $nick +n]} {
		putlog "$nick is botowner"
	} else {
		putlog "$nick tried to delete $arg from pools"
		return
	}
	
    if {[llength [registeredpools eval {SELECT user FROM pools WHERE url=$arg}]] == 0} {
      puthelp "PRIVMSG $chan :\002$arg\002 is not in the database."
    } {
      registeredpools eval {DELETE FROM pools WHERE url=$arg}
      puthelp "PRIVMSG $chan :\002$arg\002 deleted."
    }
    registeredpools close
}

#
# list pools from database
#
proc pool_list {nick uhost hand chan arg} {
	global debug allowpooladding sqlite_poolfile
	sqlite3 pools $sqlite_poolfile
	
	if {[matchattr $nick +n]} {
		putlog "$nick is botowner"
	} else {
		putlog "$nick tried to list $arg from pools"
		return
	}
	
	if {$arg eq ""} {
		set scount [registeredpools eval {SELECT COUNT(1) FROM pools}]
		foreach {url coin payout_sys fees} [registeredpools eval {SELECT url,coin,payoutsys,fees FROM pools} ] {
    	  append outvar "Coin: $coin -> \002$url\002  "
    	}
	} else {
		set poolcoin [string toupper $arg]
		set scount [registeredpools eval {SELECT COUNT(1) FROM pools WHERE coin=$poolcoin}]
		set outvar "Coin: $poolcoin | "
		foreach {url coin payout_sys fees} [registeredpools eval {SELECT url,coin,payoutsys,fees FROM pools WHERE coin=$poolcoin} ] {
    	  append outvar "\002$url\002 -> Payout: $payout_sys | Poolfee: $fees %"
    	}
	}

	putquick "PRIVMSG $chan :Number of Pools: $scount"
    putquick "PRIVMSG $chan :$outvar"
    registeredpools close
}

putlog "===>> Mining-Pool-Pools - Version $scriptversion loaded"
