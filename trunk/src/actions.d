module actions; //basic module

private {
	import derelict.sdl.sdl;
	
	import action;
	import shape;
	import matrices;
	import scene;
	import colors;
	import stringz;
	import listeners;
	import basic;
	
	import std.stdio;
	import std.string;
	import std.random;
	import std.math;
	import std.thread;
	import std.c.stdlib;
	import std.c.string;
	}

interface CollisionDetector {
	int checkAssuming(); // notifies object that could be put into coolision with one another
	void reportCollision(int x = 0,int y = 0); // report collision event
	};

class CubeRotation : Action {
	protected:
	Shape cube;
	Scene scene;
	Matrix m;
	uint color;
	Object shapeMutex;
	SDL_cond* var;

	public:
	this(Shape cube,Scene scene,Matrix m,uint color) {
	this.cube = cube;
	this.scene = scene;
	this.m = m;
	this.color = color;
	this.var = SDL_CreateCond();
	this.shapeMutex = new Object();
	this.cube.modelView = new Matrix(4,4);
	for (uint i = 0; i < 4; i++) this.cube.modelView[i,i] = 1.0;
	};

	int run() {
	while (true) {
		SDL_CondWait(this.var,null);
		synchronized (shapeMutex) {
			this.cube.modelView.apMul(this.m);
			}
		//SDL_Delay(100);
		}
	return 0;
	};

	void draw() {
	synchronized (shapeMutex) {
		this.scene.drawShape(this.cube,this.color);
		SDL_CondSignal(this.var);
		}
	};
	
	};


class ShadedCubeRotation : Action { // implements Action interface
	protected:
	ShadedShape* cube;
	Scene scene;
	Matrix m;
	Object shapeMutex;
	SDL_cond* var;

	public:
	this(ShadedShape* cube,Scene scene,Matrix m) {
	this.cube = cube;
	this.scene = scene;
	this.m = m;
	this.var = SDL_CreateCond();
	this.shapeMutex = new Object();
	this.cube.modelView = new Matrix(4,4);
	for (uint i = 0; i < 4; i++) this.cube.modelView[i,i] = 1.0;
	};

	int run() {
	while (true) {
		SDL_CondWait(this.var,null);
		synchronized (shapeMutex) {
			this.cube.modelView.apMul(this.m);
			}
		//SDL_Delay(100);
		}
	return 0;
	};

	void draw() {
	synchronized (shapeMutex) {
		this.scene.drawShadedShape(*(this.cube));
		SDL_CondSignal(this.var);
		}
	};
	
	};


class Metronome : Action {
	protected:
	Scene scene;
	uint color;
	uint ticks;
	uint time1,time2;
	float result;
	char* unit;

	Object resultMutex, ticksMutex;
	
	public:
	this(Scene scene,uint color) {
	this.ticks = 0;
	this.time1 = SDL_GetTicks();
	this.color = color;
	this.result = 0.0;
	this.scene = scene;
	this.unit = toStringz(" fr/s");
	this.resultMutex = new Object();
	this.ticksMutex = new Object();
	};

	/+~this() {
	//free(unit);
	};+/

	int run() {
	uint* time = new uint;
	scope(exit) delete time;
	while (true) {
		SDL_Delay(1000);
		time2 = SDL_GetTicks();
		*time = time2 - time1;
		if (*time >= 1000) {
			synchronized (this.resultMutex) {
				this.result = cast(float)ticks / (cast(float)(*time) / 1000.0);
				}
			this.time1 = time2;
			synchronized (this.ticksMutex) {
				this.ticks = 0;
				}
			}
		else {
			}
		}
	return 0;
	};

	void draw() {
	char* resultText;
	resultText = cast(char*)calloc(20,char.sizeof);
	synchronized (this.resultMutex) {
		ftostr(result,resultText);
		}
	strcat(resultText,unit);
	this.scene.drawText(resultText,0.7,0.02,color);
	free(resultText);
	synchronized (this.ticksMutex) {
		this.ticks++;
		}
	};
	
	};

class Image : Action {
	protected:
	Scene scene;
	Texture texture = null;
	float x,y;
	
	public:
	this(Scene scene,char[] filename,float x,float y) {
	this.scene = scene;
	this.x = x;
	this.y = y;
	this.texture = new Texture(filename);
 	};
	
	~this() {
	if (texture !is null) delete texture;
	};

	int run() {
	
	return 0;
	};

