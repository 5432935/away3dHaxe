package a3d.animators.states;

import flash.geom.Vector3D;

interface IAnimationState
{
	var positionDelta(get,null):Vector3D;

	function offset(startTime:Int):Void;

	function update(time:Int):Void;

	/**
	 * Sets the animation phase of the node.
	 *
	 * @param value The phase value to use. 0 represents the beginning of an animation clip, 1 represents the end.
	 */
	function phase(value:Float):Void;
}
