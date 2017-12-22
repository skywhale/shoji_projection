import codeanticode.syphon.*;
import processing.sound.*;

SyphonServer server;

FFT fft;
AudioIn in;
Amplitude rms;

enum Scene {
  TEST,
  FFT_BARS
}
Scene currentScene = Scene.TEST;

static final int bands = 256;
final float[] spectrum = new float[bands];

static final int xval = 16;
static final int yval = 6;
final Shoji[][] shojis = new Shoji[xval][yval];

static final float FRAME_MILLIS = 1000.0 / 24;
static final float ANIMATION_START_DELAY_MILLIS = 3000;

//////////////////////////////////////////////////////////////////////
void setup() {
  size(1296, 576, P3D);
  colorMode(HSB);

  noStroke();
  fill(0);

  server = new SyphonServer(this, "Processing Syphon");
  println("Started Syphon server.");
  
  in = new AudioIn(this, 0);
  in.start();
  println("Started audio input.");

  // Patch the input to an volume analyzer
  rms = new Amplitude(this);
  rms.input(in);

  // patch the AudioIn
  fft = new FFT(this, bands);
  fft.input(in);

  for (int i = 0; i < xval; i ++) {
    for (int j = 0; j < yval; j ++) {
      shojis[i][j] = new Shoji(
          width/xval*i, height/yval*j, width/xval, height/yval,
          ANIMATION_START_DELAY_MILLIS + (i + j) * FRAME_MILLIS);
    }
  }
}


//////////////////////////////////////////////////////////////////////
void draw() {
  background(0);
  lights();
  
  if (currentScene == Scene.TEST) {
    drawTestPattern();
  } else if (currentScene == Scene.FFT_BARS) {
    drawFftBars();
  }
  
  server.sendScreen();
}

void drawTestPattern() {
   for (int i = 0; i < xval; i++) {
    for (int j = 0; j < yval; j++) {
      shojis[i][j].colorValue = (i + j) * 10;
      shojis[i][j].display();
    }
  }
}

void drawFftBars() {
  fft.analyze(spectrum);

  for (int i = 0; i < xval; i++) {
    for (int j = 0; j < yval; j++) {
      shojis[i][j].colorValue = (spectrum[i*3]*255*40)/(1+yval-j);
      shojis[i][j].display();
    }
  }
}

//////////////////////////////////////////////////////////////////////
class Shoji {
  float x, y, w, h, animationStart;
  float colorValue = 0;

  static final float ANIMATION_DURATION_MILLIS = 35 * FRAME_MILLIS;

  Shoji (float x, float y, float w, float h, float animationStart) {
    this.x = x;
    this.y = y;
    this.w = w;
    this.h = h;
    this.animationStart = animationStart;
  }

  void display() {
    pushMatrix();
    translate(x + w / 2, y + h / 2, 0);

    float now = millis();
    float animationTime = now - animationStart;
    if (animationTime >= 0 && animationTime < ANIMATION_DURATION_MILLIS) {
      float intensity = EasingFunctions.easeInOutQuad(animationTime / ANIMATION_DURATION_MILLIS);
      rotateY(PI * 3 * intensity);
    }

    fill(35, 90, colorValue);
    beginShape(QUADS);
    normal(0, 0, 1);
    vertex(-w/2, -h/2, 0);
    vertex( w/2, -h/2, 0);
    vertex( w/2,  h/2, 0);
    vertex(-w/2,  h/2, 0);
    endShape();
    fill(0);
    popMatrix();
  }
}