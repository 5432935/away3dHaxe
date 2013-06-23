package a3d.textures
{
	import flash.display3D.Context3D;
	import flash.display3D.Context3DTextureFormat;
	import flash.display3D.textures.TextureBase;

	
	import a3d.core.managers.Stage3DProxy;
	import a3d.errors.AbstractMethodError;
	import a3d.io.library.assets.AssetType;
	import a3d.io.library.assets.IAsset;
	import a3d.io.library.assets.NamedAssetBase;

	

	class TextureProxyBase extends NamedAssetBase implements IAsset
	{
		private var _format:String = Context3DTextureFormat.BGRA;
		private var _hasMipmaps:Bool = true;

		private var _textures:Vector<TextureBase>;
		private var _dirty:Vector<Context3D>;

		private var _width:Int;
		private var _height:Int;

		public function TextureProxyBase()
		{
			_textures = new Vector<TextureBase>(8);
			_dirty = new Vector<Context3D>(8);
		}

		private inline function get_hasMipMaps():Bool
		{
			return _hasMipmaps;
		}

		private inline function get_format():String
		{
			return _format;
		}

		private inline function get_assetType():String
		{
			return AssetType.TEXTURE;
		}

		private inline function get_width():Int
		{
			return _width;
		}

		private inline function get_height():Int
		{
			return _height;
		}

		public function getTextureForStage3D(stage3DProxy:Stage3DProxy):TextureBase
		{
			var contextIndex:Int = stage3DProxy.stage3DIndex;
			var tex:TextureBase = _textures[contextIndex];
			var context:Context3D = stage3DProxy.context3D;

			if (!tex || _dirty[contextIndex] != context)
			{
				_textures[contextIndex] = tex = createTexture(context);
				_dirty[contextIndex] = context;
				uploadContent(tex);
			}

			return tex;
		}

		private function uploadContent(texture:TextureBase):Void
		{
			throw new AbstractMethodError();
		}

		private function setSize(width:Int, height:Int):Void
		{
			if (_width != width || _height != height)
				invalidateSize();

			_width = width;
			_height = height;
		}

		public function invalidateContent():Void
		{
			for (var i:Int = 0; i < 8; ++i)
			{
				_dirty[i] = null;
			}
		}

		private function invalidateSize():Void
		{
			var tex:TextureBase;
			for (var i:Int = 0; i < 8; ++i)
			{
				tex = _textures[i];
				if (tex)
				{
					tex.dispose();
					_textures[i] = null;
					_dirty[i] = null;
				}
			}
		}



		private function createTexture(context:Context3D):TextureBase
		{
			throw new AbstractMethodError();
		}

		/**
		 * @inheritDoc
		 */
		public function dispose():Void
		{
			for (var i:Int = 0; i < 8; ++i)
				if (_textures[i])
					_textures[i].dispose();
		}
	}
}
