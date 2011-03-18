/*----------------------------------------------------------------------------
  LOrkNetLib - Laptop Orchestra Network Library Toolkit

  Copyright (c) 2010 Mark Cerqueira and Dan Trueman.  All rights reserved.

  This program is free software; you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation; either version 2 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program; if not, write to the Free Software
  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307
  U.S.A.
-----------------------------------------------------------------------------*/

//-----------------------------------------------------------------------------
// name: server.ck
// desc: this program sends packets via OSC using either multicast or opening
// a direct socket to each client. The number of packets, the rate at which
// packets are sent, and the mode to send packets in are specified when the
// program is called. 
//
// to run (in command line chuck):
//     %> chuck server.ck:MODE:NUM_PACKETS:RATE:RANK:NUM_CLIENTS
//     MODE: 0 for multicast, 1 for unicast
//     NUM_PACKETS: packets to send
//     RATE: send a packet every x ms
//     RANK: 0 for parent, 1 for regular server - you need one parent
//     NUM_CLIENTS: for unicasting mode, number of clients to open sockets to
//-----------------------------------------------------------------------------

// EDIT - edit this array to match the sharing/NET_NAME of your test setup
