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
// name: server-multi.ck
// desc: clix server to synchronize N hosts
//
// author: Ge Wang
//
// EDITING THIS FILE:
//
// 1. find TODO_1 below, and set the desired number of hosts.
//
// 2. find TODO_2 below, and put the names of the sound making
//    making machines below.  (note: on OS X, use the machine
//    name appended with ".local".
//
// to run (in command line chuck):
//    (see clix.ck, under MULTIPLE HOSTS)
//-----------------------------------------------------------------------------

//some global vars
50 => int maxclients; 		//when PLOrk gets really huge, we can change this!
string clients[maxclients];	//for storing client names, as needed
0 => int numclients;		//number of current clients
OscSend xmit[maxclients];	//osc connection to clients
5502 => int port; 			//port for sockets to clients

4096::samp => dur T;

//listen for multicast messages from new clients
spork ~ multicast_receive();

8 => int width;
4 => int height;

int x;
int y;
int z;

// infinite time loop
while( true )
{
    for( 0 => y; y < height; y++ )
        for( 0 => x; x < width; x++ )
        {
            for( 0 => z; z < numclients; z++ )
            {
                // start the message...
                xmit[z].startMsg( "/plork/synch/clock", "i i" );

                // a message is kicked as soon as it is complete 
                x => xmit[z].addInt; y => xmit[z].addInt;
            }

            // advance time
            T => now;
        }
    }



/* ********** networking funcs ************ */

// listens for multicast messages from clients
fun void multicast_receive()
{
    // create our OSC receiver
    OscRecv recv;
    5501 => recv.port;
    // start listening (launch thread)
    recv.listen();

    // create an address in the receiver, store in new variable
    recv.event( "/plork/newclient, s" ) @=> OscEvent oe;

    // infinite event loop
    while ( true )
    {
        // wait for event to arrive
        oe => now;

        // grab the next message from the queue. 
        while( oe.nextMsg() != 0 )
        {
            // get x and y
            oe.getString() 	=> string newClientName;
            newsocket(newClientName);
            
            //<<<newClientName>>>;

        }
    }
}

//check to see if hosttoadd is already
//connected and if not, open up socket 
fun void newsocket(string hosttoadd)
{

	0 => int gotAlready;

	for(0=>int j;j<numclients;j++) {
		if (hosttoadd == clients[j]) {
			1 => gotAlready;
			//<<<"already have host " + hosttoadd>>>;
		}
	}
	
	if(!gotAlready) {
	
		hosttoadd => clients[numclients];  //retain client names if needed
		hosttoadd + ".local" => hosttoadd;
		<<<"adding " + hosttoadd + " as client # " + numclients>>>;

		xmit[numclients].setHost( hosttoadd, port );
		
		numclients++;
		
	}
		
}

    
    
