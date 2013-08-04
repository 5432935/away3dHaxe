package a3d.animators.nodes;

import a3d.animators.data.SkeletonPose;
import a3d.animators.IAnimator;
import a3d.animators.states.SkeletonClipState;
import flash.geom.Vector3D;
import flash.Vector;



/**
 * A skeleton animation node containing time-based animation data as individual skeleton poses.
 */
class SkeletonClipNode extends AnimationClipNodeBase
{
	
	/**
	 * Determines whether to use SLERP equations (true) or LERP equations (false) in the calculation
	 * of the output skeleton pose. Defaults to false.
	 */
	public var highQuality:Bool = false;

	/**
	 * Returns a vector of skeleton poses representing the pose of each animation frame in the clip.
	 */
	public var frames(get, null):Vector<SkeletonPose>;
	
	private var _frames:Vector<SkeletonPose>;

	/**
	 * Creates a new <code>SkeletonClipNode</code> object.
	 */
	public function new()
	{
		super();
		_frames = new Vector<SkeletonPose>();
		_stateClass = SkeletonClipState;
	}

	/**
	 * Adds a skeleton pose frame to the internal timeline of the animation node.
	 *
	 * @param skeletonPose The skeleton pose object to add to the timeline of the node.
	 * @param duration The specified duration of the frame in milliseconds.
	 */
	public function addFrame(skeletonPose:SkeletonPose, duration:UInt):Void
	{
		_frames.push(skeletonPose);
		_durations.push(duration);

		_numFrames = _durations.length;

		_stitchDirty = true;
	}

	/**
	 * @inheritDoc
	 */
	public function getAnimationState(animator:IAnimator):SkeletonClipState
	{
		return Std.instance(animator.getAnimationState(this), SkeletonClipState);
	}

	/**
	 * @inheritDoc
	 */
	override private function updateStitch():Void
	{
		super.updateStitch();

		var i:Int = _numFrames - 1;
		var p1:Vector3D, p2:Vector3D, delta:Vector3D;
		while (i-- > 0)
		{
			_totalDuration += _durations[i];
			p1 = _frames[i].jointPoses[0].translation;
			p2 = _frames[i + 1].jointPoses[0].translation;
			delta = p2.subtract(p1);
			_totalDelta.x += delta.x;
			_totalDelta.y += delta.y;
			_totalDelta.z += delta.z;
		}

		if (_stitchFinalFrame || !_looping)
		{
			_totalDuration += _durations[_numFrames - 1];
			p1 = _frames[0].jointPoses[0].translation;
			p2 = _frames[1].jointPoses[0].translation;
			delta = p2.subtract(p1);
			_totalDelta.x += delta.x;
			_totalDelta.y += delta.y;
			_totalDelta.z += delta.z;
		}
	}
	
	private function get_frames():Vector<SkeletonPose>
	{
		return _frames;
	}
}
