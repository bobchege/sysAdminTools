#!/bin/sh

#################################################################################
# Name: LinhardManager.sh                                                       #
# Date: 24/12/2015                                                              #
# Author: aprils3c0nd                                                           #
# Function: This script is the manager process for the linux hardeniing script. #
#################################################################################
# Import the library file
source lib.sh 

DIR=$PWD
DAEMON=$DIR/LinhardApp.sh
DAEMON_NAME=linhard

# Add any command line options for your daemon here
DAEMON_OPTS=""

DAEMON_USER=root

# The process ID of the script when it runs is stored here:
PIDFILE=/var/run/$DAEMON_NAME.pid
LOG_DIR=$PWD
LOGFILE=$LOG_DIR/linhard.log


. /lib/lsb/init-functions

get_proc_status() {
#   ----------------------------------------------------------------
#   Function for checking the  process status
#   Accepts 0 argument:
#   ----------------------------------------------------------------

   #status=$(ls -al /var/run/$DAEMON_NAME.pid)
   
   if [ -f /var/run/$DAEMON_NAME.pid ]; then
      logd "Linhard application is running"
   else
      logd "Linhard application is not running"
   fi 
} 

do_start () {
#   ----------------------------------------------------------------
#   Function to start the LinhardApp.sh script
#   Accepts 0 argument:
#   ----------------------------------------------------------------

    if [ -f $PIDFILE ];then
        logd "PIDFILE Exists. Linhard application running"
    else
        logd "Starting system $DAEMON_NAME daemon"
        touch $PIDFILE
        start-stop-daemon --start --pidfile $PIDFILE  --user $DAEMON_USER  --exec\
            $DAEMON -- $DAEMON_OPTS
        logd $?
    fi
}

do_stop() {
#   ----------------------------------------------------------------
#   Function for stopping the LinhardApp.sh script
#   Accepts 0 argument:
#   ----------------------------------------------------------------

    # check if stopped first
    logd "TERM signal invoked. Stopping $DAEMON_NAME..."
    PID=$(ps fax | grep -i '/bin/bash /home/ops/test/test2.sh'  | grep -v grep | awk\
        '{print $1}')
    
    if [ -z $PID ];then
        logd "Linhard application is not running"
      
        # Check if the log file exists
        rm /var/run/$DAEMON_NAME.pid || logd "Deleting the pid file"
    else
        kill -TERM $PID #`cat $PIDFILE`
        rm $PIDFILE
        logd "$DAEMON_NAME."
    fi
}

case "$1" in

    start|stop)
        do_${1}
        ;;
    restart|reload|force-reload)
        do_stop
        do_start
        ;;
    status)
        #get_proc_status "$DAEMON_NAME" "$DAEMON" && exit 0 || exit $?
        get_proc_status
        ;;
    *)
        echo "Usage: /etc/init.d/$DAEMON_NAME {start|stop|restart|status}"
        exit 1
        ;;
esac
exit 0
