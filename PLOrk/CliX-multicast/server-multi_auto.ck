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
// modified to multicast: Mark Cerqueira
//
// to run (in command line chuck):
//    (see clix.ck, under MULTIPLE HOSTS)
//-----------------------------------------------------------------------------

//some global vars
OscSend xmit;	            //osc connection to clients
5502 => int port; 			//port for sockets to clients

xmit.setHost("224.0.0.1", port);

4096::samp => dur T;

8 => int width;
4 => int height;

int x;
int y;
int z;

// infinite time loop
while( true )
{
    for( 0 => y; y < height; y++ ) {
        for( 0 => x; x < width; x++ )
        {  
            // start the message...
            xmit.startMsg( "/plork/synch/clock", "i i" );
            
            // a message is kicked as soon as it is complete 
            x => xmit.addInt; y => xmit.addInt;
            
            // advance time
            T => now;
        }
    }
}
