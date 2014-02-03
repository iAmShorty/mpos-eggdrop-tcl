#
# Config File for channel output
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
##################################################################
# General Config
##################################################################

#
# WARNING !!!
# Be careful what you are doing, changing the values and putting in
# wrong variables, can cause the bot to stop working!!!
#
#
# Color Scheme
# all color numbers are the same like they are in mIRC
# 
# NOTE:
# colors may or may not work in your irc client
# tested with XChat Azure on MAC, there are no
# colors shown. So don't blame me if the output
# is not colored. Sometimes you have to set channelmode
# in IRC to -c to get colors working
#
# 0  = white		8  = yellow
# 1  = black		9  = lightgreen
# 2  = darkblue		10 = darkcyan
# 3  = darkgreen	11 = lightcyan
# 4  = red			12 = lightblue
# 5  = brown		13 = pink
# 6  = magenta		14 = darkgrey
# 7  = orange		15 = lightgrey
#
# setting colors with \003X where X is the colorcode
# and resetting color with \003 where color should be
# normal again
#
# other options
#
# \027 = underline
# \002 = bold
#
# reset with \027 or \002 at the end of the value
#

#
# output for user balance
#
# -> %balance_coin%
# -> %balance_user%
# -> %balance_confirmed%
# -> %balance_unconfirmed%
# -> %balance_orphaned%
#
set output_balance "Coin: \0032%balance_coin%\003\
| User: %balance_user%\
| Confirmed: %balance_confirmed%\
| Unconfirmed: %balance_unconfirmed%\
| Orphan: %balance_orphan%"

# different announcements per coin
# use coins set in config.tcl with config option
# -> set poolstocheck "BTC LTC"
# the coins listed here, can be used for different
# announcements per coin. if not set or commented out
# the standard announce will be used for announcing
#
# NOTE:
# coinname must be in lowercase
#
#set output_balance_percoin(btc) "Coin: \0032%balance_coin%\003 - test output btc"
#set output_balance_percoin(ltc) "Coin: \0032%balance_coin%\003 - test output ltc"

#
# output for current block information
#
# -> %blockstats_coin%
# -> %blockstats_current%
# -> %blockstats_next%
# -> %blockstats_last%
# -> %blockstats_diff%
# -> %blockstats_time%
# -> %blockstats_shares%
# -> %blockstats_timelast%
#
set output_blockinfo "Coin: \0032%blockstats_coin%\003\
| Current Block: %blockstats_current%\
| Next Block: %blockstats_next%\
| Last Block: %blockstats_last%\
| Difficulty: %blockstats_diff%\
| Est. Time to resolve: %blockstats_time% minutes\
| Est. Shares to resolve: %blockstats_shares%\
| Time since last Block: %blockstats_timelast% minutes"

# different announcements per coin
# use coins set in config.tcl with config option
# -> set poolstocheck "BTC LTC"
# the coins listed here, can be used for different
# announcements per coin. if not set or commented out
# the standard announce will be used for announcing
#
# NOTE:
# coinname must be in lowercase
#
#set output_blockinfo_percoin(btc) "Coin: \0032%blockstats_coin%\003 - test output btc"
#set output_blockinfo_percoin(ltc) "Coin: \0032%blockstats_coin%\003 - test output ltc"

#
# output for last block information
#
# -> %blockstats_coin%
# -> %blockstats_lastblock%
# -> %blockstats_lastconfirmed%
# -> %blockstats_lastconfirmations%
# -> %blockstats_lastdifficulty%
# -> %blockstats_lasttimefound%
# -> %blockstats_lastshares%
# -> %blockstats_lastestshares%
# -> %blockstats_lastfinder%
#
set output_lastblock "Coin: \0032%blockstats_coin%\003\
| Block: #%blockstats_lastblock%\
| Status: %blockstats_lastconfirmed%\
| Confirmations: %blockstats_lastconfirmations%\
| Difficulty: %blockstats_lastdifficulty%\
| Time found: %blockstats_lasttimefound%\
| Shares: %blockstats_lastshares%\
| Est. Shares: %blockstats_lastestshares%\
| Finder: %blockstats_lastfinder%"

# different announcements per coin
# use coins set in config.tcl with config option
# -> set poolstocheck "BTC LTC"
# the coins listed here, can be used for different
# announcements per coin. if not set or commented out
# the standard announce will be used for announcing
#
# NOTE:
# coinname must be in lowercase
#
#set output_lastblock_percoin(btc) "Coin: \0032%blockstats_coin%\003 - test output btc"
#set output_lastblock_percoin(ltc) "Coin: \0032%blockstats_coin%\003 - test output ltc"

