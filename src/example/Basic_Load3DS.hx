﻿package example;

import away3d.controllers.HoverController;
import away3d.entities.lights.DirectionalLight;
import away3d.entities.Mesh;
import away3d.entities.primitives.PlaneGeometry;
import away3d.events.AssetEvent;
import away3d.io.library.assets.AssetType;
import away3d.io.loaders.Loader3D;
import away3d.io.loaders.misc.AssetLoaderContext;
import away3d.io.loaders.parsers.Parsers;
import away3d.materials.lightpickers.StaticLightPicker;
import away3d.materials.methods.FilteredShadowMapMethod;
import away3d.materials.TextureMaterial;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.geom.Vector3D;
import flash.Lib;



class Basic_Load3DS extends BasicApplication
{
	static function main()
	{
		Lib.current.addChild(new Basic_Load3DS());
	}

	//engine variables
	private var _cameraController:HoverController;

	//light objects
	private var _light:DirectionalLight;
	private var _lightPicker:StaticLightPicker;
	private var _direction:Vector3D;

	//material objects
	private var _groundMaterial:TextureMaterial;

	//scene objects
	private var _loader:Loader3D;
	private var _ground:Mesh;

	//navigation variables
	private var _move:Bool = false;
	private var _lastPanAngle:Float;
	private var _lastTiltAngle:Float;
	private var _lastMouseX:Float;
	private var _lastMouseY:Float;

	/**
	 * Constructor
	 */
	public function new()
	{
		super();
	}

	/**
	 * Global initialise function
	 */
	override private function init():Void
	{
		initEngine();
		initObjects();
		initListeners();
	}

	/**
	 * Initialise the scene objects
	 */
	private function initObjects():Void
	{
		//setup the lights for the scene
		_light = new DirectionalLight(-1, -1, 1);
		_direction = new Vector3D(-1, -1, 1);
		_lightPicker = new StaticLightPicker([_light]);
		view.scene.addChild(_light);

		//setup parser to be used on Loader3D
		Parsers.enableAllBundled();

		//setup the url map for textures in the 3ds file
		var assetLoaderContext:AssetLoaderContext = new AssetLoaderContext();
		assetLoaderContext.mapUrlToData("texture.jpg", new AntTexture(0,0));

		//setup materials
		_groundMaterial = new TextureMaterial(createBitmapTexture(SandTexture));
		_groundMaterial.shadowMethod = new FilteredShadowMapMethod(_light);
		_groundMaterial.lightPicker = _lightPicker;
		_groundMaterial.specular = 0;
		_ground = new Mesh(new PlaneGeometry(1000, 1000), _groundMaterial);
		view.scene.addChild(_ground);

		//setup the scene
		_loader = new Loader3D();
		_loader.scale(300);
		_loader.z = -200;
		_loader.addEventListener(AssetEvent.ASSET_COMPLETE, onAssetComplete);
		_loader.loadData(new AntModel(), assetLoaderContext);
		view.scene.addChild(_loader);
	}

	/**
	 * Initialise the engine
	 */
	override private function initEngine():Void
	{
		super.initEngine();

		//setup the camera for optimal shadow rendering
		view.camera.lens.far = 2100;

		//setup controller to be used on the camera
		_cameraController = new HoverController(view.camera, null, 45, 20, 1000, 10);

	}

	/**
	 * Navigation and render loop
	 */
	override private function render():Void
	{
		if (_move)
		{
			_cameraController.panAngle = 0.3 * (stage.mouseX - _lastMouseX) + _lastPanAngle;
			_cameraController.tiltAngle = 0.3 * (stage.mouseY - _lastMouseY) + _lastTiltAngle;
		}

		_direction.x = -Math.sin(Lib.getTimer() / 4000);
		_direction.z = -Math.cos(Lib.getTimer() / 4000);
		_light.direction = _direction;

		super.render();
	}

	/**
	 * Listener function for asset complete event on loader
	 */
	private function onAssetComplete(event:AssetEvent):Void
	{
		if (event.asset.assetType == AssetType.MESH)
		{
			var mesh:Mesh = Std.instance(event.asset,Mesh);
			mesh.castsShadows = true;
		}
		else if (event.asset.assetType == AssetType.MATERIAL)
		{
			var material:TextureMaterial = Std.instance(event.asset,TextureMaterial);
			material.shadowMethod = new FilteredShadowMapMethod(_light);
			material.lightPicker = _lightPicker;
			material.gloss = 30;
			material.specular = 1;
			material.ambientColor = 0x303040;
			material.ambient = 1;
		}
	}

	/**
	 * Mouse down listener for navigation
	 */
	override private function onMouseDown(event:MouseEvent):Void
	{
		_lastPanAngle = _cameraController.panAngle;
		_lastTiltAngle = _cameraController.tiltAngle;
		_lastMouseX = stage.mouseX;
		_lastMouseY = stage.mouseY;
		_move = true;
		stage.addEventListener(Event.MOUSE_LEAVE, onStageMouseLeave);
	}

	/**
	 * Mouse up listener for navigation
	 */
	override private function onMouseUp(event:MouseEvent):Void
	{
		_move = false;
		stage.removeEventListener(Event.MOUSE_LEAVE, onStageMouseLeave);
	}

	/**
	 * Mouse stage leave listener for navigation
	 */
	private function onStageMouseLeave(event:Event):Void
	{
		_move = false;
		stage.removeEventListener(Event.MOUSE_LEAVE, onStageMouseLeave);
	}
}


//solider ant texture
@:bitmap("embeds/soldier_ant.jpg") class AntTexture extends flash.display.BitmapData { }
//solider ant model
@:file("embeds/soldier_ant.3ds") class AntModel extends flash.utils.ByteArray { }

//ground texture
@:bitmap("embeds/CoarseRedSand.jpg") class SandTexture extends flash.display.BitmapData { }
