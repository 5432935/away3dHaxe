package a3d.materials;

import flash.display.BlendMode;
import flash.display3D.Context3D;
import flash.display3D.Context3DCompareMode;
import flash.events.Event;
import flash.geom.Matrix3D;


import a3d.animators.IAnimationSet;
import a3d.entities.Camera3D;
import a3d.core.base.IMaterialOwner;
import a3d.core.base.IRenderable;
import a3d.core.managers.Stage3DProxy;
import a3d.core.traverse.EntityCollector;
import a3d.io.library.assets.AssetType;
import a3d.io.library.assets.IAsset;
import a3d.io.library.assets.NamedAssetBase;
import a3d.materials.lightpickers.LightPickerBase;
import a3d.materials.passes.DepthMapPass;
import a3d.materials.passes.DistanceMapPass;
import a3d.materials.passes.MaterialPassBase;



/**
 * MaterialBase forms an abstract base class for any material.
 */
class MaterialBase extends NamedAssetBase implements IAsset
{
	private static var MATERIAL_ID_COUNT:UInt = 0;
	/**
	 * An object to contain any extra data
	 */
	public var extra:Object;

	// can be used by other renderers to determine how to render this particular material
	// in practice, this can be checked by a custom EntityCollector
	public var classification:String;

	// this value is usually derived from other settings
	private var _uniqueId:UInt;
	
	//内部使用
	public var renderOrderId:Int;
	public var depthPassId:Int;

	private var _bothSides:Bool;
	private var _animationSet:IAnimationSet;

	private var _owners:Vector<IMaterialOwner>;

	private var _alphaPremultiplied:Bool;

	private var _blendMode:String = BlendMode.NORMAL;

	private var _numPasses:UInt;
	private var _passes:Vector<MaterialPassBase>;

	private var _mipmap:Bool = true;
	private var _smooth:Bool = true;
	private var _repeat:Bool;

	private var _depthPass:DepthMapPass;
	private var _distancePass:DistanceMapPass;

	private var _lightPicker:LightPickerBase;
	private var _distanceBasedDepthRender:Bool;
	private var _depthCompareMode:String = Context3DCompareMode.LESS_EQUAL;

	/**
	 * Creates a new MaterialBase object.
	 */
	public function new()
	{
		_owners = new Vector<IMaterialOwner>();
		_passes = new Vector<MaterialPassBase>();
		_depthPass = new DepthMapPass();
		_distancePass = new DistanceMapPass();
		_depthPass.addEventListener(Event.CHANGE, onDepthPassChange);
		_distancePass.addEventListener(Event.CHANGE, onDistancePassChange);

		// Default to considering pre-multiplied textures while blending
		alphaPremultiplied = true;

		_uniqueId = MATERIAL_ID_COUNT++;
	}

	private inline function get_assetType():String
	{
		return AssetType.MATERIAL;
	}

	private inline function get_lightPicker():LightPickerBase
	{
		return _lightPicker;
	}

	private inline function set_lightPicker(value:LightPickerBase):Void
	{
		if (value != _lightPicker)
		{
			_lightPicker = value;
			var len:UInt = _passes.length;
			for (var i:UInt = 0; i < len; ++i)
				_passes[i].lightPicker = _lightPicker;
		}
	}

	/**
	 * Indicates whether or not any used textures should use mipmapping.
	 */
	private inline function get_mipmap():Bool
	{
		return _mipmap;
	}

	private inline function set_mipmap(value:Bool):Void
	{
		_mipmap = value;
		for (var i:Int = 0; i < _numPasses; ++i)
			_passes[i].mipmap = value;
	}

	/**
	 * Indicates whether or not any used textures should use smoothing.
	 */
	private inline function get_smooth():Bool
	{
		return _smooth;
	}

	private inline function set_smooth(value:Bool):Void
	{
		_smooth = value;
		for (var i:Int = 0; i < _numPasses; ++i)
			_passes[i].smooth = value;
	}

