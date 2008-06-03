module basic;

private {
	import derelict.sdl.sdl;
	import std.math;
	import std.stdio;
	import std.c.string;
	
	import shape;
	import colors;
	import matrices;
	}

void putPixel(SDL_Surface* canvas,int x,int y,uint c) {
if ((x >= 0) && (x < canvas.w) && (y >= 0) && (y < canvas.h)) {
	//SDL_LockSurface(canvas);
	synchronized {
		(cast(uint*)(canvas.pixels))[y * canvas.w + x] = c;
		}
	//SDL_UnlockSurface(canvas);
	}
};


void putPixel(SDL_Surface* canvas,float x,float y,uint c) {
int xi = cast(int)round(x * (canvas.w - 1));
int yi = cast(int)round(y * (canvas.h - 1));
putPixel(canvas,xi,yi,c);
};

void putPixel(SDL_Surface* canvas,//draw surface
			float x, float y, float z,//coordinates beyond 3D 
			float D,//distance between projection plane and an observer
			uint c//color of pixel
			) {
float W = z / D + 1.0;
float X = x / W, Y = y / W, Z = z / W;
float xi = X * D / (Z + D), yi = Y * D / (Z + D);
putPixel(canvas,xi,yi,c);
};


void drawLine(SDL_Surface* canvas,int x1,int y1,int x2,int y2,uint c) {
float dx,x11,x12;
if (y1 == y2) {
	if (x2 < x1) {
		x1 = x1 + x2;
		x2 = x1 - x2;
		x1 = x1 - x2;
		}
	for (int x = x1; x <= x2; x++) {
		putPixel(canvas,x,y1,c);
		}
	return;
	}
if (y2 < y1) {
	x1 = x1 + x2;
    x2 = x1 - x2;
    x1 = x1 - x2;
    y1 = y1 + y2;
    y2 = y1 - y2;
    y1 = y1 - y2;
	}
y2++;
dx = cast(float)(x2-x1) / cast(float)(y2-y1);
x11 = cast(float)x1;
x12 = cast(float)x1;
for (int y = y1; y < y2; y++) {
	x12 += dx;
	if (x12 < x11) {
		x11 = x11 + x12;
		x12 = x11 - x12;
		x11 = x11 - x12;
		}
	for (int i = cast(int)round(x11); i <= cast(int)round(x12); i++) {
		putPixel(canvas,i,y,c);
		}
	x11 += dx;
	}
};


void drawLine(SDL_Surface* canvas,float x1,float y1,float x2,float y2,uint c) {
int x1i = cast(int)(x1 * (canvas.w - 1)), y1i = cast(int)(y1 * (canvas.h - 1));
int x2i = cast(int)(x2 * (canvas.w - 1)), y2i = cast(int)(y2 * (canvas.h - 1));
drawLine(canvas,x1i,y1i,x2i,y2i,c);
};

void drawLine(SDL_Surface* canvas,
				float x1,float y1,float z1,//1st point coordinates
				float x2,float y2,float z2,//2nd point coordinates
				float D,//distance between projection plane and an observer
				uint c//color of pixel
				) {
float W = z1 / D + 1.0;
float X = x1 / W, Y = y1 / W, Z = z1 / W;
float x1i = X * D / (Z + D), y1i = Y * D / (Z + D);
W = z2 / D + 1.0;
X = x2 / W; Y = y2 / W; Z = z2 / W;
float x2i = X * D / (Z + D), y2i = Y * D / (Z + D);
drawLine(canvas,x1i,y1i,x2i,y2i,c);
};


