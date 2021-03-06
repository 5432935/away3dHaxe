package a3d.animators.nodes;

import a3d.animators.data.UVAnimationFrame;
import a3d.animators.states.UVClipState;
import flash.Vector;

/**
 * A uv animation node containing time-based animation data as individual uv animation frames.
 */
class UVClipNode extends AnimationClipNodeBase
{
	/**
	 * Returns a vector of UV frames representing the uv values of each animation frame in the clip.
	 */
	public var frames(get, null):Vector<UVAnimationFrame>;
	
	private var _frames:Vector<UVAnimationFrame>;

	/**
	 * Creates a new <code>UVClipNode</code> object.
	 */
	public function new()
	{
		super();
		_stateClass = UVClipState;
		_frames = new Vector<UVAnimationFrame>();
	}
	
	
	private function get_frames():Vector<UVAnimationFrame>
	{
		return _frames;
	}

	/**
	 * Adds a UV frame object to the internal timeline of the animation node.
	 *
	 * @param uvFrame The uv frame object to add to the timeline of the node.
	 * @param duration The specified duration of the frame in milliseconds.
	 */
	public function addFrame(uvFrame:UVAnimationFrame, duration:UInt):Void
	{
		_frames.push(uvFrame);
		_durations.push(duration);
		_numFrames = _durations.length;

		_stitchDirty = true;
	}

	/**
	 * @inheritDoc
	 */
	override private function updateStitch():Void
	{
		super.updateStitch();
		
		var i:Int = 0;
		if (_durations.length > 0)
		{

			i = _numFrames - 1;
			while (i-- != 0)
			{
				_totalDuration += _durations[i];
			}

			if (_stitchFinalFrame || !_looping)
			{
				_totalDuration += _durations[_numFrames - 1];
			}
		}


	}
}
