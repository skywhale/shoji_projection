// Taken from https://gist.github.com/gre/1650294
public class EasingFunctions {
  // no easing, no acceleration
  public static float linear(float t) { return t; }
  // accelerating from zero velocity
  public static float easeInQuad(float t) { return t*t; }
  // decelerating to zero velocity
  public static float easeOutQuad(float t) { return t*(2-t); }
  // acceleration until halfway, then deceleration
  public static float easeInOutQuad(float t) { return t<.5 ? 2*t*t : -1+(4-2*t)*t; }
  // accelerating from zero velocity 
  public static float easeInCubic(float t) { return t*t*t; }
  // decelerating to zero velocity 
  public static float easeOutCubic(float t) { return (--t)*t*t+1; }
  // acceleration until halfway, then deceleration 
  public static float easeInOutCubic(float t) { return t<.5 ? 4*t*t*t : (t-1)*(2*t-2)*(2*t-2)+1; }
  // accelerating from zero velocity 
  public static float easeInQuart(float t) { return t*t*t*t; }
  // decelerating to zero velocity 
  public static float easeOutQuart(float t) { return 1-(--t)*t*t*t; }
  // acceleration until halfway, then deceleration
  public static float easeInOutQuart(float t) { return t<.5 ? 8*t*t*t*t : 1-8*(--t)*t*t*t; }
  // accelerating from zero velocity
  public static float easeInQuint(float t) { return t*t*t*t*t; }
  // decelerating to zero velocity
  public static float easeOutQuint(float t) { return 1+(--t)*t*t*t*t; }
  // acceleration until halfway, then deceleration 
  public static float easeInOutQuint(float t) { return t<.5 ? 16*t*t*t*t*t : 1+16*(--t)*t*t*t*t; }
}