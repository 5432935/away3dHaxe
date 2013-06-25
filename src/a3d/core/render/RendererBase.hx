package a3d.core.render;

import flash.display.BitmapData;
import flash.display3D.Context3D;
import flash.display3D.Context3DCompareMode;
import flash.display3D.textures.TextureBase;
import flash.events.Event;
import flash.geom.Matrix3D;
import flash.geom.Rectangle;


import a3d.core.managers.Stage3DProxy;
import a3d.core.sort.IEntitySorter;
import a3d.core.sort.RenderableMergeSort;
import a3d.core.traverse.EntityCollector;
import a3d.errors.AbstractMethodError;
import a3d.events.Stage3DEvent;
import a3d.textures.Texture2DBase;



/**
 * RendererBase forms an abstract base class for classes that are used in the rendering pipeline to render geometry
 * to the back buffer or a texture.
 */
class RendererBase
{
	private var _context:Context3D;
	private var _stage3DProxy:Stage3DProxy;

	private var _backgroundR:Float = 0;
	private var _backgroundG:Float = 0;
	private var _backgroundB:Float = 0;
	private var _backgroundAlpha:Float = 1;
	private var _shareContext:Bool = false;

	private var _renderTarget:TextureBase;
	private var _renderTargetSurface:Int;

	// only used by renderers that need to render geometry to textures
	private var _viewWidth:Float;
	private var _viewHeight:Float;

	private var _renderableSorter:IEntitySorter;
	private var _backgroundImageRenderer:BackgroundImageRenderer;
	private var _background:Texture2DBase;

	private var _renderToTexture:Bool;
	private var _antiAlias:UInt;
	private var _textureRatioX:Float = 1;
	private var _textureRatioY:Float = 1;

	private var _snapshotBitmapData:BitmapData;
	private var _snapshotRequired:Bool;

	private var _clearOnRender:Bool = true;
	private var _rttViewProjectionMatrix:Matrix3D = new Matrix3D();

	/**
	 * Creates a new RendererBase object.
	 */
	public function new(renderToTexture:Bool = false)
	{
		_renderableSorter = new RenderableMergeSort();
		_renderToTexture = renderToTexture;
	}

	public function createEntityCollector():EntityCollector
	{
		return new EntityCollector();
	}

	private inline function get_viewWidth():Float
	{
		return _viewWidth;
	}

	private inline function set_viewWidth(value:Float):Void
	{
		_viewWidth = value;
	}

	private inline function get_viewHeight():Float
	{
		return _viewHeight;
	}

	private inline function set_viewHeight(value:Float):Void
	{
		_viewHeight = value;
	}

	private inline function get_renderToTexture():Bool
	{
		return _renderToTexture;
	}

	private inline function get_renderableSorter():IEntitySorter
	{
		return _renderableSorter;
	}

	private inline function set_renderableSorter(value:IEntitySorter):Void
	{
		_renderableSorter = value;
	}

	private inline function get_clearOnRender():Bool
	{
		return _clearOnRender;
	}

	private inline function set_clearOnRender(value:Bool):Void
	{
		_clearOnRender = value;
	}

	/**
	 * The background color's red component, used when clearing.
	 *
	 * @private
	 */
	private inline function get_backgroundR():Float
	{
		return _backgroundR;
	}

	private inline function set_backgroundR(value:Float):Void
	{
		_backgroundR = value;
	}

	/**
	 * The background color's green component, used when clearing.
	 *
	 * @private
	 */
	private inline function get_backgroundG():Float
	{
		return _backgroundG;
	}

	private inline function set_backgroundG(value:Float):Void
	{
		_backgroundG = value;
	}

	/**
	 * The background color's blue component, used when clearing.
	 *
	 * @private
	 */
	private inline function get_backgroundB():Float
	{
		return _backgroundB;
	}

	private inline function set_backgroundB(value:Float):Void
	{
		_backgroundB = value;
	}

	/**
	 * The Stage3DProxy that will provide the Context3D used for rendering.
	 *
	 * @private
	 */
	private inline function get_stage3DProxy():Stage3DProxy
	{
		return _stage3DProxy;
	}

	private inline function set_stage3DProxy(value:Stage3DProxy):Void
	{
		if (value == _stage3DProxy)
			return;

		if (!value)
		{
			if (_stage3DProxy)
			{
				_stage3DProxy.removeEventListener(Stage3DEvent.CONTEXT3D_CREATED, onContextUpdate);
				_stage3DProxy.removeEventListener(Stage3DEvent.CONTEXT3D_RECREATED, onContextUpdate);
			}
			_stage3DProxy = null;
			_context = null;
			return;
		}
		//else if (_stage3DProxy) throw new Error("A Stage3D instance was already assigned!");

		_stage3DProxy = value;
		_stage3DProxy.addEventListener(Stage3DEvent.CONTEXT3D_CREATED, onContextUpdate);
		_stage3DProxy.addEventListener(Stage3DEvent.CONTEXT3D_RECREATED, onContextUpdate);
		if (_backgroundImageRenderer)
			_backgroundImageRenderer.stage3DProxy = value;

		if (value.context3D)
			_context = value.context3D;
	}

	/**
	 * Defers control of Context3D clear() and present() calls to Stage3DProxy, enabling multiple Stage3D frameworks
	 * to share the same Context3D object.
	 *
	 * @private
	 */
	private inline function get_shareContext():Bool
	{
		return _shareContext;
	}