	void draw() {
	SDL_Rect rect;
	rect.x = cast(short)(this.x * scene.w());
	rect.y = cast(short)(this.y * scene.h());
	SDL_BlitSurface(texture.getSurface(),null,scene.getFrame(),&rect);
	};
	
	};

class SceneBackground : Action {
	protected:
	struct ObjProps {
	int[2] coords;
	float x,y;
	/* primary colors */
	//ubyte r,g,b;
	/* current colors */
	float h,s,v;
	bool sign;
	};
	
	Scene scene;
	ObjProps[] flash;
	SDL_cond* cond;

	const uint objNumDefault = 30;
	
	public:
	this(Scene scene,uint objNum = objNumDefault) {
	float lum;
	float r,g,b;
	float h,s,v;
	this.scene = scene;
	this.cond = SDL_CreateCond();
	this.flash.length = objNum;
	int width = scene.getFrame().w, height = scene.getFrame().h;
	for (uint i = 0; i < objNum; i++) {
		this.flash[i].coords[0] = std.random.rand() % width;
		this.flash[i].coords[1] = std.random.rand() % height;
		this.flash[i].x = cast(float)(this.flash[i].coords[0]) / cast(float)width;
		this.flash[i].y = cast(float)(this.flash[i].coords[1]) / cast(float)height;
		//writefln(this.flash[i].x * this.scene.getFrame().w," ",this.flash[i].y * this.scene.getFrame().h);
		lum = (std.random.rand() % 66 + 30) / 100.0; /* jasnosc obiektu od 30% do 95% */
		if (std.random.rand() % 10 == 0) {
			/* wstawianie niebieskiego obiektu */
			r = g = 0.0;
			b = 1.0;
			rgb2hsv(r,g,b,&h,&s,&v);
			v = lum;
			this.flash[i].h = h;
			this.flash[i].s = s;
			this.flash[i].v = v;
			this.flash[i].sign = std.random.rand() % 2 == 0 ? false : true;
			if (this.flash[i].v > 0.94) this.flash[i].sign = false;
			if (this.flash[i].v < 0.31) this.flash[i].sign = true;
			}
		else {
			/* wstawianie czerwonego - zielonego obiektu / wartosc G losowa*/
			r = 1.0;
			g = (std.random.rand() % 256) / 255.0;
			b = 0;
			rgb2hsv(r,g,b,&h,&s,&v);
			v = lum;
			this.flash[i].h = h;
			this.flash[i].s = s;
			this.flash[i].v = v;
			this.flash[i].sign = std.random.rand() % 2 == 0 ? false : true;
			if (this.flash[i].v > 0.94) this.flash[i].sign = false;
			if (this.flash[i].v < 0.31) this.flash[i].sign = true;
			}
		}
	};

	~this() {
	SDL_DestroyCond(this.cond);
	this.flash = null;
	};

	int run() {
	float r,g,b;
	float h,s,v;
	uint i;
	while (true) {
		SDL_CondWait(this.cond,null);
		//SDL_Delay(30);
		for (i = 0; i < this.flash.length; i++) {
			if (this.flash[i].sign) this.flash[i].v += 0.03; else this.flash[i].v -= 0.01;
			if (this.flash[i].v > 0.94) this.flash[i].sign = false;
			if (this.flash[i].v < 0.31) this.flash[i].sign = true;
			}
		}
	return 0;
	};

	void draw() {
	float r,g,b;
	int x,y;
	//SDL_Surface* frame;
	for (uint i = 0; i < this.flash.length; i++) {
		hsv2rgb(this.flash[i].h,this.flash[i].s,this.flash[i].v,&r,&g,&b);
		//frame = this.scene.getFrame();
		x = cast(int)(this.flash[i].x * this.scene.getFrame().w);
		y = cast(int)(this.flash[i].y * this.scene.getFrame().h);
		putPixel(this.scene.getFrame(),x,y,rgb(cast(ubyte)floor(r * 255),cast(ubyte)floor(g * 255),cast(ubyte)floor(b * 255)));
		}
	SDL_CondSignal(this.cond);
	};
	
};

class FlyingGifts : Action {
	private:
	ShadedShape shape;
	Shooter shooter;
	Craft craft;
	Counter counter;
	
	protected:
	struct Gift {
		float x,z;
		/* x - NOT being changed, z - being changed */
		TVector3[] points;
		uint colors;
		bool used = false;
		};
	Scene scene;

	SDL_cond* cond;

	Gift[] gift;

