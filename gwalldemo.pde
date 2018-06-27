/***********
  GWALLDEMO
 ***********/
/*
 * main function for running and drawing visualization
 * sets up bacgkround images + visual cells based on a csv file that stores each cell + bounds + id. 
 * visual cells look up id in WallMatrix class, which stores actual shifting data (as two dimensional matrix). if exists then draws rectangle.
 *
 * Copyright Chris Malcolm, NBBJ digital 2018
 * http://www.nbbj.com/about/digital-practice/
 *
 */

import javax.swing.JColorChooser;
import java.awt.Color;
import java.util.ArrayList;
import java.util.Set;
import java.util.Hashtable;
import processing.pdf.*;
import com.google.gson.Gson;

String VERSION = "0.49.2";
float masterX = 1280;
float masterY = 800;
float boundStartX;
float boundStartY;
PImage bg,fg,logo;
PShape worldMap;
PFont font;
Gson jsonParser = new Gson();
boolean animationIsPaused = false;
boolean origAnimationState = false; //used as a store for where its at
String exportFolder = "C:/"; //save folder to export to
int exportMode = 4; //0=start to save, 1=saving has begun, 2=main ended, 3=start control frame, 4=done not saving..
String ts = ""; //current timestamp
PShader blur;
Bounds mainBounds;
Hashtable <String, Bounds> Rects = new Hashtable();

//data structure for wall 
WallMatrix  matrix;
//for client side interaction (WIP)
GWallClient  gwc;
//google trends api lib
GTrends gt =  new GTrends();
boolean loading = true;

void settings() {
  size(1280, 800);
}


/***********
SETUP
***********/

void setup() {
  //15 frames 
   frameRate(15);
   smooth(4);
   //to avoid pdf erros...
   PFont font = createFont("LSANS.TTF",32);
   textFont(font);
   //launch bg images + control panel
   thread("loadImagesAndControlPanel");
  
    gt.APIKEY = getAPIKey();

   //lets init our gwallclient so we can read input coming in from the server (CURRENTLY DISABLED)
    gwc = new GWallClient(this);
    
    //finally we'll do initial queries, and supply callback to run
    thread("doQueries");

}

public String getAPIKey(){
       //load apikey offsite
      try{
      String[] lines = loadStrings(dataPath("gapi.key"));
      return lines[0];
      }catch(Exception e){
        log(new Object[]{"Error! ", e});
      }
      return "";
 }

public void loadImagesAndControlPanel(){
  //run seperate window for controls
  worldMap = loadShape("world_map_e.svg");
  win = new ControlFrame(this, 400, 800, "Controls");
  
  //init window + pan settings
  lastPan = new float[]{xPan,yPan};
  surface.setLocation(420, 30);
  surface.setTitle("Visual Panel");
  surface.setResizable(true);

  //store ratio of image for scaling 
   
  //background image init
   bg = loadImage("L1-L2Stair_PrototypeGrid_bg-01.png"); 
   bg.filter(INVERT);
   fg = loadImage("L1-L2Stair_PrototypeGrid_fg-01-01.png"); 
   logo = loadImage("nbbjDigital.png"); 
   fg.filter(INVERT);
   loading = false;
}

  //folder browser..unfortunately have to do outside of controlframe
  public void doFolderRoutine(){
      selectFolder("Select a folder to export to:", "folderSelected");
  }  

    
  //folder selected callback (used by controlframe)
    public void folderSelected(File selection) {
    if (selection == null) {
      println("Window was closed or the user hit cancel.");
      win.endSaveRoutine();
    } else {
      //save export folder...
      exportFolder =  selection.getAbsolutePath();
      //toggle export mode
      exportMode = 0; //will save next frame.
      println("User selected " + selection.getAbsolutePath());
    }
    animationIsPaused = origAnimationState;
  }

/***********
QUERIES ROUTINE 
***********/

//uses gtrends api to query server

//popularity query
public void popQuery(){
    //query seattle popularity on may 1
    JSONObject googleResp = gt.queryPopularity(textValue, -1, "", gt.previousMonth(reformattedDate),reformattedDate, searchDate);
    if (googleResp.getString("status")=="success"){
      //we got data
      if (matrix!=null)
        matrix.popularityFactor = (float)gt.clampedCurrentDateValue/(float)100;
    }else{
      //print out the error
      log(new Object[]{googleResp.getString("status"), " when querying trends api: ", googleResp.getString("message")});
    }
    //toggle as initalized
     if (gt.initPopQuery==0){
         gt.initPopQuery=1;
     }else if (gt.initPopQuery==3){
       gt.initPopQuery=2;
     }
}

