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
source scripts/mininginfo/http.tcl
source scripts/mininginfo/config.tcl
source scripts/mininginfo/basics.tcl
source scripts/mininginfo/bothelp.tcl
source scripts/mininginfo/output.tcl
source scripts/mininginfo/sqlite.tcl
source scripts/mininginfo/pools.tcl
source scripts/mininginfo/users.tcl

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
source scripts/mininginfo/marketdata.tcl
source scripts/mininginfo/coinchoose.tcl
source scripts/mininginfo/notify.tcl
</pre>

Managing Pools
================

Setting up multiple Pools is very easy

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
</pre>

Deactivating a Pool for Block advertising
<pre>
!blockfinder APIURL enable

e.g. !blockfinder http://youpoolurl.tld enable
</pre>

You can add as many as you want. For example, the Value "BTC" is the Coin Name, used to query the Pool.
Apiurl and Apikey are the Values from your MPOS installation. So, if your Pool Coin is set to "BTC"
you can query the bot with following command

<pre>
!pool BTC
</pre>

Querying userinfos works like that

<pre>
!user BTC USERNAME
</pre>

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
!adduser <ircnick>                - Adding User to userfile"
!deluser <ircnick>                - Deleting User from userfile"
!block COINNAME                   - Blockstats"
!pool COINNAME                    - Pool Information"
!round COINNAME                   - Round Information"
!last COINNAME                    - Last found Block"
!user COINNAME <user>             - User Information"
!worker COINNAME <user>           - Workerinfo for user"
!worker COINNAME <user> active    - Users active Workers"
!worker COINNAME <user> inactive  - User inactive Workers"
!balance COINNAME <user>          - User Wallet Balance"
!price                            - Get actual Coinprice"
!coinchoose COINNAME              - Get actual Coininfo from Coinchoose"
!pools                            - Shows all registered Miningpools"
!pools COINNAME                   - Shows registered Miningpools for specified coin"
!addpool URL COIN PAYOUTSYS FEE   - Add Pool to Database"
!delpool URL                      - Delete Pool from Database"
!blockfinder URL enable/disable   - Activate/Deactivate Blockfinder announce in channel for specified pool"
/msg Botnick !apikey URL APIKEY   - Adds Apikey for specified host"
?help                             - This help text"
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