	TVector3[] giftPattern;
	uint[] giftPatternIndex;
	uint[][4] giftPatternColorPalette;
	uint[] giftPatternColorIndex;
	Matrix giftModelView = null;

	int num = 0;
	Object numMutex;

	float hop;

	ShadedShape* collisionShape = null;
	TVector3[] collisionCoords;

	public:
	this(Scene scene,float hop = 0.05) {
	this.scene = scene;
	this.cond = SDL_CreateCond();
	float D = scene.getObservingDistance();
	//this.giftPattern = [[0.05,0.7,D - 0.05],[0.0,0.75,D - 0.05],[0.05,0.75,D - 0.1],[0.1,0.75,D - 0.05],[0.05,0.75,D],[0.05,0.8,D - 0.05]];
	this.giftPattern = [[0.05,0.7,D + 0.05],[0.0,0.75,D + 0.05],[0.05,0.75,D],[0.1,0.75,D + 0.05],[0.05,0.75,D + 0.1],[0.05,0.8,D + 0.05]];
	this.giftPatternIndex = [0,2,1,0,3,2,0,4,3,0,1,4,1,2,5,2,3,5,3,4,5,4,1,5];
	this.giftPatternColorIndex = [0,2,1,0,3,2,0,4,3,0,1,4,1,2,5,2,3,5,3,4,5,4,1,5];
	giftPatternColorPalette[0] = [rgb(128,128,128),rgb(192,192,192),rgb(192,192,192),rgb(192,192,192),rgb(192,192,192),rgb(128,128,128)];
	giftPatternColorPalette[1] = [rgb(255,0,0),rgb(255,255,0),rgb(255,128,0),rgb(255,255,0),rgb(255,128,0),rgb(255,0,0)];
	giftPatternColorPalette[2] = [rgb(0,255,0),rgb(0,64,0),rgb(0,64,0),rgb(0,64,0),rgb(0,64,0),rgb(0,255,0)];
	giftPatternColorPalette[3] = [rgb(0,0,255),rgb(255,0,0),rgb(255,0,0),rgb(255,0,0),rgb(255,0,0),rgb(0,255,0)];
	this.hop = hop;
	this.numMutex = new Object();
	this.gift.length = 0;
	this.shape.index = this.giftPatternIndex;
	this.shape.shadeIndex = this.giftPatternColorIndex;
	this.shape.modelView = new Matrix(4,4);
	for (uint i = 0; i < 4; i++) this.shape.modelView[i,i] = 1.0;
	this.shooter = null;
	this.craft = null;
	this.counter = null;
	};

	~this() {
	SDL_DestroyCond(cond);
	};

