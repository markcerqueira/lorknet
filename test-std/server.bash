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
# name: server.sh
# desc: this program runs a non-parent server on a machine, making it run a 
# server that multicasts and unicasts at varying rates
#
# to run (in command line python):
#     %> ./server.sh num_clients
#
# NOTE: this server will not send any packets unless a parent is running
#------------------------------------------------------------------------------


# script needs to be passed number of clients for unicasting
if [ $# -ne 1 ];
then
    echo "server.sh: usage: server_script num_clients"
	echo "num_clients = number of computers currently connected to the network"
    exit 65
fi

# multicast tests
chuck server.ck:0:500:50:1
sleep 1

chuck server.ck:0:500:100:1
sleep 1

chuck server.ck:0:500:200:1
sleep 1

chuck server.ck:0:200:400:1
sleep 1

chuck server.ck:0:200:800:1
sleep 1

chuck server.ck:0:100:1600:1
sleep 1

# unicast tests
chuck server.ck:1:500:50:1:$1
sleep 1

chuck server.ck:1:500:100:1:$1
sleep 1

chuck server.ck:1:500:200:1:$1
sleep 1

chuck server.ck:1:200:400:1:$1
sleep 1

chuck server.ck:1:200:800:1:$1
sleep 1

chuck server.ck:1:100:1600:1:$1

