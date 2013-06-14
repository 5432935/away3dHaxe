/*

Creating fire effects with particles in Away3D

Demonstrates:

How to setup a particle geometry and particle animationset in order to simulate fire.
How to stagger particle animation instances with different animator objects running on different timers.
How to apply fire lighting to a floor mesh using a multipass material.

Code by Rob Bateman & Liao Cheng
rob@infiniteturtles.co.uk
http://www.infiniteturtles.co.uk
liaocheng210@126.com

This code is distributed under the MIT License

Copyright (c) The Away Foundation http://www.theawayfoundation.org

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the “Software”), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

*/

package
{
	import flash.display.BlendMode;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.geom.ColorTransform;
	import flash.geom.Vector3D;
	import flash.utils.Timer;

	import away3d.animators.ParticleAnimationSet;
	import away3d.animators.ParticleAnimator;
	import away3d.animators.data.ParticleProperties;
	import away3d.animators.data.ParticlePropertiesMode;
	import away3d.animators.nodes.ParticleBillboardNode;
	import away3d.animators.nodes.ParticleColorNode;
	import away3d.animators.nodes.ParticleScaleNode;
	import away3d.animators.nodes.ParticleVelocityNode;
	import away3d.cameras.Camera3D;
	import away3d.containers.Scene3D;
	import away3d.controllers.HoverController;
	import away3d.core.base.Geometry;
	import away3d.core.base.ParticleGeometry;
	import away3d.entities.Mesh;
	import away3d.lights.DirectionalLight;
	import away3d.lights.PointLight;
	import away3d.materials.TextureMaterial;
	import away3d.materials.TextureMultiPassMaterial;
	import away3d.materials.lightpickers.StaticLightPicker;
	import away3d.primitives.PlaneGeometry;
	import away3d.tools.helpers.ParticleGeometryHelper;
	import away3d.utils.Cast;

	public class Basic_Fire extends BasicApplication
	{
		private static const NUM_FIRES:uint = 10;

		//fire texture
		[Embed(source = "../embeds/blue.png")]
		public static var FireTexture:Class;

		//plane textures
		[Embed(source = "/../embeds/floor_diffuse.jpg")]
		public static var FloorDiffuse:Class;
		[Embed(source = "/../embeds/floor_specular.jpg")]
		public static var FloorSpecular:Class;
		[Embed(source = "/../embeds/floor_normal.jpg")]
		public static var FloorNormals:Class;

		//engine variables
		private var cameraController:HoverController;

		//material objects
		private var planeMaterial:TextureMultiPassMaterial;
		private var particleMaterial:TextureMaterial;

		//light objects
		private var directionalLight:DirectionalLight;
		private var lightPicker:StaticLightPicker;

		//particle objects
		private var fireAnimationSet:ParticleAnimationSet;
		private var particleGeometry:ParticleGeometry;
		private var timer:Timer;

		//scene objects
		private var plane:Mesh;
		private var fireObjects:Vector.<FireVO> = new Vector.<FireVO>();

		//navigation variables
		private var move:Boolean = false;
		private var lastPanAngle:Number;
		private var lastTiltAngle:Number;
		private var lastMouseX:Number;
		private var lastMouseY:Number;

		/**
		 * Constructor
		 */
		public function Basic_Fire()
		{
			init();
		}

		/**
		 * Global initialise function
		 */
		private function init():void
		{
			initEngine();
			initLights();
			initMaterials();
			initParticles();
			initObjects();
			initListeners();
		}

		/**
		 * Initialise the engine
		 */
		override protected function initEngine():void
		{
			super.initEngine();

			scene = new Scene3D();

			camera = new Camera3D();

			view.antiAlias = 4;
			view.scene = scene;
			view.camera = camera;

			//setup controller to be used on the camera
			cameraController = new HoverController(camera);
			cameraController.distance = 1000;
			cameraController.minTiltAngle = 0;
			cameraController.maxTiltAngle = 90;
			cameraController.panAngle = 45;
			cameraController.tiltAngle = 20;
		}

		/**
		 * Initialise the lights
		 */
		private function initLights():void
		{
			directionalLight = new DirectionalLight(0, -1, 0);
			directionalLight.castsShadows = false;
			directionalLight.color = 0xeedddd;
			directionalLight.diffuse = .5;
			directionalLight.ambient = .5;
			directionalLight.specular = 0;
			directionalLight.ambientColor = 0x808090;
			view.scene.addChild(directionalLight);

			lightPicker = new StaticLightPicker([directionalLight]);
		}

		/**
		 * Initialise the materials
		 */
		private function initMaterials():void
		{
			planeMaterial = new TextureMultiPassMaterial(Cast.bitmapTexture(FloorDiffuse));
			planeMaterial.specularMap = Cast.bitmapTexture(FloorSpecular);
			planeMaterial.normalMap = Cast.bitmapTexture(FloorNormals);
			planeMaterial.lightPicker = lightPicker;
			planeMaterial.repeat = true;
			planeMaterial.mipmap = false;
			planeMaterial.specular = 10;

			particleMaterial = new TextureMaterial(Cast.bitmapTexture(FireTexture));
			particleMaterial.blendMode = BlendMode.ADD;
		}

		/**
		 * Initialise the particles
		 */
		private function initParticles():void
		{

			//create the particle animation set
			fireAnimationSet = new ParticleAnimationSet(true, true);

			//add some animations which can control the particles:
			//the global animations can be set directly, because they influence all the particles with the same factor
			fireAnimationSet.addAnimation(new ParticleBillboardNode());
			fireAnimationSet.addAnimation(new ParticleScaleNode(ParticlePropertiesMode.GLOBAL, false, false, 2.5, 0.5));
			fireAnimationSet.addAnimation(new ParticleVelocityNode(ParticlePropertiesMode.GLOBAL, new Vector3D(0, 80, 0)));
			fireAnimationSet.addAnimation(new ParticleColorNode(ParticlePropertiesMode.GLOBAL, true, true, false, false, new ColorTransform(0, 0, 0, 1, 0xFF, 0x33, 0x01), new ColorTransform(0, 0, 0, 1,
				0x99)));

			//no need to set the local animations here, because they influence all the particle with different factors.
			fireAnimationSet.addAnimation(new ParticleVelocityNode(ParticlePropertiesMode.LOCAL_STATIC));

			//set the initParticleFunc. It will be invoked for the local static property initialization of every particle
			fireAnimationSet.initParticleFunc = initParticleFunc;

			//create the original particle geometry
			var particle:Geometry = new PlaneGeometry(10, 10, 1, 1, false);

			//combine them into a list
			var geometrySet:Vector.<Geometry> = new Vector.<Geometry>;
			for (var i:int = 0; i < 500; i++)
				geometrySet.push(particle);

			particleGeometry = ParticleGeometryHelper.generateGeometry(geometrySet);
		}

		/**
		 * Initialise the scene objects
		 */
		private function initObjects():void
		{
			plane = new Mesh(new PlaneGeometry(1000, 1000), planeMaterial);
			plane.geometry.scaleUV(2, 2);
			plane.y = -20;

			scene.addChild(plane);

			//create fire object meshes from geomtry and material, and apply particle animators to each
			for (var i:int = 0; i < NUM_FIRES; i++)
			{
				var particleMesh:Mesh = new Mesh(particleGeometry, particleMaterial);
				var animator:ParticleAnimator = new ParticleAnimator(fireAnimationSet);
				particleMesh.animator = animator;

				//position the mesh
				var degree:Number = i / NUM_FIRES * Math.PI * 2;
				particleMesh.x = Math.sin(degree) * 400;
				particleMesh.z = Math.cos(degree) * 400;
				particleMesh.y = 5;

				//create a fire object and add it to the fire object vector
				fireObjects.push(new FireVO(particleMesh, animator));
				view.scene.addChild(particleMesh);
			}

			//setup timer for triggering each particle aniamtor
			timer = new Timer(1000, fireObjects.length);
			timer.addEventListener(TimerEvent.TIMER, onTimer);
			timer.start();
		}

		/**
		 * Initialiser function for particle properties
		 */
		private function initParticleFunc(prop:ParticleProperties):void
		{
			prop.startTime = Math.random() * 5;
			prop.duration = Math.random() * 4 + 0.1;

			var degree1:Number = Math.random() * Math.PI * 2;
			var degree2:Number = Math.random() * Math.PI * 2;
			var r:Number = 15;
			prop[ParticleVelocityNode.VELOCITY_VECTOR3D] = new Vector3D(r * Math.sin(degree1) * Math.cos(degree2), r * Math.cos(degree1) * Math.cos(degree2), r * Math.sin(degree2));
		}

		/**
		 * Returns an array of active lights in the scene
		 */
		private function getAllLights():Array
		{
			var lights:Array = new Array();

			lights.push(directionalLight);

			for each (var fireVO:FireVO in fireObjects)
				if (fireVO.light)
					lights.push(fireVO.light);

			return lights;
		}

		/**
		 * Timer event handler
		 */
		private function onTimer(e:TimerEvent):void
		{
			var fireObject:FireVO = fireObjects[timer.currentCount - 1];

			//start the animator
			fireObject.animator.start();

			//create the lightsource
			var light:PointLight = new PointLight();
			light.color = 0xFF3301;
			light.diffuse = 0;
			light.specular = 0;
			light.position = fireObject.mesh.position;

			//add the lightsource to the fire object
			fireObject.light = light;

			//update the lightpicker
			lightPicker.lights = getAllLights();
		}

		/**
		 * Navigation and render loop
		 */
		override protected function render():void
		{
			if (move)
			{
				cameraController.panAngle = 0.3 * (stage.mouseX - lastMouseX) + lastPanAngle;
				cameraController.tiltAngle = 0.3 * (stage.mouseY - lastMouseY) + lastTiltAngle;
			}

			//animate lights
			var fireVO:FireVO;
			for each (fireVO in fireObjects)
			{
				//update flame light
				var light:PointLight = fireVO.light;

				if (!light)
					continue;

				if (fireVO.strength < 1)
					fireVO.strength += 0.1;

				light.fallOff = 380 + Math.random() * 20;
				light.radius = 200 + Math.random() * 30;
				light.diffuse = light.specular = fireVO.strength + Math.random() * .2;
			}

			super.render();
		}

		/**
		 * Mouse down listener for navigation
		 */
		override protected function onMouseDown(event:MouseEvent):void
		{
			lastPanAngle = cameraController.panAngle;
			lastTiltAngle = cameraController.tiltAngle;
			lastMouseX = stage.mouseX;
			lastMouseY = stage.mouseY;
			move = true;
			stage.addEventListener(Event.MOUSE_LEAVE, onStageMouseLeave);
		}

		/**
		 * Mouse up listener for navigation
		 */
		override protected function onMouseUp(event:MouseEvent):void
		{
			move = false;
			stage.removeEventListener(Event.MOUSE_LEAVE, onStageMouseLeave);
		}

		/**
		 * Mouse stage leave listener for navigation
		 */
		private function onStageMouseLeave(event:Event):void
		{
			move = false;
			stage.removeEventListener(Event.MOUSE_LEAVE, onStageMouseLeave);
		}
	}
}

import away3d.animators.ParticleAnimator;
import away3d.entities.Mesh;
import away3d.lights.PointLight;

/**
 * Data class for the fire objects
 */
internal class FireVO
{
	public var mesh:Mesh;
	public var animator:ParticleAnimator;
	public var light:PointLight;
	public var strength:Number = 0;

	public function FireVO(mesh:Mesh, animator:ParticleAnimator):void
	{
		this.mesh = mesh;
		this.animator = animator;
	}
}