	int run() {
	uint index,i,j;
	uint last = 0;
	int num;
	float D = this.scene.getObservingDistance();
	Ammo[] ammo;
	Ammo* temp;
	while (true) {
		SDL_CondWait(this.cond,null);
		synchronized (numMutex) {
			num = this.num;
			}
		if ((num <= 0) || (this.gift[last].z > 0.25 * D - 0.05)) {
			index = 0;
			while ((index < this.gift.length) && (this.gift[index].used)) index++;
			if (index == this.gift.length) this.gift.length = this.gift.length + 1;
			this.gift[index].used = true;
			this.gift[index].x = cast(float)(std.random.rand() % 91) / 100.0;
			this.gift[index].z = 0.0;
			this.gift[index].points.length = this.giftPattern.length;
			this.gift[index].points[] = this.giftPattern[];
			for (i = 0; i < this.gift[index].points.length; i++) {
				this.gift[index].points[i][0] += this.gift[index].x;
				}
			this.gift[index].colors = std.random.rand() % 4;
			/+//if (num == 0) {
				num++;
				synchronized (numMutex) {
					this.num++;
					}
			//	}+/
			last = index;
			//writefln(index);
			//writefln(this.gift[index].points[0]);
			}
		else {
			if ((this.collisionShape !is null) && (this.collisionShape.modelView !is null)) {
				this.collisionCoords[] = this.collisionShape.points[];
				for (i = 0; i < this.collisionCoords.length; i++) {
					transform(this.collisionShape.modelView,this.collisionCoords[i]);
					}
				}
			for (i = 0; i < this.gift.length; i++) {
				for (j = 0; j < this.gift[i].points.length; j++) {
					this.gift[i].points[j][2] -= this.hop;
					}
				this.gift[i].z += this.hop;
				if (this.gift[i].points[4][2] < 0.0) {
					this.gift[i].used = false;
					/+synchronized (this.numMutex) {
						num = this.num;
						}
					//num--;
					synchronized (this.numMutex) {
						this.num = num;
						}+/
					}
				if ((this.collisionShape !is null) && (this.collisionShape.modelView !is null)) {
					/* checking collision with pencil */
					if (this.gift[i].points[2][2] <= this.collisionCoords[0][2]) {
						if (((this.gift[i].points[1][0] >= this.collisionCoords[18][0]) && (this.gift[i].points[1][0] <= this.collisionCoords[20][0])) || 
							((this.gift[i].points[3][0] >= this.collisionCoords[18][0]) && (this.gift[i].points[3][0] <= this.collisionCoords[20][0]))) {

							if (this.gift[i].used) {
								if (this.gift[i].colors == 0) {
									this.shooter.load(3);
									this.gift[i].used = false;
									}
								else {
									if ((this.craft !is null) && (this.craft.isEnabled())) {
										if (this.counter !is null) {
											this.counter.giveDots(-5);
											this.counter.reportFail();
											}
										this.craft.setEnabled(false);
										}
									this.gift[i].used = false;
									}
								}
							}
						}
					}
				if (shooter !is null) {
					ammo = shooter.getAmmo();
					for (j = 0; j < ammo.length; j++) {
						/* !!! UWAGA NA WYCIEK PAMIECI !!! */
						temp = &(ammo[j]);
						if (!(temp.launched)) continue;
						/* checking collision with rocket */
						if ((temp.points[0][0] >= this.gift[i].points[1][0]) && (temp.points[0][0] <= this.gift[i].points[3][0]) && (temp.points[0][2] >= this.gift[i].points[2][2])) {
							temp.launched = temp.loaded = false;
							if (this.gift[i].colors != 2) {
								if (counter !is null) this.counter.giveDots();
								this.gift[i].used = false;
								}
							}
						}
					}
				}
			}
		}
	return 0;
	};

	void draw() {
	int num = 0;
	//if (num > 0) {
		for (int i = this.gift.length - 1; i >= 0; i--) {
		//for (int i = 0; i < this.gift.length; i++) {
			if (this.gift[i].used) {
				this.shape.points = this.gift[i].points;
				this.shape.colorPalette = this.giftPatternColorPalette[this.gift[i].colors];
				//for (uint j = 0; j < this.shape.points.length; j++) writefln(this.shape.points[j]);
				//writefln(this.shape.shadeIndex);
				this.scene.drawShadedShape(this.shape);
				num++;
				}
			}
	//	}
	synchronized (numMutex) {
		this.num = num;
		}
	SDL_CondSignal(this.cond);
	};

	void setCollisionShape(ShadedShape* shape) {
	this.collisionShape = shape;
	this.collisionCoords.length = this.collisionShape.points.length;
	};

	void setShooter(Shooter shooter) {
	this.shooter = shooter;
	};

	void setCraft(Craft craft) {
	this.craft = craft;
	};

	void setCounter(Counter counter) {
	this.counter = counter;
	};
	
};

class Counter : Action {
	private:
	uint mana,dots;
	uint manaColor,dotsColor,lifelineColor;
	char* manaResult,dotsResult;
	uint lifeline,originLifeline;
	char* lifelineResult;

	SDL_cond* cond;

	Scene scene;
	
	public:
	this(Scene scene,uint lifeline = 3) {
	this.mana = this.dots = 0;
	this.manaColor = rgb(255,255,0);
	this.dotsColor = rgb(0,255,0);
	this.lifelineColor = rgb(255,255,255);
	this.cond = SDL_CreateCond();
	this.scene = scene;
	this.manaResult = cast(char*)calloc(20,char.sizeof);
	this.dotsResult = cast(char*)calloc(20,char.sizeof);
	this.lifeline = this.originLifeline = lifeline;
	this.lifelineResult = cast(char*)calloc(20,char.sizeof);
	};

	~this() {
	if (this.manaResult !is null) free(this.manaResult);
	if (this.dotsResult !is null) free(this.dotsResult);
	if (this.dotsResult !is null) free(this.lifelineResult);
	SDL_DestroyCond(cond);
	};

	int run() {
	while (true) {
		uitostr(this.mana,this.manaResult);
		uitostr(this.dots,this.dotsResult);
		uitostr(this.lifeline,this.lifelineResult);
		SDL_CondWait(this.cond,null);
		}
	return 0;
	};