//perform category query
public void catQuery(){
       //then do category breakdown
       gt.getCategoryBreakdown(textValue, "", reformattedDate,reformattedDate, searchDate);
       //toggle as initalized
       if (gt.initCatQuery==0){
         gt.initCatQuery=1;
       }else if  (gt.initCatQuery==3){
        gt.initCatQuery=2;
     }
}

//perform hot topics query
public void topicQuery(){
    //query topics
    JSONObject googleResp = gt.queryTopTopics(textValue, searchDate,searchDate);
    if (googleResp.getString("status")=="success"){
      //log(new Object[]{"hot topics boiii", gt.getHotTopics()});
    }
    
}

//perform region query
public void regionQuery(){
    JSONObject regionDataResp = gt.queryRegions(textValue, "", reformattedDate,reformattedDate);
    //see what we get from the server
    if (regionDataResp.getString("status")=="success"){
      if (matrix!=null){
        matrix.lengthRange = gt.countryBarRange;
      }
    }else{
      //print out the error
      log(new Object[]{regionDataResp.getString("status"), " when querying trends api: ", regionDataResp.getString("message")});
    }
    //toggle as initalized
     if (gt.initRegionQuery==0){
         gt.initRegionQuery=1;
     }else if(gt.initRegionQuery==3){
        gt.initRegionQuery=2;
     }

}

//run all queries on seperate threads 
public void doQueries(){

    thread("popQuery");
    thread("regionQuery");
    thread("catQuery");
    thread("topicQuery");


}




public int[] parseIdStrToIntArr(String idStr){
  int[] idArr = new int[2];
  String[] pieces = idStr.split(":");
  for (int i = 0; i<pieces.length; i++){
    idArr[i] = Integer.parseInt(pieces[i]);
  }
  return idArr;
}

/***********
LOGGING Routines 
***********/

//a simpler logging method


//myultiple object
void log(Object[] args){
  //disble enable logging
  boolean logging = true;
  if (logging){
    for (int i=0; i<args.length; i++){
      if (args[i] instanceof String){
         print(args[i]+" ");
      }else{
        print(jsonParser.toJson(args[i])+" ");
      }
    }
    println();
  }
}


//single object overload
void log(Object args){
  log(new Object[]{args});
}
//single object overload
void _log(Object[] args){
  log(args);
}

/***********
RECTANGLE GRID DATA
***********/

//uses gtrends api to query server


void initRectangleData(){
  
  //read csv
  String[] rows = loadStrings("pixel_grid.csv");
  int[] mainBoundsRowColTotals = new int[2];
  for (String row : rows){
  
    String[] cells = split(row, ",");
    if (cells[0].contains("Rect")){
      Rects.put(cells[5],  new Bounds(Float.parseFloat(cells[1]),  Float.parseFloat(cells[2]),  Float.parseFloat(cells[3]),  Float.parseFloat(cells[4])));
  }else if (cells[0].contains("Bounds")){
    
      mainBounds = new Bounds( Float.parseFloat(cells[1]),  Float.parseFloat(cells[2]),  Float.parseFloat(cells[3]),  Float.parseFloat(cells[4])); 
      mainBoundsRowColTotals = parseIdStrToIntArr(cells[5]);
    }
  }
  //we add one because we want totals not index
  matrix = new WallMatrix(
        mainBoundsRowColTotals[0]+1,
        mainBoundsRowColTotals[1]+1, 
        map(gt.clampedCurrentDateValue,0,100,0,1),
        gt.countryBarRange, 
        gt.getCategoryRatiosAsArray(), 
        new color[]{mainColors[0], mainColors[1]}, 
        new color[]{mainColors[2], mainColors[3]}
  );
  
}