	private inline function get_depthCompareMode():String
	{
		return _depthCompareMode;
	}

	private inline function set_depthCompareMode(value:String):Void
	{
		_depthCompareMode = value;
	}

	/**
	 * Indicates whether or not any used textures should be tiled.
	 */
	private inline function get_repeat():Bool
	{
		return _repeat;
	}

	private inline function set_repeat(value:Bool):Void
	{
		_repeat = value;
		for (var i:Int = 0; i < _numPasses; ++i)
			_passes[i].repeat = value;
	}

	/**
	 * Cleans up any resources used by the current object.
	 * @param deep Indicates whether other resources should be cleaned up, that could potentially be shared across different instances.
	 */
	public function dispose():Void
	{
		var i:UInt;
		for (i = 0; i < _numPasses; ++i)
			_passes[i].dispose();

		_depthPass.dispose();
		_distancePass.dispose();
		_depthPass.removeEventListener(Event.CHANGE, onDepthPassChange);
		_distancePass.removeEventListener(Event.CHANGE, onDistancePassChange);
	}

	/**
	 * Defines whether or not the material should perform backface culling.
	 */
	private inline function get_bothSides():Bool
	{
		return _bothSides;
	}

	private inline function set_bothSides(value:Bool):Void
	{
		_bothSides = value;

		for (var i:Int = 0; i < _numPasses; ++i)
			_passes[i].bothSides = value;

		_depthPass.bothSides = value;
		_distancePass.bothSides = value;
	}

	/**
	 * The blend mode to use when drawing this renderable. The following blend modes are supported:
	 * <ul>
	 * <li>BlendMode.NORMAL: No blending, unless the material inherently needs it</li>
	 * <li>BlendMode.LAYER: Force blending. This will draw the object the same as NORMAL, but without writing depth writes.</li>
	 * <li>BlendMode.MULTIPLY</li>
	 * <li>BlendMode.ADD</li>
	 * <li>BlendMode.ALPHA</li>
	 * </ul>
	 */
	private inline function get_blendMode():String
	{
		return _blendMode;
	}

	private inline function set_blendMode(value:String):Void
	{
		_blendMode = value;
	}


	/**
	 * Indicates whether visible textures (or other pixels) used by this material have
	 * already been premultiplied. Toggle this if you are seeing black halos around your
	 * blended alpha edges.
	*/
	private inline function get_alphaPremultiplied():Bool
	{
		return _alphaPremultiplied;
	}

	private inline function set_alphaPremultiplied(value:Bool):Void
	{
		_alphaPremultiplied = value;

		for (var i:Int = 0; i < _numPasses; ++i)
			_passes[i].alphaPremultiplied = value;
	}


	/**
	 * Indicates whether or not the material requires alpha blending during rendering.
	 */
	private inline function get_requiresBlending():Bool
	{
		return _blendMode != BlendMode.NORMAL;
	}

	/**
	 * The unique id assigned to the material by the MaterialLibrary.
	 */
	private inline function get_uniqueId():UInt
	{
		return _uniqueId;
	}

	/**
	 * The amount of passes used by the material.
	 *
	 * @private
	 */
	private inline function get_numPasses():UInt
	{
		return _numPasses;
	}

	public function hasDepthAlphaThreshold():Bool
	{
		return _depthPass.alphaThreshold > 0;
	}

	public function activateForDepth(stage3DProxy:Stage3DProxy, camera:Camera3D, distanceBased:Bool = false):Void
	{
		_distanceBasedDepthRender = distanceBased;

		if (distanceBased)
			_distancePass.activate(stage3DProxy, camera);
		else
			_depthPass.activate(stage3DProxy, camera);
	}

	public function deactivateForDepth(stage3DProxy:Stage3DProxy):Void
	{
		if (_distanceBasedDepthRender)
			_distancePass.deactivate(stage3DProxy);
		else
			_depthPass.deactivate(stage3DProxy);
	}

