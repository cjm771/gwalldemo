/***********
ZOOM + PAN
***********/
/*
 *
 * class to enable panning and zooming around visualization
 * middle click and drag to pan
 * middle scroll to zoom in/out
 *
 * Copyright Chris Malcolm, NBBJ digital 2018
 * http://www.nbbj.com/about/digital-practice/
 *
 */


float scale = 1.25;
float xPan =masterX/2;
float yPan = masterY/2;
float zoomSpeed = 1.07;
float panSpeed = 5;
int lastMousePress[];
float lastPan[];

void mouseWheel(MouseEvent event) {
  float e = event.getCount();
 if (e==-1){
    scale *= zoomSpeed;
 }else{
    scale /= zoomSpeed;
 }
}


void mouseReleased(MouseEvent event){
    lastPan = new float[]{xPan,yPan};

}

void mousePressed(MouseEvent event){
  lastMousePress = new int[]{event.getX(),event.getY()};
  
}

void mouseDragged(MouseEvent event){
    if (mouseButton == CENTER){
      int change[] = new int[]{lastMousePress[0]-event.getX(),lastMousePress[1]-event.getY()};
     xPan = lastPan[0]+ (change[0]*scale);
     yPan = lastPan[1]+ (change[1]*scale);
    }
}
