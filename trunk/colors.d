module colors;

private import derelict.sdl.sdl;

extern (C) {
	float maxrgb(float r,float g,float b);
	float minrgb(float r,float g,float b);
	void rgb2hsv(float r,float g,float b,float* hout,float* sout,float* vout);
	void hsv2rgb(float hin,float s,float v,float* rout,float* gout,float* bout);
	};

alias maxrgb max3;
alias minrgb min3;

uint rgb(ubyte R,ubyte G,ubyte B,ubyte A = 0) {
uint x;
ubyte* y = cast(ubyte*)&x;
if (SDL_BYTEORDER == SDL_BIG_ENDIAN) {
	y[0] = R;
	y[1] = G;
	y[2] = B;
	y[3] = A;
	}
else {
	y[0] = B;
	y[1] = G;
	y[2] = R;
	y[3] = A;
	}
return x;
};
/+
void rgb2hsv(ubyte R,ubyte G,ubyte B,float* H,float* S,float* V) {

};

void hsv2rgb(float H,float S,float V,ubyte* R,ubyte* G,ubyte* B) {

};
+/
uint hsv(float H,float S,float V) {
uint x;

return x;
};
