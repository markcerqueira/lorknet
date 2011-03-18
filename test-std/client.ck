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
// name: client.ck
// desc: this program receives packets sent by server.ck and logs the computer
// the packet came from, the VM time the packet was received at, and the time
// since the last packet was received from that particular machine
//
// to run (in command line chuck):
//     %> chuck server.ck:RATE
//     RATE: expecting a packet every x ms
//-----------------------------------------------------------------------------

0 => int rate;

// Step UGen to play impulses
Step step => dac.chan(1);
10::samp => dur spike_len;

// create our OSC receiver
OscRecv recv;
9001 => recv.port;
recv.listen();
recv.event( "/lorknet/interval, i i s i" ) @=> OscEvent oe;

// read expected rate from command line
if( me.args() ) me.arg(0) => Std.atoi => rate;

listener(rate);
me.exit();

//-----------------------------------------------------------------------------

fun void listener(int rate) {
    int seqID, mode, rate_sent;
    time packet_received[0];
    string s;
    
    while (true) {
        oe => now;
        
        // grab the next message from the queue
        while (oe.nextMsg() != 0) {
            oe.getInt() => mode;
            oe.getInt() => rate_sent;
            
            // if we didn't get killed by the parent, we will die if we get a
            // packet coming in at a non-expected rate
            if (rate != rate_sent || rate == 6969)
                return;
            
            oe.getString() => s;
            oe.getInt() => seqID;
            
            if (s == "DIE" || seqID == 6969)
                return;
            
            // client ignores the first five "warm-up" packets
            if (seqID < 5) {
                now => packet_received[s];
                continue;
            }
            
            1.0 => step.next;
            
            // print it so longer NET_NAMES do not make the columns look weird
            // supports NET_NAMEs up to 12 characters to look "pretty"
            if (s.length() <= 6) {
                <<< s, "\t\t", 
                seqID - 5, "\t", 
                now / 1::ms, "\t",
                (now - packet_received[s]) / 1::ms >>>;
            }
            else {
                <<< s, "\t\t", 
                seqID - 5, "\t", 
                now / 1::ms, "\t",
                (now - packet_received[s]) / 1::ms >>>;
            }
            
            now => packet_received[s];
            
            spike_len => now;
            0.0 => step.next;
        }
    }
}

//-----------------------------------------------------------------------------