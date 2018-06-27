/***********
GWallClient  
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
import java.util.ArrayList;

class GWallClient {
  
  //WIP...set enabled to true to try it out, make sure you're server is running!
  boolean ENABLED  = false;
  
  Client myClient;
  String dataIn; 
  Socket s = null;
  boolean clientActive = true;
  BufferedReader input;
  ArrayList<JSONArray>  sketchesToDo = new ArrayList<JSONArray>();
  JSONArray currentSketch = new JSONArray(); //current sketch drawing
  
  int pixelIndex = 0; //where the pixel is at
  int sketchStartedAt = 0; //when we started drawing sketch
  int fadeOutStart  = 0; //fade out timetstamp start, 0 means not init'd
  int waitUntilFade = 1000; //500 millis
  int fadeOutAnimLength = 1000; //500 millis 
  int drawingASketch = 0; //are we drawing a sketch? 0=no, 1=done ..to fade mode, 2=finish, back to 0
  
  public GWallClient(PApplet _applet){
    
   
      // Connect to the local machine at port xxx.
      // This example will not run if you haven't
      // previously started a server on this port.
         if (ENABLED){
           try{
           myClient = new Client(_applet, "localhost", 45010);
           //myClient = new Client(_applet, "gwall-server.now.sh", 443);
           log(new Object[]{"client info:", "active:", myClient.active()});
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
            String[] lines=dataIn.split("\n");
            for (int i=0; i<lines.length; i++){
              try{
                sketchesToDo.add(parseJSONArray(lines[i]));
                log(new Object[]{"current sketches:", sketchesToDo});
              }catch(Exception e){
                log(new Object[]{"coud not parse data..(",lines[i],")", "\nError:",e});
              }
            }
          }
        }catch(Exception e){
           println("error occurred when trying to reach out to server");
           clientActive = false;
        }
      }
}
  
}
