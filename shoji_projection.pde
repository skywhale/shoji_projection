import codeanticode.syphon.*;
import processing.sound.*;
import processing.video.*;
import oscP5.*;
import netP5.*;

SyphonServer server;
OscP5 oscP5;
FFT fft;
AudioIn in;
Amplitude rms;
PImage dogImage;
Movie dogIdleMovie;
Movie dogPeepMovie;
Movie dogRunMovie;

enum Scene {
  TEST_COLORFUL,
  TEST_RED_WHITE,
  RANDOM_GRAYSCALE,
  RANDOM_COLOR,
  FFT_FADE,
  FFT_SOLID
}
Scene currentScene = Scene.RANDOM_GRAYSCALE;

static final int bands = 256;
final float[] spectrum = new float[bands];

static final int xval = 16;
static final int yval = 6;
final Shoji[][] shojis = new Shoji[xval][yval];

static final float FRAME_MILLIS = 1000.0 / 24;

//////////////////////////////////////////////////////////////////////
void setup() {
  size(1296, 576, P3D);
  colorMode(HSB);

  noStroke();
  fill(0);

  server = new SyphonServer(this, "Processing Syphon");
  println("Started Syphon server.");

  oscP5 = new OscP5(this, 12000);
  println("Started OscP5 server.");

  in = new AudioIn(this, 0);
  in.start();
  println("Started audio input.");

  // Patch the input to an volume analyzer
  rms = new Amplitude(this);
  rms.input(in);

  // patch the AudioIn
  fft = new FFT(this, bands);
  fft.input(in);

  dogImage = loadImage("data/dog.jpg");

  //dogIdleMovie = new Movie(this, "data/dog_idle.mp4");
  //dogIdleMovie.loop();

  for (int i = 0; i < xval; i ++) {
    for (int j = 0; j < yval; j ++) {
      Rect rect = new Rect(width/xval*i, height/yval*j, width/xval, height/yval);
      Texture texture = new Texture(
          new Rect(360 / 4 * (i % 4), 720 / 4 * j, 90, 180),
          dogImage);
      shojis[i][j] = new Shoji(rect, texture);
    }
  }
}

void movieEvent(Movie m) {
  m.read();
}

//////////////////////////////////////////////////////////////////////
int transitionStartTimerMillis = 0;
int transitionTimerMillis = MAX_INT;
void draw() {
  background(0);
  lights();
  
  fft.analyze(spectrum);
  
  boolean inTransition = false;
  if (millis() > transitionStartTimerMillis) {
    inTransition = true;
    transitionStartTimerMillis = millis() + 20000;
    transitionTimerMillis = millis() + int(35 * FRAME_MILLIS / 3);
  }
  if (millis() > transitionTimerMillis) {
    nextScene();
    transitionTimerMillis = MAX_INT;
  }
 
  for (int i = 0; i < xval; i++) {
    for (int j = 0; j < yval; j++) {
      Shoji shoji = shojis[i][j];
      float intensity = (spectrum[(i*rangeFactor)]*255*sensitivityValue)/(1+yval-j)*2;
      shoji.updateRandom(intensity);
      if (currentScene == Scene.TEST_COLORFUL) {
        testColorfulPattern(shoji, i, j);
      } else if (currentScene == Scene.TEST_RED_WHITE) {
        testRedWhitePattern(shoji, i, j);
      } else if (currentScene == Scene.RANDOM_GRAYSCALE) {
        randomGrayscalePattern(shoji);
      } else if (currentScene == Scene.RANDOM_COLOR) {
        randomColorPattern(shoji);
      } else if (currentScene == Scene.FFT_FADE) {
        fftFadePattern(shoji, i, j);
      } else if (currentScene == Scene.FFT_SOLID) {
        fftSolidPattern(shoji, i, j);
      }
      
      if (inTransition) {
        float offsetMillis = (i + j) * FRAME_MILLIS;
        shoji.startAnimation(AnimationPattern.SPIN, offsetMillis, null);
      }

      shoji.display();
    }
  }

  server.sendScreen();
}

void testColorfulPattern(Shoji shoji, int x, int y) {
  shoji.setColor(color((x+y) * 10, 255, 150));
}

void testRedWhitePattern(Shoji shoji, int x, int y) {
  shoji.setColor(color(0, (x+y)%2 == 0 ? 255 : 0, 150));
}
  
void randomGrayscalePattern(Shoji shoji) {
  shoji.setColor(color(shoji.randomFill));
}

void randomColorPattern(Shoji shoji) {
  shoji.setColor(color(hueValue, saturationValue, shoji.randomFill));
}

void fftFadePattern(Shoji shoji, int x, int y) {
  shoji.setColor(color(hueValue + y/20, saturationValue, shoji.randomValue));
}

void fftSolidPattern(Shoji shoji, int x, int y) {
  if (shoji.randomValue > 50) {
    shoji.setColor(color(hueValue, saturationValue, 255));
  } else {
    shoji.setColor(color(0));
  }
}

//////////////////////////////////////////////////////////////////////
class Position {
  float x;
  float y;

  Position(float x, float y) {
    this.x = x;
    this.y = y;
  }
}

//////////////////////////////////////////////////////////////////////
class Rect {
  float x;
  float y;
  float w;
  float h;
  
  Rect(float x, float y, float w, float h) {
    this.x = x;
    this.y = y;
    this.w = w;
    this.h = h;
  }
  
  float getRight() {
    return x + w;
  }
  
