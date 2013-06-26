package a3d.animators.nodes;

import flash.geom.ColorTransform;
import flash.Vector;


import a3d.animators.ParticleAnimationSet;
import a3d.animators.data.AnimationRegisterCache;
import a3d.animators.data.ColorSegmentPoint;
import a3d.animators.data.ParticlePropertiesMode;
import a3d.animators.states.ParticleSegmentedColorState;
import a3d.materials.compilation.ShaderRegisterElement;
import a3d.materials.passes.MaterialPassBase;



class ParticleSegmentedColorNode extends ParticleNodeBase
{
	/** @private */
	public static inline var START_MULTIPLIER_INDEX:UInt = 0;

	/** @private */
	public static inline var START_OFFSET_INDEX:UInt = 1;

	/** @private */
	public static inline var TIME_DATA_INDEX:UInt = 2;

	/** @private */
	public var usesMultiplier:Bool;
	/** @private */
	public var usesOffset:Bool;
	/** @private */
	public var startColor:ColorTransform;
	/** @private */
	public var endColor:ColorTransform;
	/** @private */
	public var numSegmentPoint:Int;
	/** @private */
	public var segmentPoints:Vector<ColorSegmentPoint>;

	public function new(usesMultiplier:Bool, usesOffset:Bool, numSegmentPoint:Int, startColor:ColorTransform, endColor:ColorTransform, segmentPoints:Vector<ColorSegmentPoint>)
	{
		_stateClass = ParticleSegmentedColorState;

		//because of the stage3d register limitation, it only support the global mode
		super("ParticleSegmentedColor", ParticlePropertiesMode.GLOBAL, 0, ParticleAnimationSet.COLOR_PRIORITY);

		if (numSegmentPoint > 4)
			throw(new Error("the numSegmentPoint must be less or equal 4"));
		this.usesMultiplier = usesMultiplier;
		this.usesOffset = usesOffset;
		this.numSegmentPoint = numSegmentPoint;
		this.startColor = startColor;
		this.endColor = endColor;
		this.segmentPoints = segmentPoints;
	}

	/**
	 * @inheritDoc
	 */
	override public function processAnimationSetting(particleAnimationSet:ParticleAnimationSet):Void
	{
		if (usesMultiplier)
			particleAnimationSet.hasColorMulNode = true;
		if (usesOffset)
			particleAnimationSet.hasColorAddNode = true;
	}

