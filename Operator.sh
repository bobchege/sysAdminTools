#!/usr/bin/expect

###########################################################
# Author: aprils3c0nd                                     #
# Date: 02/02/2016                                        #
# Use: This script is used to log a server and manage     # 
# log files. It could as well be adapted to run any cmd   # 
# To use this script create a file with list of ips and   #
# invoke this script with a for loop on the list of IPs   #
###########################################################

set prompt "(%|#|>|\\$) $"
set user bmuuser
set password "******"
set root_password "******"

#for line in $(cat ip.txt); do echo $line; done
#exit
set ip [lindex $argv 0];

spawn ssh "$user\@$ip"
expect ""
expect "(yes/no)?"
#send -- "yes"
#expect ""
#expect "assword:"
send "$password\r";
expect -re $prompt
send -- "su - root\r"
expect "assword:"
send "$root_password\r";
#expect -re $prompt
#send -- "cd /var/log/atop\r"
send -- "ls -al /var/log/atop\r"
send -- "find /var/log/atop* -mtime +2 -delete;\r"
send -- "ls -al  /var/log/atop\r"
#expect -ex "--More--" {send -- " "; exp_continue }
expect -re $prompt
send -- "exit\r"
