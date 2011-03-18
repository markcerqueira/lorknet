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
// 2. one, and only one machine (potentially one of the sound making  
//    machine, or a standalone host) should edit the server program (see 
//    server-multi.ck for details) and then run it:
//    %> chuck server-multi.ck
//
// to run (in miniAudicle):
//     (you can't, as of yet due to KBHit incompatibility)
//-----------------------------------------------------------------------------

// auto networking
//get the name of our machine as it appears on the network
Std.getenv("NET_NAME") => string newclient;
<<<newclient>>>;

//this port must be the same as "port" in the server script
//this port is for the direct sockets, not the multicasting
5502 => int port;

//spork a shreads that regularly broadcasts our presence
//and name to all on LAN
spork ~ multicast_me();

// computer keyboard input via terminal
KBHit kb;

// time
4096::samp => dur T;

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
  0.4, 0.1, 0.3, 0.2, 0.3, 0.1, 0.2, 0.1 ] @=> float mygains[];

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
int x;
int y;
int clear;

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

        // figure out period
        y * 8 + x => int index;
        // generate impulse
        mygains[index] => i.next;
        // set filtre freq
        c => Std.mtof => f.pfreq;
        // print int value
        <<< "ascii:", c, "velocity:", mygains[index], "channel:", which >>>;

        // disconnect from previous
        if( last != NULL ) r =< last;
        // the dac channel to connect
        dac.chan(which) @=> last;
        // the next channel
        (++which) % C => which;
        <<<"which = ", which>>>;
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
    // create our OSC receiver
    OscRecv recv;
    // use port 6449
    5502 => recv.port;
    // start listening (launch thread)
    recv.listen();

    // create an address in the receiver, store in new variable
    recv.event( "/plork/synch/clock, i i" ) @=> OscEvent oe;

    // count
    0 => int count;

    // infinite event loop
    while ( true )
    {
        // wait for event to arrive
        oe => now;

        // count
        if( count < 5 ) count++;
        if( count < 4 ) <<< ".", "" >>>;
        else if( count == 4 ) <<< "keyboard ready...", "" >>>;

        // grab the next message from the queue. 
        while( oe.nextMsg() != 0 )
        {
            // get x and y
            oe.getInt() => x;
            oe.getInt() => y;
            //<<<"got click!">>>;

            // broadcast on event
            event.broadcast();
        }
    }
}


/* ******** funcs ********* */

//multicasts name of this machine to all on LAN
fun void multicast_me()
{
	
	// send object
	OscSend xmit;

	//multicast IP, port should also be the
	//same as the multicast recv port in the server script
	xmit.setHost( "224.0.0.1", 5501 );
		
	//send out our presence every second
	while(true)
	{

		1::second => now;

		xmit.startMsg( "/plork/newclient", "s");
		newclient => xmit.addString;
		
	}

}
