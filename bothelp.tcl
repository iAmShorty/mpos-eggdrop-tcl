#
# Output Commands to the users
#
#
#

bind pub - !help printUsage

# print bot usage info
#

proc printUsage {nick host hand chan arg} {
	putquick "NOTICE $nick :Usage:"
    putquick "NOTICE $nick :       !adduser <ircnick> <mposuser> <password> - Adding User to userfile"
    putquick "NOTICE $nick :       !deluser <ircnick> <mposuser> <password> - Deleting User from userfile"
    putquick "NOTICE $nick :       !block                                   - Blockstats"
    putquick "NOTICE $nick :       !pool                                    - Pool Information"
    putquick "NOTICE $nick :       !round                                   - Round Information"
    putquick "NOTICE $nick :       !last                                    - Last found Block"
    putquick "NOTICE $nick :       !user <user>                             - User Information"
    putquick "NOTICE $nick :       !worker <user>                           - User Workers"
    putquick "NOTICE $nick :       !balance <user>                          - User Wallet Balance"
    putquick "NOTICE $nick :       !price                                   - Get actual Coinprice"
    putquick "NOTICE $nick :       !help                                    - This help text"
}

