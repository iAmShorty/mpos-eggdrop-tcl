mpos-eggdrop-tcl
================

MPOS Addon - TCL Script for Eggdrop IRC Bot

This script is an addon for the popular eggdrop <a href="http://www.eggheads.org" target="_blank">Bot</a>

and gets API Data from <a href="https://github.com/TheSerapher/php-mpos" target="_blank">MPOS</a>, 
a fantastic Webinterface for people running Cryptocoin Pools

Active Pools
================

* http://fastcoin.auxmining.de
* http://feathercoin.auxmining.de
* http://litecoin.auxmining.de

Donations
================

For those of you finding my project and are willing to appreciate the work
with some hard earned coins feel free to donate:

* Litecoin:    `Lhiuh9Zv4dypuHn8gTphcveQydViUdKLux`
* Bitcoin:     `1HeUGoZGrSQPDmq24s9768J7oH6tdMeJBa`
* Feathercoin: `6pxUWFWFshzDCYUQZyVsTtBbGNroGEfkGx`
* Fastcoin:    `fwhuoXRk4BcQabGtvoi97GrNWVqu7MTavz`

Contributing
================

You can contribute to this project in different ways:

* Report outstanding issues and bugs by creating an [Issue][1]
* Suggest feature enhancements also via [Issues][1]

INSTALL
================

simply add these lines at the end of your eggdrop.conf

<pre>
#
### Mininginfo
#
source scripts/mininginfo/http.tcl
source scripts/mininginfo/poolstats.tcl
source scripts/mininginfo/users.tcl
source scripts/mininginfo/marketdata.tcl
</pre>

USAGE
================

If you are on IRC and the Bot sits in your channel, type one of the following commands to
communicate with the bot and get the output right in the channel

<pre>
!adduser ircnick mposuser password       - Adding User to userfile"
!deluser ircnick mposuser password       - Deleting User from userfile"
!block                                   - Blockstats
!pool                                    - Pool Information
!round                                   - Actual Round Information
!last                                    - Information about last found Block
!user username                           - Information about a specific User
!worker username                         - Workers for specific User
!balance username                        - Get User Wallet Balance
!price                                   - Get actual Coinprice
!help                                    - This help text
</pre>

Requirements 
================

 - <a href="http://www.tcl.tk" target="_blank">TCL</a> (with JSON Support)
 - <a href="http://www.eggheads.org" target="_blank">eggdrop</a> IRC Bot
 - <a href="https://github.com/TheSerapher/php-mpos" target="_blank">MPOS</a>


Contact
================

You can find me on Freenode.net, #MPOS.

[1]: https://github.com/iAmShorty/mpos-eggdrop-tcl/issues "Issue"
