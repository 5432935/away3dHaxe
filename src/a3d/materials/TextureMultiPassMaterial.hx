package a3d.materials;


import a3d.textures.Texture2DBase;



class TextureMultiPassMaterial extends MultiPassMaterialBase
{
	private var _animateUVs:Bool;

	public function new(texture:Texture2DBase = null, smooth:Bool = true, repeat:Bool = false, mipmap:Bool = true)
	{
		super();
		this.texture = texture;
		this.smooth = smooth;
		this.repeat = repeat;
		this.mipmap = mipmap;
	}

	private function get_animateUVs():Bool
	{
		return _animateUVs;
	}

	private function set_animateUVs(value:Bool):Void
	{
		_animateUVs = value;
	}

	/**
	 * The texture object to use for the albedo colour.
	 */
	private function get_texture():Texture2DBase
	{
		return diffuseMethod.texture;
	}

	private function set_texture(value:Texture2DBase):Void
	{
		diffuseMethod.texture = value;
	}

	/**
	 * The texture object to use for the ambient colour.
	 */
	private function get_ambientTexture():Texture2DBase
	{
		return ambientMethod.texture;
	}

	private function set_ambientTexture(value:Texture2DBase):Void
	{
		ambientMethod.texture = value;
		diffuseMethod.useAmbientTexture = Bool(value);
	}


	override private function updateScreenPasses():Void
	{
		super.updateScreenPasses();
		if (_effectsPass)
			_effectsPass.animateUVs = _animateUVs;
	}
}
