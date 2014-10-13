#!/bin/bash

# This script changes file in format below
###########################################
# |heading1 heading2 | heading3 | heading4|
# | data1 | data2 | data3 | data4| data5|
##########################################
# To the following structure
##########################################
# | heading1
# | heading2
# |-
# | data1
# | data2
#########################################

 cat format.txt| sed 's/|/\n|/g' > format2.txt  | cat format2.txt | sed 's/^\s*$/|-/g'
