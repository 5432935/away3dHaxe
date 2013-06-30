package a3d.materials.methods;


import a3d.core.managers.Stage3DProxy;
import a3d.materials.compilation.ShaderRegisterCache;
import a3d.materials.compilation.ShaderRegisterElement;
import a3d.textures.CubeTextureBase;
import a3d.textures.Texture2DBase;

import flash.display3D.Context3D;



class EnvMapMethod extends EffectMethodBase
{
	private var _cubeTexture:CubeTextureBase;
	private var _alpha:Float;
	private var _mask:Texture2DBase;

	public function new(envMap:CubeTextureBase, alpha:Float = 1)
	{
		super();
		_cubeTexture = envMap;
		_alpha = alpha;
	}

	public var mask(get,set):Texture2DBase;
	private function get_mask():Texture2DBase
	{
		return _mask;
	}

	private function set_mask(value:Texture2DBase):Texture2DBase
	{
		if ((value != null) != (_mask != null) ||
			(value != null && _mask != null && 
			(value.hasMipMaps != _mask.hasMipMaps || value.format != _mask.format)))
			invalidateShaderProgram();
		_mask = value;
		
		return _mask;
	}

	override public function initVO(vo:MethodVO):Void
	{
		vo.needsNormals = true;
		vo.needsView = true;
		vo.needsUV = _mask != null;
	}

	/**
	 * The cube environment map to use for the diffuse lighting.
	 */
	public var envMap(get,set):CubeTextureBase;
	private function get_envMap():CubeTextureBase
	{
		return _cubeTexture;
	}

	private function set_envMap(value:CubeTextureBase):CubeTextureBase
	{
		return _cubeTexture = value;
	}

	/**
	 * @inheritDoc
	 */
	override public function dispose():Void
	{
	}

	/**
	 * The reflectiveness of the surface
	 */
	public var alpha(get,set):Float;
	private function get_alpha():Float
	{
		return _alpha;
	}

	private function set_alpha(value:Float):Float
	{
		return _alpha = value;
	}

	override public function activate(vo:MethodVO, stage3DProxy:Stage3DProxy):Void
	{
		var context:Context3D = stage3DProxy.context3D;
		vo.fragmentData[vo.fragmentConstantsIndex] = _alpha;
		context.setTextureAt(vo.texturesIndex, _cubeTexture.getTextureForStage3D(stage3DProxy));
		if (_mask != null)
			context.setTextureAt(vo.texturesIndex + 1, _mask.getTextureForStage3D(stage3DProxy));
	}

	override public function getFragmentCode(vo:MethodVO, regCache:ShaderRegisterCache, targetReg:ShaderRegisterElement):String
	{
		var dataRegister:ShaderRegisterElement = regCache.getFreeFragmentConstant();
		var temp:ShaderRegisterElement = regCache.getFreeFragmentVectorTemp();
		var code:String = "";
		var cubeMapReg:ShaderRegisterElement = regCache.getFreeTextureReg();
		vo.texturesIndex = cubeMapReg.index;
		vo.fragmentConstantsIndex = dataRegister.index * 4;

		regCache.addFragmentTempUsages(temp, 1);
		var temp2:ShaderRegisterElement = regCache.getFreeFragmentVectorTemp();

		// r = I - 2(I.N)*N
		code += "dp3 " + temp + ".w, " + _sharedRegisters.viewDirFragment + ".xyz, " + _sharedRegisters.normalFragment + ".xyz		\n" +
			"add " + temp + ".w, " + temp + ".w, " + temp + ".w											\n" +
			"mul " + temp + ".xyz, " + _sharedRegisters.normalFragment + ".xyz, " + temp + ".w						\n" +
			"sub " + temp + ".xyz, " + temp + ".xyz, " + _sharedRegisters.viewDirFragment + ".xyz					\n" +
			getTexCubeSampleCode(vo, temp, cubeMapReg, _cubeTexture, temp) +
			"sub " + temp2 + ".w, " + temp + ".w, fc0.x									\n" + // -.5
			"kil " + temp2 + ".w\n" + // used for real time reflection mapping - if alpha is not 1 (mock texture) kil output
			"sub " + temp + ", " + temp + ", " + targetReg + "											\n";

		if (_mask != null)
		{
			var maskReg:ShaderRegisterElement = regCache.getFreeTextureReg();
			code += getTex2DSampleCode(vo, temp2, maskReg, _mask, _sharedRegisters.uvVarying) +
				"mul " + temp + ", " + temp2 + ", " + temp + "\n";
		}
		code += "mul " + temp + ", " + temp + ", " + dataRegister + ".x										\n" +
			"add " + targetReg + ", " + targetReg + ", " + temp + "										\n";

		regCache.removeFragmentTempUsage(temp);

		return code;
	}
}
