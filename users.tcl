#
# MPOS eggdrop users
#
#
# some functions ONLY work with admin api key
# -> getting worker from specified user
# -> getting userinfo from specified user
#
set scriptversion "v0.1"

# time to wait before next command in seconds
#
set help_blocktime "5"

# debug mode
# set to 1 to display debug messages
#
set debug "1"

# debug output
# set to 1 to display json output
# beware, lots of data
#
set debugoutput "0"

# script path
# 
# path where poolstats.tcl is located
#
# if your script is installed in /usr/src/eggdrop/scripts/mininginfo/users.tcl
# scriptpath is "./scripts/mininginfo/"
# 
set registereduserfile "./scripts/mininginfo/"

# file to save last blocks
#
set registereduserfile "mposuser"




######################################################################
##########           nothing to edit below this line        ##########
######################################################################

# key bindings
#
bind pub - !adduser user_add
bind pub - !deluser user_del












