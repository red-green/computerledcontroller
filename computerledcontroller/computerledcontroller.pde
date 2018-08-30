// settings
int crosshairsize = 12; // diameter of crosshairs on color picker
int previewsize = 40; // square side len for color previews
int scrollbaredges = 15; // buffer from edge of screen
int scrollbarthreshold = 10; // add this much to ends of sb to facilitate maximizing the value
String[] modestrings = {"Off","Rainbow","Breathing","Static"};
int sendinterval = 70; // milliseconds between data packets

import processing.serial.*;

PImage colorwheel;
Serial arduino;
Selector modes;
ScrollBar speed, brightness, redsb, greensb, bluesb;

int curRed = 0,curGreen = 255,curBlue = 255;
String lastMessage = "";
long lastSend = 0;

void setup() {
  size(300,600);
  frameRate(30);
  background(0);
   
  colorwheel = loadImage("colorwheel.jpg");
  colorwheel.resize(width,width); // resample it beforehand to avoid doing it every frame
  
  modes = new Selector(scrollbaredges,scrollbaredges,width-scrollbaredges*2,20,1,modestrings);
  
  speed = new ScrollBar(scrollbaredges,height-width-125,width-scrollbaredges*2,20,100,1,35,"speed");
  brightness = new ScrollBar(scrollbaredges,height-width-100,width-scrollbaredges*2,20,0,255,100,"brightness");
  redsb = new ScrollBar(scrollbaredges,height-width-75,width-scrollbaredges*2,20,0,255,curRed,"red");
  greensb = new ScrollBar(scrollbaredges,height-width-50,width-scrollbaredges*2,20,0,255,curGreen,"green");
  bluesb = new ScrollBar(scrollbaredges,height-width-25,width-scrollbaredges*2,20,0,255,curBlue,"blue");
  
  String serport = "";
  for (String p : Serial.list()) {
    if (p.contains("usbmodem")) {
      serport = p; 
      break;
    }
  }
  arduino = new Serial(this, serport, 115200);
}

void draw() {
  if (focused) {
    // handle the color wheel selection
    int mousePixel = colorwheel.get((int)map(mouseX,0,width,0,colorwheel.width),(int)map(mouseY,height-width,height,0,colorwheel.height));
    float wheelRed = red(mousePixel), wheelGreen = green(mousePixel), wheelBlue = blue(mousePixel);
    boolean isOnWheel = mouseY >= height-width && mouseY <= height && mouseX >= 0 && mouseX <= width && (wheelRed != 0 || wheelGreen != 0 || wheelBlue != 0);
    if (isOnWheel && mousePressed) {
      curRed = (int)wheelRed;
      curGreen = (int)wheelGreen;
      curBlue = (int)wheelBlue;
      redsb.setVal(curRed);
      greensb.setVal(curGreen);
      bluesb.setVal(curBlue);
    }
    
    if (isOnWheel) {
      noCursor();
    } else {
      cursor(ARROW);
    }
    
    // now draw it all
    background(0);
    // run selector
    modes.run();
    // run scrollbars
    speed.run();
    brightness.run();
    if (isOnWheel) {
      redsb.run(wheelRed,true);
      greensb.run(wheelGreen,true);
      bluesb.run(wheelBlue,true);
    } else {
      redsb.run();
      greensb.run();
      bluesb.run();
    }
    if ((int)redsb.getVal() != curRed) curRed = (int)redsb.getVal();
    if ((int)greensb.getVal() != curGreen) curGreen = (int)greensb.getVal();
    if ((int)bluesb.getVal() != curBlue) curBlue = (int)bluesb.getVal();
    
    // color wheel
    //image(colorwheel,0,height-width,width,width);
    image(colorwheel,0,height-width);
    if (isOnWheel) {
      stroke(255);
      // draw crosshairs
      noFill();
      strokeWeight(1);
      ellipse(mouseX, mouseY, crosshairsize*2, crosshairsize*2);
      line(mouseX-crosshairsize, mouseY, mouseX-3, mouseY);
      line(mouseX+crosshairsize, mouseY, mouseX+3, mouseY);
      line(mouseX, mouseY-crosshairsize, mouseX, mouseY-3);
      line(mouseX, mouseY+crosshairsize, mouseX, mouseY+3);
      // draw a preview of the color
      noStroke();
      fill(wheelRed,wheelGreen,wheelBlue);
      rect(width-previewsize,height-width,previewsize,previewsize);
      fill(255);
      text("new",width-previewsize+3,width-height+previewsize+15);
    }
    // preview of last color picked
    noStroke();
    fill(curRed,curGreen,curBlue);
    rect(0,height-width,previewsize,previewsize);
    fill(255);
    text("cur",3,width-height+previewsize+15); 
  }
  
  // now we get all the data and send it if nessecary
  if (lastSend + sendinterval < millis()) {
    lastSend = millis();
    byte[] data = {(byte)(modes.getVal()), 
                   (byte)((int)speed.getVal()), 
                   (byte)((int)brightness.getVal()), 
                   (byte)((int)redsb.getVal()), 
                   (byte)((int)greensb.getVal()), 
                   (byte)((int)bluesb.getVal()),
                   0}; // zero padding?
    String message = new String(data); // compare using a string for ease of use
    if (!message.equals(lastMessage)) { // if the message is the same as last time, no need to resend
      arduino.write(data);
      //println("updated state");
      lastMessage = message;
    }
  }
}

