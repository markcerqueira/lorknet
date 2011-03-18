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
[ "sing.local" , "shout.local" , "shovel.local" , "pow.local" , "ooze.local" ] @=> string hosts[];

OscSend uxmit[hosts.size()];

// -------------------------- Standard ChucK NTP Code -------------------------
0.0 => float NTP_TIME;
now => time shred_now;

// returns absolute time in seconds
fun float time_second() {
    // NTP_TIME + time shred is alive + time shred was spawned in VM
    return NTP_TIME + now / 1::second - shred_now / 1::second;
}

// get system time with short python program, subtract out 03/27/2010 00:00:00 GMT
Std.system("python -c'import time; print repr(time.time() - 1269648000)' > mytime.txt");

// read NTP time from file it was written to
FileIO fio;
fio.open("mytime.txt", FileIO.READ);
Std.system("rm -f mytime.txt");
fio.readLine() => string str => Std.atof => NTP_TIME;

if (NTP_TIME == 0.0) {
    <<< "ERROR - NTP time not acquired. Call ChucK with the --caution-to-the-wind flag." >>>;
    me.exit();
}
// -------------------------- Standard ChucK NTP Code -------------------------

// Step UGen for producing sound
Step step => dac.chan(0);
10::samp => dur spike_len;

// create our OSC receiver
OscRecv recv;
9001 => recv.port;
recv.listen();
recv.event( "/lorknet/interval, i f s i i f" ) @=> OscEvent oe;

// CHECK - make sure you have a NET_NAME environment variable and it matches
// your sharing name under the Sharing pane in System Preferences
Std.getenv("NET_NAME") => string myname;

-1 => int rank; // 0 for parent server, 1 for regular server
-1 => int num_clients;

if (me.args() > 0) me.arg(0) => Std.atoi => rank;
if (me.args() > 1) me.arg(1) => Std.atoi => num_clients;

// unicast mode - configure sockets!
for (0 => int i; i < num_clients; i++)
    uxmit[i].setHost(hosts[i], 9001);

spork ~ listener();

OscSend mxmit;
mxmit.setHost("224.0.0.1", 9001);

sender(0, 500, 50, rank);
sender(0, 500, 100, rank);
sender(0, 500, 200, rank);
sender(0, 200, 400, rank);
sender(0, 200, 800, rank);
sender(0, 100, 1600, rank);

sender(1, 500, 50, rank);
sender(1, 500, 100, rank);
sender(1, 500, 200, rank);
sender(1, 200, 400, rank);
sender(1, 200, 800, rank);
sender(1, 100, 1600, rank);

// parent server sends signals to kill all clients
if (rank == 0) {    
    // let the dust settle before killing clients
    1500::ms => now;
    
    for (0 => int i; i < 40; i++) {
        mxmit.startMsg( "/lorknet/interval", "i f s i i f" );
        1 => mxmit.addInt;
        0.0 => mxmit.addFloat;
        "DIE" => mxmit.addString;
        6969 => mxmit.addInt;
        6969 => mxmit.addInt;
        69.69 => mxmit.addFloat;
        15::ms => now;
        
    }        
}

//-----------------------------------------------------------------------------

fun void sender(int mode, int num_packets, int rate, int rank) {
    
    // the first five packets are warm-ups and are discarded by the client
    5 +=> num_packets;
    
    // sending packets over port 9001
    9001 => int port;
    
    rate * ms => dur interval;
    
    // we are the parent server - send start signals to the other servers
    if (rank == 0) {
        OscSend start;
        start.setHost("224.0.0.1", 4500);
        
        for (10 => int i; i > 0; i--) {
            start.startMsg( "/lorknet/interval/start", "i");
            <<< "parent: countdown to start...", i >>>;
            i => start.addInt;
            1::second => now;
        }
    }
    
    // we are a regular server, the parent needs to tell us to start
    else {
        OscRecv start;
        4500 => start.port;
        start.listen();
        start.event("/lorknet/interval/start, i") @=> OscEvent oe;
        
        <<< "server: waiting for start signal from parent server" >>>;
        
        oe => now;
        oe.nextMsg();
        oe.getInt() => int time_wait;
        
        <<< "server: pausing for" , time_wait , "seconds" >>>;
        
        time_wait * second => now;
        
        <<< "server: sending", num_packets - 5, "at rate", rate >>>;
    }
    
    0 => int packets_sent;
    int server_int;
    float server_time;
    
    // multicast mode
    if (mode == 0) {
        
        
        while(packets_sent < num_packets) {
            1.0 => step.next;
            
            mxmit.startMsg( "/lorknet/interval", "i f s i i f" );
            
            mode => mxmit.addInt;
            rate => mxmit.addFloat;
            myname => mxmit.addString;
            packets_sent => mxmit.addInt;
            
            time_second() => server_time;
            server_time $ int => mxmit.addInt;
            (server_time - (server_time $ int)) => mxmit.addFloat;
            
            packets_sent++;

            spike_len => now;
            0.0 => step.next;
            (interval - spike_len) => now;
        }
    }
    
    // unicast mode
    else {        
        while(packets_sent < num_packets) {
            1.0 => step.next;
            
            for (0 => int i; i < num_clients; i++) {
                uxmit[i].startMsg( "/lorknet/interval", "i f s i i f" );
                mode => uxmit[i].addInt;
                rate => uxmit[i].addFloat;
                myname => uxmit[i].addString;
                packets_sent => uxmit[i].addInt;
                
                time_second() => server_time;
                server_time $ int => uxmit[i].addInt;
                (server_time - (server_time $ int)) => uxmit[i].addFloat;
            }
            
            packets_sent++;
            
            spike_len => now;
            0.0 => step.next;
            interval - spike_len => now;
        }
    }  
}

//-----------------------------------------------------------------------------

fun void listener() {
    int seqID, mode;
    float rate_sent;
    time packet_received[0];
    int server_int;
    float server_float, client_time;
    string s, p;
    
    Step step => dac.chan(1);
    
    while (true) {
        oe => now;
        
        // grab the next message from the queue
        while (oe.nextMsg() != 0) {
            oe.getInt() => mode;
            oe.getFloat() => rate_sent;
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
            
            oe.getInt() => server_int;
            oe.getFloat() => server_float;
            
            server_int + server_float => float server_time;
            
            //<<< server_int, server_float, server_time >>>;
            
            time_second() => client_time;
            
            // print it so longer NET_NAMES do not make the columns look weird
            // supports NET_NAMEs up to 12 characters to look "pretty"
            if (s.length() <= 6) {
                <<< mode + ":" + rate_sent $ int + " ",
                s, "\t\t", 
                seqID - 5, "\t", 
                (server_time) * 1000, "\t",
                client_time * 1000, "\t", 
                (client_time - server_time) * 1000, "\t",
                ((now - packet_received[s]) / (second/samp/1000)) / samp >>>;
            }
            else {
                <<< mode + ":" + rate_sent $ int + " ", 
                s, "\t\t", 
                seqID - 5, "\t", 
                (server_time) * 1000, "\t",
                client_time * 1000, "\t", 
                (client_time - server_time) * 1000, "\t",
                ((now - packet_received[s]) / (second/samp/1000)) / samp >>>;
            }
            
            now => packet_received[s];
            
            spike_len => now;
            0.0 => step.next;
        }
    }
}

//-----------------------------------------------------------------------------