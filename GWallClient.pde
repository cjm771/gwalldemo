/***********
GWallClient  (NOT CURRENTLY ACTIVE)
***********/
/*
 * connect to server for realtime interactivity from web (testing)
 *
 * Copyright Chris Malcolm, NBBJ digital 2018
 * http://www.nbbj.com/about/digital-practice/
 *
 */
 
import java.net.Socket;
import processing.net.*; 

class GWallClient {
  
  //WIP...set enabled to true to try it out, make sure you're server is running!
  boolean ENABLED  = false;
  
  Client myClient;
  String dataIn; 
  Socket s = null;
  boolean clientActive = true;
  BufferedReader input;
 
  public GWallClient(PApplet _applet){
      // Connect to the local machine at port xxx.
      // This example will not run if you haven't
      // previously started a server on this port.
     //  wsc= new WebsocketClient(_applet, "ws://localhost:40510/"); 
         if (ENABLED){
           try{
           myClient = new Client(_applet, "127.0.0.1", 45010);
           }catch(Exception e){
             println("error occurred when trying to reach out to server");
             clientActive = false;
            }
         }
}
  

  public void readToConsole(){
      if (ENABLED){
        try{
          if (clientActive && myClient.active() && myClient.available() > 0) {
            dataIn = myClient.readString();
            println(dataIn);
          }
        }catch(Exception e){
           println("error occurred when trying to reach out to server");
           clientActive = false;
        }
      }
}
  
}
