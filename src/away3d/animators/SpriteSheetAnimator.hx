package away3d.animators;

import away3d.animators.data.SpriteSheetAnimationFrame;
import away3d.animators.states.ISpriteSheetAnimationState;
import away3d.animators.states.SpriteSheetAnimationState;
import away3d.animators.transitions.IAnimationTransition;
import away3d.core.base.IRenderable;
import away3d.core.base.SubMesh;
import away3d.core.managers.Stage3DProxy;
import away3d.cameras.Camera3D;
import away3d.materials.MaterialBase;
import away3d.materials.passes.MaterialPassBase;
import away3d.materials.SpriteSheetMaterial;
import away3d.materials.TextureMaterial;
import away3d.utils.TimerUtil;
import flash.display3D.Context3DProgramType;
import flash.errors.Error;
import flash.Lib;
import flash.Vector;





/**
 * Provides an interface for assigning uv-based sprite sheet animation data sets to mesh-based entity objects
 * and controlling the various available states of animation through an interative playhead that can be
 * automatically updated or manually triggered.
 */
class SpriteSheetAnimator extends AnimatorBase implements IAnimator
{
	/* Set the playrate of the animation in frames per second (not depending on player fps)*/
	public var fps(get, set):Int;
	/* If true, reverse causes the animation to play backwards*/
	public var reverse(get, set):Bool;
	/* If true, backAndForth causes the animation to play backwards and forward alternatively. Starting forward.*/
	public var backAndForth(get, set):Bool;
	/* returns the current frame*/
	public var currentFrameNumber(get, null):Int;
	/* returns the total amount of frame for the current animation*/
	public var totalFrames(get, null):Int;
	
	private var _activeSpriteSheetState:ISpriteSheetAnimationState;
	private var _spriteSheetAnimationSet:SpriteSheetAnimationSet;
	private var _frame:SpriteSheetAnimationFrame;
	private var _vectorFrame:Vector<Float>;
	private var _fps:Int = 10;
	private var _ms:Int = 100;
	private var _lastTime:Int;
	private var _reverse:Bool;
	private var _backAndForth:Bool;
	private var _specsDirty:Bool;
	private var _mapDirty:Bool;

	/**
	 * Creates a new <code>SpriteSheetAnimator</code> object.
	 * @param spriteSheetAnimationSet  The animation data set containing the sprite sheet animation states used by the animator.
	 */
	public function new(spriteSheetAnimationSet:SpriteSheetAnimationSet)
	{
		super(spriteSheetAnimationSet);
		_spriteSheetAnimationSet = spriteSheetAnimationSet;
		_vectorFrame = new Vector<Float>();
		_frame = new SpriteSheetAnimationFrame();
	}

	
	private function set_fps(val:Int):Int
	{
		_ms = Std.int(1000 / val);
		return _fps = val;
	}

	private function get_fps():Int
	{
		return _fps;
	}

	
	private function set_reverse(b:Bool):Bool
	{
		_specsDirty = true;
		return _reverse = b;
	}

	private function get_reverse():Bool
	{
		return _reverse;
	}

	
	private function set_backAndForth(b:Bool):Bool
	{
		_specsDirty = true;
		return _backAndForth = b;
	}

	private function get_backAndForth():Bool
	{
		return _backAndForth;
	}

	/* sets the animation pointer to a given frame and plays from there. Equivalent to ActionScript, the first frame is at 1, not 0.*/
	public function gotoAndPlay(frameNumber:UInt):Void
	{
		gotoFrame(frameNumber, true);
	}

	/* sets the animation pointer to a given frame and stops there. Equivalent to ActionScript, the first frame is at 1, not 0.*/
	public function gotoAndStop(frameNumber:UInt):Void
	{
		gotoFrame(frameNumber, false);
	}

	
	private function get_currentFrameNumber():Int
	{
		return Std.instance(_activeState,SpriteSheetAnimationState).currentFrameNumber;
	}

	
	private function get_totalFrames():Int
	{
		return Std.instance(_activeState,SpriteSheetAnimationState).totalFrames;
	}

	/**
	 * @inheritDoc
	 */
	public function setRenderState(stage3DProxy:Stage3DProxy, renderable:IRenderable, vertexConstantOffset:Int, vertexStreamOffset:Int, camera:Camera3D):Void
	{
		var material:MaterialBase = renderable.material;
		if (material == null || !Std.is(material,TextureMaterial))
			return;

		var subMesh:SubMesh = Std.instance(renderable,SubMesh);
		if (subMesh == null)
			return;

		//because textures are already uploaded, we can't offset the uv's yet
		var swapped:Bool = false;

		if (Std.is(material,SpriteSheetMaterial) && _mapDirty)
			swapped = Std.instance(material,SpriteSheetMaterial).swap(_frame.mapID);

		if (!swapped)
		{
			_vectorFrame[0] = _frame.offsetU;
			_vectorFrame[1] = _frame.offsetV;
			_vectorFrame[2] = _frame.scaleU;
			_vectorFrame[3] = _frame.scaleV;
		}

		//vc[vertexConstantOffset]
		stage3DProxy.context3D.setProgramConstantsFromVector(Context3DProgramType.VERTEX, vertexConstantOffset, _vectorFrame);
	}

	/**
	 * @inheritDoc
	 */
	public function play(name:String, transition:IAnimationTransition = null, offset:Float = null):Void
	{
		if (_activeAnimationName == name)
			return;

		_activeAnimationName = name;

		if (!_animationSet.hasAnimation(name))
			throw new Error("Animation root node " + name + " not found!");

		_activeNode = _animationSet.getAnimation(name);
		_activeState = getAnimationState(_activeNode);
		_frame = Std.instance(_activeState,SpriteSheetAnimationState).currentFrameData;
		_activeSpriteSheetState = Std.instance(_activeState,ISpriteSheetAnimationState);

		start();
	}

	/**
	 * Applies the calculated time delta to the active animation state node.
	 */
	override private function updateDeltaTime(dt:Float):Void
	{
		if (_specsDirty)
		{
			Std.instance(_activeSpriteSheetState,SpriteSheetAnimationState).reverse = _reverse;
			Std.instance(_activeSpriteSheetState,SpriteSheetAnimationState).backAndForth = _backAndForth;
			_specsDirty = false;
		}

		_absoluteTime += dt;
		var now:Int = Lib.getTimer();

		if ((now - _lastTime) > _ms)
		{
			_mapDirty = true;
			_activeSpriteSheetState.update(Std.int(_absoluteTime));
			_frame = Std.instance(_activeSpriteSheetState,SpriteSheetAnimationState).currentFrameData;
			_lastTime = now;

		}
		else
		{
			_mapDirty = false;
		}

	}

	public function testGPUCompatibility(pass:MaterialPassBase):Void
	{
	}

	public function clone():IAnimator
	{
		return new SpriteSheetAnimator(_spriteSheetAnimationSet);
	}

	private function gotoFrame(frameNumber:Int, doPlay:Bool):Void
	{
		if (_activeState == null)
			return;
		Std.instance(_activeState,SpriteSheetAnimationState).currentFrameNumber = (frameNumber == 0) ? frameNumber : frameNumber - 1;
		var currentMapID:Int = _frame.mapID;
		_frame = Std.instance(_activeSpriteSheetState,SpriteSheetAnimationState).currentFrameData;

		if (doPlay)
		{
			start();
		}
		else
		{
			if (currentMapID != _frame.mapID)
			{
				_mapDirty = true;
				TimerUtil.setTimeout(stop, _fps);
			}
			else
			{
				stop();
			}

		}
	}

}