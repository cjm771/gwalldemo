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

import controlP5.*;
ControlP5 cp5;
Controller cp5TextField;
ColorPicker cp5ColorPicker1;
ControlFrame win;

boolean buttonAInit = false;
boolean buttonBInit = false;
boolean buttonCInit = false;
boolean buttonDInit = false;

String textValue = "Seattle";
String searchDate = "01/01/2018";
String reformattedDate= "2018-01";
int[] mainColors = new int[]{
  color(66, 134, 245), 
  color(52, 168, 83), 
  color(237, 67, 52), 
  color(248, 186, 5)
};
color[] warmColorRange, coolColorRange; //cache color ranges


class ControlFrame extends PApplet {

  int w, h;
  PApplet parent;
  ControlP5 cp5;
  PShape US;
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
    println("a textfield event for controller 'input' : "+theText);
    textValue = theText;
    parent.thread("doQueries");
  }

  public void date(String theText) {
    // automatically receives results from controller input

    searchDate = theText;
    reformattedDate = getReformattedDate(searchDate);
    println("a textfield event for controller 'input' : "+theText+"--->"+reformattedDate);
    parent.thread("doQueries");
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
  public void colorA(int theValue) {
    if (buttonAInit) {
      Button btn = cp5.get(Button.class, "colorA");
      btn.setColorBackground(promptToChooseColor(btn.getColor().getBackground()));
      mainColors[0] = btn.getColor().getBackground();
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
      for (String key : keys) {
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

        count++;
      }
      fill(0);
      ellipse(x, y, (diameter-thickness), (diameter-thickness));
    }
  }

  public void drawPopChart(int x, int y, int w, int h) {
    if ( gt.popularityData.size()>0) {

      stroke(155);
      strokeWeight(1);
      int[] nums = gt.getDateValuesAsList();
      String[] dateNames = gt.getDateStringsAsList();
      int[] xPerDate = new int[dateNames.length];
        //line(x, y, x+w, y);
        strokeWeight(1);
      //
      beginShape();
      vertex(x, y);
      int[][] vertices = new int[nums.length][2];
      int[] currentDayVertex = new int[2];
      for (int i=0; i<nums.length; i++) {  
        nums[i] = (int)map(nums[i], 0, 100, 0, h);
        int vx = x+(i*w/(nums.length-1));
        int vy = y-nums[i];
        if (i==gt.currentDateIndex) {
          currentDayVertex = new int[]{vx, vy};
        }
        vertices[i] = new int[]{vx, vy};
        //text labels
        textSize(10);
        fill(255);
        if (i%5==0 || i==nums.length-1) {
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
      text(gt.currentDateValue+"%", currentDayVertex[0], currentDayVertex[1]-10);
      checkGraphMapHover(x, y, w, h, dateNames, nums);
    }
  }

  public void checkGraphMapHover(int x, int y, int w, int h,String[] dateNames, int[] nums) {
    //add a buffer to capture more
    int buffer =3;
    int monthBuffer = 20;
    x = x- buffer;
    w = w-(buffer);
      textSize(8);
      textAlign(RIGHT);
    if (mouseX > x && mouseX < x+w && 
      mouseY < y && mouseY > y-h) {
     
      int calcIndex = int(((dateNames.length-1)*(mouseX-x))/(w-buffer));
      stroke(color(255,0,0));
      line(mouseX, y,mouseX, y-nums[calcIndex]); 
     
      String newDate = dateNames[calcIndex]+"/"+searchDate.split("/")[2];
      text("Click to jump to: "+dateNames[calcIndex]+" ["+int(((float)nums[calcIndex]/(float)h*100))+"% ]", x+w, y-h-20);
      if (mousePressed){
        //set new value
        cp5.get(Textfield.class, "date").setValue(newDate);
        //then trigger event
        date(newDate);
      }
    
    }else if (mouseX > x-monthBuffer && mouseX < x+w+monthBuffer && 
      mouseY < y && mouseY > y-h) {
        //next month
        if (mouseX>x){
        text("Click to jump to next month", x+w, y-h-20);
        }else{
         text("Click to jump back a month", x+w, y-h-20);
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


  void draw() {
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
    line(20, 210, 220, 210);

    if (loading==false) {
      stroke(60);
      line(20, height-490, width-40, height-490);    
      drawUSMap(40, height-220 );
      drawPopChart(40, height-280, width-130, 60);
      drawCategoryChart(80, height-420, 100, 20);
      drawLogoAndVersion();
    }
  }
}
