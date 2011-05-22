// sample-TOSC-client.ck
// Author: Mark Cerqueira

// everyone else runs NTPClient and connects to the NTPServer
NTPClient c;
c.setHost("localhost", 7005);

// let the NTPClient synchronize its clock to NTPServer
3::second => now;

// standard OSC-like set-up is the same for TOSC
TOscRecv recv;
8080 => recv.port;
recv.listen();
recv.event("fudge, i"); // no need to @ChucK to OscEvent!

Mandolin m => dac;
440 => m.freq;

while (true)
{
    recv.oe => now;
    
    // nextMsg() now returns a float of how long the program should
    // wait before processing the packet
    while ((recv.nextMsg(c.currentTime()/samp) => float timeSauce) > 0.0)
    {
        // the wait to process the packet
        timeSauce::samp => now;
        1 => m.noteOn;
        recv.getInt() => int hello;
    }  
}