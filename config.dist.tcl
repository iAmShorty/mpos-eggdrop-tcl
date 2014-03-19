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

set scriptversion "v 1.1"

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

# set the query timeout for api calls
# 
# -> standard value is 5000 ms
# set this to a higher value if your pool api response is
# slow or the internet connection from bot is bad
#
set http_query_timeout 5000

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
# this channels will be used if no specific channel
# is set for coin announcement
#
set channels "#channel1 #channel2"

#
# Setting list of protected commands
#
# here you can set a list of protected commands
# per channel. all commands set in this list can't
# be triggered if not set to enabled. commands not in
# this list can be triggered from every channel.
#
# set command_protect to 1 to activate it
#
set command_protect "0"

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
	"calc"
}

# admins who should receive notifications and
# error messages from channel or scripts
#
set notificationadmins "YOURREGISTEREDIRCUSER"

##################################################################
# Advertising Settings
##################################################################

# the bot can change the channeltopic to actual 
# coinprice, if set to 1. deactivate with 0
# NOTE
# bot must have channel privileges to change the
# channel topic. if not, no change will happen
#
set changechanneltopic "0"

# posting coininfo to channel
# there are 2 modes to set
# 0 -> deactivated
# 1 -> activates posting actual coinprice in given interval
# 2 -> activates posting coinprice at a give value
#      if price of coin has reached this value, it will
#      be announced in channel 5 times with 1 minute interval
#
set postcoininfo "0"

# set interval in second in which bot should post the
# actual coinprice to channel
#
set postcoininfointerval "600"

# posting pool information to channel
# posts pool information from added pools
# in channel
#
set postpoolinfo "0"

# set interval in second in which bot should post the
# the pools in db
#
set postpoolinfointerval "300"

##################################################################
# Pool Config
##################################################################

# show net hashrate as 
# KH, MH, GH or TH
#
set shownethashrate "MH"

# show pool hashrate as 
# KH, MH, GH or TH
#
set showpoolhashrate "MH"

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
set ownersbalanceonly "1"

# only allow botowners query users workers
# if set to "0" every user can query workers
# from all users available in mpos
#
set ownersworkeronly "1"

##################################################################
# Blockfinder Config
##################################################################

# confirmations before a block will be advertised
#
set confirmations "10"

# interval to check for new blocks in seconds
# if set to 0, the bot will do no automatic
# checking for new blocks
# 
# NOTE
# be sure you set "block statistics count" in MPOS
# to a value where all blocks are shown. if this is
# set to low on fast finding block pools, not
# all found and confirmed blocks will be advertised
# this setting depends on confirmations before posting in channel
#
set blockchecktime "60"

# interval to delete advertised blocks in seconds
# if set to 0, the bot will do no automatic
# delete of advertised blocks
#
# NOTE
# set this to value where all blocks should have
# network confirmations, else blocks not confirmed
# by network will be deleted. this setting depends
# on confirmations before posting in channel. setting
# this value to low, will delete advertised blocks and
# insert them again depending on blockchecktime and
# confirmations needed before advertising if bot is
# advertising blocks more than one time, set this to
# a higher value
#
# 1 hour -> 3600 seconds (suggested)
# 1 day  -> 86400 seconds
# will delete blocks older than one day from database
#
set blockdeletetime "3600"

# keep certain amount of blocks in database
# useful for slow finding blockrate
# keeps blocks in database to prevent double
# post in channel. best practice, set this to
# your shown blocks in block statistics page
# -> standard setting in mmpos = 20
#
set blockstokeep "20"

##################################################################
# Marketdata Config
##################################################################

# what market to use
#
# coins-e   -> 1
# vircurex  -> 2
# cryptsy   -> 3
# mintpal   -> 4
#
# set to 0 to disable marketdata
#
set activemarket "4"

# api url
#
# Coins-E
# https://www.coins-e.com/api/v2/markets/data/
#
# Vircurex
# https://vircurex.com/api/get_highest_bid.json
# 
# Cryptsy
# http://pubapi.cryptsy.com/api.php?method=marketdatav2
#
# Mintpal
# https://api.mintpal.com/market/stats/
#
#set marketapi "https://www.coins-e.com/api/v2/markets/data/"
#set marketapi "https://api.vircurex.com/api/get_highest_bid.json"
#set marketapi "http://pubapi.cryptsy.com/api.php?method=marketdatav2"
set marketapi "https://api.mintpal.com/market/stats/"
putlog "===>> Mining-Pool-Config - Version $scriptversion loaded"
