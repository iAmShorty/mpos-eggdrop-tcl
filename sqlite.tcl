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

package require sqlite3

set sqlite_poolfile "$scriptpath/db/pooldata.db"
set sqlite_userfile "$scriptpath/db/userdata.db"
set sqlite_blockfile "$scriptpath/db/blockdata.db"
set sqlite_announce "$scriptpath/db/announce.db"
set sqlite_commands "$scriptpath/db/commands.db"

if {![file exists "$scriptpath/db"]} {
	file mkdir "$scriptpath/db" 
}

if {![file exists $sqlite_poolfile]} { 
	sqlite3 pools $sqlite_poolfile
	pools eval {CREATE TABLE pools(pool_id integer primary key autoincrement, url TEXT NOT NULL, coin TEXT NOT NULL, payoutsys TEXT NOT NULL, fees INTEGER NOT NULL, apikey TEXT NOT NULL default 0, blockfinder INTEGER DEFAULT 0, advertise INTEGER DEFAULT 0, user TEXT NOT NULL, timestamp DATETIME)}
	pools close
}

if {![file exists $sqlite_userfile]} { 
	sqlite3 users $sqlite_userfile
	users eval {CREATE TABLE users(user_id integer primary key autoincrement, ircnick TEXT NOT NULL, hostmask TEXT NOT NULL, timestamp DATETIME)}
	users close
}

if {![file exists $sqlite_blockfile]} { 
	sqlite3 blocks $sqlite_blockfile
	blocks eval {CREATE TABLE blocks(block_id integer primary key autoincrement, poolcoin TEXT NOT NULL default 'null', last_block INTEGER NOT NULL, last_status TEXT NOT NULL default 'null', last_estshares INTEGER NOT NULL, last_shares INTEGER NOT NULL, last_finder TEXT NOT NULL default 'null', last_confirmations INTEGER NOT NULL, last_diff FLOAT NOT NULL default '0', last_anon TEXT NOT NULL default 'null', last_worker TEXT NOT NULL default 'null', last_amount FLOAT NOT NULL, posted TEXT NOT NULL default 'N', timestamp DATETIME)}
	blocks close
}

if {![file exists $sqlite_announce]} { 
	sqlite3 announce $sqlite_announce
	announce eval {CREATE TABLE announce(announce_id integer primary key autoincrement, coin TEXT NOT NULL, channel TEXT NOT NULL, advertise INTEGER DEFAULT 0)}
	announce close
}

if {![file exists $sqlite_commands]} { 
	sqlite3 commands $sqlite_commands
	commands eval {CREATE TABLE commands(command_id integer primary key autoincrement, command TEXT NOT NULL, channel TEXT NOT NULL, activated INTEGER DEFAULT 0)}
	commands close
}

putlog "===>> Mining-Pool-DB-Initialization - Version $scriptversion loaded"