	/**
	 * @inheritDoc
	 */
	override public function getAGALVertexCode(pass:MaterialPassBase, animationRegisterCache:AnimationRegisterCache):String
	{
		pass = pass;

		var code:String = "";
		if (animationRegisterCache.needFragmentAnimation)
		{
			var accMultiplierColor:ShaderRegisterElement;
			//var accOffsetColor:ShaderRegisterElement;
			if (usesMultiplier)
			{
				accMultiplierColor = animationRegisterCache.getFreeVertexVectorTemp();
				animationRegisterCache.addVertexTempUsages(accMultiplierColor, 1);
			}

			var tempColor:ShaderRegisterElement = animationRegisterCache.getFreeVertexVectorTemp();
			animationRegisterCache.addVertexTempUsages(tempColor, 1);

			var temp:ShaderRegisterElement = animationRegisterCache.getFreeVertexVectorTemp();
			var accTime:ShaderRegisterElement = new ShaderRegisterElement(temp.regName, temp.index, 0);
			var tempTime:ShaderRegisterElement = new ShaderRegisterElement(temp.regName, temp.index, 1);

			if (usesMultiplier)
				animationRegisterCache.removeVertexTempUsage(accMultiplierColor);

			animationRegisterCache.removeVertexTempUsage(tempColor);

			//for saving all the life values (at most 4)
			var lifeTimeRegister:ShaderRegisterElement = animationRegisterCache.getFreeVertexConstant();
			animationRegisterCache.setRegisterIndex(this, TIME_DATA_INDEX, lifeTimeRegister.index);

			var i:Int;

			var startMulValue:ShaderRegisterElement;
			var deltaMulValues:Vector<ShaderRegisterElement>;
			if (usesMultiplier)
			{
				startMulValue = animationRegisterCache.getFreeVertexConstant();
				animationRegisterCache.setRegisterIndex(this, START_MULTIPLIER_INDEX, startMulValue.index);
				deltaMulValues = new Vector<ShaderRegisterElement>;
				for (i in 0...numSegmentPoint + 1)
				{
					deltaMulValues.push(animationRegisterCache.getFreeVertexConstant());
				}
			}

			var startOffsetValue:ShaderRegisterElement;
			var deltaOffsetValues:Vector<ShaderRegisterElement>;
			if (usesOffset)
			{
				startOffsetValue = animationRegisterCache.getFreeVertexConstant();
				animationRegisterCache.setRegisterIndex(this, START_OFFSET_INDEX, startOffsetValue.index);
				deltaOffsetValues = new Vector<ShaderRegisterElement>;
				for (i in 0...numSegmentPoint+1)
				{
					deltaOffsetValues.push(animationRegisterCache.getFreeVertexConstant());
				}
			}


			if (usesMultiplier)
				code += "mov " + accMultiplierColor + "," + startMulValue + "\n";
			if (usesOffset)
				code += "add " + animationRegisterCache.colorAddTarget + "," + animationRegisterCache.colorAddTarget + "," + startOffsetValue + "\n";

			for (i in 0...numSegmentPoint)
			{
				switch (i)
				{
					case 0:
						code += "min " + tempTime + "," + animationRegisterCache.vertexLife + "," + lifeTimeRegister + ".x\n";
					case 1:
						code += "sub " + accTime + "," + animationRegisterCache.vertexLife + "," + lifeTimeRegister + ".x\n";
						code += "max " + tempTime + "," + accTime + "," + animationRegisterCache.vertexZeroConst + "\n";
						code += "min " + tempTime + "," + tempTime + "," + lifeTimeRegister + ".y\n";

					case 2:
						code += "sub " + accTime + "," + accTime + "," + lifeTimeRegister + ".y\n";
						code += "max " + tempTime + "," + accTime + "," + animationRegisterCache.vertexZeroConst + "\n";
						code += "min " + tempTime + "," + tempTime + "," + lifeTimeRegister + ".z\n";

					case 3:
						code += "sub " + accTime + "," + accTime + "," + lifeTimeRegister + ".z\n";
						code += "max " + tempTime + "," + accTime + "," + animationRegisterCache.vertexZeroConst + "\n";
						code += "min " + tempTime + "," + tempTime + "," + lifeTimeRegister + ".w\n";

				}
				if (usesMultiplier)
				{
					code += "mul " + tempColor + "," + tempTime + "," + deltaMulValues[i] + "\n";
					code += "add " + accMultiplierColor + "," + accMultiplierColor + "," + tempColor + "\n";
				}
				if (usesOffset)
				{
					code += "mul " + tempColor + "," + tempTime + "," + deltaOffsetValues[i] + "\n";
					code += "add " + animationRegisterCache.colorAddTarget + "," + animationRegisterCache.colorAddTarget + "," + tempColor + "\n";
				}
			}

			//for the last segment:
			if (numSegmentPoint == 0)
				tempTime = animationRegisterCache.vertexLife;
			else
			{
				switch (numSegmentPoint)
				{
					case 1:
						code += "sub " + accTime + "," + animationRegisterCache.vertexLife + "," + lifeTimeRegister + ".x\n";
					
					case 2:
						code += "sub " + accTime + "," + accTime + "," + lifeTimeRegister + ".y\n";
					
					case 3:
						code += "sub " + accTime + "," + accTime + "," + lifeTimeRegister + ".z\n";
					
					case 4:
						code += "sub " + accTime + "," + accTime + "," + lifeTimeRegister + ".w\n";
					
				}
				code += "max " + tempTime + "," + accTime + "," + animationRegisterCache.vertexZeroConst + "\n";
			}
			if (usesMultiplier)
			{
				code += "mul " + tempColor + "," + tempTime + "," + deltaMulValues[numSegmentPoint] + "\n";
				code += "add " + accMultiplierColor + "," + accMultiplierColor + "," + tempColor + "\n";
				code += "mul " + animationRegisterCache.colorMulTarget + "," + animationRegisterCache.colorMulTarget + "," + accMultiplierColor + "\n";
			}
			if (usesOffset)
			{
				code += "mul " + tempColor + "," + tempTime + "," + deltaOffsetValues[numSegmentPoint] + "\n";
				code += "add " + animationRegisterCache.colorAddTarget + "," + animationRegisterCache.colorAddTarget + "," + tempColor + "\n";
			}

		}
		return code;
	}

}
