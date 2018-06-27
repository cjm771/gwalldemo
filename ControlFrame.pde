/***********
 CONTROL WINDOW
 ***********/
/*
 * this class is for the control window
 *
 * Copyright Chris Malcolm, NBBJ digital 2018
 * http://www.nbbj.com/about/digital-practice/
 *
 */

import java.text.SimpleDateFormat;
import controlP5.*;
ControlP5 cp5;
Controller cp5TextField;
ColorPicker cp5ColorPicker1;
ControlFrame win;

boolean buttonAInit = false;
boolean buttonBInit = false;
boolean buttonCInit = false;
boolean buttonDInit = false;
boolean buttonPlayPauseInit = false;
boolean buttonSaveStillInit = false;
boolean buttonresetZoomInit= false;
boolean buttoncolorResetInit = false;
boolean buttonUp = true;

String textValue = "Seattle";
String searchDate = "06/01/2018";
String reformattedDate= "2018-06";
int[] defaultColors = new int[]{
  color(66, 134, 245), 
  color(52, 168, 83), 
  color(237, 67, 52), 
  color(255, 240, 68) //248,186, 5--> changing for more vibrance
};
int[] mainColors = new int[]{
  color(66, 134, 245), 
  color(52, 168, 83), 
  color(237, 67, 52), 
  color(255, 240, 68) //248,186, 5--> changing for more vibrance
};
color[] warmColorRange, coolColorRange; //cache color ranges



class ControlFrame extends PApplet {

  int w, h;
  PApplet parent;
  ControlP5 cp5;
  PShape US;
  boolean dateError = false;
  float mapScale = 0.3;
  JSONArray mapData = new JSONArray();

  public ControlFrame(PApplet _parent, int _w, int _h, String _name) {
    super();   
    parent = _parent;
    w=_w;
    h=_h;
    PApplet.runSketch(new String[]{this.getClass().getName()}, this);
  }

  public void settings() {
    size(w, h);
  }

  public void input(String theText) {
    // automatically receives results from controller input
    textValue = theText;
    parent.thread("doQueries");
  }

  public void date(String theText) {
    // automatically receives results from controller input

     Textfield dateField = cp5.get(Textfield.class, "date");
     //_log(new Object[]{"datefield: ", dateField.toString()});
    String regex = "^(?:0[1-9]|1[0-2])/[0-3][0-9]/[1-9][0-9]{3}$";
    if (theText.matches(regex)){
      dateError = false;
      searchDate = theText;
      reformattedDate = getReformattedDate(searchDate);
      parent.thread("doQueries");
    }else{
      dateError = true;
    }
  }

  public String getReformattedDate(String date) {
    String[] pieces= date.split("/");
    return pieces[2]+"-"+pieces[0];
  }

  public color promptToChooseColor(color c) {
    Color javaColor;
    javaColor  = JColorChooser.showDialog(null, "Java Color Chooser", Color.white);
    if (javaColor!=null) 
      c  = color(javaColor.getRed(), javaColor.getGreen(), javaColor.getBlue());
    return c;
  }
  
    // button controller with name colorA
  public void playPause(int theValue) {
    if (buttonPlayPauseInit) {
      animationIsPaused = !animationIsPaused;
      Button btn = cp5.get(Button.class, "playPause");
      if (animationIsPaused){
        btn.setLabel("Play");
      }else{
        btn.setLabel("Pause");
      }
    } else {
      buttonPlayPauseInit = true;
    }
  }
  
  //color reset
  public void  colorReset(int theValue){
     if (buttoncolorResetInit) {
         resetColors();
      } else {
      buttoncolorResetInit = true;
    }
  }


  // button controller with name colorA
  public void saveStill(int theValue) {
    if (buttonSaveStillInit) {
        //pause animation
        origAnimationState = animationIsPaused;
        animationIsPaused = true;
        Button btn = cp5.get(Button.class, "saveStill");
        btn.setLabel("Saving...");
        btn.lock();
        doFolderRoutine();
      } else {
      buttonSaveStillInit = true;
    }
  }
  
  // button controller with name colorA
  public void resetZoom(int theValue) {
    if (buttonresetZoomInit) {
        _resetZoom();
      } else {
      buttonresetZoomInit = true;
    }
  }
  
  

  // button controller with name colorA
  public void colorA(int theValue) {
    if (buttonAInit) {
      Button btn = cp5.get(Button.class, "colorA");
      btn.setColorBackground(promptToChooseColor(btn.getColor().getBackground()));
      mainColors[0] = btn.getColor().getBackground();
      _log(new Object[]{"main color[0]:", mainColors[0], "default color[0]:",defaultColors[0]});
      regenColorRangeCache();
    } else {
      buttonAInit = true;
    }
  }