class Selector {
  float x,y,w,eh,fh;
  String[] names;
  int mode,cnt;
  
  Selector(float xp, float yp, float sw, float sh, int def, String[] ele) {
    x = xp;
    y = yp;
    w = sw;
    eh = sh;
    cnt = ele.length;
    fh = eh * cnt;
    mode = def;
    names = ele;
  }
  
  void run() {
    // calculate mouse bounds
    int mouseOver = -1; // the element its over, otherwise -1
    if (mouseX >= x && mouseY >= y && mouseX <= x+w && mouseY <= y+fh) {
      for (int i = 0; i < cnt; i++) {
        if (mouseY >= y + i*eh && mouseY <= y + (i+1)*eh) {
          mouseOver = i;
          break;
        }
      }
    }
    
    if (mouseOver >= 0 && mousePressed) {
      mode = mouseOver;
    }
    
    //draw it
    strokeWeight(1);
    for (int i = 0; i < cnt; i++) {
      stroke(255);
      if (mode == i) {
        fill(10,200,10); 
      } else if (mouseOver == i) {
        fill(50,50,90);
      } else { 
        fill(10,10,70); 
      }
      rect(x,y+i*eh,w,eh-1);
      fill(255,0,0);
      text(names[i],x+15,y+i*eh+15);
    }
  }
  
  int getVal() {
    return mode;
  }
}

class ScrollBar {
  float x,y,w,h;
  float min,max,val;
  String name;
  
  ScrollBar(float xp, float yp, float sw, float sh, float lo, float hi, float v, String n) {
    x=xp;
    y=yp;
    w=sw;
    h=sh;
    min=lo;
    max=hi;
    val=v;
    name=n;
  }
  
  void run() {
    float tempval = map(mouseX - x,0,w,min,max);
    boolean mouseover = mouseX > x-scrollbarthreshold && mouseY > y && mouseX < x+w+scrollbarthreshold && mouseY < y+h;
    run(tempval,mouseover);
  }
  
  void run(float tempval, boolean mouseover) {
    if (mousePressed && mouseover) {
      if (min < max) {
        val = constrain(tempval,min,max);
      } else {
        val = constrain(tempval,max,min);
      }
    }
    
    float computed = x + map(val,min,max,0,w);
    float tempcomputed = 0;
    if (mouseover) {tempcomputed = x + map(tempval,min,max,0,w);}
    
    noStroke();
    fill(60);
    rect(x,y,w,h);
    strokeWeight(2);
    stroke(255,255,0);
    line(computed,y,computed,y+h);
    if (mouseover) {
      stroke(0,255,255);
      line(tempcomputed,y,tempcomputed,y+h);
      fill(255,0,0);
      text(name+" - "+val+" ("+tempval+")",x+10,y+12);
    } else {
      fill(255,0,0);
      text(name+" - "+val,x+10,y+12);
    }
  }
  
  float getVal() {
    return val;
  }
  
  void setVal(float newval) {
    val = constrain(newval,min,max);
  }
}