int drawRectIfExists(String key,color prevColor){
      //set scale per rectangle
   // print(rect)
   if (matrix.cellExists(key) && Rects.containsKey(key)){
     MatrixCell currentCell;
     Bounds rect = Rects.get(key);
     rect.setBounds(mainBounds);
     //draw it if it exists          
     currentCell = matrix.getCell(key);
     color prevColorToDraw =   (prevColor==-999999) ? matrix.getColor(currentCell) : prevColor;
     rect.drawGlow(currentCell, prevColorToDraw);
     rect.drawRect(currentCell, prevColorToDraw);
     //if this is new color then return prevColor
     return (currentCell.pixelId==0 || prevColor==-999999) ? matrix.getColor(currentCell) : prevColor;
     }else{
       return prevColor;
     }
     
      
}

void drawRectangles(){

  color prevColor = -999999;
  for (int colIndex=0; colIndex<matrix.totalColumns; colIndex++){
    if (matrix.ANIMATION_MODE.equals("up")){
      for (int rowIndex=matrix.totalRows-1; rowIndex>=0; rowIndex--){
            prevColor = drawRectIfExists(matrix.getIdStr(rowIndex, colIndex), prevColor);     
      }
    }else{
     for (int rowIndex=0; rowIndex<=matrix.totalRows-1; rowIndex++){
          prevColor = drawRectIfExists(matrix.getIdStr(rowIndex, colIndex), prevColor);     
      }
    }
  }
  
  
  
  /*
  Set<String> keys = Rects.keySet();
  for (String key: keys){
    //set scale per rectangle
   // print(rect)
     Bounds rect = Rects.get(key);
     rect.setBounds(mainBounds);
     //draw it if it exists          
     if (matrix.cellExists(key)){
       rect.drawGlow(matrix.getCell(key));
       rect.drawRect(matrix.getCell(key));
     }else{
       if (frameCount==1)
         log(new Object[]{"cell exist?", key, matrix.cellExists(key)});
     }
     
  }
  */
}

public void drawSketches(){
  int[] tmpCoords = new int[]{}; 
  float[] range= new float[]{500, 20}; //100- millis = black , 20+ millis = white
   int timePassed = 0;
  //if we're drawing a sketch
  if (gwc.drawingASketch>=1){
     //look at current pixel id
     //get millis passed
     int lastKnownIndex = 0; 
     timePassed = millis()-gwc.sketchStartedAt;
     boolean timeToFade = false;
     int timeLeft = 0;
      if (gwc.drawingASketch==2){ //fade out init
         if (gwc.fadeOutStart == 0){
           gwc.fadeOutStart = millis();
         }
         timeLeft = gwc.waitUntilFade+gwc.fadeOutAnimLength-(millis()-gwc.fadeOutStart);
      }
     for (int i=0; i<gwc.currentSketch.size(); i++){
       
       //get item
       JSONObject currentItem = gwc.currentSketch.getJSONObject(i);
       int rowIndex = currentItem.getJSONArray("coord").getInt(1);
        int colIndex = currentItem.getJSONArray("coord").getInt(0);
       //time constraints, if its 0 and 0 time has passed if its 20 now and 0 was drawn 20 seconds ago
       //first wee see if time has passed yet to render this guy..if not skip
       
       lastKnownIndex = (timePassed-currentItem.getFloat("timestamp")>0) ? i : lastKnownIndex;
       
       if (timePassed>=currentItem.getFloat("timestamp") && gwc.drawingASketch==1){ //drawing..
         
         int alphaVal = (int)map(constrain(timePassed-currentItem.getFloat("timestamp"), range[1], range[0]), range[1], range[0],0, 255);
         String key = matrix.getIdStr(rowIndex, colIndex);
         if (Rects.containsKey(key)){
           Bounds rect = Rects.get(key);
           rect.renderGlow(color(255,255,255, alphaVal));
           rect.renderRect(color(255,255,255, alphaVal));
         }
         timeToFade = lastKnownIndex>=gwc.currentSketch.size()-1;
         if (timeToFade){
           gwc.drawingASketch=2;
         }
       }else if (gwc.drawingASketch==2){ //fade out
          
           int alphaVal = (int)map(constrain(timeLeft, 0, gwc.fadeOutAnimLength), 0, gwc.fadeOutAnimLength,0, 255);
            //log(new Object[]{"time left:", timeLeft,"alphaval:",alphaVal});
           String key = matrix.getIdStr(rowIndex, colIndex);
           if (Rects.containsKey(key)){
             Bounds rect = Rects.get(key);
             rect.renderGlow(color(255,255,255, min(0,alphaVal-30)));
             rect.renderRect(color(255,255,255, alphaVal));
           }
           if (timeLeft<=0){
             gwc.drawingASketch=0;
             gwc.fadeOutStart = 0;
           }
       }
       
     }
}else if (gwc.sketchesToDo.size()>0){
    gwc.drawingASketch=1;
    gwc.currentSketch = gwc.sketchesToDo.get(0);
    gwc.sketchesToDo.remove(0);
    gwc.sketchStartedAt = millis();
  }
}

 public color[] generateColorRange(color c1,color c2, int steps){
       color[] colorArr = new color[steps];
       for (int i=0; i<steps; i++){
           //generate 
           int[] rgbVals = new int[]{
             (int)(red(c1)+((red(c2)-red(c1))/steps)*i),
             (int)(green(c1)+((green(c2)-green(c1))/steps)*i),
             (int)(blue(c1)+((blue(c2)-blue(c1))/steps)*i)};
           colorArr[i] =  color(rgbVals[0],rgbVals[1],rgbVals[2]);
          
       }
       return colorArr;
    }