	void draw() {
	this.scene.drawText(this.lifelineResult,0.05,0.02,this.lifelineColor);
	this.scene.drawText(this.manaResult,0.15,0.02,this.manaColor);
	this.scene.drawText(this.dotsResult,0.35,0.02,this.dotsColor);
	if (!(this.isLiving())) this.scene.drawText(toStringz("GAME OVER :D :D :D"),0.27,0.2,this.manaColor);
	};

	void giveMana(uint val) {
	this.mana = val;
	SDL_CondSignal(this.cond);
	};

	void giveDots(int val = 1) {
	this.dots = cast(uint)((cast(int)this.dots + val > 0) ? (cast(int)this.dots + val) : 0);
	SDL_CondSignal(this.cond);
	};

	bool isLiving() {
	return this.lifeline > 0 ? true : false;
	};

	void reportFail() {
	this.lifeline = this.lifeline > 0 ? this.lifeline - 1 : 0;
	SDL_CondSignal(this.cond);
	};

	void renew() {
	this.lifeline = this.originLifeline;
	this.mana = this.dots = 0;
	SDL_CondSignal(cond);
	};
	
	};

class EscapeQuit : KeyboardEvent {
	protected:
	void keyDown(SDLKey key,SDLMod mod) {
	if (key == SDLK_ESCAPE) {
		SDL_Event e;
		e.type = SDL_QUIT;
		SDL_PushEvent(&e);
		}
	};

	void keyUp(SDLKey key,SDLMod mod) {
	
	};
	
	public:
	this() {
	super();
	};
	
	};

class ShadedShapeMotion : KeyboardEvent {
	protected:
	ShadedShape* shape;
	float speed;
	Matrix AxRight,AxLeft,AyDown,AyUp;

	void keyDown(SDLKey key,SDLMod mod) {
	switch (key) {
		case SDLK_UP:	this.shape.modelView.apMul(AyUp);
						break;
		case SDLK_DOWN:	this.shape.modelView.apMul(AyDown);
						break;
		case SDLK_LEFT:	this.shape.modelView.apMul(AxLeft);
						break;
		case SDLK_RIGHT:this.shape.modelView.apMul(AxRight);
						break;
		default:		break;
		}
	};

	void keyUp(SDLKey key,SDLMod mod) {
	
	};

	public:
	this(ShadedShape* shape,float speed = 0.01) {
	super();
	this.shape = shape;
	if (this.shape.modelView is null) {
		this.shape.modelView = new Matrix(4,4);
		for (uint i = 0; i < 4; i++) this.shape.modelView[i,i] = 1.0;
		}
	this.speed = speed;
	this.AxRight = makeMove(this.speed,0.0,0.0);
	this.AyDown = makeMove(0.0,this.speed,0.0);
	this.AxLeft = makeMove(-this.speed,0.0,0.0);
	this.AyUp = makeMove(0.0,-this.speed,0.0);
	};
	
	};

class Craft : Action {
	protected:
	Scene scene;
	ShadedShape shape;

	bool enabled = true;

