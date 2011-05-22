// sample-TOSC-server.ck
// Author: Mark Cerqueira

// you need one person to run the NTPServer
NTPServer s;
7005 => s.port;

// TOscSend set-up, just like OSC
TOscSend send;
send.setHost("224.0.0.1", 8080);

while (true)
{
    // when you send a message you specify the current time and
    // how far from the current time you want the packet to be
    // processed - NTPClient/NTPServer objects give you this
    send.startMsg("fudge", "i", s.currentTime()/samp, s.getTTO());
    1 => send.addInt;
    .5::second => now;
}