  // button controller with name colorA
  public void colorB(int theValue) {
    if (buttonBInit) {
      Button btn = cp5.get(Button.class, "colorB");
      btn.setColorBackground(promptToChooseColor(btn.getColor().getBackground()));
      mainColors[1] = btn.getColor().getBackground();
      regenColorRangeCache();
    } else {
      buttonBInit = true;
    }
  }

  // button controller with name colorA
  public void colorC(int theValue) {
    if (buttonCInit) {
      Button btn = cp5.get(Button.class, "colorC");
      btn.setColorBackground(promptToChooseColor(btn.getColor().getBackground()));
      mainColors[2] = btn.getColor().getBackground();
      regenColorRangeCache();
    } else {
      buttonCInit = true;
    }
  }

  // button controller with name colorA
  public void colorD(int theValue) {
    if (buttonDInit) {
      Button btn = cp5.get(Button.class, "colorD");
      btn.setColorBackground(promptToChooseColor(btn.getColor().getBackground()));
      mainColors[3] = btn.getColor().getBackground();
      regenColorRangeCache();
    } else {
      buttonDInit = true;
    }
  }

  //we only really need to regen color range when swatch changes..so we can store it and forget it ;p
  public void regenColorRangeCache() {
    coolColorRange = generateColorRange(mainColors[0], mainColors[1], gt.CATEGORIES.size());
    warmColorRange = generateColorRange(mainColors[2], mainColors[3], gt.CATEGORIES.size());
  }

  public void setup() {
    surface.setLocation(10, 25);
    surface.setTitle("Adjust Settings:");
    font = createFont("arial", 20);
    regenColorRangeCache();
    cp5 = new ControlP5(this);
    cp5TextField = cp5.addTextfield("input")
      .setCaptionLabel("")
      .setColorBackground(0)
      .setColorActive(255)
      .setAutoClear(false)
      .setColorForeground(0)
      .setPosition(20, 110)
      .setSize(200, 30)
      .setFont(font)
      .setFocus(false)
      .setValue(textValue)
      .setColorCursor(color(255, 255, 255))
      .setColor(color(255, 255, 255))
      ;

    cp5TextField = cp5.addTextfield("date")
      .setCaptionLabel("")
      .setColorBackground(0)
      .setColorActive(255)
      .setAutoClear(false)
      .setColorForeground(0)
      .setPosition(20, 180)
      .setSize(200, 30)
      .setFont(font)
      .setFocus(true)
      .setValue(searchDate)
      .setColorCursor(color(255, 255, 255))
      .setColor(color(255, 255, 255))
      ;

    // create a new button with name 'buttonA'
    cp5.addButton("colorA")
      .setValue(0)
      .setLabelVisible(false)
      .setColorBackground(mainColors[0])
      .setPosition(20, 260)
      .setSize(25, 25)
      ;

    // create a new button with name 'buttonA'
    cp5.addButton("colorB")
      .setValue(0)
      .setLabelVisible(false)
      .setColorBackground(mainColors[1])
      .setPosition(45, 260)
      .setSize(25, 25)
      ;

    // create a new button with name 'buttonA'
    cp5.addButton("colorC")
      .setValue(0)
      .setLabelVisible(false)
      .setColorBackground(mainColors[2])
      .setPosition(70, 260)
      .setSize(25, 25)
      ;

    // create a new button with name 'buttonA'
    cp5.addButton("colorD")
      .setValue(0)
      .setLabelVisible(false)
      .setColorBackground(mainColors[3])
      .setPosition(95, 260)
      .setSize(25, 25)
      ;

    // create a new button with name 'playPause'
    cp5.addButton("playPause")
      .setValue(0)
      .setLabelVisible(true)
      .setLabel("Pause")
      .setColorBackground(color(100))
      .setPosition(width-70, 40)
      .setSize(50, 20)
      ;
      
    
     // create a new button with name 'Reset colors'
    cp5.addButton("colorReset")
      .setValue(0)
      .setLabelVisible(true)
      .setLabel("Reset Colors")
      .setColorLabel(color(180))
      .setColorBackground(color(30))
      .setPosition(120, 225)
      .setSize(80, 20)
      ;


    // create a new button with name 'saveStill'
    cp5.addButton("saveStill")
      .setValue(0)
      .setLabelVisible(true)
      .setLabel("Save PDF")
      .setColorBackground(color(100))
      .setPosition(width-70, 70)
      .setSize(50, 20)
      ;

    // create a new button with name 'resetZoom'
    cp5.addButton("resetZoom")
      .setValue(0)
      .setLabelVisible(true)
      .setLabel("Reset Zoom")
      .setColorBackground(color(100))
      .setPosition(width-70, 100)
      .setSize(50, 20)
      ;
    //data path might not work in jar?! check

    worldMap.scale(mapScale, mapScale);
    ;
  } ///END setup

