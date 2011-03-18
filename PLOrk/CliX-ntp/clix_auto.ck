/*----------------------------------------------------------------------------
S.M.E.L.T. : Small Musically Expressive Laptop Toolkit

Copyright (c) 2007 Rebecca Fiebrink and Ge Wang.  All rights reserved.
http://smelt.cs.princeton.edu/
http://soundlab.cs.princeton.edu/

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
// name: clix.ck
// desc: networked typing-based instrument, quantized, multi-channel
//
// author: Ge Wang
//
// to run (in command line chuck):
//
// SINGLE HOST:
//    %> chuck clix.ck server-local.ck
//
// MULTIPLE HOSTS:
//
// 1. each sound making machine should run:
//    %> chuck clix.ck
//    (make sure terminal has focus in order to receive keyboard events)
//
//    for multi-channel, use the -cN flag, where N is the number of channels
//
// to run (in miniAudicle):
//     (you can't, as of yet due to KBHit incompatibility)
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

(1 - Math.fmod(time_second(), 1))::second => now;
(4 - time_second() % 4)::second => now;
// -------------------------- Standard ChucK NTP Code -------------------------

// computer keyboard input via terminal
KBHit kb;

// time - 10 pulses per second
//((second/samp)/10)::samp => dur T;
4410::samp => dur T;

// patch
Impulse i => BiQuad f => Envelope e => JCRev r;

// set the filter's pole radius
.99 => f.prad;
// set equal gain zeros
1 => f.eqzs;
// envelope rise/fall time
1::ms => e.duration;
// reverb mix
.02 => r.mix;

// strengths
[ 1.0, 0.2, 0.3, 0.2, 0.4, 0.1, 0.2, 0.1,
0.5, 0.1, 0.3, 0.2, 0.4, 0.1, 0.2, 0.1,
0.8, 0.1, 0.3, 0.2, 0.5, 0.1, 0.2, 0.1,
0.4, 0.1, 0.3, 0.2, 0.3, 0.1, 0.2, 0.1,
0.6, 0.1, 0.2, 0.3, 0.2, 0.2, 0.2, 0.1 ] @=> float mygains[];

// capacity
mygains.cap() => int N;
// period duration
N * T => dur period;

// last unen
UGen @ last;
// total number of channels
dac.channels() => int C;
//<<<"channels = ", C>>>;
// keep track of which
int which;

// event
Event event;
int x, y;
int index;
int clear;
1 => int first;

// spork
spork ~ mouse( 0 );
spork ~ clock();

// time-loop
while( true )
{
    // wait on event
    kb => now;
    
    // set clear
    0 => clear;
    
    // loop through 1 or more keys
    while( kb.more() )
    {
        // clear button hit
        if( clear )
        { kb.getchar(); continue; }
        
        // get key...
        kb.getchar() => int c;
        
        // synch
        event => now;
        
        x * 10 + y => index;
        // generate impulse
        mygains[index] => i.next;
        // set filtre freq
        c => Std.mtof => f.pfreq;
        // print int value
        <<< "ascii:", c, "velocity:", mygains[index], "channel:", which, "index:", index >>>;
        
        // disconnect from previous
        if( last != NULL ) r =< last;
        // the dac channel to connect
        dac.chan(which) @=> last;
        // the next channel
        (++which) % C => which;
        // <<<"  which = ", which>>>;
        // print the time
        <<< "  time = ", time_second(), ",", time_second() % 4 >>>;
        // connect revert to dac channel
        r => last;
        
        // open
        e.keyOn();
        // advance time
        T-2::ms => now;
        // close
        e.keyOff();
    }
    
    // check clear
    if( clear )
    { <<< "cleared!!!", "" >>>; }
}

// mouse
fun void mouse( int device )
{
    // hid objects
    Hid hi;
    HidMsg msg;
    
    // try
    if( !hi.openMouse( device ) ) me.exit();
    <<< "mouse ready...", "" >>>;
    
    // go
    while( true )
    {
        // wait on event
        hi => now;
        
        // get message
        while( hi.recv( msg ) )
        {
            if( msg.is_button_down() )
            { 1 => clear; }
        }
    }
}

// receiver
fun void clock()
{
    float current;
    0 => int count;
    0 => int factor;

    if ( Math.round(Math.fmod(time_second(), 1.0) * 10) == 10 )
       1 => factor;
    
    // infinite event loop
    while ( true )
    {   
        // count
        if( count < 5 ) count++;
        if( count < 4 ) <<< ".", "" >>>;
        else if( count == 4 ) <<< "keyboard ready...", "" >>>;
        
        time_second() % 4 => current;
        Math.round(Math.fmod(current, 1.0) * 10) => float blah;

        current $ int => x;
        (blah - factor) $ int => y;
        
        // <<< index >>>;
        
        event.broadcast();
        
        T => now;
    }
}

