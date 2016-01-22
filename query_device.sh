#!/usr/bin/expect

##########################################################
# Author: aprils3c0nd                                    #
# Date: 15/09/2015                                       #
# Use: This script is used to log into the S6900 Storage #
# device and get the bbu statistics. It can be used to   #
# push any command to the storage S6900 or S9000         #
##########################################################

set prompt "(%|#|>|\\$) $"
set ip <set ip here>
set user <set user here>
set password <set password here>


spawn ssh "$user\@$ip"
expect ""
expect "assword:"
send "$password\r";
expect -re $prompt
send -- "showbbu -a\r"
expect -ex "--More--" {send -- " "; exp_continue }
expect -re $prompt
send -- "exit\r"
