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
# name: parent.sh
# desc: this program runs a parent server on a machine, making it run a 
# server that multicasts and unicasts at varying rates
#
# to run (in command line python):
#     %> ./parent.sh num_PLORKtops
#
# NOTE: while you may have many instances of server.sh running consecutively,
# there should ONLY BE ONE parent.sh script running at any one time
#------------------------------------------------------------------------------

# script needs to be passed number of clients for unicast script
if [ $# -ne 1 ];
then
    echo "Usage: master_script num_PLOrktops"
    exit 65
fi

say -v Cellos I am Dan Trueman and will be testing your networks extensively and exhaustively

# multicast tests
chuck server.ck:0:500:50:0
sleep 10

chuck server.ck:0:500:100:0
sleep 10

chuck server.ck:0:500:200:0
sleep 10

chuck server.ck:0:200:400:0
sleep 10

chuck server.ck:0:200:800:0
sleep 10

chuck server.ck:0:100:1600:0
sleep 10

# unicast tests
chuck server.ck:1:500:50:0:$1
sleep 10

chuck server.ck:1:500:100:0:$1
sleep 10

chuck server.ck:1:500:200:0:$1
sleep 10

chuck server.ck:1:200:400:0:$1
sleep 10

chuck server.ck:1:200:800:0:$1
sleep 10

chuck server.ck:1:100:1600:0:$1
sleep 1

say Testing completed. Yeah baby!