mpos-eggdrop-tcl
================

MPOS Addon - TCL Script for Eggdrop IRC Bot

This script is an addon for the popular eggdrop <a href="http://www.eggheads.org" target="_blank">Bot</a>

and gets API Data from <a href="https://github.com/TheSerapher/php-mpos" target="_blank">MPOS</a>, 
a fantastic Webinterface for people running Cryptocoin Pools

Active Pools
================

* http://machinecoin.auxmining.de

Donations
================

For those of you finding my project and are willing to appreciate the work
with some hard earned coins feel free to donate:

* Litecoin:            `LQXG758pmkFsMVvne3pxBB7222PNyLJUMk`
* Bitcoin:             `14p1qAwme57Foq1vMBPxJGC51wuE9V6d9M`
* DOGE:                `DEYvtW2u1gaJsBFMwRGTXZC2BZMoBjMznD`
* Crypts Trade Key:    `d2e11bd8d3fcd98ba686a92be71f6c1d606a3368`
* 
FEATURES
================

* Easy Setup
* Support for multiple Pools
* Easy add Pools on the fly
* Enable/Disable Pools on the fly
* Output can set to separate channels for each coin
* Command ACL per Channel, Coin and Command
* All Pool related Settings can be set on the fly and without rehashing the Bot
* Show registered Pools on channel
* Advertise Pools in Channel at a given timeframe
* Get Userbalance
* Get User Workers
* Show Pool Stats
* Show Round Stats
* Show Last Block Info
* Checking for new Blocks on multiple Pools
* Advertise new Blocks to Channel
* Advertise Stats and Infos directly into the channel or send via private Message
* Show actual Coin Price from Cryptsy, Coins-E or Vircurex
* Show Coin Infos from choinchoose
* Create own Channel Output with predefined variables
* Create custom output per Coin
* Add users to known users, not using eggdrops userfile
* Only allow known users access to commands
* Only allow commands in defined channels

Requirements 
================

 - <a href="http://www.tcl.tk" target="_blank">TCL</a> (with JSON, SQLITE and TLS Support)
 - <a href="http://www.eggheads.org" target="_blank">eggdrop</a> IRC Bot
 - <a href="https://github.com/TheSerapher/php-mpos" target="_blank">MPOS</a>

INSTALL
================

* copy or rename config.dist.tcl to config.tcl and configure the settings to suit your need
* copy or rename output.dist.tcl to output.tcl and set the output to what you like
* add the following lines at the end of your eggdrop.conf and rehash or reload the bot

<pre>
#
### Mininginfo
#
# basic scripts for settings and functions
#
source scripts/mininginfo/config.tcl
source scripts/mininginfo/basics.tcl
source scripts/mininginfo/bothelp.tcl
source scripts/mininginfo/output.tcl
source scripts/mininginfo/sqlite.tcl
# statistic scripts
#
source scripts/mininginfo/balance.tcl
source scripts/mininginfo/blockstats.tcl
source scripts/mininginfo/findblocks.tcl
source scripts/mininginfo/poolstats.tcl
source scripts/mininginfo/roundstats.tcl
source scripts/mininginfo/userstats.tcl
source scripts/mininginfo/workers.tcl

# additional scripts - non mpos related
#
source scripts/mininginfo/pools.tcl
source scripts/mininginfo/users.tcl
source scripts/mininginfo/announce.tcl
source scripts/mininginfo/marketdata.tcl
source scripts/mininginfo/coinchoose.tcl
source scripts/mininginfo/notify.tcl
</pre>

Managing Pools
================

Setting up multiple Pools is very easy

NOTE:
Only Botowners can manage Pools. You have to be recognized by the bot, else
you can't fire any of the commands. You can add as many Pools as you want.
Apiurl and Apikey are the Values from your MPOS installation.

Add a Pool
<pre>
!addpool APIURL COIN PAYOUTSYS FEE

e.g. !addpool http://yourpoolurl.tld BTC PPLNS 1
</pre>

Add Apikey to Pool
<pre>
/msg Botnick !apikey APIURL APIKEY

e.g. /msg Poolbot !apikey http://yourpoolurl.tld 23984710298674309812734098712309471092743
</pre>

Delete a Pool
<pre>
!delpool APIURL

e.g. !delpool http://yourpoolurl.tld
</pre>

Activating a Pool for Block advertising
<pre>
!blockfinder APIURL enable

e.g. !blockfinder http://youpoolurl.tld enable
or   !blockfinder http://youpoolurl.tld true
or   !blockfinder http://youpoolurl.tld 1
</pre>

Deactivating a Pool for Block advertising
<pre>
!blockfinder APIURL disable

e.g. !blockfinder http://youpoolurl.tld disable
or   !blockfinder http://youpoolurl.tld false
or   !blockfinder http://youpoolurl.tld 0
</pre>

