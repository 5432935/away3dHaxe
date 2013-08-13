package a3d.core.render;

import a3d.core.managers.Context3DProxy;
import a3d.utils.VectorUtil;
import com.adobe.utils.AGALMiniAssembler;
import flash.Vector;

import flash.display3D.Context3D;
import flash.display3D.Context3DProgramType;
import flash.display3D.Context3DTextureFormat;
import flash.display3D.Context3DVertexBufferFormat;
import flash.display3D.IndexBuffer3D;
import flash.display3D.Program3D;
import flash.display3D.VertexBuffer3D;

import a3d.core.managers.Stage3DProxy;
import a3d.utils.Debug;
import a3d.textures.Texture2DBase;

/**
 * 背景图片绘制
 */
class BackgroundImageRenderer
{
	public var stage3DProxy(get, set):Stage3DProxy;
	
	public var texture(get, set):Texture2DBase;
	
	private var _program3d:Program3D;
	private var _texture:Texture2DBase;
	private var _indexBuffer:IndexBuffer3D;
	private var _vertexBuffer:VertexBuffer3D;
	private var _stage3DProxy:Stage3DProxy;
	private var _context:Context3DProxy;

	public function new(stage3DProxy:Stage3DProxy)
	{
		this.stage3DProxy = stage3DProxy;
	}

	private function removeBuffers():Void
	{
		if (_vertexBuffer != null)
		{
			_vertexBuffer.dispose();
			_vertexBuffer = null;
			_program3d.dispose();
			_program3d = null;
			_indexBuffer.dispose();
			_indexBuffer = null;
		}
	}

	private function getVertexCode():String
	{
		return "mov op, va0\n" +
			"mov v0, va1";
	}

	private function getFragmentCode():String
	{
		var format:String;
		switch (_texture.format)
		{
			case Context3DTextureFormat.COMPRESSED:
				format = "dxt1,";
			
			case "compressedAlpha":
				format = "dxt5,";
				
			default:
				format = "";
		}
		return "tex ft0, v0, fs0 <2d, " + format + "linear>	\n" +
			"mov oc, ft0";
	}

	public function dispose():Void
	{
		removeBuffers();
	}

	public function render():Void
	{
		var context:Context3DProxy = _stage3DProxy.context3D;

		if (context != _context)
		{
			removeBuffers();
			_context = context;
		}

		if (context == null)
			return;

		if (_vertexBuffer == null)
			initBuffers(context);

		context.setProgram(_program3d);
		context.setTextureAt(0, _texture.getTextureForStage3D(_stage3DProxy));
		context.setVertexBufferAt(0, _vertexBuffer, 0, Context3DVertexBufferFormat.FLOAT_2);
		context.setVertexBufferAt(1, _vertexBuffer, 2, Context3DVertexBufferFormat.FLOAT_2);
		context.drawTriangles(_indexBuffer, 0, 2);
		context.setVertexBufferAt(0, null);
		context.setVertexBufferAt(1, null);
		context.setTextureAt(0, null);
	}

	private function initBuffers(context:Context3DProxy):Void
	{
		_vertexBuffer = context.createVertexBuffer(4, 4);
		_program3d = context.createProgram();
		_indexBuffer = context.createIndexBuffer(6);
		_indexBuffer.uploadFromVector(VectorUtil.toUIntVector([2, 1, 0, 3, 2, 0]), 0, 6);
		_program3d.upload(new AGALMiniAssembler(Debug.active).assemble(Context3DProgramType.VERTEX, getVertexCode()),
			new AGALMiniAssembler(Debug.active).assemble(Context3DProgramType.FRAGMENT, getFragmentCode())
			);

		_vertexBuffer.uploadFromVector(Vector.ofArray([-1., -1, 0, 1,
			1, -1, 1, 1,
			1, 1, 1, 0,
			-1, 1, 0, 0
			]), 0, 4);
	}

	private function get_stage3DProxy():Stage3DProxy
	{
		return _stage3DProxy;
	}

	private function set_stage3DProxy(value:Stage3DProxy):Stage3DProxy
	{
		if (value == _stage3DProxy)
			return _stage3DProxy;
		_stage3DProxy = value;

		removeBuffers();
		
		return _stage3DProxy;
	}
	
	private function get_texture():Texture2DBase
	{
		return _texture;
	}

	private function set_texture(value:Texture2DBase):Texture2DBase
	{
		return _texture = value;
	}
}
