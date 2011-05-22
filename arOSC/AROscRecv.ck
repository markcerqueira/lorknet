public class AROscRecv {
   5 => int MIN_RATE;
   30 => int MAX_RATE; 
    
   string m_clientList[0]; 
   int m_lastSeqIDs[0];
   
   int m_portListen;
   int m_portSend;
   int seenCopies;
   
   OscRecv recv;
   OscEvent oe;
   
   fun void port(int portNum) {
       portNum => m_portListen;
       (portNum + 1) => m_portSend;
       portNum => recv.port;
   }
    
   fun void listen() {
       recv.listen();
   } 
   
   fun void event(string msg) {
       StringTokenizer tok;
       tok.set(msg);
       
       tok.next() => string msgSeqID;
       " s i i " +=> msgSeqID;
       
       while(tok.more())
           tok.next() + " " +=> msgSeqID;
       
       recv.event(msgSeqID) @=> oe;   
   } 
   
   fun int nextMsg() {
       0 => int isOnList;
       
       if (oe.nextMsg() != 0) {
           oe.getString() => string clientName;
           oe.getInt() => int seqID;
           oe.getInt() => int expectedCopies;
                      
           for (0 => int i; i < m_clientList.size(); i++)
               if (clientName == m_clientList[i])
                   1 => isOnList;
               
           if (isOnList == false) {
               m_clientList << clientName; 
               seqID => m_lastSeqIDs[clientName];
               1 => seenCopies;
               
               return 1;          
           }
           
           if (isOnList == true) {
               m_lastSeqIDs[clientName] => int lastSeqID;
               
               if (lastSeqID == seqID) {
                   seenCopies++;
                   return 0;
               }

               if ((lastSeqID + 1) != seqID) {
                   <<< "Requesting more from ", clientName >>>;
                   rateChange(clientName, m_portSend, 1);
               }
                  
               seqID => m_lastSeqIDs[clientName];

               if (seenCopies == expectedCopies && expectedCopies > 3) {
                   <<< "Requesting less from ", clientName >>>;
                   rateChange(clientName, m_portSend, -1);
               }
               
               1 => seenCopies;
               
               return 1; 
           }
       }
   } 
   
   fun void rateChange(string client, int port, int changeFactor) {
       OscSend xmit;
       string clientName;

       xmit.setHost(client, port);
       xmit.startMsg("RateChange", "i i");
       Std.rand2(1, 65535) => int randInt;
       
       for (0 => int i; i < 10; i++) {
           randInt => xmit.addInt;  
           changeFactor => xmit.addInt;
       }
   }
   
   fun int getInt() {
       return oe.getInt();
   }
   
   fun float getFloat() {
       return oe.getFloat();
   }
   
   fun string getString() {
       return oe.getString();
   }
}