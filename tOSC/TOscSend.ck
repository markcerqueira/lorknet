// TOscSend.ck
// Author: Mark Cerqueira

public class TOscSend
{
    Std.getenv("NET_NAME") + ".local" => string myName;
    
    OscSend send;
    
    int portSend;
    
    string host;
    
    fun void setHost(string hostname, int port)
    {
        send.setHost(hostname, port);
        
        hostname => host;
        port => portSend;
    }
    
    fun void startMsg(string msg, string args, float currentTime, float TTO)
    {
        send.startMsg(msg, "s, f, f, " + args);
        send.addString(myName);
        send.addFloat(currentTime);
        send.addFloat(TTO);
    }
    
    fun void addString(string add)
    {
        send.addString(add);
    }
    
    fun void addFloat(float add)
    {
        send.addFloat(add);
    }
    
    fun void addInt(int add)
    {
        send.addInt(add);
    }
        
}