  float getBottom() {
    return y + h;
  }
  
  Position getCenter() {
    return new Position(x + w / 2, y + h / 2);
  }
}

//////////////////////////////////////////////////////////////////////
class Texture {
  Rect rect = null;
  color fill = 0;
  PImage image = null;
  Movie movie = null;

  Texture(color fill) {
    this.fill = fill;
  }

  Texture(Rect rect, PImage image) {
    this.rect = rect;
    this.image = image;
  }

  Texture(Rect rect, Movie movie) {
    this.rect = rect;
    this.movie = movie;
  }

  void maybeFill() {
    if (image == null && movie == null) {
      fill(fill);
    }
  }

  void maybeTexture() {
    if (image != null) {
      texture(image);
    } else if (movie != null) {
      texture(movie);
    }
  }
 
  void clear() {
    fill(0);
  }
}

  int currentSceneIndex = 0;
  final Scene[] SCENES = {
    Scene.TEST_RED_WHITE,
    Scene.FFT_SOLID,
    Scene.RANDOM_GRAYSCALE,
    Scene.FFT_FADE
  };
  
void nextScene() {
  currentSceneIndex = ++currentSceneIndex % SCENES.length;
  currentScene = SCENES[currentSceneIndex];
  println(currentSceneIndex);
}

enum AnimationPattern {
  NONE,
  SPIN
}

//////////////////////////////////////////////////////////////////////
class Shoji {
  private final Rect rect;
  private Texture texture;
  
  private AnimationPattern pattern = AnimationPattern.NONE;
  private Texture nextTexture = null;
  private float offsetMillis;
  private float randomVelocity;
  private float randomDirection = 1;
  private float randomFill = 0;
  private float randomValue = 0;

  Shoji(Rect rect, Texture texture) {
    this.rect = rect;
    this.texture = texture;
    this.randomVelocity = random(1) + 0.1;
  }

  void startAnimation(AnimationPattern pattern, float offsetMillis, Texture nextTexture) {
    this.pattern = pattern;
    this.offsetMillis = millis() + offsetMillis;
    this.nextTexture = nextTexture;
  }

  void setColor(color c) {
    texture = new Texture(c);
  }

  void updateRandom(float intensity) {
    randomFill += randomVelocity * randomDirection;
    if (randomFill > 255) {
      randomDirection = -1;
    } else if (randomFill < 100) {
      randomDirection = 1;
    }
    randomValue = (intensity + randomValue * 5) / 6;
  }

  void update() {
    if (pattern == AnimationPattern.SPIN) {
      float t = getAnimationTime(35 * FRAME_MILLIS);
      rotateY(PI * 3 * t);
      if (t >= 1./3) {
        if (nextTexture != null) {
          texture = nextTexture;
        }
      }
    }
  }

  private float getAnimationTime(float durationMillis) {
    float now = millis();
    float t = (now - offsetMillis) / durationMillis;
    return EasingFunctions.easeInOutQuad(constrain(t, 0, 1));
  }

  void display() {
    pushMatrix();
    translate(rect.getCenter().x, rect.getCenter().y, 0);

    update();

    texture.maybeFill();
    beginShape(QUADS);
    texture.maybeTexture();
    normal(0, 0, 1);

    if (texture.rect != null) {
      vertex(-rect.w/2, -rect.h/2, 0, texture.rect.x,          texture.rect.y);
      vertex( rect.w/2, -rect.h/2, 0, texture.rect.getRight(), texture.rect.y);
      vertex( rect.w/2,  rect.h/2, 0, texture.rect.getRight(), texture.rect.getBottom());
      vertex(-rect.w/2,  rect.h/2, 0, texture.rect.x,          texture.rect.getBottom());
    } else {
      vertex(-rect.w/2, -rect.h/2, 0);
      vertex( rect.w/2, -rect.h/2, 0);
      vertex( rect.w/2,  rect.h/2, 0);
      vertex(-rect.w/2,  rect.h/2, 0);
    }

    endShape();
    
    texture.clear();
    popMatrix();
  }
}

//////////////////////////////////////////////////////////////////////
int rangeFactor = 3;
float hueValue = 120;
float saturationValue = 90;
float sensitivityValue = 150;
void oscEvent(OscMessage oscMessage) {
  println(oscMessage);

  if (oscMessage.checkAddrPattern("/1/multipush1/1/1")) {
    currentScene = Scene.RANDOM_GRAYSCALE;
  }
  if (oscMessage.checkAddrPattern("/1/multipush1/2/1")) {
    currentScene = Scene.RANDOM_COLOR;
  }
  if (oscMessage.checkAddrPattern("/1/multipush1/3/1")) {
    currentScene = Scene.FFT_FADE;
  }
  if (oscMessage.checkAddrPattern("/1/multipush1/4/1")) {
    currentScene = Scene.FFT_SOLID;
  }
  if (oscMessage.checkAddrPattern("/1/fader5")) {
    rangeFactor = int(oscMessage.get(0).floatValue() * 10);
  }
  if (oscMessage.checkAddrPattern("/1/fader1")) {
    hueValue = oscMessage.get(0).floatValue() * 255;
  }
  if (oscMessage.checkAddrPattern("/1/fader2")) {
    saturationValue = oscMessage.get(0).floatValue() * 255;
  }
  if (oscMessage.checkAddrPattern("/1/fader3")) {
    sensitivityValue = int(1 + oscMessage.get(0).floatValue() * 255);
  }
}