package away3d.animators.nodes;

import away3d.animators.IAnimator;
import away3d.animators.states.SkeletonDifferenceState;

/**
 * A skeleton animation node that uses a difference input pose with a base input pose to blend a linearly interpolated output of a skeleton pose.
 */
class SkeletonDifferenceNode extends AnimationNodeBase
{
	/**
	 * Defines a base input node to use for the blended output.
	 */
	public var baseInput:AnimationNodeBase;

	/**
	 * Defines a difference input node to use for the blended output.
	 */
	public var differenceInput:AnimationNodeBase;

	/**
	 * Creates a new <code>SkeletonAdditiveNode</code> object.
	 */
	public function new()
	{
		super();
		_stateClass = SkeletonDifferenceState;
	}

	/**
	 * @inheritDoc
	 */
	public function getAnimationState(animator:IAnimator):SkeletonDifferenceState
	{
		return Std.instance(animator.getAnimationState(this),SkeletonDifferenceState);
	}
}
