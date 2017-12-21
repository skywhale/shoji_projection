import codeanticode.syphon.*;
import processing.sound.*;

SyphonServer server;

FFT fft;
AudioIn in;
Amplitude rms;

int bands = 256;
float[] spectrum = new float[bands];

int xval = 16;
int yval = 6;
Shoji[][] shojis = new Shoji[xval][yval];

//////////////////////////////////////////////////////////////////////
void setup() {
  size(1296, 576, P3D);
  colorMode(HSB);

  noStroke();

  server = new SyphonServer(this, "Processing Syphon");

  textAlign(CENTER, CENTER);

  fill(0);

  // Create an Input stream which is routed into the Amplitude analyzer
  fft = new FFT(this, bands);
  in = new AudioIn(this, 0);

  // start the Audio Input
  in.start();

  // create a new Amplitude analyzer
  rms = new Amplitude(this);

  // Patch the input to an volume analyzer
  rms.input(in);

  // patch the AudioIn
  fft.input(in);

  for (int i = 0; i < xval; i ++) {
    for (int j = 0; j < yval; j ++) {
      shojis[i][j] = new Shoji(width/xval*i, height/yval*j, width/xval, height/yval, random(1)+0.1);
    }
  }
}


//////////////////////////////////////////////////////////////////////
void draw() {
  background(0);
  fft.analyze(spectrum);

  for (int i = 0; i < xval; i ++) {
    for (int j = 0; j < yval; j ++) {
      shojis[i][j].status = (spectrum[i*3]*255*40)/(1+yval-j);
      shojis[i][j].update();
      shojis[i][j].display();
    }
  }
  
  server.sendScreen();
}


//////////////////////////////////////////////////////////////////////
class Shoji {
  float x, y, w, h, fill, velocity;
  int direction = 1;
  float status = 0;

  Shoji (float _x, float _y, float _w, float _h, float _velocity) {
    fill = 0;
    x = _x;
    y = _y;
    w = _w;
    h = _h;
    velocity = _velocity;
  }

  void update() {
    fill += velocity * direction;
    if (fill > 255) {
      direction = -1;
    } else if (fill<100) {
      direction = 1;
    }
  }

  void display() {
    fill(35, 90, status);
    rect(x, y, w, h);
    fill(0);
  }
}