	public:
	this(Scene scene) {
	this.scene = scene;
	/+
	this.shape.points = [[0.125,0.75,0.5],
						[0.1125,0.775,0.4],[0.1375,0.775,0.4],[0.15,0.7625,0.4],[0.15,0.7375,0.4],
						[0.1375,0.725,0.4],[0.1125,0.725,0.4],[0.1,0.7375,0.4],[0.1125,0.7625,0.4],
						[],[],[],
						[],[],[],
						[],[],[],
						[],[],[],
						[],[],[],
						[],[],[],
						[],[],[],
						[],[],[]];
	+/
	this.shape.points = [[0.125,0.75,0.5],//czolo
	/* dylatacja 1 */	[0.1125,0.775,0.4],[0.1375,0.775,0.4],[0.15,0.7625,0.4],[0.15,0.7375,0.4],
	/*dylatacja 1 c.d.*/[0.1375,0.725,0.4],[0.1125,0.725,0.4],[0.1,0.7375,0.4],[0.1125,0.7625,0.4],
	/* zlacze 1 */		[0.1,0.7375,0.35],[0.1,0.7625,0.35],[0.15,0.7375,0.35],[0.15,0.7625,0.35],
	/* zlacze 2 */		[0.1,0.7375,0.15],[0.1,0.7625,0.15],[0.15,0.7375,0.15],[0.15,0.7625,0.15],
	/* skrzydlo lewe */	[0.0,0.775,0.25],[0.0,0.775,0.15],
	/* skrzydlo prawe */[0.25,0.775,0.25],[0.25,0.775,0.15],
	/* dylatacja 2 */	[0.1125,0.775,0.1],[0.1375,0.775,0.1],[0.15,0.7625,0.1],[0.15,0.7375,0.1],
	/*dylatacja 2 c.d.*/[0.1375,0.725,0.1],[0.1125,0.725,0.1],[0.1,0.7375,0.1],[0.1125,0.7625,0.1],[0.125,0.75,0.1]];
//	/* dysze */			[],[],[],[]];
/+	this.shape.index = [0,8,7,0,7,6,0,6,5,0,5,4,0,4,3,0,3,2,0,2,1,0,1,8,
						1,2,22,22,21,1,
						2,3,23,23,22,2,
						//3,4,24,24,23,3,
	/*miejsce na lewe*/	3,4,11,11,12,3,
	/* dopelnienie */	16,15,24,24,23,16,
						4,5,25,25,24,4,
						5,6,26,26,25,5,
						6,7,27,27,26,6,
						//7,8,28,28,27,7,
	/*miejsce na prawe*/7,8,10,10,9,7,
	/* dopelnienie */	13,14,28,28,27,13,
						8,1,21,21,28,8,
//	/* skrzydlo lewe */	9,17,10,13,14,18,10,14,18,18,17,10,18,13,9,9,17,18,
	/* skrzydlo lewe */	9,17,10,13,14,18,10,17,18,18,14,10,18,17,9,9,13,18,
//	/* skrzydlo prawe */19,11,12,15,16,20,16,20,19,19,12,16,15,11,19,19,20,15];
	/* skrzydlo prawe */19,11,12,15,16,20,16,20,19,19,12,16,15,11,19,19,20,15];
	+/
	this.shape.index = [0,1,2,0,2,3,0,3,4,0,4,5,0,5,6,0,6,7,0,7,8,0,8,1,
	/+miejsce na prawe+/
						16,15,20,11,12,19,12,16,20,20,19,12,11,19,20,20,15,11,
						2,1,21,21,22,2,3,2,22,22,23,3,
						//4,3,23,23,24,4,
						1,8,28,28,21,1,
						21,29,22,22,29,23,23,29,24,24,29,25,25,29,26,26,29,27,27,29,28,28,29,21,
	/+miejsce na lewe+/	8,7,9,9,10,8,14,13,27,27,28,14,
						18,13,14,17,10,9,17,10,14,14,18,17,9,13,18,18,17,9,
						5,4,24,24,25,5,6,5,25,25,26,6,7,6,26,26,27,7
						//8,7,27,27,28,8,
						];
	this.shape.colorPalette = [rgb(128,0,0),rgb(64,64,64),rgb(192,192,192),rgb(252,221,1),rgb(0,0,0),rgb(255,255,255)];
	this.shape.shadeIndex = [0,1,1,0,1,1,0,1,1,0,1,1,0,1,1,0,1,1,0,1,1,0,1,1,
	/+miejsce na prawe+/	
							1,1,5,1,1,5,1,1,5,5,5,1,1,5,5,5,1,1,
							/+1,1,2,2,2,1,1,1,2,2,2,1,1,1,2,2,2,1,1,1,2,2,2,1,
							1,1,2,2,2,1,1,1,2,2,2,1,1,1,2,2,2,1,1,1,2,2,2,1];+/
							1,1,2,2,2,1,1,1,2,2,2,1,
							1,1,2,2,2,1,
							2,4,2,2,4,2,2,4,2,2,4,2,2,4,2,2,4,2,2,4,2,2,4,2,
	/+miejsce na lewe+/		1,1,2,2,2,1,1,1,2,2,2,1,
							5,1,1,5,1,1,5,1,1,1,5,5,1,1,5,5,5,1,
							1,1,2,2,2,1,1,1,2,2,2,1,1,1,2,2,2,1
							];
	/+this.shape.shadeIndex = [0,1,1,0,1,1,0,1,1,0,1,1,0,1,1,0,1,1,0,1,1,0,1,1,
							1,1,2,2,2,1,
							1,1,2,2,2,1,
							1,1,2,2,2,1,
							1,1,2,2,2,1,
	/* dopelnienie lewe */	3,3,3,3,3,3,
							1,1,2,2,2,1,
							1,1,2,2,2,1,
							1,1,2,2,2,1,
							1,1,2,2,2,1,
							1,1,2,2,2,1,
	/* dopelnienie prawe */	3,3,3,3,3,3,
							1,1,2,2,2,1,
	/* skrzydlo lewe */		3,3,4,3,3,4,3,3,4,4,4,3,4,3,3,3,4,4,
							4,3,3,3,3,4,3,3,4,4,4,3,3,4,4,4,3,3];+/
	};

	int run() {
	//Thread.getThis().pause();
	return 0;
	};

	void draw() {
	if (this.enabled) this.scene.drawShadedShape(this.shape);
	};

	ShadedShape* getCraft() {
	return &(this.shape);
	};

	bool isEnabled() {
	return this.enabled;
	};

	void setEnabled(bool val) {
	this.enabled = val;
	};
	
	};

