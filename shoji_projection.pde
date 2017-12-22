import codeanticode.syphon.*;
import processing.sound.*;
import processing.video.*;

SyphonServer server;

FFT fft;
AudioIn in;
Amplitude rms;
PImage dogImage;  // 360 x 720
Movie snowMovie;  // 1280 x 720 

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

  dogImage = loadImage("data/dog.jpg");
  
  // FIXME: This crashes the program.
  //snowMovie = new Movie(this, "data/snow.mp4");
  //snowMovie.loop();

  for (int i = 0; i < xval; i ++) {
    for (int j = 0; j < yval; j ++) {
      Rect rect = new Rect(width/xval*i, height/yval*j, width/xval, height/yval);
      Texture texture = new Texture(
          new Rect(360 / 4 * (i % 4), 720 / 4 * j, 90, 180),
          dogImage);
      shojis[i][j] = new Shoji(rect, texture);
      float offsetMillis = ANIMATION_START_DELAY_MILLIS + (i + j) * FRAME_MILLIS;
      shojis[i][j].startAnimation(AnimationPattern.SPIN, offsetMillis, null);
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
      shojis[i][j].setColor(color((i + j) * 10, 255, 255));
      shojis[i][j].display();
    }
  }
}

void drawFftBars() {
  fft.analyze(spectrum);

  for (int i = 0; i < xval; i++) {
    for (int j = 0; j < yval; j++) {
      shojis[i][j].setColor(color(35, 90, spectrum[i*3]*255*40)/(1+yval-j));
      shojis[i][j].display();
    }
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
  
  Shoji(Rect rect, Texture texture) {
    this.rect = rect;
    this.texture = texture;
  }

  void startAnimation(AnimationPattern pattern, float offsetMillis, Texture nextTexture) {
    this.pattern = pattern;
    this.offsetMillis = offsetMillis;
    this.nextTexture = nextTexture;
  }

  void setColor(color c) {
    texture = new Texture(c);
  }
  
  void update() {
    if (pattern == AnimationPattern.SPIN) {
      float t = getAnimationTime(35 * FRAME_MILLIS);
      rotateY(PI * 3 * t);
      if (t >= 1./3 && nextTexture != null) {
        texture = nextTexture;
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