void shadeTriangle(SDL_Surface* canvas,Triangle2D t,uint[3] color,TVector3 lightValue) {
struct Point2D {
	int x,y;
	uint c;
	ubyte r,g,b;
	float lightValue;
	};

TVector2 p1,p2,p3;
uint i,j,b;
Point2D[3] p;
Point2D q; // temp

for (i = 1; i < 6; i += 2) {
	b = (i - 1) >> 1;
	p[b].x = cast(int)round(t[i - 1] * canvas.w);
	p[b].y = cast(int)round(t[i] * canvas.h);
	p[b].lightValue = (floor(lightValue[b]) != lightValue[b]) ? (abs(lightValue[b]) - floor(abs(lightValue[b]))) : (abs(lightValue[b]));
	p[b].c = color[b];
	p[b].g = (cast(ubyte*)(&(p[b].c)))[1];
	if (SDL_BYTEORDER == SDL_BIG_ENDIAN) {
		p[b].r = (cast(ubyte*)(&(p[b].c)))[0];
		p[b].b = (cast(ubyte*)(&(p[b].c)))[2];
		}
	else {
		p[b].r = (cast(ubyte*)(&(p[b].c)))[2];
		p[b].b = (cast(ubyte*)(&(p[b].c)))[0];
		}
	}
//if ((p[0].y ^ p[1].y == 0) && (p[1].y ^ p[2].y == 0)) return;
if (((p[0].y == p[1].y) && (p[1].y == p[2].y)) || ((p[0].x == p[1].x) && (p[1].x == p[2].x))) return;
//q = p[0];

for (i = 0; i < 2; i++) {
	for (j = i + 1; j < 3; j++) {
		if (p[j].y < p[i].y) {
			q = p[i];
			p[i] = p[j];
			p[j] = q;
			}
		}
	}

//for (i = 0; i < 3; i++) writefln(p[i].x," ",p[i].y,"   ",p[i].r," ",p[i].g," ",p[i].b," ",p[i].c);

/* obliczenie wspolczynnikow przyrostowych */
float temp;
float deltaL,deltaR;
TVector4 deltaCL,deltaCR,deltaCline;

/* true if p[1].x < p[2].x (p[1] is on the LEFT side of the core segment of triangle) 
 * false if p[1].x > p[2].x (p[1] is on the RIGHT side of the core segment of triangle) */
bool leftToCorrect = true;

temp = (p[1].y - p[0].y != 0) ? (1.0 / cast(float)(p[1].y - p[0].y)) : 0.0;
deltaL = cast(float)(p[1].x - p[0].x) * temp;
deltaCL[0] = cast(float)(p[1].r - p[0].r) * temp;
deltaCL[1] = cast(float)(p[1].g - p[0].g) * temp;
deltaCL[2] = cast(float)(p[1].b - p[0].b) * temp;
deltaCL[3] = cast(float)(p[1].lightValue - p[0].lightValue) * temp;
/+
deltaL = (p[1].y - p[0].y != 0) ? (cast(float)(p[1].x - p[0].x) / cast(float)(p[1].y - p[0].y)) : 0.0;
/*R*/deltaCL[0] = (p[1].y - p[0].y != 0) ? (cast(float)(p[1].r - p[0].r) / cast(float)(p[1].y - p[0].y)) : 0.0;
/*B*/deltaCL[1] = (p[1].y - p[0].y != 0) ? (cast(float)(p[1].g - p[0].g) / cast(float)(p[1].y - p[0].y)) : 0.0;
/*B*/deltaCL[2] = (p[1].y - p[0].y != 0) ? (cast(float)(p[1].b - p[0].b) / cast(float)(p[1].y - p[0].y)) : 0.0;
+/
temp = (p[2].y - p[0].y != 0) ? (1.0 / cast(float)(p[2].y - p[0].y)) : 0.0;
deltaR = cast(float)(p[2].x - p[0].x) * temp;
deltaCR[0] = cast(float)(p[2].r - p[0].r) * temp;
deltaCR[1] = cast(float)(p[2].g - p[0].g) * temp;
deltaCR[2] = cast(float)(p[2].b - p[0].b) * temp;
deltaCR[3] = cast(float)(p[2].lightValue - p[0].lightValue) * temp;
/+
deltaR = (p[2].y - p[0].y != 0) ? (cast(float)(p[2].x - p[0].x) / cast(float)(p[2].y - p[0].y)) : 0.0;
/*R*/deltaCR[0] = (p[2].y - p[0].y != 0) ? (cast(float)(p[2].r - p[0].r) / cast(float)(p[2].y - p[0].y)) : 0.0;
/*G*/deltaCR[1] = (p[2].y - p[0].y != 0) ? (cast(float)(p[2].g - p[0].g) / cast(float)(p[2].y - p[0].y)) : 0.0;
/*B*/deltaCR[2] = (p[2].y - p[0].y != 0) ? (cast(float)(p[2].b - p[0].b) / cast(float)(p[2].y - p[0].y)) : 0.0;
+/
//if (p[1].x > p[0].x) {
if (((p[2].x - p[0].x) * (p[1].y - p[0].y)) - ((p[1].x - p[0].x) * (p[2].y - p[0].y)) < 0) {
	/* swap deltas */
	temp = deltaL;
	deltaL = deltaR;
	deltaR = temp;
	deltaCline[] = deltaCL[];
	deltaCL[] = deltaCR[];
	deltaCR[] = deltaCline[];
	leftToCorrect = false;
	}
/* delta_C=((y3-y1)*(C2-C1)-(y2-y1)*(C3-C1)/((y3-y1)*(x2-x1)-(y2-y1)*(x3-x1)) */
temp = (((p[2].y - p[0].y) * (p[1].x - p[0].x)) - ((p[1].y - p[0].y) * (p[2].x - p[0].x)));
temp = (temp != 0) ? (1.0 / temp) : 0.0;
/*R*/deltaCline[0] = temp * (((p[2].y - p[0].y) * (p[1].r - p[0].r)) - ((p[1].y - p[0].y) * (p[2].r - p[0].r)));
/*G*/deltaCline[1] = temp * (((p[2].y - p[0].y) * (p[1].g - p[0].g)) - ((p[1].y - p[0].y) * (p[2].g - p[0].g)));
/*B*/deltaCline[2] = temp * (((p[2].y - p[0].y) * (p[1].b - p[0].b)) - ((p[1].y - p[0].y) * (p[2].b - p[0].b)));
/*light*/deltaCline[3] = temp * (((p[2].y - p[0].y) * (p[1].lightValue - p[0].lightValue)) - ((p[1].y - p[0].y) * (p[2].lightValue - p[0].lightValue)));
/* pierwsza czesc trojkata */
int x,y;
float xl,xr;
int xri;
TVector4 colorL,colorR,colorX;
y = p[0].y;
xl = xr = cast(float)(p[0].x);
colorL[0] = colorR[0] = p[0].r;
colorL[1] = colorR[1] = p[0].g;
colorL[2] = colorR[2] = p[0].b;
colorL[3] = colorR[3] = p[0].lightValue;
//writefln(p[0].lightValue);
//writefln(deltaCL[3]," ",deltaCR[3]);
//writefln(colorL[3]);
while (y < p[1].y) {
	xri = cast(int)round(xr);
	colorX[] = colorL[];
	for (x = cast(int)round(xl); x <= xri; x++) {
		if (x == xri) {
			putPixel(canvas,x,y,rgb(cast(ubyte)round(colorR[0] * colorR[3]), cast(ubyte)round(colorR[1] * colorR[3]), cast(ubyte)round(colorR[2] * colorR[3])));
			}
		else {
			//writefln(colorX[3]);
			putPixel(canvas,x,y,rgb(cast(ubyte)round(colorX[0] * colorX[3]), cast(ubyte)round(colorX[1] * colorX[3]), cast(ubyte)round(colorX[2] * colorX[3])));
			colorX[0] += deltaCline[0];
			colorX[1] += deltaCline[1];
			colorX[2] += deltaCline[2];
			colorX[3] += deltaCline[3];
			}
		}
	colorL[0] += deltaCL[0];
	colorL[1] += deltaCL[1];
	colorL[2] += deltaCL[2];
	colorL[3] += deltaCL[3];
	colorR[0] += deltaCR[0];
	colorR[1] += deltaCR[1];
	colorR[2] += deltaCR[2];
	colorR[3] += deltaCR[3];
	xl += deltaL;
	xr += deltaR;
	y++;
	}

/* druga czesc trojkata */
if (leftToCorrect) {
	colorL[0] = p[1].r;
	colorL[1] = p[1].g;
	colorL[2] = p[1].b;
	colorL[3] = p[1].lightValue;
	temp = (p[2].y - p[1].y != 0) ? (1.0 / cast(float)(p[2].y - p[1].y)) : 0.0;
	deltaL = cast(float)(p[2].x - p[1].x) * temp;
	deltaCL[0] = cast(float)(p[2].r - p[1].r) * temp;
	deltaCL[1] = cast(float)(p[2].g - p[1].g) * temp;
	deltaCL[2] = cast(float)(p[2].b - p[1].b) * temp;
	deltaCL[3] = cast(float)(p[2].lightValue - p[1].lightValue) * temp;
	/+
	deltaL = (p[2].y - p[1].y != 0) ? (cast(float)(p[2].x - p[1].x) / cast(float)(p[2].y - p[1].y)) : 0.0;
	/*R*/deltaCL[0] = (p[2].y - p[1].y != 0) ? (cast(float)(p[2].r - p[1].r) / cast(float)(p[2].y - p[1].y)) : 0.0;
	/*B*/deltaCL[1] = (p[2].y - p[1].y != 0) ? (cast(float)(p[2].g - p[1].g) / cast(float)(p[2].y - p[1].y)) : 0.0;
	/*B*/deltaCL[2] = (p[2].y - p[1].y != 0) ? (cast(float)(p[2].b - p[1].b) / cast(float)(p[2].y - p[1].y)) : 0.0;
	+/
	xl = p[1].x;
	}
else {
	colorR[0] = p[1].r;
	colorR[1] = p[1].g;
	colorR[2] = p[1].b;
	colorR[3] = p[1].lightValue;
	temp = (p[2].y - p[1].y != 0) ? (1.0 / (cast(float)(p[2].y - p[1].y))) : 0.0;
	deltaR = cast(float)(p[2].x - p[1].x) * temp;
	deltaCR[0] = cast(float)(p[2].r - p[1].r) * temp;
	deltaCR[1] = cast(float)(p[2].g - p[1].g) * temp;
	deltaCR[2] = cast(float)(p[2].b - p[1].b) * temp;
	deltaCR[3] = cast(float)(p[2].lightValue - p[1].lightValue) * temp;
	/+
	deltaR = (p[2].y - p[1].y != 0) ? (cast(float)(p[2].x - p[1].x) / cast(float)(p[2].y - p[1].y)) : 0.0;
	/*R*/deltaCR[0] = (p[2].y - p[1].y != 0) ? (cast(float)(p[2].r - p[1].r) / cast(float)(p[2].y - p[1].y)) : 0.0;
	/*B*/deltaCR[1] = (p[2].y - p[1].y != 0) ? (cast(float)(p[2].g - p[1].g) / cast(float)(p[2].y - p[1].y)) : 0.0;
	/*B*/deltaCR[2] = (p[2].y - p[1].y != 0) ? (cast(float)(p[2].b - p[1].b) / cast(float)(p[2].y - p[1].y)) : 0.0;
	+/
	xr = p[1].x;
	}
y = p[1].y;
while (y <= p[2].y) {
	xri = cast(int)round(xr);
	colorX[] = colorL[];
	for (x = cast(int)round(xl); x <= xri; x++) {
		if (x == xri) {
			putPixel(canvas,x,y,rgb(cast(ubyte)round(colorR[0] * colorR[3]), cast(ubyte)round(colorR[1] * colorR[3]), cast(ubyte)round(colorR[2] * colorR[3])));
			}
		else {
			putPixel(canvas,x,y,rgb(cast(ubyte)round(colorX[0] * colorX[3]), cast(ubyte)round(colorX[1] * colorX[3]), cast(ubyte)round(colorX[2] * colorX[3])));
			colorX[0] += deltaCline[0];
			colorX[1] += deltaCline[1];
			colorX[2] += deltaCline[2];
			colorX[3] += deltaCline[3];
			}
		}
	colorL[0] += deltaCL[0];
	colorL[1] += deltaCL[1];
	colorL[2] += deltaCL[2];
	colorL[3] += deltaCL[3];
	colorR[0] += deltaCR[0];
	colorR[1] += deltaCR[1];
	colorR[2] += deltaCR[2];
	colorR[3] += deltaCR[3];
	xl += deltaL;
	xr += deltaR;
	y++;
	}
}; // shadeTriangle


