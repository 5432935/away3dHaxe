package a3d.materials.methods;

import flash.display3D.Context3DTextureFormat;
import flash.Vector;


import a3d.entities.Camera3D;
import a3d.core.base.IRenderable;
import a3d.core.managers.Stage3DProxy;
import a3d.events.ShadingMethodEvent;
import a3d.io.library.assets.NamedAssetBase;
import a3d.materials.compilation.ShaderRegisterCache;
import a3d.materials.compilation.ShaderRegisterData;
import a3d.materials.compilation.ShaderRegisterElement;
import a3d.materials.passes.MaterialPassBase;
import a3d.textures.TextureProxyBase;



/**
 * ShadingMethodBase provides an abstract base method for shading methods, used by DefaultScreenPass to compile
 * the final shading program.
 */
class ShadingMethodBase extends NamedAssetBase
{
	private var _sharedRegisters:ShaderRegisterData;
	private var _passes:Vector<MaterialPassBase>;

	/**
	 * Create a new ShadingMethodBase object.
	 * @param needsNormals Defines whether or not the method requires normals.
	 * @param needsView Defines whether or not the method requires the view direction.
	 */
	public function new() // needsNormals : Bool, needsView : Bool, needsGlobalPos : Bool
	{
		super();
	}

	public function initVO(vo:MethodVO):Void
	{

	}

	public function initConstants(vo:MethodVO):Void
	{

	}

	public var sharedRegisters(get,set):ShaderRegisterData;
	private function get_sharedRegisters():ShaderRegisterData
	{
		return _sharedRegisters;
	}

	private function set_sharedRegisters(value:ShaderRegisterData):ShaderRegisterData
	{
		return _sharedRegisters = value;
	}

	/**
	 * Any passes required that render to a texture used by this method.
	 */
	public var passes(get,null):Vector<MaterialPassBase>;
	private function get_passes():Vector<MaterialPassBase>
	{
		return _passes;
	}

	/**
	 * Cleans up any resources used by the current object.
	 * @param deep Indicates whether other resources should be cleaned up, that could potentially be shared across different instances.
	 */
	public function dispose():Void
	{

	}

	/**
	 * Creates a data container that contains material-dependent data. Provided as a factory method so a custom subtype can be overridden when needed.
	 */
	public function createMethodVO():MethodVO
	{
		return new MethodVO();
	}

	public function reset():Void
	{
		cleanCompilationData();
	}

	/**
	 * Resets the method's state for compilation.
	 * @private
	 */
	public function cleanCompilationData():Void
	{
	}

	/**
	 * Get the vertex shader code for this method.
	 * @param regCache The register cache used during the compilation.
	 * @private
	 */
	public function getVertexCode(vo:MethodVO, regCache:ShaderRegisterCache):String
	{
		return "";
	}

	/**
	 * Sets the render state for this method.
	 * @param context The Context3D currently used for rendering.
	 * @private
	 */
	public function activate(vo:MethodVO, stage3DProxy:Stage3DProxy):Void
	{

	}

	/**
	 * Sets the render state for a single renderable.
	 */
	public function setRenderState(vo:MethodVO, renderable:IRenderable, stage3DProxy:Stage3DProxy, camera:Camera3D):Void
	{

	}

	/**
	 * Clears the render state for this method.
	 * @param context The Context3D currently used for rendering.
	 * @private
	 */
	public function deactivate(vo:MethodVO, stage3DProxy:Stage3DProxy):Void
	{

	}

	/**
	 * A helper method that generates standard code for sampling from a texture using the normal uv coordinates.
	 * @param targetReg The register in which to store the sampled colour.
	 * @param inputReg The texture stream register.
	 * @return The fragment code that performs the sampling.
	 */
	private function getTex2DSampleCode(vo:MethodVO, targetReg:ShaderRegisterElement, inputReg:ShaderRegisterElement, texture:TextureProxyBase, uvReg:ShaderRegisterElement = null, forceWrap:String =
		null):String
	{
		if (forceWrap == null)
		{
			forceWrap = (vo.repeatTextures ? "wrap" : "clamp");
		}
		var wrap:String = forceWrap;
		
		var filter:String;
		var format:String = getFormatStringForTexture(texture);
		var enableMipMaps:Bool = vo.useMipmapping && texture.hasMipMaps;

		if (vo.useSmoothTextures)
		{
			filter = enableMipMaps ? "linear,miplinear" : "linear";
		}
		else
		{
			filter = enableMipMaps ? "nearest,mipnearest" : "nearest";
		}

		if (uvReg == null)
			uvReg = _sharedRegisters.uvVarying;
		return "tex " + targetReg + ", " + uvReg + ", " + inputReg + " <2d," + filter + "," + format + wrap + ">\n";
	}

	private function getTexCubeSampleCode(vo:MethodVO, targetReg:ShaderRegisterElement, inputReg:ShaderRegisterElement, texture:TextureProxyBase, uvReg:ShaderRegisterElement):String
	{
		var filter:String;
		var format:String = getFormatStringForTexture(texture);
		var enableMipMaps:Bool = vo.useMipmapping && texture.hasMipMaps;

		if (vo.useSmoothTextures)
		{
			filter = enableMipMaps ? "linear,miplinear" : "linear";
		}
		else
		{
			filter = enableMipMaps ? "nearest,mipnearest" : "nearest";
		}

		return "tex " + targetReg + ", " + uvReg + ", " + inputReg + " <cube," + format + filter + ">\n";
	}

	private function getFormatStringForTexture(texture:TextureProxyBase):String
	{
		switch (texture.format)
		{
			case Context3DTextureFormat.COMPRESSED:
				return "dxt1,";
			case Context3DTextureFormat.COMPRESSED_ALPHA:
				return "dxt5,";
			default:
				return "";
		}
	}

	/**
	 * Marks the shader program as invalid, so it will be recompiled before the next render.
	 */
	private function invalidateShaderProgram():Void
	{
		dispatchEvent(new ShadingMethodEvent(ShadingMethodEvent.SHADER_INVALIDATED));
	}

	/**
	 * Copies the state from a ShadingMethodBase object into the current object.
	 */
	public function copyFrom(method:ShadingMethodBase):Void
	{
	}
}
