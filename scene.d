module scene;

private {
	import std.stdio;
	import std.string;
	import std.math;
	import std.bitarray;
	import std.thread;
	
	import basic;
	import sdlexception;
	import shape;
	import matrices;
	import colors;
	
	import derelict.sdl.sdl;
	import derelict.sdl.ttf;
	}

const uint colorDepth = 32;

class Scene {
	protected:
	SDL_Surface* frame;
	float D;
	uint bgColor;
	TTF_Font* font;

	Matrix modelView;

	/* Z-Buffer implementation */
	bool[] ZinitialValue;
	BitArray Zcontrol;
	float[int] Zbuffer;
	bool Zenabled;
	
	public:
	this(uint w,uint h,char[] fontFileName = "VeraBd.ttf") {
	this.frame = SDL_SetVideoMode(w,h,colorDepth,SDL_HWSURFACE | SDL_DOUBLEBUF | SDL_RESIZABLE);
	if (this.frame == null) throw new SDLException();
	this.D = 10.0;
	this.bgColor = rgb(0,0,0);
	this.font = TTF_OpenFont(toStringz(fontFileName),20);
	this.Zenabled = false;
	this.modelView = new Matrix(4,4);
	for (uint i = 0; i < 4; i++) this.modelView[i,i] = 1.0;
	};

	~this() {
	if (this.font !is null) TTF_CloseFont(font);
	if (this.Zenabled) this.disableZbuffer();
	};

	void resetVideoMode(uint w,uint h) {
	this.frame = SDL_SetVideoMode(w,h,colorDepth,SDL_HWSURFACE | SDL_DOUBLEBUF | SDL_RESIZABLE);
	};

	void enableZbuffer() {
	uint b = frame.w * frame.h;
	this.ZinitialValue.length = b;
	Zcontrol.init(this.ZinitialValue);
	Zenabled = true;
	};

	void disableZbuffer() {
	this.Zenabled = false;
	this.ZinitialValue = null;
	this.Zcontrol.init(this.ZinitialValue);
	this.Zbuffer = null;
	};
	
	uint w() {
	return frame.w;	
	};
	
	uint h() {
	return frame.h;
	};

	char[] getCaption() {
	char* caption,icon;
	SDL_WM_GetCaption(&caption,&icon);
	return std.string.toString(caption);
	};

	void setCaption(char[] caption) {
	SDL_WM_SetCaption(std.string.toStringz(caption),null);
	};

	synchronized void setBackgroundColor(uint c) {
	SDL_FillRect(frame,null,c);
	SDL_Flip(frame);
	this.bgColor = c;
	};

	synchronized void clear() {
	SDL_FillRect(frame,null,this.bgColor);
	};

	float getObservingDistance() {
	return this.D;
	};
	
	synchronized void setObservingDistance(float D) {
	this.D = D;
	};

	synchronized void redraw() {
	SDL_Flip(frame);
	};

	void drawShape(Shape sh,uint c) {
	if (sh.index.length % 3 > 0) throw new SDLException();
	TVector3 p1, p2, p3;
	TVector2[3] p;
	float X,Y,Z,W;
	for (uint i = 0; i < sh.index.length; i+=3) {
		p1[] = sh.points[sh.index[i]];
		p2[] = sh.points[sh.index[i + 1]];
		p3[] = sh.points[sh.index[i + 2]];
		if (sh.modelView !is null) {
			//p41[0..3] = p1[];
			//p42[0..3] = p2[];
			//p43[0..3] = p3[];
			//p41[3] = p42[3] = p43[3] = 1.0;
			//sh.modelView.update(p41);
			//sh.modelView.update(p42);
			//sh.modelView.update(p43);
			//writefln(p41," ",p42," ",p43,newline);
			try {
				transform(sh.modelView,p1);
				transform(sh.modelView,p2);
				transform(sh.modelView,p3);
				}
			catch (SDLException) {
				}
			//p1[] = p41[0..3];
			//p2[] = p42[0..3];
			//p3[] = p43[0..3];
			}
		if (this.modelView !is null) {
			try {
				transform(this.modelView,p1);
				transform(this.modelView,p2);
				transform(this.modelView,p3);
				}
			catch (SDLException) {
				}
			}
		if ((p1[2] < cast(float)0) || (p2[2] < cast(float)0) || (p3[2] < cast(float)0)) continue;
		W = p1[2] / D + 1.0;
		X = p1[0] / W; Y = p1[1] / W; Z = p1[2] / W;
		p[0][0] = X * D / (Z + D); p[0][1] = Y * D /(Z + D);
		W = p2[2] / D + 1.0;
		X = p2[0] / W; Y = p2[1] / W; Z = p2[2] / W;
		p[1][0] = X * D / (Z + D); p[1][1] = Y * D /(Z + D);
		W = p3[2] / D + 1.0;
		X = p3[0] / W; Y = p3[1] / W; Z = p3[2] / W;
		p[2][0] = X * D / (Z + D); p[2][1] = Y * D /(Z + D);
		/* backface culling */
		if (((p[1][0] - p[0][0]) * (p[1][1] - p[2][1])) - ((p[1][0] - p[2][0]) * (p[1][1] - p[0][1])) >= 0) continue;
		/* Z-buffer seeking */
		if (Zenabled) {
			
			}
		/* drawing */
		basic.drawLine(frame,p[0][0],p[0][1],p[1][0],p[1][1],c);
		basic.drawLine(frame,p[1][0],p[1][1],p[2][0],p[2][1],c);
		basic.drawLine(frame,p[2][0],p[2][1],p[0][0],p[0][1],c);
		/+basic.drawLine(frame,p1[0],p1[1],p1[2],p2[0],p2[1],p2[2],D,frame.w,frame.h,c);
		basic.drawLine(frame,p2[0],p2[1],p2[2],p3[0],p3[1],p3[2],D,frame.w,frame.h,c);
		basic.drawLine(frame,p3[0],p3[1],p3[2],p1[0],p1[1],p1[2],D,frame.w,frame.h,c);+/
		}
	};


