#
# Config File for eggdrop scripts
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
# some functions ONLY work with admin api key
# -> getting worker from specified user
# -> getting userinfo from specified user
#
##################################################################
# General Config
##################################################################

set scriptversion "v0.9"

# time to wait before next command in seconds
#
set help_blocktime "5"

# debug mode
# set to 1 to display debug messages
#
set debug "0"

# debug output
# set to 1 to display json output
# beware, lots of data
#
set debugoutput "0"

# setting the output style
#
# -> CHAN   - put all infos in channel
# -> NOTICE - sends notice to the user who triggered the command
#
set output "CHAN"

# script path
# 
# path to tcl files
#
# scriptpath is relative to you eggdrop install folder
# if your script is installed in /usr/src/eggdrop/scripts/mininginfo/
# scriptpath is "./scripts/mininginfo/
#
# NOTE:
# The user running the bot, must have rights set to 777 to
# the specified folder, otherwise the lastblock file for found
# and advertised block can not be written by the bot
# 
set scriptpath "./scripts/mininginfo/"

# channels to advertise new block information
# and post requested command output, if the bot
# sits in other channels, they will be ignored
#
set channels "#channel1 #channel2"

# admins who should receive notifications and
# error messages from channel or scripts
#
set notificationadmins "YOURREGISTEREDIRCUSER"

##################################################################
# MPOS Config
##################################################################

# Setting URLs and API Keys for multiple Pools
# you can add as much as you want
#
# Syntax is
# dict set pools COINNAME apiurl "YOURMPOSAPIURL"
# dict set pools COINNAME apikey "YOURMPOSAPIKEY"

dict set pools btc apiurl 		"https://pool1.tld/"
dict set pools btc apikey   	"YOURMPOSAPIKEY"

dict set pools ltc apiurl 		"https://pool2.tld/"
dict set pools ltc apikey   	"YOURMPOSAPIKEY"

# set to the coin you want to check for new
# blocks found. separate multiple pools with
# whitespace
#
set poolstocheck "BTC LTC"

# show net hashrate as 
# KH, MH, GH or TH
#
set shownethashrate "KH"

# show pool hashrate as 
# KH, MH, GH or TH
#
set showpoolhashrate "KH"

# file to save last blocks
#
set lastblockfile "lastblock"

# only allow registered users
# to use channel commands
#
# NOTE:
# users must have a valid auth on irc network
# and a valid and static hostmask to check for
# otherwise users can change their nick to a nick
# that belongs to another user and use the commands
# not allowed for them
#
set onlyallowregisteredusers "0"

# only allow botowners query users balances
# if set to "0" every user can query balances
# from all users available in mpos
#
set ownersbalanceonly "0"

# only allow botowners query users workers
# if set to "0" every user can query workers
# from all users available in mpos
#
set ownersworkeronly "0"

# confirmations before a block will be advertised
#
set confirmations "120"

# NOT USED AT THE MOMENT
# use one timer for all pools
# or use a timer for each pool
# 
# set to 0 if you want to use a timer for all pools
# set to 1 if you want to use a timer for each pool
#
set pooltimer "0"

# interval to check for new blocks in seconds
# if set to 0, the bot will do no automatic
# check for new blocks in seconds
#
set blockchecktime "60"

# interval to delete advertised blocks in minutes
# if set to 0, the bot will do no automatic
# delete of advertised blocks
#
set blockdeletetime "10"

##################################################################
# Marketdata Config
##################################################################

# what market to use
#
# coins-e   -> 1
# vircurex  -> 2
# cryptsy   -> 3
#
# set to 0 to disable marketdata
#
set activemarket "3"

# api url
#
# Coins-E
# https://www.coins-e.com/api/v2/markets/data/
#
# Vircurex
# https://vircurex.com/api/get_highest_bid.json
# 
# Cryptsy
# http://pubapi.cryptsy.com/api.php?method=singlemarketdata&marketid=
#
#set marketapi "https://www.coins-e.com/api/v2/markets/data/"
#set marketapi "https://vircurex.com/api/get_highest_bid.json"
set marketapi "http://pubapi.cryptsy.com/api.php?method=singlemarketdata&marketid="

#
# only used if Coins-E Market is defined
#
# coinpair to query
# coinpair must be on api page, e.g. LTC_BTC
#
set coinse_querycoin "LTC_BTC"

#
# only used if Vircurex Market is defined
#
set vircurex_querycoin "LTC"

#
# only used if Cryptsy Market is defined
#
# cryptsy market id
# 
# get market id from trade in cryptsy portal
#
# Litecoin = 3
# Fastcoin = 44
# Feathercoin = 5
# Alphacoin = 57
#
set cryptsy_marketid "3"

putlog "===>> Mining-Pool-Config - Version $scriptversion loaded"