class SettingHop : KeyboardEvent {
	
	
	};

class CraftCurve : KeyboardEvent {
	protected:
	ShadedShape* craft;
	Matrix leftMotion,rightMotion;
	Craft craftAction = null;
	
	public:
	this(ShadedShape* craft,Craft craftAction) {
		this.craftAction = craftAction;
	this.craft = craft;
	if (this.craft.modelView is null) this.craft.modelView = new Matrix(4,4);
	for (uint i = 0; i < 4; i++) for (uint j = 0; j < 4; j++) if (i == j) this.craft.modelView[i,j] = 1.0; else this.craft.modelView[i,j] = 0.0;
	this.leftMotion = makeMove(-0.05,0.0,0.0);
	this.rightMotion = makeMove(0.05,0.0,0.0);
	};

	void keyDown(SDLKey key,SDLMod mod) {
	if (!(this.craftAction.isEnabled())) return;
	float pos = 0.0;
	for (uint i = 0; i < 3; i++) {
		pos += this.craft.modelView[0,i] * this.craft.points[0][i];
		}
	pos += this.craft.modelView[0,3];
	switch (key) {
		case SDLK_UP:	
						break;
		case SDLK_DOWN:	
						break;
		case SDLK_LEFT:	if (pos > 0.05) {
							this.craft.modelView.apMul(this.leftMotion);
							}
						break;
		case SDLK_RIGHT:if (pos < 1.0) {
							this.craft.modelView.apMul(this.rightMotion);
							}
						break;
		default:		break;
		}
	};

	void keyUp(SDLKey key,SDLMod mod) {
	
	};
	
};

struct Ammo {
	bool loaded = false, launched = false;
	TVector3[5] points;
	};

class Shooter : Action {
	protected:
	Ammo[] ammo;
	uint num;

	SDL_cond* cond;

	ShadedShape pin;

	Scene scene;

	uint maxload;

	Counter counter;
	Craft craft;

	public:
	this(Scene scene,uint maxload = 5) {
	this.scene = scene;
	this.ammo.length = 0;
	this.num = 0;
	this.cond = SDL_CreateCond();
	this.pin.index = [0,1,2,0,2,3,0,3,4,0,4,1];
	this.pin.colorPalette = [rgb(128,0,0),rgb(218,158,158)];
	this.pin.shadeIndex = [0,1,1,0,1,1,0,1,1,0,1,1];
	this.pin.modelView = null;
	this.pin.points.length = 5;
	this.maxload = maxload;
	this.ammo.length = maxload + 1;
	this.counter = null;
	this.craft = null;
	};

	~this() {
	this.ammo = null;
	this.num = 0;
	SDL_DestroyCond(this.cond);
	};

	int run() {
	float D;
	while (true) {
		SDL_CondWait(cond,null);
		D = this.scene.getObservingDistance();
		uint j;
		for (uint i = 0; i < this.ammo.length; i++) {
			if (this.ammo[i].launched) {
				for (j = 0; j < this.ammo[i].points.length; j++) {
					this.ammo[i].points[j][2] += 0.08;
					if (this.ammo[i].points[j][2] > D) this.ammo[i].launched = false;
					}
				}
			}
		}
	return 0;
	};

	void draw() {
	//if (this.num > 0) {
		for (uint i = 0; i < this.ammo.length; i++) {
			if (this.ammo[i].launched) {
				pin.points[] = this.ammo[i].points[];
				scene.drawShadedShape(pin);
				}
			}
		//}
	SDL_CondSignal(cond);
	};