	void drawShadedShape(ShadedShape sh) {
	if (sh.index.length % 3 > 0) throw new SDLException();
	TVector3 p1, p2, p3;
	TVector2[3] p;
	float X,Y,Z,W;
	uint[3] c;
	Triangle2D t;
	for (uint i = 0; i < sh.index.length; i+=3) {
		p1[] = sh.points[sh.index[i]];
		p2[] = sh.points[sh.index[i + 1]];
		p3[] = sh.points[sh.index[i + 2]];
		c[0] = sh.colorPalette[sh.shadeIndex[i]];
		c[1] = sh.colorPalette[sh.shadeIndex[i + 1]];
		c[2] = sh.colorPalette[sh.shadeIndex[i + 2]];
		if (sh.modelView !is null) {
			try {
				transform(sh.modelView,p1);
				transform(sh.modelView,p2);
				transform(sh.modelView,p3);
				}
			catch (SDLException) {
				}
			}
		if (this.modelView !is null) {
			try {
				transform(this.modelView,p1);
				transform(this.modelView,p2);
				transform(this.modelView,p3);
				}
			catch (SDLException) {
				}
			}
		if ((p1[2] < cast(float)0) || (p2[2] < cast(float)0) || (p3[2] < cast(float)0)) continue;
		W = p1[2] / D + 1.0;
		X = p1[0] / W; Y = p1[1] / W; Z = p1[2] / W;
		p[0][0] = X * D / (Z + D); p[0][1] = Y * D /(Z + D);
		W = p2[2] / D + 1.0;
		X = p2[0] / W; Y = p2[1] / W; Z = p2[2] / W;
		p[1][0] = X * D / (Z + D); p[1][1] = Y * D /(Z + D);
		W = p3[2] / D + 1.0;
		X = p3[0] / W; Y = p3[1] / W; Z = p3[2] / W;
		p[2][0] = X * D / (Z + D); p[2][1] = Y * D /(Z + D);
		/* backface culling */
		if (((p[1][0] - p[0][0]) * (p[1][1] - p[2][1])) - ((p[1][0] - p[2][0]) * (p[1][1] - p[0][1])) >= 0) continue;
		/* Z-buffer seeking */
		if (Zenabled) {
			
			}
		/* drawing */
		for (uint j = 0; j < 6; j++) {
			t[j] = p[j >> 1][j & 1];
			}
		//basic.shadeTriangle(frame,[p[0][0],p[0][1],p[1][0],p[1][1],p[2][0],p[2][1]],c);
		/* setting light level */
		p1[0] = (p1[2] >= D) ? 0.0 : ((D - p1[2]) / D);
		p1[1] = (p2[2] >= D) ? 0.0 : ((D - p2[2]) / D);
		p1[2] = (p3[2] >= D) ? 0.0 : ((D - p3[2]) / D);
		basic.shadeTriangle(frame,t,c,p1);
		/+basic.drawLine(frame,p[0][0],p[0][1],p[1][0],p[1][1],c);
		basic.drawLine(frame,p[1][0],p[1][1],p[2][0],p[2][1],c);
		basic.drawLine(frame,p[2][0],p[2][1],p[0][0],p[0][1],c);+/
		}
	};
	
	Matrix getModelView() {
	return this.modelView;
	};
	
	void putPixel(float x,float y,float z,uint c) {
	basic.putPixel(frame,x,y,z,D,c);
	this.redraw();
	};

	void drawLine(float x1,float y1,float z1,float x2,float y2,float z2,uint c) {
	basic.drawLine(frame,x1,y1,z1,x2,y2,z2,D,c);
	this.redraw();
	};

	void drawText(char* text,float x,float y,uint color) {
	if (this.font !is null) {
		SDL_Color sdlcolor;
		if (SDL_BYTEORDER == SDL_BIG_ENDIAN) {
			with (sdlcolor) {
				//sdlcolor = { cast(ubyte*)(&color)[0], cast(ubyte*)(&color)[1], cast(ubyte*)(&color)[2], 0 };
				r = (cast(ubyte*)(&color))[0];
				g = (cast(ubyte*)(&color))[1];
				b = (cast(ubyte*)(&color))[2];
				unused = 0;
				}
			}
		else {
			with (sdlcolor) {
				r = (cast(ubyte*)(&color))[2];
				g = (cast(ubyte*)(&color))[1];
				b = (cast(ubyte*)(&color))[0];
				unused = 0;
				}
			}
		SDL_Surface* textSurface = TTF_RenderUTF8_Solid(font,text,sdlcolor);
		if (textSurface != null) {
			SDL_Rect* rect = new SDL_Rect;
			rect.x = cast(short)round(x * frame.w);
			rect.y = cast(short)round(y * frame.h);
			SDL_BlitSurface(textSurface,null,this.frame,rect);
			SDL_FreeSurface(textSurface);
			delete rect;
			}
		}
	};

	SDL_Surface* getFrame() {
	return frame;
	};
	
	};
