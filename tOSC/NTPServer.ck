// NTPServer.ck
// Author: Mark Cerqueira

public class NTPServer
{
    int port_timeRequest, port_timeReplies, port_RTTinfo, port_RTTbroadcast;
    
    0 => int RTTreported;
    0.0 => float RTTsum;
    
    1000.0 => float TTO;
    
    OscRecv recv;
    OscEvent oe;
    
    OscSend TTOsend;
    
    fun void port(int portNum) {
        portNum => port_timeRequest;
        (portNum + 1) => port_timeReplies;
        (portNum + 2) => port_RTTinfo;
        (portNum + 3) => port_RTTbroadcast;
        
        TTOsend.setHost("224.0.0.1", port_RTTbroadcast);
        
        portNum => recv.port;
        
        spork ~ listen();
        spork ~ RTTlisten();
        spork ~ broadcastTTO();
    }
    
    fun void listen() {
        recv.listen();
        recv.event("/ntp/request, s f") @=> oe;
        
        OscSend send;
        
        while (true)  {
            oe => now;
            
            while(oe.nextMsg() != 0)  {
                oe.getString() => string host;
                oe.getFloat() => float clientTime;
                
                send.setHost(host, port_timeReplies);
                send.startMsg("/ntp/reply", "s f f");
                
                host => send.addString;
                clientTime => send.addFloat;
                now / samp => send.addFloat;
            }
        }
    }
    
    fun void RTTlisten() {
        OscRecv recv;
        port_RTTinfo => recv.port;
        recv.listen();
        recv.event("/ntp/rtt, s f") @=> OscEvent roe;
        
        while (true) {
            roe => now;
            
            while (roe.nextMsg() != 0) {
                roe.getString() => string host;
                roe.getFloat() => float RTT;
                
                RTT + RTTsum => RTTsum;
                1 +=> RTTreported;
                
                if (RTTsum/RTTreported < .2 * TTO && RTTreported > 3) {
                    Math.round(TTO * 0.5) => TTO;
                    broadcastTTO();
                }
               
                if (RTTsum/RTTreported > .6 * TTO && RTTreported > 3) {
                    Math.round(TTO * 2.0) => TTO;
                    broadcastTTO();
                }
            }
        }        
    }
    
    fun void broadcastTTO() {
        while (true) {
            TTOsend.startMsg("/ntp/tto", "f");
            TTOsend.addFloat(TTO); 
            
            10::second => now;   
        }      
    }
    
    fun time currentTime() {
        return now;   
    } 
    
    fun float getTTO() {
        return TTO;
    }
    
    fun float avgRTT() {
        return RTTsum/RTTreported;
    }
}