void textureTriangle(SDL_Surface* canvas,Triangle2D t,Texture texture,Triangle2D tTex,uint[3] color,TVector3 lightValue) {
struct Point2D {
	int x,y;
	uint c;
	ubyte r,g,b;
	};

TVector2 p1,p2,p3;
uint i,j,b;
Point2D[3] p;
Point2D q; // temp

for (i = 1; i < 6; i += 2) {
	b = (i - 1) >> 1;
	p[b].x = cast(int)round(t[i - 1] * canvas.w);
	p[b].y = cast(int)round(t[i] * canvas.h);
	p[b].c = color[b];
	p[b].g = (cast(ubyte*)(&(p[b].c)))[1];
	if (SDL_BYTEORDER == SDL_BIG_ENDIAN) {
		p[b].r = (cast(ubyte*)(&(p[b].c)))[0];
		p[b].b = (cast(ubyte*)(&(p[b].c)))[2];
		}
	else {
		p[b].r = (cast(ubyte*)(&(p[b].c)))[2];
		p[b].b = (cast(ubyte*)(&(p[b].c)))[0];
		}
	}
//if ((p[0].y ^ p[1].y == 0) && (p[1].y ^ p[2].y == 0)) return;
if (((p[0].y == p[1].y) && (p[1].y == p[2].y)) || ((p[0].x == p[1].x) && (p[1].x == p[2].x))) return;
//q = p[0];

for (i = 0; i < 2; i++) {
	for (j = i + 1; j < 3; j++) {
		if (p[j].y < p[i].y) {
			q = p[i];
			p[i] = p[j];
			p[j] = q;
			}
		}
	}

//for (i = 0; i < 3; i++) writefln(p[i].x," ",p[i].y,"   ",p[i].r," ",p[i].g," ",p[i].b," ",p[i].c);

/* obliczenie wspolczynnikow przyrostowych */
float temp;
float deltaL,deltaR;
TVector3 deltaCL,deltaCR,deltaCline;

/* true if p[1].x < p[2].x (p[1] is on the LEFT side of the core segment of triangle) 
 * false if p[1].x > p[2].x (p[1] is on the RIGHT side of the core segment of triangle) */
bool leftToCorrect = true;

deltaL = (p[1].y - p[0].y != 0) ? (cast(float)(p[1].x - p[0].x) / cast(float)(p[1].y - p[0].y)) : 0.0;
/*R*/deltaCL[0] = (p[1].y - p[0].y != 0) ? (cast(float)(p[1].r - p[0].r) / cast(float)(p[1].y - p[0].y)) : 0.0;
/*B*/deltaCL[1] = (p[1].y - p[0].y != 0) ? (cast(float)(p[1].g - p[0].g) / cast(float)(p[1].y - p[0].y)) : 0.0;
/*B*/deltaCL[2] = (p[1].y - p[0].y != 0) ? (cast(float)(p[1].b - p[0].b) / cast(float)(p[1].y - p[0].y)) : 0.0;
deltaR = (p[2].y - p[0].y != 0) ? (cast(float)(p[2].x - p[0].x) / cast(float)(p[2].y - p[0].y)) : 0.0;
/*R*/deltaCR[0] = (p[2].y - p[0].y != 0) ? (cast(float)(p[2].r - p[0].r) / cast(float)(p[2].y - p[0].y)) : 0.0;
/*G*/deltaCR[1] = (p[2].y - p[0].y != 0) ? (cast(float)(p[2].g - p[0].g) / cast(float)(p[2].y - p[0].y)) : 0.0;
/*B*/deltaCR[2] = (p[2].y - p[0].y != 0) ? (cast(float)(p[2].b - p[0].b) / cast(float)(p[2].y - p[0].y)) : 0.0;
//if (p[1].x > p[0].x) {
if (((p[2].x - p[0].x) * (p[1].y - p[0].y)) - ((p[1].x - p[0].x) * (p[2].y - p[0].y)) < 0) {
	/* swap deltas */
	temp = deltaL;
	deltaL = deltaR;
	deltaR = temp;
	deltaCline[] = deltaCL[];
	deltaCL[] = deltaCR[];
	deltaCR[] = deltaCline[];
	leftToCorrect = false;
	}
/* delta_C=((y3-y1)*(C2-C1)-(y2-y1)*(C3-C1)/((y3-y1)*(x2-x1)-(y2-y1)*(x3-x1)) */
temp = (((p[2].y - p[0].y) * (p[1].x - p[0].x)) - ((p[1].y - p[0].y) * (p[2].x - p[0].x)));
temp = (temp != 0) ? (1.0 / temp) : 0.0;
/*R*/deltaCline[0] = temp * (((p[2].y - p[0].y) * (p[1].r - p[0].r)) - ((p[1].y - p[0].y) * (p[2].r - p[0].r)));
/*G*/deltaCline[1] = temp * (((p[2].y - p[0].y) * (p[1].g - p[0].g)) - ((p[1].y - p[0].y) * (p[2].g - p[0].g)));
/*B*/deltaCline[2] = temp * (((p[2].y - p[0].y) * (p[1].b - p[0].b)) - ((p[1].y - p[0].y) * (p[2].b - p[0].b)));
/* pierwsza czesc trojkata */
int x,y;
float xl,xr;
int xri;
TVector3 colorL,colorR,colorX;
y = p[0].y;
xl = xr = cast(float)(p[0].x);
colorL[0] = colorR[0] = p[0].r;
colorL[1] = colorR[1] = p[0].g;
colorL[2] = colorR[2] = p[0].b;
while (y < p[1].y) {
	xri = cast(int)round(xr);
	colorX[] = colorL[];
	for (x = cast(int)round(xl); x <= xri; x++) {
		if (x == xri) {
			putPixel(canvas,x,y,rgb(cast(ubyte)round(colorR[0]), cast(ubyte)round(colorR[1]), cast(ubyte)round(colorR[2])));
			}
		else {
			putPixel(canvas,x,y,rgb(cast(ubyte)round(colorX[0]), cast(ubyte)round(colorX[1]), cast(ubyte)round(colorX[2])));
			colorX[0] += deltaCline[0];
			colorX[1] += deltaCline[1];
			colorX[2] += deltaCline[2];
			}
		}
	colorL[0] += deltaCL[0];
	colorL[1] += deltaCL[1];
	colorL[2] += deltaCL[2];
	colorR[0] += deltaCR[0];
	colorR[1] += deltaCR[1];
	colorR[2] += deltaCR[2];
	xl += deltaL;
	xr += deltaR;
	y++;
	}

/* druga czesc trojkata */
if (leftToCorrect) {
	colorL[0] = p[1].r;
	colorL[1] = p[1].g;
	colorL[2] = p[1].b;
	deltaL = (p[2].y - p[1].y != 0) ? (cast(float)(p[2].x - p[1].x) / cast(float)(p[2].y - p[1].y)) : 0.0;
	/*R*/deltaCL[0] = (p[2].y - p[1].y != 0) ? (cast(float)(p[2].r - p[1].r) / cast(float)(p[2].y - p[1].y)) : 0.0;
	/*B*/deltaCL[1] = (p[2].y - p[1].y != 0) ? (cast(float)(p[2].g - p[1].g) / cast(float)(p[2].y - p[1].y)) : 0.0;
	/*B*/deltaCL[2] = (p[2].y - p[1].y != 0) ? (cast(float)(p[2].b - p[1].b) / cast(float)(p[2].y - p[1].y)) : 0.0;
	xl = p[1].x;
	}
else {
	colorR[0] = p[1].r;
	colorR[1] = p[1].g;
	colorR[2] = p[1].b;
	deltaR = (p[2].y - p[1].y != 0) ? (cast(float)(p[2].x - p[1].x) / cast(float)(p[2].y - p[1].y)) : 0.0;
	/*R*/deltaCR[0] = (p[2].y - p[1].y != 0) ? (cast(float)(p[2].r - p[1].r) / cast(float)(p[2].y - p[1].y)) : 0.0;
	/*B*/deltaCR[1] = (p[2].y - p[1].y != 0) ? (cast(float)(p[2].g - p[1].g) / cast(float)(p[2].y - p[1].y)) : 0.0;
	/*B*/deltaCR[2] = (p[2].y - p[1].y != 0) ? (cast(float)(p[2].b - p[1].b) / cast(float)(p[2].y - p[1].y)) : 0.0;
	xr = p[1].x;
	}
y = p[1].y;
while (y <= p[2].y) {
	xri = cast(int)round(xr);
	colorX[] = colorL[];
	for (x = cast(int)round(xl); x <= xri; x++) {
		if (x == xri) {
			putPixel(canvas,x,y,rgb(cast(ubyte)round(colorR[0]), cast(ubyte)round(colorR[1]), cast(ubyte)round(colorR[2])));
			}
		else {
			putPixel(canvas,x,y,rgb(cast(ubyte)round(colorX[0]), cast(ubyte)round(colorX[1]), cast(ubyte)round(colorX[2])));
			colorX[0] += deltaCline[0];
			colorX[1] += deltaCline[1];
			colorX[2] += deltaCline[2];
			}
		}
	colorL[0] += deltaCL[0];
	colorL[1] += deltaCL[1];
	colorL[2] += deltaCL[2];
	colorR[0] += deltaCR[0];
	colorR[1] += deltaCR[1];
	colorR[2] += deltaCR[2];
	xl += deltaL;
	xr += deltaR;
	y++;
	}
}; // textureTriangle

