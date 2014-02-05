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

if {![file exists "$scriptpath/db"]} { 
         file mkdir "$scriptpath/db" 
}

if {![file exists $sqlite_poolfile]} { 
  sqlite3 pools $sqlite_poolfile
    pools eval {CREATE TABLE pools(pool_id integer primary key autoincrement, url TEXT NOT NULL COLLATE NOCASE, coin TEXT NOT NULL COLLATE NOCASE, payoutsys TEXT NOT NULL COLLATE NOCASE, fees TEXT NOT NULL COLLATE NOCASE, user TEXT NOT NULL COLLATE NOCASE)}
  pools close
}

if {![file exists $sqlite_userfile]} { 
  sqlite3 users $sqlite_userfile
    users eval {CREATE TABLE users(user_id integer primary key autoincrement, ircnick TEXT NOT NULL COLLATE NOCASE, hostmask TEXT NOT NULL COLLATE NOCASE)}
  users close
}

if {![file exists $sqlite_blockfile]} { 
  sqlite3 blocks $sqlite_blockfile
    blocks eval {CREATE TABLE blocks(block_id integer primary key autoincrement, blockheight TEXT NOT NULL COLLATE NOCASE, coin TEXT NOT NULL COLLATE NOCASE, confirmations INTEGER NOT NULL, posted TEXT NOT NULL default 'N')}
  blocks close
}

putlog "===>> Mining-Pool-DB-Initialization - Version $scriptversion loaded"