public PImage drawBackgroundImage(PImage img){
    float ratio = float(img.height)/float(img.width);
    image(img, 0, 0, width, width*ratio);
     return img;
}


//draw loading routin4
public void drawLoadingRoutine(){
    textSize(33);
    String loadingText = "Loading";
    int frameLoadDelay=30;
    int frameModule=frameLoadDelay/5;
    for (int i=0; i<(int)(frameCount%frameLoadDelay)/frameModule; i++){
      loadingText+=".";
    }
     frameLoadDelay=100;
     frameModule=frameLoadDelay/20;
    for (int i=0; i<(int)(frameCount%frameLoadDelay)/frameModule; i++){
      fill(map(i, 0,3,100,255));
    }
    
    text(loadingText,width/2-60, height/2);
}
 
 public String getTimestamp(){
     int s = second();  // Values from 0 - 59
    int m = minute();  // Values from 0 - 59
    int h = hour();    // Values from 0 - 23
    return h+"-"+m+"-"+s;
 }
/***********
DRAW FUNCTIONALITY
***********/

void testFrameRate(){
   log(new Object[]{"frame rate: ",frameRate});
}

void draw() {
  //check if we need to do an export routine
   //testFrameRate();
  if (exportMode==0){

   log(new Object[]{"saving to.."+exportFolder});
    ts = getTimestamp();
   beginRecord(PDF, exportFolder+"/"+ts+"-main.pdf");
   win.beginRecord(PDF, exportFolder+"/"+ts+"-controlFrame.pdf");
   exportMode = 1; //start export
  }
  if (exportMode==1 || exportMode==4){ //starting save or typical routine not exporting...
    if (loading){
      background(0);
      drawLoadingRoutine();
    }else if (gt.initPopQuery==0 || gt.initCatQuery==0 || gt.initRegionQuery==0){
    //still not ready..
       background(0);
      drawLoadingRoutine();
    }else if (gt.initPopQuery==1 || gt.initCatQuery==1 || gt.initRegionQuery==1){ //FIRST INIT
      //ready to init matrix..
      initRectangleData();
      gt.initPopQuery=3; 
      gt.initCatQuery=3;
      gt.initRegionQuery=3;
    }else if (gt.initPopQuery==2 || gt.initCatQuery==2 || gt.initRegionQuery==2){ //CHANGE to date occurred after init
      //update state + stuff for existing
      matrix.handleDayChange();
      //recolorize matrix (for unseen bars + major changes
      matrix.currentMatrix = matrix.reColorizeMatrix(matrix.currentMatrix);
      gt.initPopQuery=3; 
      gt.initCatQuery=3;
      gt.initRegionQuery=3;
    }else{ //typical state
        translate(width/2, height/2);
        scale(scale);
        translate(-xPan, -yPan);
        background(0);
        //do shifting animation
        if (!animationIsPaused){ 
          matrix.shift();
        }
      
      //listen to server
      gwc.readToConsole();
      
      //draw bg
      tint(255,150);
      //drawBackgroundImage(bg);
      drawRectangles();
      drawSketches();
      tint(255,100);
      //drawBackgroundImage(fg);
    }
  }
  if (exportMode==1){ //check if we need to do end export routine   
      endRecord();
      exportMode = 2; //set to start the control frame export
    }

}

