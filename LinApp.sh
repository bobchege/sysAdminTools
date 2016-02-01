#!/bin/bash

source lib.sh 

#################################################################################
# Name: LinhardApp.sh                                                           #
# Date: 04/01/2016                                                              #
# Author: aprils3c0nd                                                           #
# Function: This script is the main script that executes the hardening process. #
#################################################################################

FLAG=0
count=0

trap 'killall' TERM INT

killall() {
#   ----------------------------------------------------------------
#   Function for handling trap function
#   Accepts 1 argument:
#   SIGINT or SIGTERM signal
#   ----------------------------------------------------------------

if [ "$FLAG" == 1 ]; then
   trap 'echo "Ending...."; exit 0' INT TERM
   #send TERM not INT
   kill -TERM 0      
elif [ "$FLAG" == 0 ]; then
   echo "not yet done running...cannot exit"
   kill -TERM 0
fi
}

#check if separate directories are created
check_separate_partition() {
#   ----------------------------------------------------------------
#   Function for check if a separate partion exists
#   Accepts 1 argument:
#   string containing the partition name
#   ----------------------------------------------------------------

set_begin_flag

PARTITION=$1

logd "Checking if separate /$PARTITION partition exists..."

df -h | grep -i /$PARTITION

if [ $? -eq 0 ]; then 
   logd "OK. Partition exists..."
else 
   logd "Failed. Partition does not exist..."
   echo "Would you like to create a new partition automatically or manually?\
        Partitions created will be logical of size 1G.If automaticall press\
        [Y].If Manually press [N]..."
   read choice
   
   if [ $choice == 'Y' ] || [ $choice == 'y' ];then
       logd "Creating separate /$PARTITION partition..."
       create_separate_partition $PARTITION
   elif [ $choice == 'N' ] || [ $choice == 'n' ]; then 
       logd "Choice [N] picked"
   else 
       echo "This option is not supported. Kindly create partition manually"
   fi
fi

set_end_flag
}