void clearZbuffer(float* buffer,uint w,uint h,float D) {
ulong size = w * h;
float* pointer = buffer;
for (ulong i = 0; i < size; i++) *pointer++ = D;
};

void ZbufferUpdate(float* buffer,Triangle2D t,TVector3 z) {

};

bool checkTriangleCollision(TVector3 t1,TVector3 t2) {

return false;
};

/+
/* checks if two shapes collision with each other applying enclosing cuboids on them */
bool checkCollision(ShadedShape s1,ShadedShape s2) {
if ((s1.points.length == 0) || (s2.points.length == 0)) return false;
float[3] max1,max2,min1,min2;
max1[0] = s1.points[0][0]; max1[1] = s1.points[0][1]; max1[2] = s1.points[0][2];
max2[0] = s2.points[0][0]; max2[1] = s2.points[0][1]; max2[2] = s2.points[0][2];
min1[0] = s1.points[0][0]; min1[1] = s1.points[0][1]; min1[2] = s1.points[0][2];
min2[0] = s2.points[0][0]; min2[1] = s2.points[0][1]; min2[2] = s2.points[0][2];
for (uint i = 1; i < s1.points.length; i++) {
	max1[0] = s1.points[i][0] > max1[0] ? s1.points[i][0] : max1[0];
	max1[1] = s1.points[i][1] > max1[1] ? s1.points[i][1] : max1[1];
	max1[2] = s1.points[i][2] > max1[2] ? s1.points[i][2] : max1[2];
	min1[0] = s1.points[i][0] < min1[0] ? s1.points[i][0] : min1[0];
	min1[1] = s1.points[i][1] < min1[1] ? s1.points[i][1] : min1[1];
	min1[2] = s1.points[i][2] < min1[2] ? s1.points[i][2] : min1[2];
	}
for (uint i = 1; i < s2.points.length; i++) {
	max2[0] = s2.points[i][0] > max2[0] ? s2.points[i][0] : max2[0];
	max2[1] = s2.points[i][1] > max2[1] ? s2.points[i][1] : max2[1];
	max2[2] = s2.points[i][2] > max2[2] ? s2.points[i][2] : max2[2];
	min2[0] = s2.points[i][0] < min2[0] ? s2.points[i][0] : min2[0];
	min2[1] = s2.points[i][1] < min2[1] ? s2.points[i][1] : min2[1];
	min2[2] = s2.points[i][2] < min2[2] ? s2.points[i][2] : min2[2];
	}
if ((max1[0] < min2[0]) && (max2[0] < min1[0])) return false;
if ((max1[1] < min2[1]) && (max2[1] < min1[1])) return false;
if ((max1[2] < min2[2]) && (max2[2] < min1[2])) return false;
return true;
};
+/

