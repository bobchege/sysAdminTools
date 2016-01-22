#!/bin/bash

#################################################################################
# Name: Lib.sh                                                                  #
# Date: 04/01/2016                                                              #
# Author: aprils3c0nd                                                           #
# Function: This script contains the import variables and utility functions.    #
#################################################################################

LOG_FILE=$PWD/mgr_log.txt

# The logging function
logd() {
#   ----------------------------------------------------------------
#   Function for logging 
#   Accepts 1 argument: 
#   string containing output to be logged
#   ----------------------------------------------------------------

LOGTIME=`date "+%Y-%m-%d %H:%M:%S"`

# If log file is not defined, just echo the output
if [ "$LOG_FILE" == "" ]; then
    echo $LOGTIME": $1";
else
    LOG=$LOG_FILE.`date +%Y%m%d`
    touch $LOG
    if [ ! -f $LOG ]; then
       echo "ERROR!! Cannot create log file $LOG. Exiting.";
       exit 1;
    fi
       echo $LOGTIME": $1" | tee -a $LOG;
fi
}

audit_a="-a always,exit -F arch=b64 -S adjtimex -S set\
timeofday -k time-change
-a always,exit -F arch=b32 -S adjtimex -S settimeofday -S stime -k time-change
-a always,exit -F arch=b64 -S clock_settime -k time-change
-a always,exit -F arch=b32 -S clock_settime -k time-change
-w /etc/localtime -p wa -k time-change"

audit_b="-w /etc/group -p wa -k identity
-w /etc/passwd -p wa -k identity
-w /etc/gshadow -p wa -k identity
-w /etc/shadow -p wa -k identity
-w /etc/security/opasswd -p wa -k identity"

audit_c="-a exit,always -F arch=b64 -S sethostname -S setdomainname -k system-locale
-a exit,always -F arch=b32 -S sethostname -S setdomainname -k system-locale
-w /etc/issue -p wa -k system-locale
-w /etc/issue.net -p wa -k system-locale
-w /etc/hosts -p wa -k system-locale
-w /etc/sysconfig/network -p wa -k system-locale"

audit_d="-w /var/log/faillog -p wa -k logins
-w /var/log/lastlog -p wa -k logins
-w /var/log/tallylog -p -wa -k logins"

audit_e="-a always,exit -F arch=b64 -S chmod -S fchmod -S fchmodat -F auid>=500  -F auid!=4294967295 -k perm_mod
-a always,exit -F arch=b32 -S chmod -S fchmod -S fchmodat -F auid>=500  -F auid!=4294967295 -k perm_mod
-a always,exit -F arch=b64 -S chown -S fchown -S fchownat -S lchown -F auid>=500  -F auid!=4294967295 -k perm_mod
-a always,exit -F arch=b32 -S chown -S fchown -S fchownat -S lchown -F auid>=500  -F auid!=4294967295 -k perm_mod
-a always,exit -F arch=b64 -S setxattr -S lsetxattr -S fsetxattr -S removexattr -S  lremovexattr -S fremovexattr -F auid>=500 -F auid!=4294967295 -k perm_mod
-a always,exit -F arch=b32 -S setxattr -S lsetxattr -S fsetxattr -S removexattr -S lremovexattr -S fremovexattr -F auid>=500 -F auid!=4294967295 -k perm_mod"

audit_f="-a always,exit -F arch=b64 -S creat -S open -S openat -S truncate -S ftruncate -F exit=-EACCES -F auid>=500 -F auid!=4294967295 -k access
-a always,exit -F arch=b32 -S creat -S open -S openat -S truncate -S ftruncate  -F exit=-EACCES -F auid>=500 -F auid!=4294967295 -k access
-a always,exit -F arch=b64 -S creat -S open -S openat -S truncate -S ftruncate  -F exit=-EPERM -F auid>=500 -F auid!=4294967295 -k access
-a always,exit -F arch=b32 -S creat -S open -S openat -S truncate -S ftruncate  -F exit=-EPERM -F auid>=500 -F auid!=4294967295 -k access"

audit_g="-a always,exit -F arch=b64 -S mount -F auid>=500 -F auid!=4294967295 -k mounts
-a always,exit -F arch=b32 -S mount -F auid>=500 -F auid!=4294967295 -k mounts"

audit_h="-w /etc/sudoers -p wa -k scope"

audit_i="-w /var/log/sudo.log -p wa -k actions"

audit_j="-w /sbin/insmod -p x -k modules
-w /sbin/rmmod -p x -k modules
-w /sbin/modprobe -p x -k modules
-a always,exit arch=b64 -S init_module -S delete_module -k modules"

update_a="ClientAliveInterval 600
    ClientAliveCountMax 0"

#@TODO Get this userlist
update_b="AllowUsers <userlist>
          AllowGroups <grouplist>
          DenyUsers <userlist>
          DenyGroups <grouplist>"

update_c="pam-config -a --cracklib --cracklib-retry=3 --cracklib-minlen=8 --cracklib-dcredit=-1 --cracklib-ucredit=-1 --crac\
klib-ocredit=-1 --cracklib-lcredit=-1"

update_d="*****************************************WARNING************************************
This system is for the use of authorized users only. Any or all uses of this system and all files on this system may be intercepted, monitored, recorded, copied, audited, inspected, and disclosed to authorized organizational and law enforcement personnel.
Your access is strictly limited to applicable services of the system for which you have obtained written authorization, and will be governed by <Company>'s Corporate Security Policy & Acceptable Usage Standard.

Unauthorized or improper use of this system is strictly prohibited and may result in administrative disciplinary action and/or civil charges/criminal penalties. By continuing to use this system you indicate your awareness of and consent to these terms and conditions of use.
LOG OFF IMMEDIATELY if you do not agree to the conditions stated in this warning.
********************************************WARNING*****************************"