  public void drawLogoAndVersion() {
    float scale = .5;
    image(logo, 20, height-30, logo.width*scale, logo.height*scale);
    fill(200);
    textSize(14);
    textAlign(RIGHT);
    text("V"+VERSION, width-20, height-15);
    textAlign(LEFT);
    stroke(60);
    line(20, height-40, width-20, height-40);
  }
  
 
  public void   drawCategoryChart(int x, int y, int diameter, int thickness) {
    if (gt.categoryBreakdown.size()> 0) {
      Hashtable<String, Float> catPercentages = gt.getCategoryPercentages();
      Set<String> keys =  catPercentages.keySet();
      float lastAngle = 0;
      float currentAngle = 0;
      int count = 0;
      float angleBuffer =2 ;
      noStroke();
       String key;
      float[] savedAngles = new float[catPercentages.size()];
      for (int i=0; i<gt.categories_sortList.length; i++){
         key = gt.categories_sortList[i];
        //remap from 0 to 100 to 360
        currentAngle = map(catPercentages.get(key), 0, 100, 0, 360);
        fill(coolColorRange[count]);

        arc(x, y, diameter, diameter, lastAngle+radians(angleBuffer), lastAngle+radians(currentAngle)-radians(angleBuffer));
        fill(warmColorRange[count]);
        arc(x, y, diameter-thickness/2, diameter-thickness/2, lastAngle+radians(angleBuffer), lastAngle+radians(currentAngle)-radians(angleBuffer));
        lastAngle += radians(currentAngle);
      

        int textX = x+(diameter/2)+30;
        int textY =  y-(diameter/2)+ 10 +(count*12);

        //do legend
        noStroke();
        fill(coolColorRange[count]);
        rect(textX-15, textY-5, 5, 5);
        fill(warmColorRange[count]);
        rect(textX-10, textY-5, 5, 5);
        //do text
        fill(255);
        textSize(10);
        text(key, textX, textY);
        savedAngles[count] = currentAngle;
        count++;
      }
      fill(0);
      ellipse(x, y, (diameter-thickness), (diameter-thickness));
      /*
      for (int i=0; i<savedAngles.length; i++){
        float translationAngle = savedAngles[i];
        float amplitude = (diameter-thickness)/2-5;
        fill(255);
        textSize(10);
        //println(x," ", x amplitude * cos(translationAngle)," ", y," ", y+amplitude * sin(translationAngle));
        text(i+1, x+amplitude * cos(translationAngle), y-amplitude * sin(translationAngle));
      }
       */
    }
  }

  public void drawPopChart(int x, int y, int w, int h) {
    if ( gt.popularityData.size()>0) {

      stroke(155);
      strokeWeight(1);
      int[] nums = gt.getDateValuesAsList(reformattedDate);
      int[] heights = gt.getDateValuesAsList(reformattedDate);
      String[] dateNames = gt.getDateStringsAsList(reformattedDate, "shorthand");
      
      int[] xPerDate = new int[dateNames.length];
        //line(x, y, x+w, y);
        strokeWeight(1);
      //
      beginShape();
      vertex(x, y);
      int[][] vertices = new int[nums.length][2];
      int[] currentDayVertex = new int[2];
      for (int i=0; i<nums.length; i++) { 
        //_log(new Object[]{"nums:", nums[i], "date name:", dateNames[i]});
        heights[i] = (int)map(heights[i], 0, 100, 0, h);
        int vx = x+(i*w/(heights.length-1));
        int vy = y-heights[i];
        //if it equals current month day
        if (dateNames[i].equals(parseMonthDay())) {
          currentDayVertex = new int[]{vx, vy};
        }
        vertices[i] = new int[]{vx, vy};
        //text labels
        textSize(10);
        fill(255);
        if (i%5==0 || i==heights.length-1) {
          pushMatrix();
          translate(vx, y+30);
          rotate(-HALF_PI);
          text(dateNames[i], 0, 0);
          popMatrix();
        }
      }
      noStroke();
      fill(50);
      drawShape(vertices, new int[]{x, y}, new int[]{x+w, y});
      stroke(255);
      strokeWeight(1);
      noFill();
      drawShape(vertices, null, null);
      strokeWeight(1);
      ellipse(currentDayVertex[0], currentDayVertex[1], 10, 10);
      textSize(10);
      fill(255);
      //percentage
       textAlign(RIGHT);
      text(gt.currentDateValue+"%", currentDayVertex[0], currentDayVertex[1]-10);
      //green or red for delta
      String prefix = (gt.delta<0) ? "\u25BC" : (gt.delta==0) ? "\u25BC" : "\u25B2";
      fill(((gt.delta<0) ? color(255,0,0) : (gt.delta==0) ? color(250,250,250) : color(0,255,0)));
      text(prefix+gt.delta+"%", x+w+40, y-h);
      textAlign(LEFT);
      fill(255);
      checkGraphMapHover(x, y, w, h, dateNames, nums);
    }
  }
  