	public function renderDepth(renderable:IRenderable, stage3DProxy:Stage3DProxy, camera:Camera3D, viewProjection:Matrix3D):Void
	{
		if (_distanceBasedDepthRender)
		{
			if (renderable.animator)
				_distancePass.updateAnimationState(renderable, stage3DProxy, camera);
			_distancePass.render(renderable, stage3DProxy, camera, viewProjection);
		}
		else
		{
			if (renderable.animator)
				_depthPass.updateAnimationState(renderable, stage3DProxy, camera);
			_depthPass.render(renderable, stage3DProxy, camera, viewProjection);
		}
	}

	public function passRendersToTexture(index:UInt):Bool
	{
		return _passes[index].renderToTexture;
	}

	/**
	 * Sets the render state for a pass that is independent of the rendered object.
	 * @param index The index of the pass to activate.
	 * @param context The Context3D object which is currently rendering.
	 * @param camera The camera from which the scene is viewed.
	 * @private
	 */
	public function activatePass(index:UInt, stage3DProxy:Stage3DProxy, camera:Camera3D):Void
	{
		_passes[index].activate(stage3DProxy, camera);
	}

	/**
	 * Clears the render state for a pass.
	 * @param index The index of the pass to deactivate.
	 * @param context The Context3D object that is currently rendering.
	 * @private
	 */
	public function deactivatePass(index:UInt, stage3DProxy:Stage3DProxy):Void
	{
		_passes[index].deactivate(stage3DProxy);
	}

	/**
	 * Renders a renderable with a pass.
	 * @param index The pass to render with.
	 * @private
	 */
	public function renderPass(index:UInt, renderable:IRenderable, stage3DProxy:Stage3DProxy, entityCollector:EntityCollector, viewProjection:Matrix3D):Void
	{
		if (_lightPicker)
			_lightPicker.collectLights(renderable, entityCollector);

		var pass:MaterialPassBase = _passes[index];

		if (renderable.animator)
			pass.updateAnimationState(renderable, stage3DProxy, entityCollector.camera);

		pass.render(renderable, stage3DProxy, entityCollector.camera, viewProjection);
	}


//
// MATERIAL MANAGEMENT
//
	/**
	 * Mark an IMaterialOwner as owner of this material.
	 * Assures we're not using the same material across renderables with different animations, since the
	 * Program3Ds depend on animation. This method needs to be called when a material is assigned.
	 *
	 * @param owner The IMaterialOwner that had this material assigned
	 *
	 * @private
	 */
	public function addOwner(owner:IMaterialOwner):Void
	{
		_owners.push(owner);

		if (owner.animator)
		{
			if (_animationSet && owner.animator.animationSet != _animationSet)
			{
				throw new Error("A Material instance cannot be shared across renderables with different animator libraries");
			}
			else
			{
				if (_animationSet != owner.animator.animationSet)
				{
					_animationSet = owner.animator.animationSet;
					for (var i:Int = 0; i < _numPasses; ++i)
						_passes[i].animationSet = _animationSet;
					_depthPass.animationSet = _animationSet;
					_distancePass.animationSet = _animationSet;
					invalidatePasses(null);
				}
			}
		}
	}

	/**
	 * Removes an IMaterialOwner as owner.
	 * @param owner
	 * @private
	 */
	public function removeOwner(owner:IMaterialOwner):Void
	{
		_owners.splice(_owners.indexOf(owner), 1);
		if (_owners.length == 0)
		{
			_animationSet = null;
			for (var i:Int = 0; i < _numPasses; ++i)
				_passes[i].animationSet = _animationSet;
			_depthPass.animationSet = _animationSet;
			_distancePass.animationSet = _animationSet;
			invalidatePasses(null);
		}
	}

