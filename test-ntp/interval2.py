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
# name: interval.py
# desc: this program processes the raw data collected during the running of
# the tests and produces a condensed output providing summary information in
# both text and graphical form
#
# while this file can be run on its own, it is recommended that you just
# let the client.sh call this script
#------------------------------------------------------------------------------

import os, sys, math, pylab
from pylab import *

#------------------------------------------------------------------------------

# function that reads data from filename and plots the information
# mode needs to be 'UNICAST' or 'MULTICAST'
def boiler(filename, mode):
	first_time = 1;
	last_ID = 0;
	packets_received = 0;
	within_JND = 0;
	within_GT = 0;
	average = 0;
	travel_avg = 0;
	travel_stddev = 0;
	stddev = 0;
        diff = 0;

        # arrays to store the point that will get plotted
        x = [];
        y = [];
        dropped_x = [];
        dropped_y = [];

	# calculate average interval, packets within JND/GT
	for line in open(filename,'r').readlines():
		elements = line.split();
		packets_received += 1;

		if (first_time == 1):
			first_time = 0;

			interval = float(elements[6]);

			first_packet = float(elements[4]);

                        x.append(int(elements[2]));
                        y.append(0);

			average = average + interval;

                        diff = math.fabs(interval - rate);

                        # print str(elements[1]) + " " + str(interval) + " " + str(diff)

			if (diff < JND):
				within_JND += 1;

			if (diff < GT):
				within_GT += 1;

			travel_avg = travel_avg + float(elements[5]);

			last_ID = float(elements[2]);

		else:
			current_ID = float(elements[2]);

			interval = float(elements[6])/(current_ID - last_ID);
			average = average + interval;

			offset = interval - rate;
			# offset = float(elements[3]) - (first_packet + current_ID * rate)

                        x.append(current_ID);
                        y.append(offset);

                        diff = math.fabs(offset);

			if (diff < JND):
				within_JND += 1;

			if (diff < GT):
				within_GT += 1;

			travel_avg = travel_avg + float(elements[5]);

                        while (last_ID + 1 != current_ID):
                          last_ID = last_ID + 1;
                          dropped_x.append(last_ID);

                          if (mode == 'UNICAST'):
                            dropped_y.append(18);
                          if (mode == 'MULTICAST'):
                            dropped_y.append(-18);

                        last_ID = current_ID;

	if (packets_received == 0):
		packets_received = 1;

	average = average / packets_received;
        travel_avg = travel_avg / packets_received;
	first_time = 1;

	# calculate the standard deviation
	for line in open(filename,'r').readlines():
		elements = line.split();

		if (first_time == 1):
			first_time = 0;
			travel_stddev = travel_stddev + math.pow(float(elements[5]) - travel_avg, 2);
			stddev = stddev + math.pow(float(elements[6]) - average, 2);
			last_ID = float(elements[2]);

		else:
			current_ID = float(elements[2]);
			travel_stddev = travel_stddev + math.pow(float(elements[5]) - travel_avg, 2);
			stddev = stddev + math.pow(float(elements[6])/(current_ID - last_ID) - average, 2);
			last_ID = current_ID;

	if (packets_received <= 1):
		packets_received = 2;

        stddev = math.sqrt(stddev/(packets_received-1));
	travel_stddev = math.sqrt(travel_stddev/(packets_received-1));

        re = open("results_" + NET_NAME + "." + target + ".txt", 'a');

        if (packets_received > 0):
          withJND = round((float(within_JND) / packets_received * 100), 1);
          withGT = round((float(within_GT) / packets_received * 100), 1);
        else:
          withJND = 0;
          withGT = 0;

	# write summary data to file
	if (mode == "UNICAST"):
		re.write("------------------------------------------------------------------------\n");
		re.write("Results - " + NET_NAME + " receiving from " + target + " sending at a rate of " + str(rate) + " ms\n\n");
		re.write("Unicast:\n");
		
	if (mode == "MULTICAST"):
		re.write("Multicast:\n");

	re.write("Packets received: " + str(packets_received) + ", " + str(float(packets_received) / packets_expected * 100) + "%\n");
	re.write("Packets within JND: " + str(within_JND) + ", "+ str(withJND) + "%\n");
	re.write("Packets within GT: " + str(within_GT) + ", " + str(withGT) + "%\n");
	re.write("Average of interval: " + str(round(average, 2)) + " ms\n");
        re.write("Std dev of interval: " + str(round(stddev, 2)) + " ms\n");
	re.write("Average of latency: " + str(round(travel_avg, 2)) + " ms\n");
        re.write("Std dev of latency: " + str(round(travel_stddev, 2)) + " ms\n\n");

        #print "JND: " + str(within_JND) + " GT: " + str(within_GT);

        # plot unicast data
        if (mode == "UNICAST"):
          # plot received packets
          plot(x, y, color = 'g', marker = 's', label = 'Unicast', linewidth = 1.5)

          # plot dropped packets, if any
          if (len(dropped_x) != 0):
            scatter(dropped_x, dropped_y, marker = 'v', color = 'g', label = 'Dropped unicast')

          # plot text summary
          summary = "Unicast: \n " + str(packets_received) + ", " + str(float(packets_received) / packets_expected * 100) + "%\n "
          summary += str(within_JND) + ", "+ str(withJND) + "%\n "
          summary += str(within_GT) + ", "+ str(withGT) + "%\n "
          summary += str(round(average, 2)) + " ms\n "
          summary += str(round(stddev, 2)) + " ms\n "
          summary += str(round(travel_avg, 2)) + " ms\n "
          summary += str(round(travel_stddev, 2)) + " ms"
          text(packets_expected * .78, 25, summary, color = 'g', weight = 'bold', size = '10', backgroundcolor = 'w')
   
        # plot multicast data
        if (mode == "MULTICAST"):
          plot(x, y, color = 'b', marker = 'o', label = 'Multicast', linewidth = 1)

          if (len(dropped_x) != 0):
            scatter(dropped_x, dropped_y, marker = '^', color = 'b', label = 'Dropped multicast')

          # plot text summary
          summary = "Multicast: \n " + str(packets_received) + ", " + str(float(packets_received) / packets_expected * 100) + "%\n "
          summary += str(within_JND) + ", "+ str(withJND) + "%\n "
          summary += str(within_GT) + ", "+ str(withGT) + "%\n "
          summary += str(round(average, 2)) + " ms\n "
          summary += str(round(stddev, 2)) + " ms\n "
          summary += str(round(travel_avg, 2)) + " ms\n "
          summary += str(round(travel_stddev, 2)) + " ms"
          text(packets_expected * .90, 25, summary, color = 'b', weight = 'bold', size = '10', backgroundcolor = 'w')

