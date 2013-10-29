# Pool Stats

set scriptversion "v0.1 ALPHA"
set help_blocktime "10"

load ./modules/fbsql.so

set sqluser "sqluser"
set sqlpass "sqlpass"
set sqlhost "sqlhost"
set sqldb "sqldb"


bind pub - !mininginfo mining_info
bind pub - !pool pool_info
bind pub - !last last_info
bind pub - !user user_info
bind pub - !help printUsage


proc printUsage {nick host hand chan arg} {
    putquick "NOTICE $nick :Usage: !mininginfo  - Blockstats"
    putquick "NOTICE $nick :       !pool        - Pool Information"
    putquick "NOTICE $nick :       !last        - Information about last found Block"
    putquick "NOTICE $nick :       !user <user> - Information about a specific User"
}



proc user_info {nick host hand chan arg} {
 	global sqluser sqlpass sqlhost sqldb help_blocktime help_blocked
 	sql connect $sqlhost $sqluser $sqlpass
 	sql selectdb $sqldb

 	set mask [string trimleft $host ~]
 	regsub -all {@([^\.]*)\.} $mask {@*.} mask	 	
 	set mask *!$mask
 
  	if {[info exists help_blocked($mask)]} {
    	  putquick "NOTICE $nick :You have been blocked for $help_blocktime Seconds, please be patient..."
    	  sql disconnect
    	  return
  	}
  	
  	
  	set UserID [sql query "select id from accounts WHERE username = '$arg'"]
	set Shares_valid [sql query "select SUM(valid) from statistics_shares WHERE account_id = '$UserID'"]
  	set Shares_invalid [sql query "select SUM(invalid) from statistics_shares WHERE account_id = '$UserID'"]
  	
	putquick "PRIVMSG $chan :Username: $arg | Hashrate: 300 kh/s | Shares Valid: $Shares_valid | Shares Invalid: $Shares_invalid "

 	sql disconnect

	set help_blocked($mask) 1
	utimer $help_blocktime [ list unset help_blocked($mask) ]

}



proc last_info {nick host hand chan arg } {
 	global sqluser sqlpass sqlhost sqldb help_blocktime help_blocked
 	sql connect $sqlhost $sqluser $sqlpass
 	sql selectdb $sqldb

 	set mask [string trimleft $host ~]
 	regsub -all {@([^\.]*)\.} $mask {@*.} mask	 	
 	set mask *!$mask
 
  	if {[info exists help_blocked($mask)]} {
    	  putquick "NOTICE $nick : You have been blocked for $help_blocktime Seconds, please be patient..."
    	  sql disconnect
    	  return
  	}

	foreach row [sql query "SELECT height, confirmations, difficulty, shares, account_id from blocks ORDER BY id DESC LIMIT 1"] {
		set Block [lindex $row 0]
		set Confirmed [lindex $row 1]
		set Difficulty [lindex $row 2]
		set Shares [lindex $row 3]
		set AccID [lindex $row 4]
		set Founder [sql query "select username from accounts WHERE id = '$AccID'"]
		putquick "PRIVMSG $chan :Last Block: $Block | Shares: $Shares | Confirmations: $Confirmed | Solved By: $Founder"
 	}

 	sql disconnect

	set help_blocked($mask) 1
	utimer $help_blocktime [ list unset help_blocked($mask) ]

}

proc mining_info {nick host hand chan arg } {
 	global sqluser sqlpass sqlhost sqldb help_blocktime help_blocked
 	sql connect $sqlhost $sqluser $sqlpass
 	sql selectdb $sqldb

 	set mask [string trimleft $host ~]
 	regsub -all {@([^\.]*)\.} $mask {@*.} mask	 	
 	set mask *!$mask
 
  	if {[info exists help_blocked($mask)]} {
    	  putquick "NOTICE $nick : You have been blocked for $help_blocktime Seconds, please be patient..."
    	  sql disconnect
    	  return
  	}

	set countblocks [sql query "select count(ID) from blocks"]
	set countorphanblocks [sql query "select count(ID) from blocks where confirmations = -1"]
	set countvalidblocks [sql query "select count(ID) from blocks where confirmations > 0"]

	putquick "PRIVMSG $chan : Found Blocks: $countblocks | Orphaned: $countorphanblocks | Valid: $countvalidblocks"

 	sql disconnect

	set help_blocked($mask) 1
	utimer $help_blocktime [ list unset help_blocked($mask) ]

}

# Pool Stats
proc pool_info {nick host hand chan arg} {
	package require http
	package require json

 	set mask [string trimleft $host ~]
 	regsub -all {@([^\.]*)\.} $mask {@*.} mask	 	
 	set mask *!$mask
 
  	if {[info exists help_blocked($mask)]} {
    	  putquick "NOTICE $nick : You have been blocked for $help_blocktime Seconds, please be patient..."
    	  sql disconnect
    	  return
  	}
  	
    set token [::http::geturl "http://yourownurl.com/index.php?page=api&action=public"]
    set data [::http::data $token]
    ::http::cleanup $token
    #putlog "xml: $data"
    set results [::json::json2dict $data]
    
    set pool_name [dict get $results pool_name]
    set pool_hashrate [dict get $results hashrate]
    set pool_workers [dict get $results workers]
    set pool_lastblock [dict get $results last_block]
    set pool_roundshares [dict get $results shares_this_round]
    
    putlog $results
    putquick "PRIVMSG $chan :Pool Name: $pool_name"
    putquick "PRIVMSG $chan :Hashrate: $pool_hashrate khash | Workers: $pool_workers | Last Block: $pool_lastblock | Shares this round: $pool_roundshares"

}


putlog "===>> Mining-Pool-Stats - Version $scriptversion - geladen"
