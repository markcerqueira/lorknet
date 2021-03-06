
OscSend uxmit[hosts.size()];

// Step UGen for producing sound
Step step => dac.chan(0);
10::samp => dur spike_len;

// CHECK - make sure you have a NET_NAME environment variable and it matches
// your sharing name under the Sharing pane in System Preferences
Std.getenv("NET_NAME") => string myname;

// server needs the following command line arguments
-1 => int mode; // 0 to send via multicast, 1 to send via unicast
-1 => int num_packets; // number of packets to send
-1 => int rate; // send packets every x miliseconds
-1 => int rank; // 0 for parent server, 1 for regular server
-1 => int num_clients; // if in unicast mode, specify number of clients

if (me.args() > 0) me.arg(0) => Std.atoi => mode;
if (me.args() > 1) me.arg(1) => Std.atoi => num_packets;
if (me.args() > 2) me.arg(2) => Std.atoi => rate;
if (me.args() > 3) me.arg(3) => Std.atoi => rank;
if (me.args() > 4) me.arg(4) => Std.atoi => num_clients;

// validate inputs, printing errors and exiting if anything is incorrect
if (num_packets == -1 || rate == -1 || rank == -1) {
    <<< "Provide number of packets to send, rate, and rank of server" >>>;
    me.exit();     
}

if (mode != 0 && mode != 1) {
    <<< "Provide mode - multicast (0) or unicast (1)" >>>;
    me.exit();
}

if (rank != 0 && rank != 1) {
    <<< "Provide rank - parent (0) or regular (1)" >>>;
    me.exit();
}

if (mode == 1 && num_clients == -1) {
    <<< "In unicast mode, but did not specify number of clients" >>>;
    me.exit();    
}

9001 => int port;


// unicast mode - configure sockets!
if (mode == 1) {
    for (0 => int i; i < num_clients; i++)
        uxmit[i].setHost(hosts[i], port);
}

sender(mode, num_packets, rate, rank, num_clients);

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
            
            if (packets_sent % 10 == 0)
                <<< "server: multicast - rate: " , rate, " , " , 
                packets_sent , " / ", num_packets >>>;
            
            spike_len => now;
            0.0 => step.next;
            (interval - spike_len) => now;
        }
    }
    
    // unicast mode
    else {        
        while(packets_sent < num_packets) {
            1.0 => step.next;
            
            for (0 => int i; i < num_clients; i++) {
                uxmit[i].startMsg( "/lorknet/interval", "i i s i" );
                mode => uxmit[i].addInt;
                rate $ int => uxmit[i].addInt;
                myname => uxmit[i].addString;
                packets_sent => uxmit[i].addInt;
            }
            
            packets_sent++;
            
            if (packets_sent % 10 == 0)
                <<< "server: unicast - rate: " , rate, " , " , 
                packets_sent , " / ", num_packets >>>;
            
            spike_len => now;
            0.0 => step.next;
            interval - spike_len => now;
        }
    }
    
    // parent server sends signals to kill all clients
    if (rank == 0) {
        <<< "parent: sending kill signal to clients for rate of", rate, "ms" >>>;
        
        // let the dust settle before killing clients
        1500::ms => now;
        
        // multicast kill
        if (mode == 0) {
            for (0 => int i; i < 20; i++) {
                mxmit.startMsg( "/lorknet/interval", "i i s i" );
                6969 => mxmit.addInt;
                6969 => mxmit.addInt;
                "DIE" => mxmit.addString;
                6969 => mxmit.addInt;
                15::ms => now;
                
            }        
        }
        
        // unicast kill
        else {
            for (0 => int i; i < 20; i++) {
                for (0 => int j; j < num_clients; j++) {
                    uxmit[j].startMsg( "/lorknet/interval", "i i s i" );
                    6969 => uxmit[j].addInt;
                    6969 => uxmit[j].addInt;
                    "DIE" => uxmit[j].addString;
                    6969 => uxmit[j].addInt;
                }
                
                15::ms => now;
            }        
        }
        
        // give the next group of servers and clients time to start up
        2000::ms => now;
    }
}

//-----------------------------------------------------------------------------