  //parse month and day for current search date 05/20/2014 will give 05/20
  public String parseMonthDay(){
    String[] pieces =  searchDate.split("/");
    return pieces[0]+"/"+pieces[1];
  }
  
    
  //parse month and day for google date format current search date 05/20/2014 will give 2014-05-20
  public String getGoogleDateFormat(){
    String[] pieces =  searchDate.split("/");
    return pieces[2]+"-"+pieces[0]+"-"+pieces[1];
  }

  public void makeNextPrevTriangle(int x,int y,int w,int h,boolean prev){
    if (prev){
      w*=-1;
    }
    triangle(x,y,x,y+h, x+w, y+h/2);
  }

  public void checkGraphMapHover(int x, int y, int w, int h,String[] dateNames, int[] nums) {
    //add a buffer to capture more
    int buffer =3;
    int monthBuffer = 20;
    x = x- buffer;
    w = w-(buffer);
      textSize(11);
      textAlign(RIGHT);
     int calcIndex = int(((dateNames.length-1)*(mouseX-x))/(w-buffer));
    if (mouseX > x && mouseX < x+w && 
      mouseY < y && mouseY > y-h) {
     
      
      stroke(color(255,0,0));
      line(mouseX, y,mouseX, y-nums[calcIndex]); 
     
      String newDate = dateNames[calcIndex]+"/"+searchDate.split("/")[2];
      text("Click to jump to: "+dateNames[calcIndex]+" ["+nums[calcIndex]+"% ]", x+w, y-h-20);
      if (mousePressed){
        //set new value
        cp5.get(Textfield.class, "date").setValue(newDate);
        //then trigger event
        date(newDate);
      }
    
    }else if (mouseX > x-monthBuffer && mouseX < x+w+monthBuffer && 
      mouseY < y && mouseY > y-h) {
         int modifier = 1;
        //next month
        if (mouseX>x){
        text("Click to jump to next month ", x+w, y-h-20);
        makeNextPrevTriangle(int(x+w+monthBuffer),y-h/2,8,10, false);
       
        }else{
         text("Click to jump back a month", x+w, y-h-20);
          makeNextPrevTriangle(int(x-monthBuffer),y-h/2,8,10, true);
          modifier = -1;
        }
        if (mousePressed & buttonUp==true){
          buttonUp = false;
           String zeroPrefix = "";
         //set new value
         int newMonth =Integer.parseInt(searchDate.split("/")[0])+modifier;
         int newYear = Integer.parseInt(searchDate.split("/")[2]);
         if (newMonth==0){
           newMonth = 12;
           newYear--;
         }else if (newMonth>12){
           newMonth=newMonth%12;
           newYear++;
         }
         if (newMonth<10){
           zeroPrefix = "0";
         }
         String newDate = zeroPrefix+newMonth+"/"+searchDate.split("/")[1]+"/"+newYear;
          cp5.get(Textfield.class, "date").setValue(newDate);
          //then trigger event
          date(newDate);
        }
    }
    textAlign(LEFT);
  }
  
  public void mouseReleased(){
    buttonUp = true;
  }
  String mySubString(String myString, int start, int length) {
    return myString.substring(start, Math.min(start + length, myString.length()));
}

//make default colors
  public void resetColors(){
    _log(new Object[]{"reseting colors:", mainColors,"-->",defaultColors});
    for (int i=0; i<mainColors.length; i++){
      mainColors[i] = defaultColors[i];
    }
    String[] buttonList = new String[]{"colorA", "colorB", "colorC", "colorD"};
    Button btn;
    for (int i=0; i<buttonList.length; i++){
        btn = cp5.get(Button.class, buttonList[i]);
        btn.setColorBackground(mainColors[i]);
    }
    regenColorRangeCache();
  }

