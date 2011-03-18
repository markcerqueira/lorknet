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
// name: sleeper.ck
// desc: this program is used in the sauto script. It waits for a start signal
// from the parent server and then sleeps for a bit before quitting.
//
// should only be used from within the sauto.sh script
//-----------------------------------------------------------------------------

OscRecv start;
4500 => start.port;
start.listen();
start.event("/lorknet/interval/start, i") @=> OscEvent oe;
    
<<< "sleeper: waiting for sleep signal from parent server" >>>;
    
oe => now;
oe.nextMsg();
oe.getInt() => int time_wait;
        
(time_wait + 2) * second => now;
    
me.exit();