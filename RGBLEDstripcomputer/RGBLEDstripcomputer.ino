#define REDPIN 3 // pwm pins for each output channel
#define GREENPIN 6
#define BLUEPIN 5
#define SERIALINTERVAL 50 // interval (in ms) to discard the current serial message and wait for a new one (should be less than the send interval in the processing sketch)
#define SERIALMSGLEN 6 // number of bytes the computer sends per packet

byte red = 0,green = 0,blue = 0; // current led output levels (before being mapped)
int counter = 0, counter2 = 0; // counter just goes up to 255 and back to 0; counter2 goes up and down
bool counter2dir = false; // whether its currently going up or down
long lasttime = 0; // used for timing the led updates asychronously

byte mode = 1; // the current display pattern (index of the array in the processing sketch matches up)
byte modecolor_r = 0, modecolor_g = 100, modecolor_b = 255; // the color associated with patterns that need a color
byte brightness = 60; // the overall brightness of the strip (not linear btw)
byte pspeed = 35; //number of milliseconds between updates (so higher speed = slower)

long lastrecv = 0; // timestamp of last recieved serial message 
byte curindex = 0; // current index in the receiving array
byte serialmesg[SERIALMSGLEN]; // buffer for the serial message

void setup() {
  Serial.begin(115200); // for comms with the processing sketch
  
  pinMode(REDPIN,OUTPUT);
  pinMode(GREENPIN,OUTPUT);
  pinMode(BLUEPIN,OUTPUT);
}

void loop() {
  long msnow = millis(); // save this for later
  // recieve serial data
  if (lastrecv + SERIALINTERVAL < msnow) { // if this timeout elapses, clear the buffer and reset the counter
    curindex = 0;
  }
  if (Serial.available()) {
    serialmesg[curindex] = Serial.read();
    curindex++;
    lastrecv = msnow;
  }
  if (curindex >= SERIALMSGLEN) { // pull the data from the array into the variables
    mode = serialmesg[0];
    pspeed = serialmesg[1];
    brightness = serialmesg[2];
    modecolor_r = serialmesg[3];
    modecolor_g = serialmesg[4];
    modecolor_b = serialmesg[5];
    curindex = 0;
  }
  
  if (lasttime + pspeed <= msnow) { // led update time
    lasttime = msnow;
    // run counters
    counter++;
    if (counter > 255) counter = 0;
    if (counter2dir) {counter2++;} else {counter2--;}
    if (counter2 >= 255) counter2dir = false;
    if (counter2 <= 0) counter2dir = true;
  
    // do the appropriate color stuff based on mode
    if (mode == 0) { // off
      red = 0;
      green = 0;
      blue = 0;
    } else if (mode == 1) { // rainbow
      Wheel(counter); // sets the global r,g,b vars
    } else if (mode == 2) { // breathing
      red = map(modecolor_r,0,255,0,counter2);
      green = map(modecolor_g,0,255,0,counter2);
      blue = map(modecolor_b,0,255,0,counter2);
    } else if (mode == 3) { // static
      red = modecolor_r;
      green = modecolor_g;
      blue = modecolor_b;
    }
  
    // now set the colors to the output channels
    if (brightness > 0) {
      analogWrite(REDPIN,map(red,0,255,0,brightness)); // map each channel based on brighness
      analogWrite(GREENPIN,map(green,0,255,0,brightness));
      analogWrite(BLUEPIN,map(blue,0,255,0,brightness));
    } else { // don't need to map if its basically off
      analogWrite(REDPIN,0);
      analogWrite(GREENPIN,0);
      analogWrite(BLUEPIN,0);
    }
  }
}

void Wheel(byte WheelPos) { // hsv to rgb
  WheelPos = 255 - WheelPos;
  if(WheelPos < 85) {
   red = 255 - WheelPos * 3;
   green = 0;
   blue = WheelPos * 3;
  } else if (WheelPos < 170) {
    WheelPos -= 85;
   red = 0;
   green = WheelPos * 3;
   blue = 255 - WheelPos * 3;
  } else {
   WheelPos -= 170;
   red = WheelPos * 3;
   green = 255 - WheelPos * 3;
   blue = 0;
  }
}
