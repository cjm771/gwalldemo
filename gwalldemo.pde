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
import com.google.gson.Gson;

String VERSION = "0.35.2";
float masterX = 1280;
float masterY = 800;
float boundStartX;
float boundStartY;
PImage bg,fg,logo;
PShape worldMap;
PFont font;
Gson jsonParser = new Gson();
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
   smooth();
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
/***********
QUERIES ROUTINE 
***********/

//uses gtrends api to query server

//popularity query
public void popQuery(){
    //query seattle popularity on may 1
    JSONObject googleResp = gt.queryPopularity(textValue, -1, "", reformattedDate,reformattedDate, searchDate);
    if (googleResp.getString("status")=="success"){
      //we got data
      if (matrix!=null)
        matrix.popularityFactor = (float)gt.currentDateValue/(float)100;
    }else{
      //print out the error
      log(new Object[]{googleResp.getString("status"), " when querying trends api: ", googleResp.getString("message")});
    }
    //toggle as initalized
     if (gt.initPopQuery==0)
         gt.initPopQuery=1;
}

//perform category query
public void catQuery(){
       //then do category breakdown
       gt.getCategoryBreakdown(textValue, "", reformattedDate,reformattedDate, searchDate);
       //toggle as initalized
       if (gt.initCatQuery==0)
         gt.initCatQuery=1;
}

//perform region query
public void regionQuery(){
    JSONObject regionDataResp = gt.queryRegions(textValue, "", reformattedDate,reformattedDate);
    //see what we get from the server
    if (regionDataResp.getString("status")=="success"){
      //we got data
      //log(new Object[]{googleResp.getString("status"), googleResp.getJSONObject("data")});
      log(new Object[]{"country_value: ", gt.countryValue});
      //we got data
      if (matrix!=null){
        matrix.lengthRange = gt.countryBarRange;
         log(new Object[]{"current bar range:",matrix.lengthRange});
      }
    }else{
      //print out the error
      log(new Object[]{regionDataResp.getString("status"), " when querying trends api: ", regionDataResp.getString("message")});
    }
    //toggle as initalized
     if (gt.initRegionQuery==0)
         gt.initRegionQuery=1;

}

//run all queries on seperate threads 
public void doQueries(){

    thread("popQuery");
    thread("regionQuery");
    thread("catQuery");

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
        map(gt.currentDateValue,0,100,0,1),
        gt.countryBarRange, 
        gt.getCategoryRatiosAsArray(), 
        new color[]{mainColors[0], mainColors[1]}, 
        new color[]{mainColors[2], mainColors[3]}
  );
  
}

void drawRectangles(){


  Set<String> keys = Rects.keySet();
  for (String key: keys){
    //set scale per rectangle
   // print(rect)
     Bounds rect = Rects.get(key);
     rect.setBounds(mainBounds);
     //draw it if it exists          
     if (matrix.cellExists(key)){
       
       rect.drawRect(matrix.getCell(key));
     }else{
       if (frameCount==1)
         log(new Object[]{"cell exist?", key, matrix.cellExists(key)});
     }
     
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
 
/***********
DRAW FUNCTIONALITY
***********/


void draw() {
  if (loading){
    background(0);
    drawLoadingRoutine();
  }else if (gt.initPopQuery==0 || gt.initCatQuery==0 || gt.initRegionQuery==0){
  //still not ready..
     background(0);
    drawLoadingRoutine();
  }else if (gt.initPopQuery==1 || gt.initCatQuery==1 || gt.initRegionQuery==1){
    //ready to init matrix..
    initRectangleData();
    gt.initPopQuery=2; 
    gt.initCatQuery=2;
    gt.initRegionQuery=2;
  }else{
    translate(width/2, height/2);
    scale(scale);
    translate(-xPan, -yPan);
    
    background(0);
    //do shifting animation
    matrix.shift();
    
    //listen to server
    gwc.readToConsole();
    
    //draw bg
    tint(255,150);
    drawBackgroundImage(bg);
    drawRectangles();
    tint(255,100);
    drawBackgroundImage(fg);
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
  
  public void setBounds(Bounds _b){
      xRatio = width/_b.getWidth();
      boundStartX = _b.tlX;
      boundStartY = _b.tlY;
  }
  public float getHeight(){
    return abs(brY-tlY);
  }
  public color brightenColor(color c, int amount){
    colorMode(HSB, 255);
    float v = brightness(c);
    c = color(hue(c), saturation(c), min(255, v+amount));
    colorMode(RGB, 255);
    return c;
  }
  public void drawRect(MatrixCell cell){
   
    noFill();
    color c;
    if (cell.isWarm){
      c = warmColorRange[cell.colorIndex];
    }else{
      c = coolColorRange[cell.colorIndex];
    }
     stroke(brightenColor(c,20),4);
    strokeWeight(16);
    rect((tlX)*xRatio,(tlY)*xRatio*-1,getWidth()*xRatio, getHeight()*xRatio);
    stroke(brightenColor(c,50),15);
    strokeWeight(9);
    rect((tlX)*xRatio,(tlY)*xRatio*-1,getWidth()*xRatio, getHeight()*xRatio);
    stroke(brightenColor(c,150),40);
    strokeWeight(4);
    rect((tlX)*xRatio,(tlY)*xRatio*-1,getWidth()*xRatio, getHeight()*xRatio);
    noStroke();
    fill(brightenColor(c,60));
    rect((tlX)*xRatio,(tlY)*xRatio*-1,getWidth()*xRatio, getHeight()*xRatio);

  }
  public Bounds(float _tlX, float _tlY, float _brX, float _brY) {
    xRatio = 1;
    tlX = _tlX;
    tlY = _tlY;
    brX = _brX;
    brY = _brY;
   
  }
}
