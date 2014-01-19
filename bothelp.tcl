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
    putquick "NOTICE $nick :       !block COINNAME                          - Blockstats"
    putquick "NOTICE $nick :       !pool COINNAME                           - Pool Information"
    putquick "NOTICE $nick :       !round COINNAME                          - Round Information"
    putquick "NOTICE $nick :       !last COINNAME                           - Last found Block"
    putquick "NOTICE $nick :       !user COINNAME <user>                    - User Information"
    putquick "NOTICE $nick :       !worker COINNAME <user>                  - User Workers"
    putquick "NOTICE $nick :       !balance COINNAME <user>                 - User Wallet Balance"
    putquick "NOTICE $nick :       !price                                   - Get actual Coinprice"
    putquick "NOTICE $nick :       !help                                    - This help text"
}

putlog "===>> Mining-Pool-Bothelp - Version $scriptversion loaded"