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
  boolean ENABLED  = true;
  
  Client myClient;
  String dataIn; 
  Socket s = null;
  boolean clientActive = true;
  BufferedReader input;
  ArrayList<JSONArray>  sketchesToDo = new ArrayList<JSONArray>();
  JSONArray currentSketch = new JSONArray(); //current sketch drawing
  
  int pixelIndex = 0; //where the pixel is at
  int sketchStartedAt = 0; //when we started drawing sketch
  boolean drawingASketch = false; //are we drawing a sketch?
  
  public GWallClient(PApplet _applet){
    
   
      // Connect to the local machine at port xxx.
      // This example will not run if you haven't
      // previously started a server on this port.
     //  wsc= new WebsocketClient(_applet, "ws://localhost:40510/"); 
         if (ENABLED){
           try{
           myClient = new Client(_applet, "127.0.0.1", 45010);
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
