package away3d.materials.methods;


import away3d.errors.AbstractMethodError;
import away3d.library.assets.AssetType;
import away3d.library.assets.IAsset;
import away3d.lights.LightBase;
import away3d.lights.shadowmaps.ShadowMapperBase;
import away3d.materials.compilation.ShaderRegisterCache;
import away3d.materials.compilation.ShaderRegisterElement;


/**
 * ShadowMapMethodBase provides an abstract base method for shadow map methods.
 */
class ShadowMapMethodBase extends ShadingMethodBase implements IAsset
{
	public var assetType(get, null):String;
	/**
	 * The "transparency" of the shadows. This allows making shadows less strong.
	 */
	public var alpha(get,set):Float;
	/**
	 * The light casting the shadows.
	 */
	public var castingLight(get,null):LightBase;
	/**
	 * A small value to counter floating point precision errors when comparing values in the shadow map with the
	 * calculated depth value. Increase this if shadow banding occurs, decrease it if the shadow seems to be too detached.
	 */
	public var epsilon(get, set):Float;
	
	private var _castingLight:LightBase;
	private var _shadowMapper:ShadowMapperBase;

	private var _epsilon:Float = .02;
	private var _alpha:Float = 1;

	/**
	 * Creates a new ShadowMapMethodBase object.
	 * @param castingLight The light used to cast shadows.
	 */
	public function new(castingLight:LightBase)
	{
		super();
		_castingLight = castingLight;
		castingLight.castsShadows = true;
		_shadowMapper = castingLight.shadowMapper;
	}

	
	private function get_assetType():String
	{
		return AssetType.SHADOW_MAP_METHOD;
	}

	
	private function get_alpha():Float
	{
		return _alpha;
	}

	private function set_alpha(value:Float):Float
	{
		return _alpha = value;
	}

	
	private function get_castingLight():LightBase
	{
		return _castingLight;
	}

	
	private function get_epsilon():Float
	{
		return _epsilon;
	}

	private function set_epsilon(value:Float):Float
	{
		return _epsilon = value;
	}

	public function getFragmentCode(vo:MethodVO, regCache:ShaderRegisterCache, targetReg:ShaderRegisterElement):String
	{
		throw new AbstractMethodError();
		return null;
	}
}