/*********
BOUNDS CLASS
**********/

class Bounds { 
  float tlX,io,tlY,brY,brX, xRatio;
  PGraphics pg;

  public float getWidth(){
    return abs(brX-tlX);
  }
  
  public float[] getCenter(){
    return new float[]{tlX+getWidth()/2,
    tlY-getHeight()/2};
  }
  
  public void setBounds(Bounds _b){
      xRatio = width/_b.getWidth();
      boundStartX = _b.tlX;
      boundStartY = _b.tlY;
  }
  public float getHeight(){
    return abs(brY-tlY);
  }
  
  //normalize color(brightness=100)
  public color normalize(color c){
      colorMode(HSB, 255);
      c = color(hue(c), saturation(c), 100);
      colorMode(RGB, 255);
      return c;
  }
  
  //brighten color depending on percentage
  public color brightenColor(color c, float amount){
    //normalize color
    c = normalize(c);
    colorMode(HSB, 255);
    c = color(hue(c), saturation(c), min(255, round(amount*255)));
    colorMode(RGB, 255);
    return c;
  }
  
  
  public void _renderRect(){
     rect((tlX)*xRatio,(tlY)*xRatio*-1,getWidth()*xRatio, getHeight()*xRatio);
  }

  
  
  //get color
  public color getColor(MatrixCell cell){
   color c;
    if (cell.isWarm){
      c = warmColorRange[cell.colorIndex];
    }else{
      c = coolColorRange[cell.colorIndex];
    }
    return c;
    
  }
  
  public void renderGlow(color c){
    noFill();
    //color c = getSmoothenedColor(cell,prevColor, 4); //smooth color with next ..tail length 2  noFill();
    float[] brightness = new float[]{1,1,1}; //original 1,1,1
    int[] weights = new int[]{4,9,16}; //original 4,9,16
    float[] alpha = new float[]{0.15,0.05,0.01}; //original 0.15,0.05,.01
    stroke(brightenColor(c,brightness[2]),map(alpha[2], 0,1,0,255));
    strokeWeight(weights[2]);
    _renderRect();
    stroke(brightenColor(c,brightness[1]),map(alpha[1], 0,1,0,255));
    strokeWeight(weights[1]);
   _renderRect();
    stroke(brightenColor(c,brightness[0]),map(alpha[0], 0,1,0,255));
    strokeWeight(weights[0]);
   _renderRect();
   noStroke();
  }
  //draws glow
  public void drawGlow(MatrixCell cell, color prevColor){
    
    color c = getColor(cell);
    renderGlow(c);
  }
  
  //smoothens color at tail
  public color getSmoothenedColor(MatrixCell cell, color prevColor, int tailLength){
    color c1,c2;
    
    //0 is tail..1 is one after tail..
    int tailIndex = cell.pixelLength-cell.pixelId;
    if (tailIndex<tailLength){
      c1 = getColor(cell);
      c2 = prevColor;
      int[] tailColorRange = generateColorRange( c2, c1, tailLength+2); //add two to 
      tailColorRange = java.util.Arrays.copyOfRange(tailColorRange, 1, tailColorRange.length-1); //slice off the end conditions
      return tailColorRange[tailIndex];
    
    }else{
      return getColor(cell);
    }
  }
  public void renderRect(color c){
     noStroke();
    fill(c);
    _renderRect();
    fill(255);
  }
  //draws cell
  public void drawRect(MatrixCell cell, color prevColor){
    color c = getColor(cell);
    renderRect(brightenColor(c,map(cell.pixelId, 0, cell.pixelLength, 1,.85)));
    //textSize(.45); //this causes weird errors..but shouldnet need this its for debugging.
    //text(cell.verticalBarId, getCenter()[0]*xRatio, getCenter()[1]*xRatio*-1);
  }
  public Bounds(float _tlX, float _tlY, float _brX, float _brY) {
    xRatio = 1;
    tlX = _tlX;
    tlY = _tlY;
    brX = _brX;
    brY = _brY;
   
  }
}