#
# output for advertising blocks
#
# -> %blockfinder_coinname%
# -> %blockfinder_newblock%
# -> %blockfinder_lastblock%
# -> %blockfinder_laststatus%
# -> %blockfinder_confirmations%
# -> %blockfinder_lastestshares%
# -> %blockfinder_lastshares%
# -> %blockfinder_percentage%
# -> %blockfinder_lastfinder%
# -> %blockfinder_diff%
# -> %blockfinder_worker%
# -> %blockfinder_amount%
#
set output_findblocks "Coin: \0032%blockfinder_coinname%\003\
| New Block: #%blockfinder_newblock%\
| Last Block: #%blockfinder_lastblock%\
| Status: %blockfinder_laststatus%\
| Confirmations: %blockfinder_confirmations%\
| Est. Shares: %blockfinder_lastestshares%\
| Shares: %blockfinder_lastshares%\
| Percentage: %blockfinder_percentage% %\
| Difficulty: %blockfinder_diff%\
| Amount: %blockfinder_amount%\
| Finder: %blockfinder_lastfinder%\
| Worker: %blockfinder_worker%"

# different announcements per coin
# use coins set in config.tcl with config option
# -> set poolstocheck "BTC LTC"
# the coins listed here, can be used for different
# announcements per coin. if not set or commented out
# the standard announce will be used for announcing
#
# NOTE:
# coinname must be in lowercase
#
#set output_findblocks_percoin(btc) "Coin: \0032%blockfinder_coinname%\003 - test output btc"
#set output_findblocks_percoin(ltc) "Coin: \0032%blockfinder_coinname%\003 - test output ltc"

#
# output for poolstats
#
# -> %roundstats_coin%
# -> %poolstats_block%
# -> %poolstats_diffchange%
# -> %poolstats_diff%
# -> %poolstats_nextdiff%
# -> %poolstats_esttime%
# -> %poolstats_nethashratevalue%
# -> %poolstats_nethashrate%
# -> %poolstats_sharesvalid%
# -> %poolstats_sharesinvalid%
# -> %poolstats_sharesestimated%
# -> %poolstats_sharesprogress%
# -> %poolstats_poolhashratevalue%
# -> %poolstats_poolhashrate%
# -> %poolstats_poolworkers%
# -> %poolstats_efficiency%
#
set output_poolstats "Pool: \0032%poolstats_coin%\003\
| Block: #%poolstats_block%\
| Diff change in: %poolstats_blocksuntildiffchange% Blocks\
| Pool Diff: %poolstats_diff%\
| Next Diff: %poolstats_nextdiff%\
| Est. Time per Block: %poolstats_esttime% min.\
| Shares valid: %poolstats_sharesvalid%\
| Shares invalid: %poolstats_sharesinvalid%\
| Shares est.: %poolstats_sharesestimated%\
| Progress: %poolstats_sharesprogress% %\
| Hashrate: %poolstats_poolhashrate% %poolstats_poolhashratevalue%\
| Efficiency: %poolstats_efficiency% %\
| Workers: %poolstats_poolworkers%\
| Net Hashrate: %poolstats_nethashrate% %poolstats_nethashratevalue%"

# different announcements per coin
# use coins set in config.tcl with config option
# -> set poolstocheck "BTC LTC"
# the coins listed here, can be used for different
# announcements per coin. if not set or commented out
# the standard announce will be used for announcing
#
# NOTE:
# coinname must be in lowercase
#
#set output_poolstats_percoin(btc) "Coin: \0032%poolstats_coin%\003 - test output btc"
#set output_poolstats_percoin(ltc) "Coin: \0032%poolstats_coin%\003 - test output ltc"

#
# output for roundstats
#
# -> %roundstats_coin%
# -> %roundstats_block%
# -> %roundstats_diff%
# -> %roundstats_estshares%
# -> %roundstats_allshares%
# -> %roundstats_validshares%
# -> %roundstats_invalidshares%
# -> %roundstats_progress%
#
set output_roundstats "Pool: \0032%roundstats_coin%\003\
| Block: #%roundstats_block%\
| Difficulty: %roundstats_diff%\
| Estimated Shares: %roundstats_estshares%\
| Sharecount: %roundstats_allshares%\
| Shares valid: %roundstats_validshares%\
| Shares invalid: %roundstats_invalidshares%\
| Progress: %roundstats_progress%"

# different announcements per coin
# use coins set in config.tcl with config option
# -> set poolstocheck "BTC LTC"
# the coins listed here, can be used for different
# announcements per coin. if not set or commented out
# the standard announce will be used for announcing
#
# NOTE:
# coinname must be in lowercase
#
#set output_roundstats_percoin(btc) "Coin: \0032%roundstats_coin%\003 - test output btc"
#set output_roundstats_percoin(ltc) "Coin: \0032%roundstats_coin%\003 - test output ltc"

