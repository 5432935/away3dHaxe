package a3d.animators.states;


import a3d.animators.IAnimator;
import a3d.animators.SpriteSheetAnimator;
import a3d.animators.data.SpriteSheetAnimationFrame;
import a3d.animators.nodes.SpriteSheetClipNode;
import flash.Vector;



class SpriteSheetAnimationState extends AnimationClipState implements ISpriteSheetAnimationState
{
	private var _frames:Vector<SpriteSheetAnimationFrame>;
	private var _clipNode:SpriteSheetClipNode;
	private var _currentFrameID:UInt = 0;
	private var _reverse:Bool;
	private var _back:Bool;
	private var _backAndForth:Bool;
	private var _forcedFrame:Bool;

	public function new(animator:IAnimator, clipNode:SpriteSheetClipNode)
	{
		super(animator, clipNode);

		_clipNode = clipNode;
		_frames = _clipNode.frames;
	}

	private function set_reverse(b:Bool):Void
	{
		_back = false;
		_reverse = b;
	}

	private function set_backAndForth(b:Bool):Void
	{
		if (b)
			_reverse = false;
		_back = false;
		_backAndForth = b;
	}

	/**
	* @inheritDoc
	*/
	private function get_currentFrameData():SpriteSheetAnimationFrame
	{
		if (_framesDirty)
			updateFrames();

		return _frames[_currentFrameID];
	}

	/**
	* returns current frame index of the animation.
	* The index is zero based and counts from first frame of the defined animation.
	*/
	private function get_currentFrameNumber():UInt
	{
		return _currentFrameID;
	}

	private function set_currentFrameNumber(frameNumber:UInt):Void
	{
		_currentFrameID = (frameNumber > _frames.length - 1) ? _frames.length - 1 : frameNumber;
		_forcedFrame = true;
	}

	/**
		* returns the total frames for the current animation.
		*/
	private function get_totalFrames():UInt
	{
		return (!_frames) ? 0 : _frames.length;
	}

	/**
	* @inheritDoc
	*/
	override private function updateFrames():Void
	{
		if (_forcedFrame)
		{
			_forcedFrame = false;
			return;
		}

		super.updateFrames();

		if (_reverse)
		{

			if (_currentFrameID - 1 > -1)
			{
				_currentFrameID--;

			}
			else
			{

				if (_clipNode.looping)
				{

					if (_backAndForth)
					{
						_reverse = false;
						_currentFrameID++;
					}
					else
					{
						_currentFrameID = _frames.length - 1;
					}
				}

				SpriteSheetAnimator(_animator).dispatchCycleEvent();
			}

		}
		else
		{

			if (_currentFrameID < _frames.length - 1)
			{
				_currentFrameID++;

			}
			else
			{

				if (_clipNode.looping)
				{

					if (_backAndForth)
					{
						_reverse = true;
						_currentFrameID--;
					}
					else
					{
						_currentFrameID = 0;
					}
				}

				SpriteSheetAnimator(_animator).dispatchCycleEvent();
			}
		}


	}
}
