package a3d.materials;


import a3d.materials.passes.SkyBoxPass;
import a3d.textures.CubeTextureBase;



/**
 * SkyBoxMaterial is a material exclusively used to render skyboxes
 *
 * @see a3d.primitives.SkyBox
 */
class SkyBoxMaterial extends MaterialBase
{
	private var _cubeMap:CubeTextureBase;
	private var _skyboxPass:SkyBoxPass;

	/**
	 * Creates a new SkyBoxMaterial object.
	 * @param cubeMap The CubeMap to use as the skybox.
	 */
	public function new(cubeMap:CubeTextureBase)
	{
		super();
		_cubeMap = cubeMap;
		addPass(_skyboxPass = new SkyBoxPass());
		_skyboxPass.cubeTexture = _cubeMap;
	}

	/**
	 * The CubeMap to use as the skybox.
	 */
	public var cubeMap(get, set):CubeTextureBase;
	private function get_cubeMap():CubeTextureBase
	{
		return _cubeMap;
	}

	private function set_cubeMap(value:CubeTextureBase):CubeTextureBase
	{
		if (value != null && _cubeMap != null && 
			(value.hasMipMaps != _cubeMap.hasMipMaps || value.format != _cubeMap.format))
			invalidatePasses(null);

		_cubeMap = value;

		_skyboxPass.cubeTexture = _cubeMap;
		
		return _cubeMap;
	}
}
