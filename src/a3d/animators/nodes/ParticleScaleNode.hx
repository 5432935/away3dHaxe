package a3d.animators.nodes;

import flash.geom.Vector3D;


import a3d.animators.IAnimator;
import a3d.animators.data.AnimationRegisterCache;
import a3d.animators.data.ParticleProperties;
import a3d.animators.data.ParticlePropertiesMode;
import a3d.animators.states.ParticleScaleState;
import a3d.materials.compilation.ShaderRegisterElement;
import a3d.materials.passes.MaterialPassBase;



/**
 * A particle animation node used to control the scale variation of a particle over time.
 */
class ParticleScaleNode extends ParticleNodeBase
{
	/** @private */
	public static inline var SCALE_INDEX:UInt = 0;

	/** @private */
	public var usesCycle:Bool;

	/** @private */
	public var usesPhase:Bool;

	/** @private */
	public var minScale:Float;
	/** @private */
	public var maxScale:Float;
	/** @private */
	public var cycleDuration:Float;
	/** @private */
	public var cyclePhase:Float;

	/**
	 * Reference for scale node properties on a single particle (when in local property mode).
	 * Expects a <code>Vector3D</code> representing the min scale (x), max scale(y), optional cycle speed (z) and phase offset (w) applied to the particle.
	 */
	public static inline var SCALE_VECTOR3D:String = "ScaleVector3D";

	/**
	 * Creates a new <code>ParticleScaleNode</code>
	 *
	 * @param               mode            Defines whether the mode of operation acts on local properties of a particle or global properties of the node.
	 * @param    [optional] usesCycle       Defines whether the node uses the <code>cycleDuration</code> property in the shader to calculate the period of animation independent of particle duration. Defaults to false.
	 * @param    [optional] usesPhase       Defines whether the node uses the <code>cyclePhase</code> property in the shader to calculate a starting offset to the animation cycle. Defaults to false.
	 * @param    [optional] minScale        Defines the default min scale transform of the node, when in global mode. Defaults to 1.
	 * @param    [optional] maxScale        Defines the default max color transform of the node, when in global mode. Defaults to 1.
	 * @param    [optional] cycleDuration   Defines the default duration of the animation in seconds, used as a period independent of particle duration when in global mode. Defaults to 1.
	 * @param    [optional] cyclePhase      Defines the default phase of the cycle in degrees, used as the starting offset of the cycle when in global mode. Defaults to 0.
	 */
	public function new(mode:UInt, usesCycle:Bool, usesPhase:Bool, minScale:Float = 1, maxScale:Float = 1, cycleDuration:Float = 1, cyclePhase:Float = 0)
	{
		var len:Int = 2;
		if (usesCycle)
			len++;
		if (usesPhase)
			len++;
		super("ParticleScale", mode, len, 3);

		_stateClass = ParticleScaleState;

		this.usesCycle = usesCycle;
		this.usesPhase = usesPhase;

		this.minScale = minScale;
		this.maxScale = maxScale;
		this.cycleDuration = cycleDuration;
		this.cyclePhase = cyclePhase;
	}

	/**
	 * @inheritDoc
	 */
	override public function getAGALVertexCode(pass:MaterialPassBase, animationRegisterCache:AnimationRegisterCache):String
	{
		pass = pass;

		var code:String = "";
		var temp:ShaderRegisterElement = animationRegisterCache.getFreeVertexSingleTemp();

		var scaleRegister:ShaderRegisterElement = (_mode == ParticlePropertiesMode.GLOBAL) ? animationRegisterCache.getFreeVertexConstant() : animationRegisterCache.getFreeVertexAttribute();
		animationRegisterCache.setRegisterIndex(this, SCALE_INDEX, scaleRegister.index);

		if (usesCycle)
		{
			code += "mul " + temp + "," + animationRegisterCache.vertexTime + "," + scaleRegister + ".z\n";

			if (usesPhase)
				code += "add " + temp + "," + temp + "," + scaleRegister + ".w\n";

			code += "sin " + temp + "," + temp + "\n";
		}

		code += "mul " + temp + "," + scaleRegister + ".y," + ((usesCycle) ? temp : animationRegisterCache.vertexLife) + "\n";
		code += "add " + temp + "," + scaleRegister + ".x," + temp + "\n";
		code += "mul " + animationRegisterCache.scaleAndRotateTarget + ".xyz," + animationRegisterCache.scaleAndRotateTarget + ".xyz," + temp + "\n";

		return code;
	}

	/**
	 * @inheritDoc
	 */
	public function getAnimationState(animator:IAnimator):ParticleScaleState
	{
		return Std.instance(animator.getAnimationState(this), ParticleScaleState);
	}

	/**
	 * @inheritDoc
	 */
	override public function generatePropertyOfOneParticle(param:ParticleProperties):Void
	{
		var scale:Vector3D = param[SCALE_VECTOR3D];
		if (scale == null)
			throw(new Error("there is no " + SCALE_VECTOR3D + " in param!"));

		if (usesCycle)
		{
			_oneData[0] = (scale.x + scale.y) / 2;
			_oneData[1] = Math.abs(scale.x - scale.y) / 2;
			if (scale.z <= 0)
				throw(new Error("the cycle duration must be greater than zero"));
			_oneData[2] = Math.PI * 2 / scale.z;
			if (usesPhase)
				_oneData[3] = scale.w * Math.PI / 180;
		}
		else
		{
			_oneData[0] = scale.x;
			_oneData[1] = scale.y - scale.x;
		}
	}
}