/* checks if two shapes collision with each other applying enclosing cuboids on them */
bool checkCollision(TVector3[] p1,TVector3[] p2) {
if ((p1.length == 0) || (p2.length == 0)) return false;
float[3] max1,max2,min1,min2;
max1[0] = p1[0][0]; max1[1] = p1[0][1]; max1[2] = p1[0][2];
max2[0] = p2[0][0]; max2[1] = p2[0][1]; max2[2] = p2[0][2];
min1[0] = p1[0][0]; min1[1] = p1[0][1]; min1[2] = p1[0][2];
min2[0] = p2[0][0]; min2[1] = p2[0][1]; min2[2] = p2[0][2];
for (uint i = 1; i < p1.length; i++) {
	max1[0] = p1[i][0] > max1[0] ? p1[i][0] : max1[0];
	max1[1] = p1[i][1] > max1[1] ? p1[i][1] : max1[1];
	max1[2] = p1[i][2] > max1[2] ? p1[i][2] : max1[2];
	min1[0] = p1[i][0] < min1[0] ? p1[i][0] : min1[0];
	min1[1] = p1[i][1] < min1[1] ? p1[i][1] : min1[1];
	min1[2] = p1[i][2] < min1[2] ? p1[i][2] : min1[2];
	}
for (uint i = 1; i < p2.length; i++) {
	max2[0] = p2[i][0] > max2[0] ? p2[i][0] : max2[0];
	max2[1] = p2[i][1] > max2[1] ? p2[i][1] : max2[1];
	max2[2] = p2[i][2] > max2[2] ? p2[i][2] : max2[2];
	min2[0] = p2[i][0] < min2[0] ? p2[i][0] : min2[0];
	min2[1] = p2[i][1] < min2[1] ? p2[i][1] : min2[1];
	min2[2] = p2[i][2] < min2[2] ? p2[i][2] : min2[2];
	}
if ((max1[0] < min2[0]) && (max2[0] < min1[0])) return false;
if ((max1[1] < min2[1]) && (max2[1] < min1[1])) return false;
if ((max1[2] < min2[2]) && (max2[2] < min1[2])) return false;
return true;
};
