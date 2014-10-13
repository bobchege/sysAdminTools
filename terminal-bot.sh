#!/usr/bin/expect

set timeout 2

spawn ssh bchege@zion.cellulant.com -p38000
expect "Password:"
send "bob12chege\r"
expect "~]$"
send " ll\r"
expect "~]$"
send "exit\r"
exit
