// NTPClient.ck
// Author: Mark Cerqueira

public class NTPClient
{
    Std.getenv("NET_NAME") + ".local" => string myName;
    
    int port_timeRequest, port_timeReplies, port_RTTinfo, port_RTTget;
    
    1000.0 => float TimeToExecute;
    
    OscRecv recv;
    OscEvent oe;
    
    OscSend send;
    
    float RTT, offset;
    
    string host;
    
    fun void setHost(string hostname, int port) {
        send.setHost(hostname, port);
        
        port_timeReplies => recv.port;
        
        hostname => host;
        
        port => port_timeRequest;
        (port + 1) => port_timeReplies;
        (port + 2) => port_RTTinfo;
        (port + 3) => port_RTTget;
        
        spork ~ requestTime();
        spork ~ getTime();
        spork ~ getRTT();
    }
    
    fun void requestTime() {                
        while(true) {
            send.startMsg("/ntp/request", "s f");
            send.addString(myName);
            send.addFloat(now/samp);
            
            1::second => now;
        }
    }
    
    fun void getTime() {
        OscRecv timeGetter;
        port_timeReplies => timeGetter.port;
        timeGetter.listen();
        timeGetter.event("/ntp/reply, s f f") @=> OscEvent toe;
        
        OscSend RTTdata;
        RTTdata.setHost(host, port_RTTinfo);
        
        while(true) {
            toe => now;
            
            while (toe.nextMsg() != 0) {
                now / samp => float timeReplyReceived;
                
                toe.getString() => string host;
                toe.getFloat() => float timeRequestSent;
                toe.getFloat() => float serverTime;
                
                timeReplyReceived - timeRequestSent => RTT;
                serverTime - timeRequestSent => offset;
                
                RTTdata.startMsg("/ntp/rtt", "s f");
                RTTdata.addString(myName);
                RTTdata.addFloat(RTT);
            }
        }
    }
    
    fun void getRTT() {
        OscRecv RTTget;
        port_RTTget => RTTget.port;
        RTTget.listen();
        RTTget.event("/ntp/tto, f") @=> OscEvent roe;
        
        while(true) {
            roe => now;
            
            while (roe.nextMsg() != 0)
                roe.getFloat() => TimeToExecute;
        }
    }
    
    fun time currentTime() {
        return (now + offset*samp + .5 * RTT*samp);
    }
    
    fun float getTTO() {
       return TimeToExecute; 
    }
}