	/**
	 * A list of the IMaterialOwners that use this material
	 * @private
	 */
	private inline function get_owners():Vector<IMaterialOwner>
	{
		return _owners;
	}

	/**
	 * Updates the material
	 *
	 * @private
	 */
	public function updateMaterial(context:Context3D):Void
	{

	}

	/**
	 * Deactivates the material (in effect, its last pass)
	 * @private
	 */
	public function deactivate(stage3DProxy:Stage3DProxy):Void
	{
		_passes[_numPasses - 1].deactivate(stage3DProxy);
	}

	/**
	 * Marks the depth shader programs as invalid, so it will be recompiled before the next render.
	 * @param triggerPass The pass triggering the invalidation, if any, so no infinite loop will occur.
	 */
	public function invalidatePasses(triggerPass:MaterialPassBase):Void
	{
		var owner:IMaterialOwner;

		_depthPass.invalidateShaderProgram();
		_distancePass.invalidateShaderProgram();

		if (_animationSet)
		{
			_animationSet.resetGPUCompatibility();
			for each (owner in _owners)
			{
				if (owner.animator)
				{
					owner.animator.testGPUCompatibility(_depthPass);
					owner.animator.testGPUCompatibility(_distancePass);
				}
			}
		}

		for (var i:Int = 0; i < _numPasses; ++i)
		{
			if (_passes[i] != triggerPass)
				_passes[i].invalidateShaderProgram(false);
			// test if animation will be able to run on gpu BEFORE compiling materials
			if (_animationSet)
				for each (owner in _owners)
					if (owner.animator)
						owner.animator.testGPUCompatibility(_passes[i]);
		}
	}

	private function removePass(pass:MaterialPassBase):Void
	{
		_passes.splice(_passes.indexOf(pass), 1);
		--_numPasses;
	}

	/**
	 * Clears all passes in the material.
	 */
	private function clearPasses():Void
	{
		for (var i:Int = 0; i < _numPasses; ++i)
			_passes[i].removeEventListener(Event.CHANGE, onPassChange);

		_passes.length = 0;
		_numPasses = 0;
	}

	/**
	 * Adds a pass to the material
	 * @param pass
	 */
	private function addPass(pass:MaterialPassBase):Void
	{
		_passes[_numPasses++] = pass;
		pass.animationSet = _animationSet;
		pass.alphaPremultiplied = _alphaPremultiplied;
		pass.mipmap = _mipmap;
		pass.smooth = _smooth;
		pass.repeat = _repeat;
		pass.lightPicker = _lightPicker;
		pass.addEventListener(Event.CHANGE, onPassChange);
		invalidatePasses(null);
	}

	private function onPassChange(event:Event):Void
	{
		var mult:Float = 1;
		var ids:Vector<Int>;
		var len:Int;

		renderOrderId = 0;

		for (var i:Int = 0; i < _numPasses; ++i)
		{
			ids = _passes[i].getProgram3Dids();
			len = ids.length;
			for (var j:Int = 0; j < len; ++j)
			{
				if (ids[j] != -1)
				{
					renderOrderId += mult * ids[j];
					j = len;
				}
			}
			mult *= 1000;
		}
	}

	private function onDistancePassChange(event:Event):Void
	{
		var ids:Vector<Int> = _distancePass.getProgram3Dids();
		var len:UInt = ids.length;

		depthPassId = 0;

		for (var j:Int = 0; j < len; ++j)
		{
			if (ids[j] != -1)
			{
				depthPassId += ids[j];
				j = len;
			}
		}
	}

	private function onDepthPassChange(event:Event):Void
	{
		var ids:Vector<Int> = _depthPass.getProgram3Dids();
		var len:UInt = ids.length;

		depthPassId = 0;

		for (var j:Int = 0; j < len; ++j)
		{
			if (ids[j] != -1)
			{
				depthPassId += ids[j];
				j = len;
			}
		}
	}
}