	private inline function set_shareContext(value:Bool):Void
	{
		_shareContext = value;
	}

	/**
	 * Disposes the resources used by the RendererBase.
	 *
	 * @private
	 */
	public function dispose():Void
	{
		stage3DProxy = null;
		if (_backgroundImageRenderer)
		{
			_backgroundImageRenderer.dispose();
			_backgroundImageRenderer = null;
		}
	}

	/**
	 * Renders the potentially visible geometry to the back buffer or texture.
	 * @param entityCollector The EntityCollector object containing the potentially visible geometry.
	 * @param target An option target texture to render to.
	 * @param surfaceSelector The index of a CubeTexture's face to render to.
	 * @param additionalClearMask Additional clear mask information, in case extra clear channels are to be omitted.
	 */
	public function render(entityCollector:EntityCollector, target:TextureBase = null, scissorRect:Rectangle = null, surfaceSelector:Int = 0):Void
	{
		if (_stage3DProxy == null || !_context)
			return;

		_rttViewProjectionMatrix.copyFrom(entityCollector.camera.viewProjection);
		_rttViewProjectionMatrix.appendScale(_textureRatioX, _textureRatioY, 1);

		executeRender(entityCollector, target, scissorRect, surfaceSelector);

		// clear buffers
		for (var i:UInt = 0; i < 8; ++i)
		{
			_context.setVertexBufferAt(i, null);
			_context.setTextureAt(i, null);
		}
	}

	/**
	 * Renders the potentially visible geometry to the back buffer or texture. Only executed if everything is set up.
	 * @param entityCollector The EntityCollector object containing the potentially visible geometry.
	 * @param target An option target texture to render to.
	 * @param surfaceSelector The index of a CubeTexture's face to render to.
	 * @param additionalClearMask Additional clear mask information, in case extra clear channels are to be omitted.
	 */
	private function executeRender(entityCollector:EntityCollector, target:TextureBase = null, scissorRect:Rectangle = null, surfaceSelector:Int = 0):Void
	{
		_renderTarget = target;
		_renderTargetSurface = surfaceSelector;

		if (_renderableSorter)
			_renderableSorter.sort(entityCollector);

		if (_renderToTexture)
			executeRenderToTexturePass(entityCollector);

		_stage3DProxy.setRenderTarget(target, true, surfaceSelector);

		if ((target || !_shareContext) && _clearOnRender)
		{
			_context.clear(_backgroundR, _backgroundG, _backgroundB, _backgroundAlpha, 1, 0);
		}
		_context.setDepthTest(false, Context3DCompareMode.ALWAYS);
		_stage3DProxy.scissorRect = scissorRect;
		if (_backgroundImageRenderer)
			_backgroundImageRenderer.render();

		draw(entityCollector, target);

		//line required for correct rendering when using away3d with starling. DO NOT REMOVE UNLESS STARLING INTEGRATION IS RETESTED!
		_context.setDepthTest(false, Context3DCompareMode.LESS_EQUAL);

		if (!_shareContext)
		{
			if (_snapshotRequired && _snapshotBitmapData)
			{
				_context.drawToBitmapData(_snapshotBitmapData);
				_snapshotRequired = false;
			}
		}
		_stage3DProxy.scissorRect = null;
	}

	/*
	* Will draw the renderer's output on next render to the provided bitmap data.
	* */
	public function queueSnapshot(bmd:BitmapData):Void
	{
		_snapshotRequired = true;
		_snapshotBitmapData = bmd;
	}

	private function executeRenderToTexturePass(entityCollector:EntityCollector):Void
	{
		throw new AbstractMethodError();
	}

	/**
	 * Performs the actual drawing of geometry to the target.
	 * @param entityCollector The EntityCollector object containing the potentially visible geometry.
	 */
	private function draw(entityCollector:EntityCollector, target:TextureBase):Void
	{
		throw new AbstractMethodError();
	}

	/**
	 * Assign the context once retrieved
	 */
	private function onContextUpdate(event:Event):Void
	{
		_context = _stage3DProxy.context3D;
	}

	private inline function get_backgroundAlpha():Float
	{
		return _backgroundAlpha;
	}

	private inline function set_backgroundAlpha(value:Float):Void
	{
		_backgroundAlpha = value;
	}

	private inline function get_background():Texture2DBase
	{
		return _background;
	}

	private inline function set_background(value:Texture2DBase):Void
	{
		if (_backgroundImageRenderer && !value)
		{
			_backgroundImageRenderer.dispose();
			_backgroundImageRenderer = null;
		}

		if (!_backgroundImageRenderer && value)
			_backgroundImageRenderer = new BackgroundImageRenderer(_stage3DProxy);

		_background = value;

		if (_backgroundImageRenderer)
			_backgroundImageRenderer.texture = value;
	}

	private inline function get_backgroundImageRenderer():BackgroundImageRenderer
	{
		return _backgroundImageRenderer;
	}

	private inline function get_antiAlias():UInt
	{
		return _antiAlias;
	}

	private inline function set_antiAlias(antiAlias:UInt):Void
	{
		_antiAlias = antiAlias;
	}

	private inline function get_textureRatioX():Float
	{
		return _textureRatioX;
	}

	private inline function set_textureRatioX(value:Float):Void
	{
		_textureRatioX = value;
	}

	private inline function get_textureRatioY():Float
	{
		return _textureRatioY;
	}

	private inline function set_textureRatioY(value:Float):Void
	{
		_textureRatioY = value;
	}
}