create_separate_partition() {
#   ----------------------------------------------------------------
#   Function for creation of the separate partition
#   Accepts 1 argument:
#   string containing the full directory name to be created
#   ----------------------------------------------------------------

FULL_DIR=$1

if [[ "$FULL_DIR" == *\/* ]]; then
    DIR=${FULL_DIR%/*}
    PARTITION=$(diff <(fold -w1 <<< "$FULL_DIR") <(fold -w1 <<< "$DIR") |awk '/[<>]/{printf $2}'| sed 's/\///')

else 
   DIR=
   PARTITION=$FULL_DIR
fi

fdisk -l /dev/sda >  fdisk_comp_a.txt

echo "n
l

+1G
w
"|fdisk /dev/sda;

partprobe;

fdisk -l /dev/sda > fdisk_comp_b.txt

dev_no=$(diff fdisk_comp_a.txt fdisk_comp_b.txt | grep -i sda | awk -F\
 "/" '{print $3}'| cut -c4-5);

if [ -z "$dev_no" ]; then 
 logd " Some error occured...Most likely cylinders were used up!"
 exit 1
fi 


sleep 5
mkfs.ext3 /dev/sda$dev_no

cd /$DIR

mkdir $PARTITION
logd "making the partition /$PARTITION"

mount /dev/sda$dev_no /$FULL_DIR

# Delete the comparison files
rm $DIR/fdisk_comp_{a,b}.txt

#check if the directory has been created successfully
#check_separate_partition $PARTITION
}

checking_dir_security() {
#   ----------------------------------------------------------------
#   Function for checking security setup for various directory
#   Accepts 2 arguments:
#   string containing partition name
#   string of the fstab file location
#   ----------------------------------------------------------------

set_begin_flag

PARTITION=$1
FSTAB_FILE=/etc/fstab

check_file_exists $FSTAB_FILE

if [ $file_exists == 'false'  ];then 
    logd "file does not exist"
else
    # change this to daemon file not test file
    tmp_line=$(cat $FSTAB_FILE  |grep -i $PARTITION)

    conf_line=$(echo $tmp_line |grep -i noexec |grep -E 'nodev.*nosuid|nosuid.*nodev')

    if [ $? == 0 ]; then
        logd "Ok. The configuration is completed..."
    else
        logd "Failed.Updating the /etc/fstab file..."

        #cp $FSTAB_FILE  $FSTAB_FILE.bak.$PID
        col_drive=$(echo $tmp_line | awk '{print $1}')

        # Update the file
        sed -i -e "s|^$col_drive .*$|$col_drive            \/tmp                 ext3       acl,user_xattr,nodev,nosuid,noexec        1 2|g" $FSTAB_FILE

       logd "The $FSTAB_FILE configuration file has been updated..."
   fi
fi     

set_end_flag
}

# include export here
set_begin_flag() {
#   ----------------------------------------------------------------
#   Function for stop TERM signal from being completed
#   Accepts 0 argument:
#   ----------------------------------------------------------------

FLAG=0
}

set_end_flag() {
#   ----------------------------------------------------------------
#   Function for TERM signal from being completed
#   Accepts 0 argument:
#   ----------------------------------------------------------------

FLAG=1
}

disable_automount() {
#   ----------------------------------------------------------------
#   Function for disabling automount of partition
#   Accepts 1 argument:
#   string containing command to be executed
#   ----------------------------------------------------------------

exec_generic_cmd 'chkconfig autofs off' 
}

set_sticky_bit() {
set_begin_flag

logd "Setting the sticky bit..."
df --local -P | awk {'if (NR!=1) print $6'} | xargs -I '{}' find '{}' -xdev -type d -perm -0002 2>&1 1>/dev/null | chmod a+t
set_end_flag
}

check_file_exists() {
FILE=$1
    
if [ -f $FILE ];then
    echo "File $FILE exists..."
    file_exists=true
else
    echo "File $FILE does not exist..."
    file_exists=false
fi   
}

#update configs
update_configs() {
#   ----------------------------------------------------------------
#   Function for update of the configurations
#   Accepts 4 arguments:
#   string containing file name
#   string containing the config name
#   string containing the delimiter character
#   string containing the required value
#   ----------------------------------------------------------------

FILE=$1
CONFIG=$2
DELIMITER=$3
E_VAL=$4

set_begin_flag
check_file_exists  $FILE

if [ $file_exists == true ]; then
    #check if config exists
    replace_config $FILE "$CONFIG" $E_VAL $DELIMITER
    logd "The config $FILE has been updated..."

elif [ $file_exists == false ]; then
    logd "The config file $FILE does not exist..."
fi
   
set_end_flag
}

check_os_configs() {
#   ----------------------------------------------------------------
#   Function for checking various OS configurations
#   Accepts 3 arguments:
#   string containing module name 
#   string containing the state of the module(ON/OFF)
#   string containing the run level
#   ----------------------------------------------------------------

MODULE=$1
STATE=$2
LEVEL=$3

set_end_flag
module_conf=$(chkconfig --list | grep -i $MODULE)
 
if [ -z "$module_conf" ]; then
    logd "The Module $MODULE does not exist..."
else 
    logd "The Module $MODULE exists..."

    # For xinetd based services
    xinetd_count=$(echo $module_conf |  awk -F : 'NR==1 {print NF "\t" $0}' |\
               awk '{print $1}')

    if [ $xinetd_count == '2' ];then
        # check if we can use execute generic command here  
        exec_generic_cmd 'chkconfig $MODULE $STATE'
    else 
        # set at specific lever
        chkconfig --level $LEVEL $MODULE $2

    fi
fi  
set_end_flag
}   

exec_generic_cmd() {
#   ----------------------------------------------------------------
#   Function for execution of generic commands
#   Accepts 1 argument:
#   string containing command to be executed
#   ----------------------------------------------------------------

set_begin_flag

cmd=$1

logd "Executing the command..."
eval "$cmd"

case $? in
    0)
      #logd "-c was triggered, Parameter: $OPTARG" >&2
      logd "SUCCESS:The task was successfully performed..."
      ;;
    1)
      logd "ERROR: Catchall for general errors"
    ;;
    2)
      logd "ERROR: Misuse of shell builtins"
    ;;
    126)
      logd "ERROR: Command invoked cannot execute"
    ;;
    127)
      logd "ERROR: Command not found" 
    ;;
    128)
      logd "ERROR: Invalid argument to exit" 
    ;;
    130)
      logd "ERROR: Script terminated by Control-C"
    ;;
    255)
      logd "ERROR: Exit status out of range"
    ;;
    :)
      logd "ERROR Occured..." 
      ;;
esac

set_end_flag
}

check_perm_homedir() {
#   ----------------------------------------------------------------
#   Function for checking the home directories
#   Accepts 0 argument:
#   ----------------------------------------------------------------

for dir in `/bin/cat /etc/passwd | /bin/egrep -v '(root|halt|sync|shutdown)' |\ 
                /bin/awk -F: '($7 != "/sbin/nologin") { print $6 }'`; do
    dirperm=`/bin/ls -ld $dir | /usr/bin/cut -f1 -d" "` 
    if [ `echo $dirperm | /usr/bin/cut -c6 ` != "-" ]; then 
        echo "Group Write permission set on directory $dir" 
    fi 

    if [ `echo $dirperm | /usr/bin/cut -c8 ` != "-" ]; then 
        echo "Other Read permission set on directory $dir" 
    fi 

    if [ `echo $dirperm | /usr/bin/cut -c9 ` != "-" ]; then 
        echo "Other Write permission set on directory $dir" 
    fi 

    if [ `echo $dirperm | /usr/bin/cut -c10 ` != "-" ]; then 
        echo "Other Execute permission set on directory $dir" 
    fi 
done
}

check_dot_file_perm() {
#   ----------------------------------------------------------------
#   Function for checking dot file permissions
#   Accepts 0 argument:
#   ----------------------------------------------------------------

for dir in `/bin/cat /etc/passwd | /bin/egrep -v '(root|sync|halt|shutdown)' |
                /bin/awk -F: '($7 != ""/sbin/nologin"") { print $6 }'`; do
    for file in $dir/.[A-Za-z0-9]*; do
        if [ ! -h ""$file"" -a -f ""$file"" ]; then
            fileperm=`/bin/ls -ld $file | /usr/bin/cut -f1 -d"" ""`
            if [ `echo $fileperm | /usr/bin/cut -c6 ` != ""-"" ]; then
                echo ""Group Write permission set on file $file""
            fi
    
            if [ `echo $fileperm | /usr/bin/cut -c9 ` != ""-"" ]; then
                echo ""Other Write permission set on file $file""
            fi
       fi
   done
done
}

do_sys_access_authorization() {
#   ----------------------------------------------------------------
#   Function for running system AAA checks
#   Accepts 0 argument:
#   ----------------------------------------------------------------

ISSUE_CONF=/etc/issue.net
MOTD_CONF=/etc/motd
LOGIN_DEFS=/etc/login.defs
SU_CONF=/etc/pam.d/su
LOGIN=/etc/pam.d/login
SSHD_CONF=/etc/ssh/sshd_config

set_begin_flag

SYS_PARAM=(
    #Set User/Group Owner and Permission on /etc/crontab
    "chown root:root /etc/crontab"
    "chmod og-rwx /etc/crontab"

    #Set User/Group Owner and Permission on /etc/cron.hourly
    "chown root:root /etc/cron.hourly" 
    "chown og-rwx /etc/cron.hourly"

    #Set User/Group Owner and Permission on /etc/cron.daily
    "chown root:root /etc/cron.daily"
    "chmod og-rwx /etc/cron.daily"

    #Set User/Group Owner and Permission on /etc/cron.weekly
    "chown root:root /etc/cron.weekly"
    "chmod og-rwx /etc/cron.weekly"

    #Set User/Group Owner and Permission on /etc/cron.monthly
    "chown root:root /etc/cron.monthly"
    "chmod og-rwx /etc/cron.monthly"
  
    #Set User/Group Owner and Permission on /etc/cron.d
    "chown root:root /etc/cron.d"
    "chmod og-rwx /etc/cron.d"

    #Restrict at/cron to Authorized Users
    "/bin/rm /etc/cron.deny"
    "/bin/rm /etc/at.deny"
    "touch /etc/cron.allow"
    "touch /etc/at.allow"
    "chmod og-rwx /etc/cron.allow"
    "chmod og-rwx /etc/at.allow"
    "chown root:root /etc/cron.allow"
    "chown root:root /etc/at.allow"
    
    #Set Permissions on /etc/ssh/sshd_config
    "chown root:root /etc/ssh/sshd_config"
    "chmod 600 /etc/ssh/sshd_config"

    #Ensure Password Fields are Not Empty
    #@TODO get the username list
    #"/usr"/bin/passwd -l #<username>"

    #Verify No UID 0 Accounts Exist Other Than root
    "/bin/cat /etc/passwd | /bin/awk -F: '($3 == 0) { print $1 }' root"

    #Verify Permissions on /etc/passwd
    "/bin/chmod 644 /etc/passwd"

    #Verify Permissions on /etc/shadow
    "/bin/chmod o-rwx,g-rw /etc/shadow"

    #Verify Permissions on /etc/group
    "/bin/chmod 644 /etc/group"

    #Verify User/Group Ownership on /etc/passwd
    "/bin/chown root:root /etc/passwd"

    #Verify User/Group Ownership on /etc/shadow
    "/bin/chown root:shadow /etc/shadow"

    #Verify User/Group Ownership on /etc/group
    "/bin/chown root:root /etc/group"

    #Set Default Group for root Account
    "usermod -g 0 root"

    #Set Default umask for Users
    "pam-config -a --umask --umask-umask=0077"

    #lock inactive users
    "useradd -D -f 35"

    #Set Password Expiring Warning Days
    "update_configs /etc/login.defs PASS_WARN_AGE 14"
    #@TODO Get the user list
    #"chage --warndays 7 #<user>"

    #Set Password Change Minimum Number of Days
    "update_configs /etc/login.defs PASS_MIN_DAYS 7"
    #@TODO Get the user list
    #"chage --mindays 7 #<user>"

    #Set Password Expiration Days
    #@TODO get the userlist for this section
    "update_configs /etc/login.defs PASS_MAX_DAYS 90"
    #@TODO Get the user list
    #"chage --maxdays 90 #<user>"

    #Limit Password Reuse
    "pam-config -a --pwhistory --pwhistory-remember=12"
)

SYS_PARAMS=(
    #Set User/Group Owner and Permission on /etc/crontab
    "chown root:root /etc/crontab"
    "chmod og-rwx /etc/crontab"
)

# To change all the sysconfig params
for sys_param in "${SYS_PARAMS[@]}" ; do
    logd "The sys_Param is ....$sys_param"
        
    exec_generic_cmd "$sys_param"
done

#Set SSH Protocol to 2
update_configs $SSHD_CONF Protocol 2
   
#Set LogLevel to INFO
update_configs $SSHD_CONF  LogLevel INFO

#Disable SSH X11 Forwarding
update_configs  $SSHD_CONF  X11Forwarding no

#Set SSH MaxAuthTries to 3
update_configs $SSHD_CONF MaxAuthTries 3

#Set SSH HostbasedAuthentication to No
update_configs $SSHD_CONF  HostbasedAuthentication no 

#Disable SSH Root Login
update_configs /etc/ssh/sshd_config  PermitRootLogin no

#Set SSH PermitEmptyPasswords to No
update_configs $SSHD_CONF PermitEmptyPasswords no
    
#Do Not Allow Users to Set Environment Options
update_configs $SSHD_CONF PermitUserEnvironment no

#Use Only Approved Cipher in Counter Mode
update_configs $SSHD_CONF Ciphers aes128-ctr,aes192-ctr,aes256-ctr

#Set Idle Timeout Interval for User Login
update_configs $SSHD_CONF "update_a" 
  
#Limit Access via SSH
#@TODO Obtain the Userlist
#update_configs /etc/ssh/sshd_config "update_b"

#Set SSH Banner
update_configs $SSHD_CONF Banner /etc/issue.net

#Set Password Creation Requirement Parameters Using pam_cracklib
update_configs  $SSHD_CONF "update_c"

#Set Lockout for Failed Password Attempts
update_configs $LOGIN auth required pam_tally2.so onerr=fail audit silent deny=3 unlock_time=900

#Restrict Access to the su Command
update_configs $SU_CONF auth required pam_wheel.so use_uid
    
#Set Password Expiration Days
update_configs $LOGIN_DEFS PASS_MAX_DAYS 90

#Set Password Change Minimum Number of Days
update_configs $LOGIN_DEFS PASS_MIN_DAYS 7

#Set Password Expiring Warning Days
update_configs $LOGIN_DEFS PASS_WARN_AGE 14
   
#disable system accounts
disable_sys_acc

#@TODO allow this functionality for 2 files with same content change
#Set Warning Banner for Standard Login Services
update_configs $ISSUE_CONF "$update_d"
update_configs $MOTD_CONF "$update_d"

#Find World Writable Files
#@TODO get list of all filenames
#exec_generic_cmd chmod o-w #<filename>

#Find Un-owned Files and Directories
df --local -P | awk {'if (NR!=1) print $6'} | xargs -I '{}' find '{}' -xdev -nouser -ls

#Find Un-grouped Files and Directories
df --local -P | awk {'if (NR!=1) print $6'} | xargs -I '{}' find '{}' -xdev -group -ls

#Check Permissions on User Home Directories
check_perm_homedir

#Check User Dot File Permissions
check_dot_file_perm

#Check Permissions on User .netrc Files
check_netrcfile_own

#Check User Home Directory Ownership
check_homedir_own
     
#Check for Duplicate UIDs
check_dup_uid
}

check_dup_uid() {
#   ----------------------------------------------------------------
#   Function for checking for duplicate user ID
#   Accepts 0 argument:
#   ----------------------------------------------------------------

/bin/cat /etc/passwd | /usr/bin/cut -f3 -d"":"" | /bin/sort -n | /usr/bin/uniq -c |\ 
while read x ; do
    [ -z "${x}" ] && break set - $x 
    if [ $1 -gt 1 ]; then
        users=`/bin/gawk -F: '($3 == n) { print $1 }' n=$2 \ /etc/passwd | /usr/bin/xargs`
        logd "Duplicate UID ($2): ${users}"
    fi
done
}

check_homedir_own() {
cat /etc/passwd | awk -F: '{ print $1 "" "" $3 "" "" $6 }' | while read user uid dir; do
    if [ $uid -ge 500 -a -d ""$dir"" -a $user != ""nfsnobody"" ]; then
        owner=$(stat -L -c ""%U"" ""$dir"") 
        if [ ""$owner"" != ""$user"" ]; then
            logd ""The home directory $dir of user $user is owned by $owner.""
        fi 
    fi
done
}

check_netrcfile_own() {
#   ----------------------------------------------------------------
#   Function for checking netrc file properties
#   Accepts 0 argument:
#   ----------------------------------------------------------------

for dir in `/bin/cat /etc/passwd | /bin/egrep -v '(root|sync|halt|shutdown)' |\ 
    /bin/awk -F: '($7 != ""/sbin/nologin"") { print $6 }'`; do
    for file in $dir/.netrc; do
    if [ ! -h ""$file"" -a -f ""$file"" ]; then
        fileperm=`/bin/ls -ld $file | /usr/bin/cut -f1 -d"" ""`
        if [ `echo $fileperm | /usr/bin/cut -c5 ` != ""-"" ]
        then
            logd "Group Read set on $file"
        fi
        if [ `echo $fileperm | /usr/bin/cut -c6 ` != ""-"" ]
            then
            logd "Group Write set on $file"
        fi
        if [ `echo $fileperm | /usr/bin/cut -c7 ` != ""-"" ]
        then
            logd "Group Execute set on $file"
        fi
        if [ `echo $fileperm | /usr/bin/cut -c8 ` != ""-"" ]
        then
            logd "Other Read set on $file"
        fi
        if [ `echo $fileperm | /usr/bin/cut -c9 ` != ""-"" ]
        then
            logd "Other Write set on $file"
        fi
        if [ `echo $fileperm | /usr/bin/cut -c10 ` != ""-"" ]
        then
           logd "Other Execute set on $file"
        fi
    fi
    done
done
}

disable_sys_acc() {
#   ----------------------------------------------------------------
#   Function for disabling global use of system accounts 
#   Accepts 0 argument:
#   ----------------------------------------------------------------

for user in `awk -F: '($3 < 500) {print $1 }' /etc/passwd`;do
    if [ $user != ""root"" ]
    then
        /usr/sbin/usermod -L $user
        if [ $user != ""sync"" ] && [ $user != ""shutdown"" ] && [ $user != ""halt"" ]
        then
           /usr/sbin/usermod -s /sbin/nologin $user
        fi
    fi
done
}

disable_prelink() {
#   ----------------------------------------------------------------
#   Function for enabling prelinking 
#   Accepts 0 argument:
#   ----------------------------------------------------------------

set_begin_flag

logd "invoking disable prelink function"
exec_generic_cmd '/usr/sbin/prelink -ua'
exec_generic_cmd 'zypper remove prelink' 

set_end_flag
}

replace_config() {
#   ----------------------------------------------------------------
#   Function for updating the config files parameters
#   Accepts 4 argument:
#   string containing file name
#   string containing the specific config
#   string containing the expeced value(E_VAL)
#   string specifying the delimiter value
#   ----------------------------------------------------------------

FILE=$1
VAR=$2
E_VAL=$3
DELIMITER=$4

# Check if the variable exists
tmp_line=$(cat $FILE  |grep -i "$VAR" |head -n 1)

logd "did i get here..."
#count=$(echo $tmp_line | wc -l) 

if [ ! -z "$tmp_line" ];then
    logd "The variable is set...."

    #strip the variable from output
    c_val=$(echo $tmp_line | sed -e "s/$VAR//" | awk -F " " '{print $1}')
    
    if [ $c_val == $E_VAL ];then
        logd "The current value is expected...No need to update file"
    else 
        logd "Need to reset the value to expected value..."
        sed -i -e "s|^$VAR .*$|$VAR $DELIMITER $E_VAL|g" $FILE
    fi
    #done  
else
    logd "The variable is not set"
     
    # Append it to the end of the file
    echo "#---------------------------------------------------------" >> $FILE
    echo "# This config has been automatically added by linhard app" >> $FILE
    echo "$VAR $DELIMITER $E_VAL" >> $FILE
fi
}

do_network_config() {
#   ----------------------------------------------------------------
#   Function for execution of the network config checks
#   Accepts 0 argument:
#   ----------------------------------------------------------------

SYSCTL_FILE=/etc/sysctl.conf
CIS_FILE=/etc/modprobe.d/CIS.conf

set_begin_flag

#disable ip fowarding
NETWK_PARAMS=(
    "net.ipv4.ip_forward=0"
    "net.ipv4.route.flush=1"
    "net.ipv4.conf.all.send_redirects=0"
    "net.ipv4.conf.default.send_redirects=0"
    "net.ipv4.route.flush=1"
    "net.ipv4.conf.all.log_martians=1"
    "net.ipv4.conf.default.log_martians=1"
    "net.ipv4.route.flush=1"
    "net.ipv4.icmp_echo_ignore_broadcasts=1"
    "net.ipv4.route.flush=1"
    "net.ipv4.icmp_ignore_bogus_error_responses=1"
    "net.ipv4.route.flush=1"
    "net.ipv4.tcp_syncookies=1"
    "net.ipv4.route.flush=1"
)

FILE_PARAMS=(
    "chmod 644 /etc/hosts.allow"
    "chmod 644 /etc/hosts.deny"
    "echo 'ALL: ALL' >> /etc/hosts.deny"
    "echo 'install tipc /bin/true' >> $CIS_FILE"
    "echo 'install dccp /bin/true' >> $CIS_FILE"
    "echo 'install rds /bin/true' >> $CIS_FILE"
    "echo 'install sctp /bin/true' >> $CIS_FILE"
)

NETWK_CMDS=( 
    "/sbin/sysctl -w net.ipv4.ip_forward=0"
    "/sbin/sysctl -w net.ipv4.route.flush=1"
    "/sbin/sysctl -w net.ipv4.conf.all.send_redirects=0" 
    "/sbin/sysctl -w net.ipv4.default.all.send_redirects=0" 
    "/sbin/sysctl -w net.ipv4.route.flush=1"
    "/sbin/sysctl -w net.ipv4.conf.all.log_martians=1" 
    "/sbin/sysctl -w net.ipv4.conf.default.log_martians=1"
    "/sbin/sysctl -w net.ipv4.route.flush=1"
    "/sbin/sysctl -w net.ipv4.icmp_echo_ignore_broadcasts=1" 
    "/sbin/sysctl -w net.ipv4.route.flush=1"
    "/sbin/sysctl -w net.ipv4.icmp_ignore_bogus_error_responses=1" 
    "/sbin/sysctl -w net.ipv4.route.flush=1"
    "/sbin/sysctl -w net.ipv4.tcp_syncookies=1" 
    "/sbin/sysctl -w net.ipv4.route.flush=1"
)

# To change all the network params
for key_val in "${NETWK_PARAMS[@]}" ; do
    KEY=${key_val%%=*}
    VALUE=${key_val#*=}

    logd "Updating the network params $KEY $VALUE"
    update_configs $FILE   $KEY   '='   $VALUE
done

# To execute all the network
for cmd in "${NETWK_CMDS[@]}" ; do
    logd "Executing the network commands... $cmd"
    exec_generic_cmd "$cmd"
done

# Install TCP Wrappers
tcp_wrap_cmd='zypper install tcpd'
exec_generic_cmd "$tcp_wrap_cmd"

# Edit hosts file params and CIS configuration
for file_param in "${FILE_PARAMS[@]}" ; do
    logd "Executing the network commands... $file_param"
    exec_generic_cmd "$file_param"
done

set_end_flag
}

#standardize this
disable_services() {
#lock exiting file here. Disable DCCP, SCTP, RDS, TIPC
for service in {'tipc', 'dccp', 'rds', 'sctp'}; do
    echo "install $service /bin/true" >> $CIS_FILE
done
}

do_log_audit() {
#   ----------------------------------------------------------------
#   Function for invoking the log auditing function
#   Accepts 0 argument:
#   ----------------------------------------------------------------

set_begin_flag

AUDITD_CONF=/etc/audit/auditd.conf
MENU_CONF=/boot/grub/test_menu.lst
AUDITRULE_CONF=/etc/audit/audit.rules

#Configure Audit Log Storage Size
update_configs  $AUDITD_CONF  max_log_file  =  10MB

#Keep All Auditing Information
update_configs  $AUDITD_CONF  max_log_file_action  =  keep_logs

#Enable Auditing for Processes That Start Prior to auditd
update_configs $MENU_CONF  audit = 1

#Record Events That Modify Date and Time Information
logd "The uploaded variable is $audit_a"

update_configs $AUDITRULE_CONF "$audit_a"

#Record Events That Modify User/Group Information
update_configs $AUDITRULE_CONF  "audit_b"

#Record Events That Modify the System's Network Environment
update_configs  $AUDITRULE_CONF "audit_c" 

#Collect Login and Logout Events
update_configs  $AUDITRULE_CONF "audit_d"

#Collect Discretionary Access Control Permission Modification Events
update_configs  $AUDITRULE_CONF  "audit_e" 

#Collect Unsuccessful Unauthorized Access Attempts to Files
update_configs  $AUDITRULE_CONF  "audit_f" 

#Collect Successful File System Mounts
update_configs  $AUDITRULE_CONF "audit_g"

#Collect Changes to System Administration Scope (sudoers)
update_configs  $AUDITRULE_CONF "audit_h"

#Collect System Administrator Actions (sudolog) (Scored)
update_configs  $AUDITRULE_CONF  "audit_i"

#Collect Kernel Module Loading and Unloading
update_configs  $AUDITRULE_CONF "audit_j"

#Ensure the rsyslog Service is activated
update_configs /etc/sysconfig/syslog SYSLOG_DAEMON="rsyslog"

#Create and Set Permissions on rsyslog Log Files
exec_generic_cmd "touch $FILE"
exec_generic_cmd "chown root:root $FILE"
exec_generic_cmd "chmod og-rwx $FILE"

set_end_flag
}

do_filesystem_configuration() {
PARTITIONS=("tmp" "var" "var/log" "var/log/audit" "home" "dev/shm")

#check_separate_partitions 
for partition in "${PARTITIONS[@]}" ; do
    logd "Currently processing partition $partition..."
    check_separate_partition $partition
    checking_dir_security $partition
done

# Set the sticky bit
set_sticky_bit
    
#@TODOalso can check for floppy and cdrom if avail
#@TODOwrite code for bind function

#disable mount
disable_automount
}

do_additional_process_hardening() {
set_begin_flag

#restrict core dumps
LIMITS_CONF=/etc/limits.conf
SYSCTL_CONF=/etc/sysctl.conf

update_configs $LIMITS_CONF  'hard core' '  ' 0

update_configs $SYSCTL_CONF 'fs.suid_dumpable' '=' 0 

#Enable Randomized Virtual Memory Region Placement
update_configs $SYSCTL_CONF 'kernel.randomize_va_space' '=' 2

set_end_flag

#Disable Prelink
disable_prelink
}

do_os_sys_hardening() {
#   ----------------------------------------------------------------
#   Function for invoking the system hardening calls
#   Accepts 0 argument:
#   ----------------------------------------------------------------

set_begin_flag

# Run chkconfig cmds
OS_PARAMS=(
    "ypserv:off"
    "rsh:off"
    "talk:off"
    "telnet:off"
    "tftp:off"
    "atftpd:off"
    "xinetd:off"
    "chargen-udp:off"
    "chargen:off"
    "daytime-udp:off"
    "daytime:off"
    "echo-udp:off"
    "echo:off"
    "discard-udp:off"
    "discard:off"
    "time-udp:off"
    "time:off"
    "avahi-daemon:off"
    "cups:off"
    "dhcpd:off"
    "nfs:off"
    "named:off"
    "vsftpd:off"
    "apache2:off"
    "cyrus:off"
    "smb:off"
    "squid:off"
    "snmpd:off"
    "rsyncd:off"
    )

    for key_val in "${OS_PARAMS[@]}" ; do
        logd "The key_val is...  $key_val"
        KEY=${key_val%%:*}
        VALUE=${key_val#*:}

        logd "the key value is $KEY  .... $VALUE"
        check_os_configs $KEY $VALUE
    done

set_end_flag
}


## Main method
do_filesystem_configuration
do_additional_process_hardening
do_os_sys_hardening
do_network_config
do_log_audit
do_sys_access_authorization


DIR=$PWD
logd "Processing completed...Now exiting..."
ls -al $DIR/LinManager.sh
cd $DIR
./LinManager.sh stop
