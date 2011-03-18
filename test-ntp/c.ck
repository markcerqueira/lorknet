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

0 => int rate;

// Step UGen to play impulses
Step step => dac.chan(1);
10::samp => dur spike_len;

// create our OSC receiver
OscRecv recv;
9001 => recv.port;
recv.listen();
recv.event( "/lorknet/interval, i f s i i f" ) @=> OscEvent oe;

listener();
me.exit();

//-----------------------------------------------------------------------------

fun void listener() {
    int seqID, mode;
    float rate_sent;
    time packet_received[0];
    int server_int;
    float server_float, client_time;
    string s, p;
    
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
            
            time_second() => client_time;
            
            // print it so longer NET_NAMES do not make the columns look weird
            // supports NET_NAMEs up to 12 characters to look "pretty"
            if (s.length() <= 6) {
                <<< mode + ":" + rate_sent $ int + " ",
                s, "\t\t", 
                seqID - 5, "\t", 
                (server_int + server_float) * 1000, "\t",
                client_time * 1000, "\t", 
                (client_time - server_int + server_float) * 1000, "\t",
                ((now - packet_received[s]) / (second/samp/1000)) / samp >>>;
            }
            else {
                <<< mode + ":" + rate_sent $ int + " ", 
                s, "\t\t", 
                seqID - 5, "\t", 
                (server_int + server_float) * 1000, "\t",
                client_time * 1000, "\t", 
                (client_time - server_int + server_float) * 1000, "\t",
                ((now - packet_received[s]) / (second/samp/1000)) / samp >>>;
            }
            
            now => packet_received[s];
            
            spike_len => now;
            0.0 => step.next;
        }
    }
}

//-----------------------------------------------------------------------------