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
# name: build.py
# desc: this program is used to prepare the client.sh, cauto.sh scripts and the
# server.ck program to handle unicasting to all the machines in your setup
# and handle processing the data collected from those machines. You should run
# this script after setting/collecting the NET_NAMEs of all the machines in
# your setup and before deploying the toolkit to all your computers.
#
# to run (in command line python):
#     %> python build.py
#
# Input the NET_NAME of each machine - when done, press enter twice and
# the files client.sh, cauto.sh, and server.ck will be updated with the
# information you inputted
#------------------------------------------------------------------------------

import os, sys

i = 1;

name = str(raw_input("Enter the NET_NAME/sharing name of machine " + str(i) + ": "))

if (name == ""):
    print "\nbuilder.py: error - no names inputted - exiting\n"
    sys.exit()

i += 1;

chuck = "[ \"" + name + ".local\""
bash = "machines=(" + name

# continue reading names from command line, updating chuck/bash list as we go
while(name != ""):
    name = str(raw_input("Enter the NET_NAME/sharing name of machine " + str(i) + ": "))
    if (name == ""):
        break
    chuck += " , \"" + name + ".local\""
    bash += " " + name
    i +=1

# being responsible about use of the english language!
if (i == 2):
    print "\nbuild.py: information entered for " + str(i-1) + " machine"
else:
    print "\nbuild.py: information entered for " + str(i-1) + " machines" 

# put the finishing touches on our chuck/bash lists
chuck += " ] @=> string hosts[];\n"
bash += ")"

# debug - print bash/chuck representations of the hosts
# print bash
# print chuck

# create the cauto.sh script
# cautosh = open('cauto.bash', 'w')
# cautosh_top = open('.build_pieces/cautosh_top', 'r')
# cautosh_bottom = open('.build_pieces/cautosh_bottom', 'r')

# cautosh.write(cautosh_top.read())
# cautosh.write(bash)
# cautosh.write(cautosh_bottom.read())

# create the client.sh script
clientsh = open('client.bash', 'w')
clientsh_top = open('.build_pieces/clientsh_top', 'r')
clientsh_bottom = open('.build_pieces/clientsh_bottom', 'r')

clientsh.write(clientsh_top.read())
clientsh.write(bash)
clientsh.write(clientsh_bottom.read())

# create the server.ck file
serverck = open('server.ck', 'w')
serverck_top = open('.build_pieces/serverck_top.ck', 'r')
serverck_bottom = open('.build_pieces/serverck_bottom.ck', 'r')

serverck.write(serverck_top.read())
serverck.write(chuck)
serverck.write(serverck_bottom.read())

# give our scripts some +x power
# os.system('chmod +x cauto.bash');
os.system('chmod +x client.bash');

# print some info
print "build.py: created files client.bash, server.ck\n"

