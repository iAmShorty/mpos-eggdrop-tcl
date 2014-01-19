#
# Config File for eggdrop scripts
#
#
# some functions ONLY work with admin api key
# -> getting worker from specified user
# -> getting userinfo from specified user
#

##################################################################
# General Config
##################################################################

set scriptversion "v0.8"

# time to wait before next command in seconds
#
set help_blocktime "5"

# debug mode
# set to 1 to display debug messages in partyline and logfile
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
#
set channels "#channel1 #channel2"


##################################################################
# MPOS Config
##################################################################

# Setting URLs and API Keys for multiple Pools
# you can add as many as you want
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

# file to save last blocks
#
set lastblockfile "lastblock"

# file to save users
#
set registereduserfile "mposuser"

# confirmations before a block will be advertised
#
set confirmations "10"

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
# https://vircurex.com/api/get_highest_bid.json?base=NMC&alt=BTC
# 
# Cryptsy
# http://pubapi.cryptsy.com/api.php?method=singlemarketdata&marketid=
#
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
set marketid "3"





