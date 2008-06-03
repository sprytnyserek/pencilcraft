module engine;

private import derelict.sdl.sdl;
private import derelict.sdl.ttf;

private import std.stdio;
private import std.string;
private import std.thread;

private import scene;
private import listeners;
private import sdlexception;
private import listeners;
private import action;

class Engine {
	protected:
	Scene[] scene;
	//ActionPerformer actionPerformer;
	//EventLoop eventLoop;
	
	public:
	this() {
	DerelictSDL.load();
	DerelictSDLttf.load();
	SDL_Init(SDL_INIT_VIDEO | SDL_INIT_TIMER);
	if (TTF_WasInit() == 0) TTF_Init();
	//eventLoop = new EventLoop();
	};

	this(char[] iconFileName) {
	this();
	SDL_WM_SetIcon(SDL_LoadBMP(toStringz(iconFileName)), null);
	};
	
	~this() {
	//SDL_Quit();
	Thread.pauseAll();
	DerelictSDLttf.unload();
	DerelictSDL.unload();
	};

	/+Scene createScene(uint w,uint h) {
	this.scene = new Scene(w,h);
	return this.scene;
	};+/
	
	Scene createScene(uint w,uint h) {
	this.scene.length = this.scene.length + 1;
	this.scene[this.scene.length - 1] = new Scene(w,h);
	return this.scene[this.scene.length - 1];
	};

	uint sceneNum() {
	return scene.length;
	};

	Scene getScene(uint i) {
	if (i < scene.length) return scene[i]; else throw new SDLException();
	};

	void waitForQuit() {
	SDL_Event event;
	while (true) {
		SDL_WaitEvent(&event);
		if (event.type == SDL_QUIT) break; else {
			
			}
		}
	};
	
	};
