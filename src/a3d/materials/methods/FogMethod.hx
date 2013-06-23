package a3d.materials.methods
{
	
	import a3d.core.managers.Stage3DProxy;
	import a3d.materials.compilation.ShaderRegisterCache;
	import a3d.materials.compilation.ShaderRegisterElement;

	

	class FogMethod extends EffectMethodBase
	{
		private var _minDistance:Float = 0;
		private var _maxDistance:Float = 1000;
		private var _fogColor:UInt;
		private var _fogR:Float;
		private var _fogG:Float;
		private var _fogB:Float;

		public function FogMethod(minDistance:Float, maxDistance:Float, fogColor:UInt = 0x808080)
		{
			super();
			this.minDistance = minDistance;
			this.maxDistance = maxDistance;
			this.fogColor = fogColor;
		}

		override public function initVO(vo:MethodVO):Void
		{
			vo.needsProjection = true;
		}

		override public function initConstants(vo:MethodVO):Void
		{
			var data:Vector<Float> = vo.fragmentData;
			var index:Int = vo.fragmentConstantsIndex;
			data[index + 3] = 1;
			data[index + 6] = 0;
			data[index + 7] = 0;
		}

		private inline function get_minDistance():Float
		{
			return _minDistance;
		}

		private inline function set_minDistance(value:Float):Void
		{
			_minDistance = value;
		}

		private inline function get_maxDistance():Float
		{
			return _maxDistance;
		}

		private inline function set_maxDistance(value:Float):Void
		{
			_maxDistance = value;
		}

		private inline function get_fogColor():UInt
		{
			return _fogColor;
		}

		private inline function set_fogColor(value:UInt):Void
		{
			_fogColor = value;
			_fogR = ((value >> 16) & 0xff) / 0xff;
			_fogG = ((value >> 8) & 0xff) / 0xff;
			_fogB = (value & 0xff) / 0xff;
		}

		override public function activate(vo:MethodVO, stage3DProxy:Stage3DProxy):Void
		{
			var data:Vector<Float> = vo.fragmentData;
			var index:Int = vo.fragmentConstantsIndex;
			data[index] = _fogR;
			data[index + 1] = _fogG;
			data[index + 2] = _fogB;
			data[index + 4] = _minDistance;
			data[index + 5] = 1 / (_maxDistance - _minDistance);
		}

		override public function getFragmentCode(vo:MethodVO, regCache:ShaderRegisterCache, targetReg:ShaderRegisterElement):String
		{
			var fogColor:ShaderRegisterElement = regCache.getFreeFragmentConstant();
			var fogData:ShaderRegisterElement = regCache.getFreeFragmentConstant();
			var temp:ShaderRegisterElement = regCache.getFreeFragmentVectorTemp();
			regCache.addFragmentTempUsages(temp, 1);
			var temp2:ShaderRegisterElement = regCache.getFreeFragmentVectorTemp();
			var code:String = "";
			vo.fragmentConstantsIndex = fogColor.index * 4;

			code += "sub " + temp2 + ".w, " + _sharedRegisters.projectionFragment + ".z, " + fogData + ".x          \n" +
				"mul " + temp2 + ".w, " + temp2 + ".w, " + fogData + ".y					\n" +
				"sat " + temp2 + ".w, " + temp2 + ".w										\n" +
				"sub " + temp + ", " + fogColor + ", " + targetReg + "\n" + // (fogColor- col)
				"mul " + temp + ", " + temp + ", " + temp2 + ".w					\n" + // (fogColor- col)*fogRatio
				"add " + targetReg + ", " + targetReg + ", " + temp + "\n"; // fogRatio*(fogColor- col) + col

			regCache.removeFragmentTempUsage(temp);

			return code;
		}
	}
}
