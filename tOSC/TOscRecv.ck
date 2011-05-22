// TOscRecv.ck
// Author: Mark Cerqueira

public class TOscRecv
{
    int portListen;
    
    OscRecv recv;
    OscEvent oe;
    
    fun void port(int portNum)
    {
        portNum => portListen;
        portNum => recv.port;
    }
    
    fun void listen()
    {
        recv.listen();
    }
    
    fun void event(string msg)
    {
       StringTokenizer tok;
       tok.set(msg);
       
       tok.next() => string msgSeqID;
       " s f f " +=> msgSeqID;
       
       while(tok.more())
           tok.next() + " " +=> msgSeqID;
       
       recv.event(msgSeqID) @=> oe;  
    }
    
    fun float nextMsg(float myTime)
    {
        if (oe.nextMsg() != 0)
        {
            oe.getString() => string host;
            oe.getFloat() => float currentTime;
            oe.getFloat() => float TTO;

            return (currentTime + TTO - myTime);
        }
        
        else
            return 0.0;        
    }
    
    fun int getInt()
    {
        return oe.getInt();
    }
    
    fun float getFloat()
    {
        return oe.getFloat();
    }
    
    fun string getString()
    {
        return oe.getString();
    }    
}