module shape;

private import matrices;
private import sdlexception;

private import std.math;
private import std.string;
private import std.stdio;

private import derelict.sdl.sdl;

alias float[2] TVector2;

alias float[3] TVector3;

alias float[4] TVector4;

alias float[6] Triangle2D;

struct Shape {
	TVector3[] points;
	uint[] index;
	Matrix modelView = null;
	};

struct ShadedShape {
	TVector3[] points;
	uint[] index;
	uint[] colorPalette; /* length not greater than points.length and not lease than 1 */
	uint[] shadeIndex; /* shadeIndex.length == points.length */
	Matrix modelView = null;
	
	/+Shape opCast() {
	Shape sh;
	sh.points[] = points[];
	sh.index[] = index[];
	if (modelView is null) sh.modelView = null; else sh.modelView = modelView;
	return sh;
	};+/
	
	};

class Texture {
	private:
	char[] filename;
	SDL_Surface* surface;
	
	public:
	this(char[] filename) {
	if (filename.length == 0) throw new SDLException();
	this.filename = filename;
	char* stringzFilename = toStringz(filename);
	surface = SDL_LoadBMP(stringzFilename);
	if (SDL_BYTEORDER == SDL_BIG_ENDIAN) {
		uint b = surface.w * surface.h;
		ubyte* p;
		ubyte q;
		for (uint i = 0; i < b; i++) {
			p = cast(ubyte*)(&((cast(uint*)(surface.pixels))[i]));
			q = p[0];
			p[0] = p[2];
			p[2] = q;
			p[3] = 0;
			}
		}
	delete stringzFilename;
	};
	
	~this() {
	if (surface !is null) SDL_FreeSurface(surface);
	delete filename[];
	};

	uint w() {
	if (surface is null) return 0; else return surface.w;
	};

	uint h() {
	if (surface is null) return 0; else return surface.h;
	};

	uint opIndex(uint x,uint y) {
	if ((surface is null) || (x >= surface.w) || (y >= surface.h)) return 0;
	uint c,p;
	c = (cast(uint*)(surface.pixels))[y * surface.w + x];
	if (SDL_BYTEORDER == SDL_BIG_ENDIAN) {
		(cast(ubyte*)(&p))[0] = (cast(ubyte*)(&c))[2];
		(cast(ubyte*)(&p))[1] = (cast(ubyte*)(&c))[1];
		(cast(ubyte*)(&p))[2] = (cast(ubyte*)(&c))[0];
		(cast(ubyte*)(&p))[3] = 0;
		}
	else p = c;
	return p;
	};

	char[] getFilename() {
	return filename;
	};

	SDL_Surface* getSurface() {
	return surface;
	};
	
	};

struct TexturedShape {
	TVector3[] points;
	uint[] index;
	Texture texture;
	TVector3[] tPoints;
	uint[] tIndex;
	Matrix modelView = null;
	};

Matrix makeRotation(real x,real y,real z,TVector3 r) {
Matrix Ax = new Matrix(4,4), Ay = new Matrix(4,4), Az = new Matrix(4,4), A;
TVector4 aj,rj;
rj[0..3] = r[];
rj[3] = 1.0;
/* X - rotation */
Ax[0,0] = Ax[3,3] = 1.0;
Ax[1,1] = Ax[2,2] = cast(float)cos(x);
Ax[2,1] = cast(float)sin(x);
Ax[1,2] = cast(float)(-1) * cast(float)sin(x);
/* Y - rotation */
Ay[1,1] = Ay[3,3] = 1.0;
Ay[0,0] = Ay[2,2] = cast(float)cos(y);
Ay[0,2] = cast(float)sin(y);
Ay[2,0] = cast(float)(-1) * cast(float)sin(y);
/* Z - rotation */
Az[2,2] = Az[3,3] = 1.0;
Az[0,0] = Az[1,1] = cast(float)cos(z);
Az[1,0] = cast(float)sin(z);
Az[0,1] = cast(float)(-1) * cast(float)sin(z);
/* translates */
//writefln(Ax,newline,newline,Ay,newline,newline,Az,newline);
A = Ax * Ay * Az;
Ay = A;
for (uint i = 0; i < 4; i++) for (uint j = 0; j < 4; j++) Ax[i,j] = Az[i,j] = 0.0;
for (uint i = 0; i < 4; i++) Ax[i,i] = Az[i,i] = 1.0;
for (uint i = 0; i < 3; i++) {
	Ax[i,3] = r[i];
	Az[i,3] = cast(float)(-1) * r[i];
	}
/* linking */
A = Ax * Ay * Az;
return A;
};

Matrix makeMove(float dx,float dy,float dz) {
Matrix A = new Matrix(4,4);
for (uint i = 0; i < 4; i++) A[i,i] = 1.0;
A[0,3] = dx;
A[1,3] = dy;
A[2,3] = dz;
return A;
};
