module main;

import derelict.sdl.sdl;

import action;
import basic;
import colors;
import engine;
import scene;
import shape;
import matrices;
import listeners;
import sdlexception;

import std.stdio;
import std.math;
import std.string;

import actions;

//const uint xRes = 1022, yRes = 710;
const uint xRes = 800, yRes = 600;

int main(char[][] args) {
Engine engine = new Engine("bro.bmp");
Scene scene = engine.createScene(xRes,yRes);
ActionPerformer actionPerformer = new ActionPerformer(scene);
EventLoop eventLoop = new EventLoop(scene);
Shape cube,cube2;
ShadedShape shCube;
ShadedShape* craft;
Matrix m,m2;
//scene.setBackgroundColor(rgb(236,233,216)); // natural color
//scene.setBackgroundColor(rgb(255,0,128));
scene.setObservingDistance(2.75);
scene.setCaption("SDL Bro Test");
//scene.enableZbuffer();
//scene.disableZbuffer();

//cube.points = [[0.5,0.5,0.0],[0.8,0.5,0.0],[0.8,0.8,0.0],[0.5,0.8,0.0],
//					[0.5,0.5,0.3],[0.8,0.5,0.3],[0.8,0.8,0.3],[0.5,0.8,0.3]];
cube.points = [[0.25,0.25,0.5],[0.75,0.25,0.5],[0.75,0.75,0.5],[0.25,0.75,0.5],
			[0.25,0.25,1.0],[0.75,0.25,1.0],[0.75,0.75,1.0],[0.25,0.75,1.0]];
cube.index = [0,1,2,2,3,0,5,4,7,7,6,5,1,5,6,6,2,1,4,0,3,3,7,4,4,5,1,1,0,4,3,2,6,6,7,3];

cube2.points = [[0.25,0.25,0.5],[0.75,0.25,0.5],[0.75,0.75,0.5],[0.25,0.75,0.5],
			[0.25,0.25,1.0],[0.75,0.25,1.0],[0.75,0.75,1.0],[0.25,0.75,1.0]];
cube2.index = [0,1,2,2,3,0,5,4,7,7,6,5,1,5,6,6,2,1,4,0,3,3,7,4,4,5,1,1,0,4,3,2,6,6,7,3];

/+shCube.points = [[0.25,0.25,2.25],[0.75,0.25,2.25],[0.75,0.75,2.25],[0.25,0.75,2.25],
			[0.25,0.25,2.75],[0.75,0.25,2.75],[0.75,0.75,2.75],[0.25,0.75,2.75]];
+/
shCube.points = [[0.25,0.25,0.25],[0.75,0.25,0.25],[0.75,0.75,0.25],[0.25,0.75,0.25],
			[0.25,0.25,0.75],[0.75,0.25,0.75],[0.75,0.75,0.75],[0.25,0.75,0.75]];
shCube.index = [0,1,2,2,3,0,5,4,7,7,6,5,1,5,6,6,2,1,4,0,3,3,7,4,4,5,1,1,0,4,3,2,6,6,7,3];
shCube.colorPalette = [rgb(255,0,0), rgb(255,255,0), rgb(0,64,0)];
shCube.shadeIndex = [0,1,2,2,1,0,0,1,2,2,1,0,1,0,1,1,2,1,1,0,1,1,2,1,1,0,1,1,0,1,1,2,1,1,2,1];

//m = makeRotation(PI/24,-PI/24,PI/24,[0.5,0.5,2.5]);
m = makeRotation(PI/24,-PI/24,PI/24,[0.5,0.5,0.5]);
m2 = makeRotation(-PI/48,PI/48,-PI/48,[0.5,0.5,0.75]);
//Matrix m3 = makeRotation(0.0,PI/30,0.0,[0.5,0.5,2.75/2.0]);
Matrix m3 = makeRotation(0.0,PI/16,0.0,[1.0,1.0,0.0]);

//scene.getModelView().apMul(m3);

Texture texture = new Texture("Idylla.bmp");
scope(exit) delete texture;
//shadeTriangle(scene.getFrame(),[0.6,0.75,0.9,0.95,0.8,0.6],[rgb(255,255,0), rgb(0,0,0), rgb(255,255,0)]);
/+try {
	actionPerformer.addAction(new Image(scene,"Idylla.bmp",0.0,0.0));
	}
catch (SDLException) {
	}+/
scene.redraw();
actionPerformer.start();
//actionPerformer.addAction(new CubeRotation(cube,scene,m,rgb(255,255,0)));
//actionPerformer.addAction(new Image(scene,"Idylla.bmp",0.0,0.0));
actionPerformer.addAction(new SceneBackground(scene));
//actionPerformer.addAction(new ShadedCubeRotation(&shCube,scene,m));
FlyingGifts gifts = new FlyingGifts(scene,0.01);
actionPerformer.addAction(gifts);
Craft craftAction = new Craft(scene);
craft = craftAction.getCraft();
actionPerformer.addAction(craftAction);
Shooter shooter = new Shooter(scene,5);
shooter.setCraft(craftAction);
gifts.setCollisionShape(craft);
gifts.setShooter(shooter);
gifts.setCraft(craftAction);
actionPerformer.addAction(shooter);
Counter counter = new Counter(scene);
shooter.setCounter(counter);
gifts.setCounter(counter);
actionPerformer.addAction(counter);
actionPerformer.addAction(new Metronome(scene,rgb(255,0,0)));
//actionPerformer.addAction(new CubeRotation(cube2,scene,m2,rgb(255,0,0)));

//eventLoop.addAction(new Metronome(scene,rgb(255,0,0)));
//eventLoop.addAction(new CubeRotation(cube,scene,m,rgb(0,255,0)));
/+cube.modelView = new Matrix(4,4);
for (uint i = 0; i < 4; i++) cube.modelView[i,i] = 1.0;
while (true) {
	scene.clear();
	scene.drawShape(cube,rgb(0,0,255));
	scene.redraw();
	cube.modelView = m * cube.modelView;
	//cube.modelView.apMul(m);
	}+/
eventLoop.addListener(new EscapeQuit());
//eventLoop.addListener(new ShadedShapeMotion(&shCube,0.1));
eventLoop.addListener(new CraftCurve(craft,craftAction));
eventLoop.addListener(new CraftShoot(shooter,craft));
eventLoop.addListener(new Recharger(craftAction,counter));
eventLoop.addListener(new Pause());
eventLoop.run();
//engine.waitForQuit();

return 0;
}
