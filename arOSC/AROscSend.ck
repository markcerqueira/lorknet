public class AROscSend {
    3 => int MIN_RATE;
    30 => int MAX_RATE;
    
    OscSend packets[MAX_RATE];
    
    int m_portSend;
    int m_portListen;
    
    Std.getenv("NET_NAME") + ".local" => string myName;

    MIN_RATE => int m_numCopies;
    Std.rand2(1, 255) => int m_seqID;
    0 => int m_lastRateSeq;

    fun void setHost(string hostname, int port) {
        for (0 => int i; i < packets.size(); i++)
            packets[i].setHost(hostname, port);
        
        port => m_portSend;
        (port + 1) => m_portListen;
                
        spork ~ listenRateChange();
    }
    
    fun void startMsg(string msg, string args) {
        for (0 => int i; i < m_numCopies; i++) {
            packets[i].startMsg(msg, "s, i, i, " + args);
            packets[i].addString(myName);
            packets[i].addInt(m_seqID);
            packets[i].addInt(m_numCopies);
        }

        m_seqID++;
    }
    
    fun void listenRateChange() {
        OscRecv recv;
        m_portListen => recv.port;
        recv.listen();
        recv.event("RateChange, i i") @=> OscEvent oe;
        
        while (true) {
            oe => now;

            while (oe.nextMsg() != 0) { 
                oe.getInt() => int seqID;
                oe.getInt() => int changeFactor;
                
                if (seqID != m_lastRateSeq) {                    
                    if (changeFactor == -1 && m_numCopies >= MIN_RATE)
                        m_numCopies--;
                    if (changeFactor == 1 && m_numCopies <= MAX_RATE)
                        m_numCopies++;
                    
                    seqID => m_lastRateSeq;
                }
            }
        }    
    }
    
    fun void addString(string add) {
        for (0 => int i; i < m_numCopies; i++)
            packets[i].addString(add);  
    }
    
    fun void addInt(int add) {
        for (0 => int i; i < m_numCopies; i++)
            packets[i].addInt(add);  
    }
    
    fun void addFloat(float add) {
        for (0 => int i; i < m_numCopies; i++)
            packets[i].addFloat(add);  
    }
}