  public void drawHotTopicsList(int x, int y){
    String[] hTopics = gt.getHotTopics();
    int maxAmount = 5;
    int spacing = 15;
    textAlign(LEFT);
    textSize(12);
     fill(255);
     text("Hot Topics", x, y);
    textSize(10);
    String alteredText = "";
    int maxTextLength = 22;
    fill(200);
     stroke(50);
     line(x-20, y-10, x-20, y+100);
     noStroke();
    for (int i =0; i<hTopics.length;  i++){;
      if (i<maxAmount){
        if (hTopics[i].length()>maxTextLength)
          alteredText = mySubString(hTopics[i], 0,maxTextLength)+"...";
        else
          alteredText = hTopics[i];
        text(alteredText, x, y+5+(((i+1)*spacing)));
      }
    }
     textAlign(LEFT);
    
  }

  public void drawUSMap(int x, int y) {
    worldMap.disableStyle();
    fill(80);
    noStroke();

    //shape(worldMap,x,y);


    String countryCode;


    if (worldMap.getChildCount()>0) {
      PShape[] svgCountry = new PShape[worldMap.getChildCount()];
      for (int i=0; i<worldMap.getChildCount(); i++) {  
        svgCountry[i] = worldMap.getChild(i);
        //see if it we have it in the countries
        countryCode = svgCountry[i].getName();
        try {
          float newMapValue = map(gt.countries.get(countryCode).value, 20, 80, 125, 255);
          newMapValue = min(255, max(0, newMapValue));
          svgCountry[i].resetMatrix();
          svgCountry[i].scale(mapScale, mapScale);
          fill(int(newMapValue));
          shape(svgCountry[i], x, y);
        } 
        catch(Exception e) {
          //do nothing
        }
      }
      fill(255);
      textSize(10);
      text("Global Interest: "+gt.getWorldPercentageInterest()+"%", x-20, y+170);
    }
  }


  public void drawShape(int[][] vertices, Object start, Object end) {
    beginShape();
    if (start!=null) {
      vertex(((int[])start)[0], ((int[])start)[1]);
    }
    for (int i=0; i<vertices.length; i++) {
      vertex(vertices[i][0], vertices[i][1]);
    }
    if (end!=null) {
      vertex(((int[])end)[0], ((int[])end)[1]);
    }
    endShape();
  }
  
  //reset button and stuff
  public void endSaveRoutine(){
      Button btn = cp5.get(Button.class, "saveStill");
      btn.setLabel("Save PDF");
      btn.unlock();
  }

  void draw() {
    if (exportMode==2){
      beginRecord(PDF, exportFolder+"/"+ts+"-controlFrame.pdf");
     exportMode = 3;
    }
    
    if (exportMode==3 || exportMode==4){ //not saving or exporting control frame
      background(0);
      textFont(font);
      textSize(16);
      fill(100);
      text("Current Keyword: ", 20, 25);
      text("Enter keyword (+ Hit Enter):", 20, 100);
      text("Enter date (+ Hit Enter):", 20, 170);
      text("Color Range:", 20, 240);
      fill(255);
      textSize(32);
      textAlign(LEFT);
      text(textValue, 20, 60);
      textSize(20);
      textAlign(RIGHT);
      text(searchDate, width-20, 30);
      textAlign(LEFT);
      if (cp5.get(Textfield.class, "input").isFocus()) {
        cp5.get(Textfield.class, "input").setColor(255);
        stroke(255);
      } else {
        cp5.get(Textfield.class, "input").setColor(160);
        stroke(160);
      }
      line(20, 140, 220, 140);
      if (cp5.get(Textfield.class, "date").isFocus()) {
        cp5.get(Textfield.class, "date").setColor(255);
        stroke(255);
      } else {
        cp5.get(Textfield.class, "date").setColor(160);
        stroke(160);
      }
      if (dateError){
        cp5.get(Textfield.class, "date").setColor(color(255,0,0));
        stroke(color(255,0,0));
      }
      //date stroke
      line(20, 210, 220, 210);
  
      if (loading==false) {
        stroke(60);
        line(20, height-490, width-40, height-490);    
        drawUSMap(40, height-220 );
        drawPopChart(40, height-280, width-130, 60);
        drawCategoryChart(80, height-420, 100, 20);
        drawHotTopicsList(width-150, height-460);
        drawLogoAndVersion();
      }
    } 
    if (exportMode==3){ //we're in export mode and need to finish
      try{
      endRecord();
      }catch (Exception e){
         _log(new Object[]{"error when trying to end record! try again."});
      }
      endSaveRoutine();
      exportMode = 4;
    }
  }
}
