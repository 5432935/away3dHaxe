package a3d.animators.data
{

	/**
	 * Options for setting the animation mode of a vertex animator object.
	 *
	 * @see a3d.animators.VertexAnimator
	 */
	class VertexAnimationMode
	{
		/**
		 * Animation mode that adds all outputs from active vertex animation state to form the current vertex animation pose.
		 */
		public static inline var ADDITIVE:String = "additive";

		/**
		 * Animation mode that picks the output from a single vertex animation state to form the current vertex animation pose.
		 */
		public static inline var ABSOLUTE:String = "absolute";
	}
}