#
# output for userstats
#
# -> %userstats_coin%
# -> %userstats_user%
# -> %userstats_hashrate%
# -> %userstats_validround%
# -> %userstats_invalidround%
# -> %userstats_sharerate%
#
set output_userstats "Pool: \0032%userstats_coin%\003\
| User: %userstats_user%\
| Hashrate: %userstats_hashrate% KH/s\
| Valid this round: %userstats_validround%\
| Invalid this round: %userstats_invalidround%\
| Sharerate: %userstats_sharerate% S/s"

# different announcements per coin
# use coins set in config.tcl with config option
# -> set poolstocheck "BTC LTC"
# the coins listed here, can be used for different
# announcements per coin. if not set or commented out
# the standard announce will be used for announcing
#
# NOTE:
# coinname must be in lowercase
#
#set output_userstats_percoin(btc) "Coin: \0032%userstats_coin%\003 - test output btc"
#set output_userstats_percoin(ltc) "Coin: \0032%userstats_coin%\003 - test output ltc"

#
# output for general worker information
#
# -> %workers_username%
# -> %workers_coinname%
# -> %workers_online_count%
# -> %workers_offline_count%
# -> %workers_workername%
# -> %workers_workerhashrate%
#
set output_workerinfo "User %workers_username%\
has %workers_online_count% active\
and %workers_offline_count% inactive workers\
on %workers_coinname% Pool"

# different announcements per coin
# use coins set in config.tcl with config option
# -> set poolstocheck "BTC LTC"
# the coins listed here, can be used for different
# announcements per coin. if not set or commented out
# the standard announce will be used for announcing
#
# NOTE:
# coinname must be in lowercase
#
#set output_workerinfo_percoin(btc) "Coin: \0032%workers_coinname%\003 - test output btc"
#set output_workerinfo_percoin(ltc) "Coin: \0032%workers_coinname%\003 - test output ltc"


##########################################################################################
####################               no pool realated output            ####################
##########################################################################################


#
# output for marketdata
#
# - Cryptsy
#
# -> %marketdata_market%
# -> %marketdata_tradeprice%
# -> %marketdata_tradetrime%
# -> %marketdata_tradelabel%
# -> %marketdata_tradevolume%
#
set output_marketdata_cryptsy "Market: \0032%marketdata_market%\003\
| Latest Price: %marketdata_tradeprice% %marketdata_tradelabel%\
| Last Trade: %marketdata_tradetrime%\
| Volume: %marketdata_tradevolume%"

#
# - Vircurex
#
# -> %marketdata_market%
# -> %trade_base%
# -> %trade_price%
# -> %trade_alt%
#
set output_marketdata_vircurex "Market: \0032%marketdata_market%\003\
| Coin: %trade_base%\
| Latest Price: %trade_price% %trade_alt%"

#
# - Coins-E
#
# -> %marketdata_market%
# -> %marketdata_altcoin%
# -> %marketdata_tradehigh%
# -> %marketdata_tradelow%
# -> %marketdata_tradeavg%
# -> %marketdata_tradevolume%
# -> %marketdata_basecoin%
#
set output_marketdata_coinse "Market: \0032%marketdata_market%\003\
| Coin: %marketdata_altcoin%\
| High: %marketdata_tradehigh% %marketdata_basecoin%\
| Low: %marketdata_tradelow% %basecoin%\
| AVG: %marketdata_tradeavg% %marketdata_basecoin%\
| Volume: %marketdata_tradevolume%"

#
# Coinchoose output
#
# -> %coinchoose_name%
# -> %coinchoose_algo%
# -> %coinchoose_currentblocks%
# -> %coinchoose_diff%
# -> %coinchoose_exchange%
# -> %coinchoose_price%
# -> %coinchoose_reward%
# -> %coinchoose_networkhashrate%
# -> %coinchoose_avgprofit%
# -> %coinchoose_avghash%
#
set output_coinchoose "Coin: \0032%coinchoose_name%\003\
| Algo: %coinchoose_algo%\
| Current Blocks: %coinchoose_currentblocks%\
| Diff: %coinchoose_diff%\
| Price: %coinchoose_price% BTC\
| Blockreward: %coinchoose_reward%\
| Avg. Profit: %coinchoose_avgprofit%\
| Network Hashrate: %coinchoose_networkhashrate%\
| Avg. Hashrate: %coinchoose_avghash%\
| Exchange: %coinchoose_exchange%"

putlog "===>> Mining-Pool-Outputconfig - Version $scriptversion loaded"
