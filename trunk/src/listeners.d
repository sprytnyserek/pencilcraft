module listeners;

private {
	import derelict.sdl.sdl;
	
	import std.gc;
	import std.stdio;
	
	import action;
	import scene;
	}

class Event {
	protected:
	uint eventMask;

	public:
	this(uint eventMask) {
	this.eventMask = eventMask;
	};
	
	~this() {
	
	};

	uint getEventMask() {
	return this.eventMask;
	};

	abstract void perform(SDL_Event event);
	
};

/+class MouseEvent : Event {
	
};+/

class KeyboardEvent : Event {
	protected:
	abstract void keyDown(SDLKey key,SDLMod mod);
	abstract void keyUp(SDLKey key,SDLMod mod);

	public:
	this() {
	super(SDL_KEYDOWNMASK | SDL_KEYUPMASK);
	
	};

	void perform(SDL_Event event) {
	uint mask = 1 << event.type;
	if (event.type == SDL_KEYDOWN) {
		keyDown(event.key.keysym.sym,event.key.keysym.mod);
		}
	if (event.type == SDL_KEYUP) {
		keyUp(event.key.keysym.sym,event.key.keysym.mod);
		}
	};

};


class EventLoop {
	protected:
	Event[] event;
	//Action[] action;
	Scene scene;
	
	public:
	this(Scene scene) {
	this.scene = scene;
	//action.length = 0;
	event.length = 0;
	SDL_EnableKeyRepeat(1,SDL_DEFAULT_REPEAT_INTERVAL);
	};

	uint addListener(Event e) {
	uint id = 0;
	while ((id < event.length) && (event[id] !is null)) id++;
	if (id == event.length) event.length = event.length + 1;
	event[id] = e;
	return id;
	};

	void removeListener(Event e) {
	uint id = 0;
	while ((id < event.length) && (event[id] !is e)) id++;
	if (id < event.length) event[id] = null;
	};

	void removeListener(uint id) {
	if ((id < event.length) && (event[id] !is null)) event[id] = null;
	};
	/+
	uint addListener(Action a,Event e) {
	uint id = 0;
	while ((id < action.length) && (action[id] !is null)) id++;
	if (id == action.length) action.length = action.length + 1;
	if (id >= event.length) event.length = action.length;
	action[id] = a;
	event[id] = e;
	return id;
	};

	void removeListener(Action a) {
	uint id = 0;
	while ((id < action.length) && (action[id] !is a)) id++;
	if (id < action.length) action[id] = null;
	if (id < event.length) event[id] = null;
	};

	void removeListener(uint id) {
	if ((id < action.length) && (action[id] !is null)) action[id] = null;
	if ((id < event.length) && (event[id] !is null)) event[id] = null;
	};+/

	void run() {
	SDL_Event event;
	uint i;
	uint eventMask;
	while (true) {
		/+scene.clear();
		for (i = 0; i < action.length; i++) {
			if (action[i] !is null) {
				action[i].run();
				}
			}
		scene.redraw();+/
		
		SDL_WaitEvent(&event);
		if (event.type == SDL_QUIT) break; else {
			switch (event.type) {
				case SDL_VIDEORESIZE:	scene.resetVideoMode(event.resize.w,event.resize.h);
										break;
				default:				/* obsluga innych zdarzen */
										eventMask = 1 << event.type;
										//writefln(this.event.length);
										for (i = 0; i < this.event.length; i++) {
											
											if ((this.event[i] !is null)/+ && (this.event[i].getEventMask() & eventMask != 0)+/) {
												this.event[i].perform(event);
												}
											}
				}
			}
		
		}
	};

};