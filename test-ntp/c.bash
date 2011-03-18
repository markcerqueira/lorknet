#!/bin/bash

#------------------------------------------------------------------------------
#  LOrkNetLib - Laptop Orchestra Network Library Toolkit
#
#  Copyright (c) 2010 Mark Cerqueira and Dan Trueman.  All rights reserved.
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307
#  U.S.A.
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# name: client.sh
# desc: this program runs client programs to listen for, receive, and log
# packets received sent from servers
#
# to run (in command line python):
#     %> ./client.sh num_LOrktops num_servers
#
# NOTE: run client.sh with server.sh and parent.sh scripts
#------------------------------------------------------------------------------

# script needs to be passed the number of LOrktops running the scripts and 
# number of servers running scripts
if [ $# -ne 2 ];
then
    echo "Usage: clientsh num_LOrktops num_servers"
    exit 65
fi

# update this array to include the NET_NAME of all PLOrktops you are going
# to be using in order - to make your life easier just use the build.py script!

machines=(sing shout shovel pow ooze)

# create a directory to save all our output
filename=$(date +%d).$(date +%H).$(date +%M).${NET_NAME}
mkdir $filename

# saves some information about the wireless connection
/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport -I > $filename/${NET_NAME}.connection_info.txt

echo "Saving test results to directory:" $filename

# run multicast/unicast tests
echo ""
echo "Starting multicast tests"

echo -ne "Testing..."
chuck --caution-to-the-wind c.ck 2> $filename/${NET_NAME}_RAW.txt
echo "done!"
sleep 1

# stream edit out some trash from the data files
sed  -i  ''  -e  's/:(float)//'  -e  '/^.chuck --caution-to-the-wind --blocking --bufsize=64/d'  $filename/*
sed -i '' '/^$/d' $filename/*

# grep out individual machine data into separate files
cp interval2.py $filename/
cd $filename/

grep 0:50 ${NET_NAME}_RAW.txt > ${NET_NAME}_M_50.txt
grep 0:100 ${NET_NAME}_RAW.txt > ${NET_NAME}_M_100.txt
grep 0:200 ${NET_NAME}_RAW.txt > ${NET_NAME}_M_200.txt
grep 0:400 ${NET_NAME}_RAW.txt > ${NET_NAME}_M_400.txt
grep 0:800 ${NET_NAME}_RAW.txt > ${NET_NAME}_M_800.txt
grep 0:1600 ${NET_NAME}_RAW.txt > ${NET_NAME}_M_1600.txt

grep 1:50 ${NET_NAME}_RAW.txt > ${NET_NAME}_U_50.txt
grep 1:100 ${NET_NAME}_RAW.txt > ${NET_NAME}_U_100.txt
grep 1:200 ${NET_NAME}_RAW.txt > ${NET_NAME}_U_200.txt
grep 1:400 ${NET_NAME}_RAW.txt > ${NET_NAME}_U_400.txt
grep 1:800 ${NET_NAME}_RAW.txt > ${NET_NAME}_U_800.txt
grep 1:1600 ${NET_NAME}_RAW.txt > ${NET_NAME}_U_1600.txt

full=$(/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport -I | grep ' SSID')

for (( i = 0; i < $2; i++))
do
    grep ${machines[$i]} ${NET_NAME}_M_50.txt >  ${NET_NAME}.${machines[$i]}_M_50.txt
    grep ${machines[$i]} ${NET_NAME}_M_100.txt >  ${NET_NAME}.${machines[$i]}_M_100.txt
    grep ${machines[$i]} ${NET_NAME}_M_200.txt >  ${NET_NAME}.${machines[$i]}_M_200.txt
    grep ${machines[$i]} ${NET_NAME}_M_400.txt >  ${NET_NAME}.${machines[$i]}_M_400.txt
    grep ${machines[$i]} ${NET_NAME}_M_800.txt >  ${NET_NAME}.${machines[$i]}_M_800.txt
    grep ${machines[$i]} ${NET_NAME}_M_1600.txt >  ${NET_NAME}.${machines[$i]}_M_1600.txt

    grep ${machines[$i]} ${NET_NAME}_U_50.txt >  ${NET_NAME}.${machines[$i]}_U_50.txt
    grep ${machines[$i]} ${NET_NAME}_U_100.txt >  ${NET_NAME}.${machines[$i]}_U_100.txt
    grep ${machines[$i]} ${NET_NAME}_U_200.txt >  ${NET_NAME}.${machines[$i]}_U_200.txt
    grep ${machines[$i]} ${NET_NAME}_U_400.txt >  ${NET_NAME}.${machines[$i]}_U_400.txt
    grep ${machines[$i]} ${NET_NAME}_U_800.txt >  ${NET_NAME}.${machines[$i]}_U_800.txt
    grep ${machines[$i]} ${NET_NAME}_U_1600.txt >  ${NET_NAME}.${machines[$i]}_U_1600.txt

    python interval2.py ${machines[$i]} 50 ${full:17} $1 $2
    python interval2.py ${machines[$i]} 100 ${full:17} $1 $2
    python interval2.py ${machines[$i]} 200 ${full:17} $1 $2
    python interval2.py ${machines[$i]} 400 ${full:17} $1 $2
    python interval2.py ${machines[$i]} 800 ${full:17} $1 $2
    python interval2.py ${machines[$i]} 1600 ${full:17} $1 $2
done

rm -f interval2.py
cd ..

echo "client.sh: done!"
