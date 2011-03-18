OscSend uxmit[0];
string client_list[0];

// Step UGen for producing sound
Step step => dac.chan(0);
10::samp => dur spike_len;

// CHECK - make sure you have a NET_NAME environment variable and it matches
// your sharing name under the Sharing pane in System Preferences
Std.getenv("NET_NAME") => string myname;

-1 => int rank; // 0 for parent server, 1 for regular server

if (me.args() > 0) me.arg(0) => Std.atoi => rank;

FileIO fout;
fout.open(Std.rand2(0, 1000) * Std.rand2f(0.0, 1.0) + " " + myname + ".txt", FileIO.WRITE);

// create our OSC receiver
OscRecv recv;
9001 => recv.port;
recv.listen();
recv.event( "/lorknet/interval, i i s i" ) @=> OscEvent oe;

// shreds to add people to unicast list
spork ~ receiver();
spork ~ broadcaster();

spork ~ listener();

while (true) {
    pauser() => int test;
    
    // multicast tests
    if (test == 49) {
        <<< "tester: multicast testing" >>>;
        sender(0, 200, 50,  rank, 0);
        //sender(0, 200, 100, rank, 0);
        //sender(0, 100, 200, rank, 0);
        //sender(0, 100, 400, rank, 0);
        //sender(0, 50,  800, rank, 0);
    }
    
    // unicast tests
    if (test == 50) {
        <<< "tester: unicast testing" >>>;
        sender(1, 200, 50,  rank, 0);
        //sender(1, 200, 100, rank, 0);
        //sender(1, 100, 200, rank, 0);
        //sender(1, 100, 400, rank, 0);
        //sender(1, 50,  800, rank, 0);
    }
    
    if (test == 27)
        break;
}

<<< "tester: exiting" >>>;
fout.close();
me.exit();

//-----------------------------------------------------------------------------

fun void broadcaster() {
    OscSend xmit;
    xmit.setHost( "224.0.0.1", 9100 );
    
    KBHit kb;
    
    while (true) {
        kb => now;
        
        while (true) {
            kb => now;
            kb.getchar() => int c;
            if (c == 32)
                break;
        }
        
        <<< "broadcaster: broadcasting myself 20 times..." >>>;
        
        for(0 => int i; i < 20; i++) {
            xmit.startMsg( "/lorknet/newclient", "s");
            Std.getenv("NET_NAME") => xmit.addString;
            kb.getchar();
            .25::second => now;
        }
        
        <<< "broadcaster: done broadcasting..." >>>;
        
    }
}

fun void receiver() {
    OscRecv recv;
    9100 => recv.port;
    recv.listen();
    
    recv.event( "/lorknet/newclient, s" ) @=> OscEvent oe;
    
    while ( true ) {
        oe => now;
        
        while( oe.nextMsg() != 0 ) { 
            oe.getString() 	=> string newClientName;
            newsocket(newClientName);
        }
    }
}

fun void newsocket(string client) {
    0 => int got_already;
    
    for (0 => int j; j < client_list.size(); j++) {
        if (client == client_list[j]) {
            1 => got_already;
        }
    }
    
    if (!got_already) {
        client_list << client;
        OscSend oscsender @=> uxmit[client];
        uxmit[client].setHost(client + ".local", 9001);
        
        <<<"adding", client ,"as client #", client_list.size() >>>;
    } 
} 

fun int pauser() {
    <<< "pauser: waiting for start signal" >>>;
    
    // computer keyboard input via terminal
    KBHit kba;
    
    while (true) {
        kba => now;
        kba.getchar() => int c;
        
        //<<< c >>>;
        
        if (c == 49 || c == 50 || 27)
            return c;
        
        // thesis easter eggs
        if (c == 97) 
            Std.system("say I am Dan Trueman. Yeah baby");
        if (c == 101)
            Std.system("say -v Cellos I am Dan Trueman and I am a robot cello");
        if (c == 105)
            Std.system("say -v Agnes I am Dan Trueman, even though I sound like a woman");
        if (c == 111)
            Std.system("say -v Hysterical I am Dan Trueman ha ha ha ha ha ha ha");
        if (c == 117)
            Std.system("say -v Zarvox I am Dan Trueman. Take me to your leader");            
    }
}

