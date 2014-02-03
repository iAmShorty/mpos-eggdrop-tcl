#
# Output Commands to the users
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
# print bot usage info
#
proc printUsage {nick host hand chan arg} {
	putquick "NOTICE $nick :Usage:"
    putquick "NOTICE $nick :       !adduser <ircnick>                - Adding User to userfile"
    putquick "NOTICE $nick :       !deluser <ircnick>                - Deleting User from userfile"
    putquick "NOTICE $nick :       !block COINNAME                   - Blockstats"
    putquick "NOTICE $nick :       !pool COINNAME                    - Pool Information"
    putquick "NOTICE $nick :       !round COINNAME                   - Round Information"
    putquick "NOTICE $nick :       !last COINNAME                    - Last found Block"
    putquick "NOTICE $nick :       !user COINNAME <user>             - User Information"
    putquick "NOTICE $nick :       !worker COINNAME <user>           - Workerinfo for user"
    putquick "NOTICE $nick :       !worker COINNAME <user> active    - Users active Workers"
    putquick "NOTICE $nick :       !worker COINNAME <user> inactive  - User inactive Workers"
    putquick "NOTICE $nick :       !balance COINNAME <user>          - User Wallet Balance"
    putquick "NOTICE $nick :       !price                            - Get actual Coinprice"
    putquick "NOTICE $nick :       !coininfo COINNAME                - Get actual Coininfo from Coinchoose"
    putquick "NOTICE $nick :       ?help                             - This help text"
}

putlog "===>> Mining-Pool-Bothelp - Version $scriptversion loaded"
