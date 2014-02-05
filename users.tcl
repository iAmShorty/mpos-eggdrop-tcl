#
# MPOS eggdrop users
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
# check if user is already in userfile
#
proc check_mpos_user {username hostmask} {
	global debug sqlite_userfile
	sqlite3 registeredusers $sqlite_userfile
	
	set registereduser [string tolower $username]
	set registeredhostmask [string tolower $hostmask]
	
  	if {[llength [registeredusers eval {SELECT ircnick,hostmask FROM users WHERE hostmask=$registeredhostmask}]] == 0} {
  		set userhasrights "false"
  		putlog "user not in database"
  	} else {
  		set userhasrights "true"
  		putlog "user in database"
  	}
	
  	registeredusers close
  	return $userhasrights
}

#
# add user to userfile
#
proc user_add {nick uhost hand chan arg} {
	global debug sqlite_userfile
	sqlite3 registeredusers $sqlite_userfile

	if {[matchattr $nick +n]} {
		putlog "$nick is botowner"
	} else {
		putlog "$nick tried to add $arg to userfile"
		return
	}
 
  	if {$arg eq ""} {
  		putlog "no user to add"
  		return
  	} 

	set arg [string trim [charfilter $arg]]
	set hostmask "$arg!*[getchanhost $arg $chan]"
	if {$debug eq "1"} { putlog "Hostmask is: [string tolower $hostmask]"}
	
    if {[llength [registeredusers eval {SELECT ircnick,hostmask FROM users WHERE hostmask=$hostmask}]] == 0} {
		putlog "adding user"
		putquick "PRIVMSG $nick :user $arg added"
		registeredusers eval {INSERT INTO users (ircnick,hostmask) VALUES ($arg,$hostmask)}
    } else {
    	putlog "updating user"
    	putquick "PRIVMSG $nick :user $arg updated"
    	registeredusers eval {UPDATE users SET hostmask=$hostmask WHERE ircnick=$arg}
    }

	registeredusers close
}

#
# delete user from userfile
#
proc user_del {nick uhost hand chan arg} {
	global debug sqlite_userfile
	sqlite3 registeredusers $sqlite_userfile
	
	if {[matchattr $nick +n]} {
		putlog "$nick is botowner"
	} else {
		putlog "$nick tried to delete $arg from users"
		return
	}
  	
	set arg [string trim [charfilter $arg]]
	set hostmask "$arg!*[getchanhost $arg $chan]"

    if {[llength [registeredusers eval {SELECT hostmask FROM users WHERE ircnick=$arg}]] == 0} {
      puthelp "PRIVMSG $chan :\002$arg\002 is not in the database."
    } {
      registeredusers eval {DELETE FROM users WHERE ircnick=$arg}
      puthelp "PRIVMSG $chan :\002$arg\002 deleted."
    }
    registeredusers close
}

#
# request from users to add them to userfiles
#
proc user_request {nick uhost hand chan arg} {
	global debug scriptpath registereduserfile notificationadmins

	if {[matchattr $nick +n]} {
		putlog "$nick is botowner"
	} else {
		putlog "$nick requested adding user $arg to userfile"
		return
	}

  	if {$arg eq ""} {
  		putlog "no user to add"
  		return
  	}

	foreach admins $notificationadmins {
		putquick "NOTICE $admins :$nick requested adding user $arg to userfile"
	}

	putquick "NOTICE $nick: your request will be processed shortly, please be patient"
}


putlog "===>> Mining-Pool-Users - Version $scriptversion loaded"