//-----------------------------------------------------------------------------

fun void sender(int mode, int num_packets, int rate, int rank, int num_clients) {
    
    // the first five packets are warm-ups and are discarded by the client
    5 +=> num_packets;
    
    // sending packets over port 9001
    9001 => int port;
    
    rate * ms => dur interval;
    
    // we are the parent server - send start signals to the other servers
    if (rank == 0) {
        OscSend start;
        start.setHost("224.0.0.1", 4500);
        
        for (10 => int i; i > 0; i--) {
            start.startMsg( "/lorknet/interval/start", "i");
            <<< "parent: countdown to start...", i >>>;
            i => start.addInt;
            1::second => now;
        }
    }
    
    // we are a regular server, the parent needs to tell us to start
    else {
        OscRecv start;
        4500 => start.port;
        start.listen();
        start.event("/lorknet/interval/start, i") @=> OscEvent oe;
        
        <<< "server: waiting for start signal from parent server" >>>;
        
        oe => now;
        oe.nextMsg();
        oe.getInt() => int time_wait;
        
        <<< "server: pausing for" , time_wait , "seconds" >>>;
        
        time_wait * second => now;
        
        <<< "server: sending", num_packets - 5, "at rate", rate >>>;
    }
    
    OscSend mxmit;
    
    0 => int packets_sent;
    int server_int;
    float server_time;
    
    // multicast mode
    if (mode == 0) {
        mxmit.setHost("224.0.0.1", port);
        
        while(packets_sent < num_packets) {
            1.0 => step.next;
            
            mxmit.startMsg( "/lorknet/interval", "i i s i" );
            
            mode => mxmit.addInt;
            rate $ int => mxmit.addInt;
            myname => mxmit.addString;
            packets_sent => mxmit.addInt;
            
            packets_sent++;
            
            spike_len => now;
            0.0 => step.next;
            (interval - spike_len) => now;
        }
    }
    
    // unicast mode
    else {        
        while(packets_sent < num_packets) {
            1.0 => step.next;
            
            for (0 => int i; i < client_list.size(); i++) {
                uxmit[client_list[i]].startMsg( "/lorknet/interval", "i i s i" );
                mode => uxmit[client_list[i]].addInt;
                rate $ int => uxmit[client_list[i]].addInt;
                myname => uxmit[client_list[i]].addString;
                packets_sent => uxmit[client_list[i]].addInt;
            }
            
            packets_sent++;
            
            spike_len => now;
            0.0 => step.next;
            interval - spike_len => now;
        }
    }
    
    // give the next group of servers and clients time to start up
    if (rank == 0) {
        5000::ms => now;
    }
}

//-----------------------------------------------------------------------------

fun void listener() {
    int seqID, mode;
    int rate_sent;
    time packet_received[0];
    int server_int;
    float server_float, client_time;
    string s, p;
    
    while (true) {
        oe => now;
        
        // grab the next message from the queue
        while (oe.nextMsg() != 0) {
            oe.getInt() => mode;
            oe.getInt() => rate_sent;
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
            
            mode + ":" + rate_sent $ int + " " + s => p;
            
            if (s.length() <= 6)
                "\t\t" +=> p;
            else
                "\t" +=> p;
            
            seqID - 5 + "\t" + (((now - packet_received[s]) / (second/samp/1000)) / samp) + "\n" +=> p;
            
            fout.write(p);
            
            // print it so longer NET_NAMES do not make the columns look weird
            // supports NET_NAMEs up to 12 characters to look "pretty"
            if (s.length() <= 6) {
                <<< mode + ":" + rate_sent $ int + " ",
                s, "\t\t", 
                seqID - 5, "\t",
                ((now - packet_received[s]) / (second/samp/1000)) / samp >>>;
            }
            else {
                <<< mode + ":" + rate_sent $ int + " ", 
                s, "\t\t", 
                seqID - 5, "\t",
                ((now - packet_received[s]) / (second/samp/1000)) / samp >>>;
            }
            
            now => packet_received[s];
            
            spike_len => now;
            0.0 => step.next;
        }
    }
}

//-----------------------------------------------------------------------------