#------------------------------------------------------------------------------

# the program name, target name, rate, SSID, number of machines, number of servers
if len(sys.argv) != 6: 
  sys.exit("interval.py: python interval.py target_name rate_ms SSID machine_count server_count")

target = str(sys.argv[1]);
rate = int(sys.argv[2]);

# resolve SSID to a device name for labelling our charts
SSID = str(sys.argv[3]);

# TODO - add your SSID -> device name resolution here!
if (SSID == "PLOrknet2"):
  SSID = "Apple Airport Extreme"
elif (SSID == "PLOrk-Netgear-WNR2000"):
  SSID = "Netgear WNR2000"
elif (SSID == "PLOrk-dlink655" or SSID == "PLOrk-dlink655-orange"):
  SSID = "D-Link DIR-655"
elif (SSID == "PLOrk-dlink825-N" or SSID == "PLOrk-dlink825-G"):
  SSID = "D-Link DIR-825"
elif (SSID == "Netgear-WNDR3700-5.0" or SSID == "Netgear-WNDR3700-2.4"):
  SSID = "Netgear WNDR3700"
elif (SSID == "PLOrk-linksys-WRT54G"):
  SSID = "Linksys WRT54G"

machine_count = int(sys.argv[4]);
server_count = int(sys.argv[5]);

# figure out the file names of the data we are analyzing
NET_NAME = os.environ.get("NET_NAME");
uni_filename = NET_NAME + "." + target + "_U_" + str(rate) + ".txt";
multi_filename =  NET_NAME + "." + target + "_M_" + str(rate) + ".txt";

# figure out packets to expect based on the rate
if (rate == 50 or rate == 100 or rate == 200):
    packets_expected = 500;
elif (rate == 400 or rate == 800):
    packets_expected = 200;
elif (rate == 1600):
    packets_expected = 100;
else:
    sys.exit("Rate did not return a packet expectation");

# calculate JND
if (rate > 240):
  JND = rate * 0.025
else:
  JND = 6;

GT = 30;

high_JND = rate + JND;
low_JND = rate - JND;

# plot packet data
boiler(uni_filename, "UNICAST");
boiler(multi_filename, "MULTICAST");

summary = "Summary\n Packets received:\n Packets within JND:\n "
summary += "Packets within GT:\n Average of interval:\n Std dev of interval:\n "
summary += "Average of latency:\n Std dev of latency:"
text(packets_expected * .61, 25, summary, color = 'k', weight = 'extra bold', size = '10', backgroundcolor = 'w')

# plot JND/GT lines
axhline(JND, color = 'k', linewidth = 2);
axhline(-JND, color = 'k', linewidth = 2);
axhline(GT, color = 'r', linewidth = 2);
axhline(-GT, color = 'r', linewidth = 2);

# set axis labels, title, and grid on
xlabel('Packet ID');
ylabel('Deviation from expected arrival (ms)');

if (machine_count == 1):
  graphTitle = SSID + " - " + str(machine_count) + " client; ";
else:
  graphTitle = SSID + " - " + str(machine_count) + " clients; ";

if (server_count == 1):
  graphTitle += str(server_count) + " server\n";
else:
  graphTitle += str(server_count) + " servers\n";

graphTitle += NET_NAME + " receiving from " + target + " sending at intervals of " + str(rate) + " ms";
title(graphTitle, weight = 'light');
grid(True);

# display the legend if you want
# legend(loc = 'upper left')

# set x and y axis limits
xlim(0, packets_expected);
ylim(-50 , 50);

# set size of figure
fig = pylab.gcf()
fig.set_size_inches( (15, 8) )

# save the figure
savefig(NET_NAME + "." + target + "_" + str(rate) + ".eps", format = 'eps');
savefig(NET_NAME + "." + target + "_" + str(rate) + ".png", format = 'png');

# show the figure
# show()
