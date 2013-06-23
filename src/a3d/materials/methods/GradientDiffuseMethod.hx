package a3d.materials.methods
{
	
	import a3d.core.managers.Stage3DProxy;
	import a3d.materials.compilation.ShaderRegisterCache;
	import a3d.materials.compilation.ShaderRegisterElement;
	import a3d.textures.Texture2DBase;

	

	/**
	 * GradientDiffuseMethod is an alternative to BasicDiffuseMethod in which the shading can be modulated with a gradient
	 * to introduce color-tinted shading as opposed to the single-channel diffuse strength. This can be used as a crude
	 * approximation to subsurface scattering (for instance, the mid-range shading for skin can be tinted red to similate
	 * scattered light within the skin attributing to the final colour)
	 */
	class GradientDiffuseMethod extends BasicDiffuseMethod
	{
		private var _gradientTextureRegister:ShaderRegisterElement;
		private var _gradient:Texture2DBase;

		/**
		 * Creates a new GradientDiffuseMethod object.
		 * @param gradient A texture that contains the light colour based on the angle. This can be used to change the light colour due to subsurface scattering when dot &lt; 0
		 */
		public function GradientDiffuseMethod(gradient:Texture2DBase)
		{
			super();
			_gradient = gradient;
		}

		private inline function get_gradient():Texture2DBase
		{
			return _gradient;
		}

		private inline function set_gradient(value:Texture2DBase):Void
		{
			if (value.hasMipMaps != _gradient.hasMipMaps || value.format != _gradient.format)
				invalidateShaderProgram();
			_gradient = value;
		}

		override public function cleanCompilationData():Void
		{
			super.cleanCompilationData();
			_gradientTextureRegister = null;
		}

		override public function getFragmentPreLightingCode(vo:MethodVO, regCache:ShaderRegisterCache):String
		{
			var code:String = super.getFragmentPreLightingCode(vo, regCache);
			_isFirstLight = true;

			_gradientTextureRegister = regCache.getFreeTextureReg();
			vo.secondaryTexturesIndex = _gradientTextureRegister.index;

			return code;
		}

		override public function getFragmentCodePerLight(vo:MethodVO, lightDirReg:ShaderRegisterElement, lightColReg:ShaderRegisterElement, regCache:ShaderRegisterCache):String
		{
			var code:String = "";
			var t:ShaderRegisterElement;

			// write in temporary if not first light, so we can add to total diffuse colour
			if (_isFirstLight)
				t = _totalLightColorReg;
			else
			{
				t = regCache.getFreeFragmentVectorTemp();
				regCache.addFragmentTempUsages(t, 1);
			}

			code += "dp3 " + t + ".w, " + lightDirReg + ".xyz, " + _sharedRegisters.normalFragment + ".xyz\n" +
				"mul " + t + ".w, " + t + ".w, " + _sharedRegisters.commons + ".x\n" +
				"add " + t + ".w, " + t + ".w, " + _sharedRegisters.commons + ".x\n" +
				"mul " + t + ".xyz, " + t + ".w, " + lightDirReg + ".w\n";

			if (modulateMethod != null)
				code += modulateMethod(vo, t, regCache, _sharedRegisters);

			code += getTex2DSampleCode(vo, t, _gradientTextureRegister, _gradient, t, "clamp") +
//					"mul " + t + ".xyz, " + t + ".xyz, " + t + ".w\n" +
				"mul " + t + ".xyz, " + t + ".xyz, " + lightColReg + ".xyz\n";

			if (!_isFirstLight)
			{
				code += "add " + _totalLightColorReg + ".xyz, " + _totalLightColorReg + ".xyz, " + t + ".xyz\n";
				regCache.removeFragmentTempUsage(t);
			}

			_isFirstLight = false;

			return code;
		}


		override private function applyShadow(vo:MethodVO, regCache:ShaderRegisterCache):String
		{
			var t:ShaderRegisterElement = regCache.getFreeFragmentVectorTemp();

			return "mov " + t + ", " + _shadowRegister + ".wwww\n" +
				getTex2DSampleCode(vo, t, _gradientTextureRegister, _gradient, t, "clamp") +
				"mul " + _totalLightColorReg + ".xyz, " + _totalLightColorReg + ", " + t + "\n";
		}

		override public function activate(vo:MethodVO, stage3DProxy:Stage3DProxy):Void
		{
			super.activate(vo, stage3DProxy);
			stage3DProxy.context3D.setTextureAt(vo.secondaryTexturesIndex, _gradient.getTextureForStage3D(stage3DProxy));
		}
	}
}
