#!/usr/bin/bash

##########################################################
# Author: aprils3c0nd                                    #
# Date: 15/09/2015                                       #
# Use: This script is used to parse the log files for    #
# power for the S6900 from query device                  #
##########################################################

SRC=output.txt
LOG=log.txt

parse_file (){
echo "ControllerID,BBUID,Voltage" >> $LOG
    while read line; do
    CONT=
    BBU=
    CURR=
            #echo $line
            if [[ $line == *"Controller ID"* ]]
                then
                    CONT=$(echo $line | awk -F '|' '{print $2}')
                    echo -n "$CONT" | sed 's/\^M//g'>> $LOG
            fi
            if [[ $line == *"BBU ID"* ]]
                then
                    BBU=$(echo $line | awk -F "|" '{print $2}')
                    echo -n ,$BBU | sed 's/\^M//g' >> $LOG
            fi
            if [[ $line == *"Current Voltage"* ]]
                then
                    CURR=$(echo $line | awk -F "|" '{print $2}')
                    echo ,$CURR | sed 's/\^M//g' >> $LOG
            fi
     done < $1

dos2unix $LOG
}

process_output (){
now=$(date +"%T")
echo "==============BEGIN============" >> $LOG
echo "Current time is $now" >> $LOG
expect query_device.sh > $SRC
parse_file $SRC
#echo "" > $SRC
echo "==============END==============" >> $LOG
}

while true; do
   process_output
   sleep 5
done
