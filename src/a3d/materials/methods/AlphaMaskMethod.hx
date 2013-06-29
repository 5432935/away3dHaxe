package a3d.materials.methods;


import a3d.core.managers.Stage3DProxy;
import a3d.materials.compilation.ShaderRegisterCache;
import a3d.materials.compilation.ShaderRegisterElement;
import a3d.textures.Texture2DBase;



/**
 * Allows the use of an additional texture to specify the alpha value of the material. When used with the secondary uv
 * set, it allows for a tiled main texture with independently varying alpha (useful for water etc).
 */
class AlphaMaskMethod extends EffectMethodBase
{
	private var _texture:Texture2DBase;
	private var _useSecondaryUV:Bool;

	public function new(texture:Texture2DBase, useSecondaryUV:Bool = false)
	{
		super();
		_texture = texture;
		_useSecondaryUV = useSecondaryUV;
	}

	override public function initVO(vo:MethodVO):Void
	{
		vo.needsSecondaryUV = _useSecondaryUV;
		vo.needsUV = !_useSecondaryUV;
	}

	public var useSecondaryUV(get, set):Bool;
	private inline function get_useSecondaryUV():Bool
	{
		return _useSecondaryUV;
	}

	private inline function set_useSecondaryUV(value:Bool):Bool
	{
		if (_useSecondaryUV == value)
			return _useSecondaryUV;
		_useSecondaryUV = value;
		invalidateShaderProgram();
		return _useSecondaryUV;
	}

	public var texture(get, set):Texture2DBase;
	private inline function get_texture():Texture2DBase
	{
		return _texture;
	}

	private inline function set_texture(value:Texture2DBase):Texture2DBase
	{
		return _texture = value;
	}

	override public function activate(vo:MethodVO, stage3DProxy:Stage3DProxy):Void
	{
		stage3DProxy.context3D.setTextureAt(vo.texturesIndex, _texture.getTextureForStage3D(stage3DProxy));
	}

	override public function getFragmentCode(vo:MethodVO, regCache:ShaderRegisterCache, targetReg:ShaderRegisterElement):String
	{
		var textureReg:ShaderRegisterElement = regCache.getFreeTextureReg();
		var temp:ShaderRegisterElement = regCache.getFreeFragmentVectorTemp();
		var uvReg:ShaderRegisterElement = _useSecondaryUV ? _sharedRegisters.secondaryUVVarying : _sharedRegisters.uvVarying;
		vo.texturesIndex = textureReg.index;

		return getTex2DSampleCode(vo, temp, textureReg, _texture, uvReg) +
			"mul " + targetReg + ", " + targetReg + ", " + temp + ".x\n";
	}
}
