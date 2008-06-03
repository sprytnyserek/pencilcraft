// Needed by rgb2hsv()
float maxrgb(float r,float g,float b)
{
  float max;

  if( r > g)
    max = r;
  else
    max = g;
  if( b > max )
    max = b;
  return( max );
}


// Needed by rgb2hsv()
float minrgb(float r,float g,float b)
{
  float min;

  if( r < g)
    min = r;
  else
    min = g;
  if( b < min )
    min = b;
  return( min );
}

/* Taken from "Fund'l of 3D Computer Graphics", Alan Watt (1989)
   Assumes (r,g,b) range from 0.0 to 1.0
   Sets h in degrees: 0.0 to 360.;
      s,v in [0.,1.]
*/
void rgb2hsv(float r, float g, float b,
              float *hout, float *sout, float *vout)
{
  float h=0,s=1.0,v=1.0;
  float max_v,min_v,diff,r_dist,g_dist,b_dist;
  float undefined = 0.0;

  max_v = maxrgb(r,g,b);
  min_v = minrgb(r,g,b);
  diff = max_v - min_v;
  v = max_v;

  if( max_v != 0 )
    s = diff/max_v;
  else
    s = 0.0;
  if( s == 0 )
    h = undefined;
  else {
    r_dist = (max_v - r)/diff;
    g_dist = (max_v - g)/diff;
    b_dist = (max_v - b)/diff;
    if( r == max_v )
      h = b_dist - g_dist;
    else
      if( g == max_v )
        h = 2 + r_dist - b_dist;
      else
        if( b == max_v )
          h = 4 + g_dist - r_dist;
        else
          printf("rgb2hsv::How did I get here?\n");
    h *= 60;
    if( h < 0)
      h += 360.0;
  }
  *hout = h;
  *sout = s;
  *vout = v;
}

/* Taken from "Fund'l of 3D Computer Graphics", Alan Watt (1989)
   Assumes H in degrees, s,v in [0.,1.0];
   (r,g,b) range from 0.0 to 1.0
*/
void hsv2rgb(float hin, float s, float v,
             float *rout, float *gout, float *bout)
{
  float h;
  float r=0,g=0,b=0;
  float f,p,q,t;
  int i;

  h = hin;
  if( s == 0 ) {
    r = v;
    g = v;
    b = v;
  }
  else {
    if(h == 360.)
      h = 0.0;
    h /= 60.;
    i = (int) h;
    f = h - i;
    p = v*(1-s);
    q = v*(1-(s*f));
    t = v*(1-s*(1-f));
    switch(i) {
    case 0:
      r = v;
      g = t;
      b = p;
      break;
    case 1:
      r = q;
      g = v;
      b = p;
      break;
    case 2:
      r = p;
      g = v;
      b = t;
      break;
    case 3:
      r = p;
      g = q;
      b = v;
      break;
    case 4:
      r = t;
      g = p;
      b = v;
      break;
    case 5:
      r = v;
      g = p;
      b = q;
      break;
    default:
      r = 1.0;
      b = 1.0;
      b = 1.0;
      //printf("hsv2rgb::How did I get here?\n");
      // printf("h: %f, s: %f, v: %f; i:  %d\n",hin,s,v,i);
      break;
    }
  }
  *rout = r;
  *gout = g;
  *bout = b;
}

