package a3d.materials.methods;


import a3d.core.managers.Stage3DProxy;
import a3d.materials.methods.MethodVO;
import a3d.materials.compilation.ShaderRegisterCache;
import a3d.materials.compilation.ShaderRegisterElement;
import a3d.textures.CubeTextureBase;



/**
 * EnvMapDiffuseMethod provides a diffuse shading method that uses a diffuse irradiance environment map to
 * approximate global lighting rather than lights.
 */
class EnvMapAmbientMethod extends BasicAmbientMethod
{
	/**
	 * The cube environment map to use for the diffuse lighting.
	 */
	public var envMap(get, set):CubeTextureBase;
	
	private var _cubeTexture:CubeTextureBase;

	/**
	 * Creates a new EnvMapDiffuseMethod object.
	 * @param envMap The cube environment map to use for the diffuse lighting.
	 */
	public function new(envMap:CubeTextureBase)
	{
		super();
		_cubeTexture = envMap;
	}

	override public function initVO(vo:MethodVO):Void
	{
		super.initVO(vo);
		vo.needsNormals = true;
	}

	/**
	 * @inheritDoc
	 */
	override public function dispose():Void
	{
	}

	
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
	override public function activate(vo:MethodVO, stage3DProxy:Stage3DProxy):Void
	{
		super.activate(vo, stage3DProxy);

		stage3DProxy.context3D.setTextureAt(vo.texturesIndex, _cubeTexture.getTextureForStage3D(stage3DProxy));
	}

	/**
	 * @inheritDoc
	 */
	override public function getFragmentCode(vo:MethodVO, regCache:ShaderRegisterCache, targetReg:ShaderRegisterElement):String
	{
		var code:String = "";
		var cubeMapReg:ShaderRegisterElement = regCache.getFreeTextureReg();
		vo.texturesIndex = cubeMapReg.index;

		code += getTexCubeSampleCode(vo, targetReg, cubeMapReg, _cubeTexture, _sharedRegisters.normalFragment);

		_ambientInputRegister = regCache.getFreeFragmentConstant();
		vo.fragmentConstantsIndex = _ambientInputRegister.index;

		code += "add " + targetReg + ".xyz, " + targetReg + ".xyz, " + _ambientInputRegister + ".xyz\n";

		return code;
	}
}
