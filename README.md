mpos-eggdrop-tcl
================

MPOS Addon - TCL Script for Eggdrop IRC Bot

This script is an addon for the popular eggdrop <a href="http://www.eggheads.org" target="_blank">Bot</a>

and gets API Data from <a href="https://github.com/TheSerapher/php-mpos" target="_blank">MPOS</a>, 
a fantastic Webinterface for people running Cryptocoin Pools

Active Pools
================

* http://elephantcoin.auxmining.de
* http://alphacoin.auxmining.de
* http://krugercoin.auxmining.de

Donations
================

For those of you finding my project and are willing to appreciate the work
with some hard earned coins feel free to donate:

* Litecoin:    `Lhiuh9Zv4dypuHn8gTphcveQydViUdKLux`
* Bitcoin:     `1HeUGoZGrSQPDmq24s9768J7oH6tdMeJBa`

FEATURES
================

* Easy Setup
* Support for multiple Pools
* Get Userbalance
* Get User Workers
* Show Pool Stats
* Show Round Stats
* Show Last Block Info
* Checking for new Blocks on multiple Pools
* Advertise new Blocks to Channel
* Advertise Stats and Infos directly into the channel or send via private Message
* Show actual Coin Price from Cryptsy, Coins-E or Vircurex
* Create own Channel Output with predefined variables

Requirements 
================

 - <a href="http://www.tcl.tk" target="_blank">TCL</a> (with JSON and TLS Support)
 - <a href="http://www.eggheads.org" target="_blank">eggdrop</a> IRC Bot
 - <a href="https://github.com/TheSerapher/php-mpos" target="_blank">MPOS</a>

INSTALL
================

copy or rename config.dist.tcl to config.tcl, configure the settings and add the following
lines at the end of your eggdrop.conf

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
source scripts/mininginfo/users.tcl
source scripts/mininginfo/marketdata.tcl
</pre>

Adding multiple Pools
================

Setting up multiple Pools in Config is very easy

<pre>
dict set pools btc apiurl 		"https://pool1.tld/"
dict set pools btc apikey   	"YOURMPOSAPIKEY"

dict set pools ltc apiurl 		"https://pool2.tld/"
dict set pools ltc apikey   	"YOURMPOSAPIKEY"
</pre>

You can add as many as you want. For example, the Value "btc" is the Pool Name, used to query the Pool.
Apiurl and Apikey are the Values from your MPOS installation. So, if your Pool Name is set to "btc"
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
information.


USAGE
================

If you are on IRC and the Bot sits in your channel, type one of the following commands to
communicate with the bot and get the output right in the channel

<pre>
!adduser ircnick                         - Adding User to userfile"
!deluser ircnick                         - Deleting User from userfile"
!block POOLNAME                          - Blockstats
!pool POOLNAME                           - Pool Information
!round POOLNAME                          - Actual Round Information
!last POOLNAME                           - Information about last found Block
!user POOLNAME username                  - Information about a specific User
!worker POOLNAME username                - Workers for specific User
!balance POOLNAME username               - Get User Wallet Balance
!price                                   - Get actual Coinprice
!help                                    - This help text
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