	void shoot(float x,float y = 0.75,float z = 0.5) {
	//if (this.num == 0) return;
	if ((this.num == 0) || ((this.craft !is null) && (!(this.craft.isEnabled())))) return;
	uint i = 0;
	while ((i < this.ammo.length) && (!(this.ammo[i].loaded))) i++;
	if (i == this.ammo.length) {
		return;
		}
	with (this.ammo[i]) {
		//points = [[x,y,z],[x - 0.0125,y - 0.0125,0.05],[x + 0.0125,y - 0.0125,0.05],[x + 0.0125,y + 0.0125,0.05],[x - 0.0125,y + 0.0125,0.05]];
		points[0][] = [x,y,z];
		points[1][] = [x - 0.0125f,y - 0.0125f,0.05f];
		points[2][] = [x + 0.0125f,y - 0.0125f,0.05f];
		points[3][] = [x + 0.0125f,y + 0.0125f,0.05f];
		points[4][] = [x - 0.0125f,y + 0.0125f,0.05f];
		loaded = false;
		launched = true;
		if (this.counter !is null) this.counter.giveMana(this.num - 1);
		}
	this.num--;
	};

	void load(uint p) {
	uint q = (this.maxload - this.num > p) ? p : (this.maxload - this.num);
	this.num += q;
	uint j = 0;
	for (uint i = 0; (i < this.ammo.length) && (j < q); i++) {
		if (!(this.ammo[i].loaded) && !(this.ammo[i].launched)) {
			this.ammo[i].loaded = true;
			j++;
			}
		}
	if (j < q) this.ammo.length = this.ammo.length + q;
	for (uint i = this.ammo.length - q; i < this.ammo.length; i++) {
		this.ammo[i].launched = false;
		this.ammo[i].loaded = true;
		}
	if (this.counter !is null) {
		//writefln(this.num);
		this.counter.giveMana(this.num);
		}
	/+for (uint i = 0; i < this.ammo.length; i++) {
		if (!(this.ammo[i].loaded) && !(this.ammo[i].launched)) {
			this.ammo[i].loaded = true;
			j++;
			}
		if (j == q) break;
		}
	if (j < q) {
		this.ammo.length = q - j;
		for (uint i = this.ammo.length - q + j; i < this.ammo.length; i++) {
			this.ammo[i].launched = false;
			this.ammo[i].loaded = true;
			}
		}+/
	};

	void setMaxLoad(uint maxload) {
	this.maxload = maxload + 1;
	//this.ammo.length = maxload;
	};

	Ammo[] getAmmo() {
	return ammo;
	};

	uint getNum() {
	return this.num;
	};

	void setCounter(Counter counter) {
	this.counter = counter;
	};

	void setCraft(Craft craft) {
	this.craft = craft;
	};
	
	};

class CraftShoot : KeyboardEvent {
	protected:
	Shooter shooter;
	ShadedShape* craft;

	bool busy;

	public:
	this(Shooter shooter,ShadedShape* craft) {
	this.shooter = shooter;
	this.craft = craft;
	this.busy = false;
	};

	~this() {
	
	};

	void keyDown(SDLKey key,SDLMod mod) {
	if (key == SDLK_SPACE) {
		if (this.busy) return;
		TVector3 barrel;
		if (this.craft !is null) {
			barrel[] = this.craft.points[0];
			if (this.craft.modelView !is null) transform(this.craft.modelView,barrel);
			}
		this.shooter.shoot(barrel[0],barrel[1],barrel[2]);
		this.busy = true;
		}
	};

	void keyUp(SDLKey key,SDLMod mod) {
	if (key == SDLK_SPACE) {
		this.busy = false;
		}
	};
	
	};

class Pause : KeyboardEvent {
	private:
	bool status = true;
	
	public:
	void keyDown(SDLKey key,SDLMod mod) {
	if (key == SDLK_p) {
		if (status) {
			Thread.pauseAll();
			status = false;
			}
		else {
			Thread.resumeAll();
			status = true;
			}
		}
	};

	void keyUp(SDLKey key,SDLMod mod) {
	
	};
	
	};

class Recharger : KeyboardEvent {
	private:
	Craft craft;
	Counter counter;
	
	public:
	this(Craft craft,Counter counter = null) {
	this.craft = craft;
	this.counter = counter;
	};

	~this() {
	
	};
	
	void keyDown(SDLKey key,SDLMod mod) {
	if (key == SDLK_F1) {
		if (craft !is null) {
			if (!(craft.isEnabled())) craft.setEnabled(true);
			if ((counter !is null) && (!(counter.isLiving()))) {
				counter.renew();
				}
			}
		}
	};
	
	void keyUp(SDLKey key,SDLMod mod) {
	
	};
	
	};
