module action;

private import derelict.sdl.sdl;
private import std.thread;
private import std.stdio;
private import std.gc;

private import scene;

interface Action {
	void draw();
	int run();
	};

class ActionPerformer : public Thread {
	protected:
	Action[] action;
	Object actionListMutex;
	Thread[] thread;
	//Object[] cond;
	Scene scene;
	
	public:
	this(Scene scene) {
		this.scene = scene;
		actionListMutex = new Object();
		super();
		};

	~this() {
		action.length = 0;
		};

	uint addAction(Action a) {
	uint id = 0;
	synchronized (actionListMutex) {
		while ((id < action.length) && (action[id] !is null)) id++;
		if (id == action.length) action.length = action.length + 1;
		action[id] = a;
		if (id >= thread.length) thread.length = action.length;
		thread[id] = new Thread(&(action[id].run));
		thread[id].start();
		}
	return id;
	};

	void removeAction(Action a) {
	uint id = 0;
	synchronized (actionListMutex) {
		while ((id < action.length) && (action[id] !is a)) id++;
		if (id < action.length) {
			action[id] = null;
			if (thread[id] !is null) {
				delete thread[id];
				thread[id] = null;
				}
			}
		}
	};

	void removeAction(uint id) {
	synchronized (actionListMutex) {
		if ((id < action.length) && (action[id] !is null)) {
			action[id] = null;
			if (thread[id] !is null) {
				delete thread[id];
				thread[id] = null;
				}
			}
		}
	};
	
	/+uint addAction(Action a) {
	uint id = 0;
	while ((id < action.length) && (action[id] !is null)) id++;
	if (id == action.length) action.length = action.length + 1;
	action[id] = a;
		int runAction() {
		while (true) {
			Thread.getThis().pause();
			synchronized (cond[id]) {
				action[id].run();
				}
			}
		return 0;
		};
	if (thread.length < action.length) thread.length = action.length;
	if (cond.length < action.length) cond.length = action.length;
	thread[id] = new Thread(&runAction);
	cond[id] = new Object();
	thread[id].start();
	return id;
	};

	void removeAction(Action a) {
	uint id;
	while ((id < action.length) && (action[id] !is a)) id++;
	if (id < action.length) {
		action[id] = null;
		delete thread[id];
		thread[id] = null;
		delete cond[id];
		cond[id] = null;
		}
	};

	void removeAction(uint id) {
	if ((id < action.length) && (action[id] !is null)) {
		action[id] = null;
		delete thread[id];
		thread[id] = null;
		delete cond[id];
		cond[id] = null;
		}
	};+/

	int run() {
	uint i;
	while (true) {
		scene.clear();
		synchronized (actionListMutex) {
			for (i = 0; i < action.length; i++) {
				if (action[i] !is null) {
					//action[i].run();
					if ((thread[i] !is null) && (thread[i].getState() == TS.TERMINATED)) {
						thread[i].wait();
						thread[i] = null;
						}
					action[i].draw();
					}
				}
			}
		scene.redraw();
		//SDL_Delay(5);
		}
	return 0;
	};
	
	/+int run() {
	//thread.length = action.length;
	while (true) {
		scope(exit) {
			foreach (uint i, Thread t; thread) {
			if (t !is null) {
				delete t;
				}
			}
			}
		scene.clear();
		foreach (uint i, Thread t; thread) {
			if (t !is null) {
				t.resume();
				}
			}
		foreach (uint i, Object o; cond) {
			if (o !is null) {
				synchronized (o) {
					;
					}
				}
			}
		scene.redraw();
		}
	
	return 0;
	};+/
	
	};

/+interface Action {
	void run();
	};

class ActionPerformer : Thread {
	protected:
	Action action;
	
	int run() {
	action.run();
	return 0;
	};
	
	public:
	this(Action action) {
	this.action = action;
	super();
	};
	
	};
+/
/+
class ActionPerformer {
	protected:
	SDL_Thread* threadPointer;
	int (C)(void*);
	bool running;
	
	public:
	this(int function(void*) run) {
	this.C = run;
	this.running = false;
	this.threadPointer = null;
	};

	void start() {
	if (!running) {
		this.threadPointer = SDL_CreateThread(C,null);
		if (this.threadPointer !is null) this.running = true;
		}
	};

	void kill() {
	
	};
	
	};
+/