Setting different Channel Announces for specified Coin
================

NOTE:
If not set for Coin, default Channels from Config file will be used. If you set different
Channels to advertise the Coins, config file entries will only be used to recognize
Commands typed in channel, not for Advertising Blockfinder Statistics.

Activating Announce for specified Coin to a specific Channel

<pre>
!announce COIN #channel 1
</pre>

Deactivating Announce for specified Coin to a specific Channel (defaults from config File will be used)

<pre>
!announce mac #channel 0
</pre>

Deleting Announces from Database

<pre>
!announce mac #auxmining delete
</pre>

Showing Announcement entries, will show all entries in Announce Table

<pre>
!announce
</pre>

Using Commands to query the Infos
================

Let's say the Value "BTC" is the Coin Name, used to query the Pool.
So, if your Pool Coin is set to "BTC" you can query the bot with following command

<pre>
!pool BTC
</pre>

Querying userinfos works like that

<pre>
!user BTC USERNAME
</pre>

Commands ACL
================

You can set access rights for every command and coin in defined Channels. Only set Commands
that should be protected in use.

<pre>
set protected_commands {
	"hashrate"
	"diff"
	"pool"
	"block"
	"last"
	"user"
	"round"
	"worker"
	"balance"
	"coinchoose"
	"request"
	"price"
}
</pre>

This is a Standard List of Commands that are protected. If you want specific Commands
not to be protected, remove them from the list and they will trigger in every Channel.
If you want to allow commands for a specific channel or coin, only activate them via
!command.

Use one of the Values set in protected_commands as COMMANDNAME. If you use ALL instead
of COMMANDNAME, all commands are allowed in specified channel.
<pre>
e.g. !command COMMANDNAME COIN #channel enable
or !command COMMANDNAME COIN #channel true
or !command COMMANDNAME COIN #channel 1
</pre>

You can simply disable the Command like this
<pre>
e.g. !command COMMANDNAME COIN #channel disable
or !command COMMANDNAME COIN #channel false
or !command COMMANDNAME COIN #channel 0
</pre>

Or delete them from Command list
<pre>
e.g. !command COMMANDNAME COIN #channel delete
</pre>

NOTE:
Commands in protected_commands and not enabled via !command, will not work

Creating self defined Output
================

In output.tcl, there are predefined output variables. If you want to create your own message that will
be posted to channel or by private message, you have to create your own text in the putput variables
of each section. Now there are predefined standard messages, which can be used to post the relevant
information. You can also use different messages based on coins you set in config.tcl

Standard Output looks like this and is predefined
<pre>
set output_balance "Coin: \0032%balance_coin%\003\
| User: %balance_user%\
| Confirmed: %balance_confirmed%\
| Unconfirmed: %balance_unconfirmed%\
| Orphan: %balance_orphan%"
</pre>

Customized output can look like this and is disabled by default
<pre>
set output_balance_percoin(btc) "Coin: \0032%balance_coin%\003 - test output btc"
set output_balance_percoin(ltc) "Coin: \0032%balance_coin%\003 - test output ltc"
</pre>
Customized output can be set for every coin added to config

USAGE
================

If you are on IRC and the Bot sits in your channel, type one of the following commands to
communicate with the bot and get the output right in the channel

<pre>
!adduser IRCNICK                       - Adding User to userfile"
!deluser IRCNICK                       - Deleting User from userfile"
!block COINNAME                        - Blockstats"
!pool COINNAME                         - Pool Information"
!round COINNAME                        - Round Information"
!last COINNAME                         - Last found Block"
!user COINNAME USER                    - User Information"
!worker COINNAME USER                  - Workerinfo for user"
!worker COINNAME USER active           - Users active Workers"
!worker COINNAME USER inactive         - User inactive Workers"
!balance COINNAME USER                 - User Wallet Balance"
!price                                 - Get actual Coinprice"
!coinchoose COINNAME                   - Get actual Coininfo from Coinchoose"
!pools                                 - Shows all registered Miningpools"
!pools COINNAME                        - Shows registered Miningpools for specified coin"
!addpool URL COIN PAYOUTSYS FEE        - Add Pool to Database"
!delpool URL                           - Delete Pool from Database"
!blockfinder URL enable/disable        - Activate/Deactivate Blockfinder announce in channel for specified pool"
!announce COIN CHANNEL enable/disable  - Set Announce for specified Coin an Channel, else post in Standard set in config"
/msg Botnick !apikey URL APIKEY        - Adds Apikey for specified host"
?help                                  - This help text"
</pre>

Contributing
================

You can contribute to this project in different ways:

* Report outstanding issues and bugs by creating an [Issue][1]
* Suggest feature enhancements also via [Issues][1]

Contact
================

You can find me on Freenode.net, #MPOS.

[1]: https://github.com/iAmShorty/mpos-eggdrop-tcl/issues "Issue"
