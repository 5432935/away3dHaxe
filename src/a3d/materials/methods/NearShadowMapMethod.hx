package a3d.materials.methods;


import a3d.entities.Camera3D;
import a3d.core.base.IRenderable;
import a3d.core.managers.Stage3DProxy;
import a3d.events.ShadingMethodEvent;
import a3d.entities.lights.shadowmaps.NearDirectionalShadowMapper;
import a3d.materials.compilation.ShaderRegisterCache;
import a3d.materials.compilation.ShaderRegisterData;
import a3d.materials.compilation.ShaderRegisterElement;
import flash.errors.Error;
import flash.Vector;




// TODO: shadow mappers references in materials should be an interface so that this class should NOT extend ShadowMapMethodBase just for some delegation work
/**
 * NearShadowMapMethod provides a shadow map method that restricts the shadowed area near the camera to optimize
 * shadow map usage. This method needs to be used in conjunction with a NearDirectionalShadowMapper.
 *
 * @see a3d.lights.shadowmaps.NearDirectionalShadowMapper
 */
class NearShadowMapMethod extends SimpleShadowMapMethodBase
{
	private var _baseMethod:SimpleShadowMapMethodBase;

	private var _fadeRatio:Float;
	private var _nearShadowMapper:NearDirectionalShadowMapper;

	/**
	 * The base shadow map method on which this method's shading is based.
	 */
	public var baseMethod(get,set):SimpleShadowMapMethodBase;
	

	/**
	 * Creates a new NearShadowMapMethod object.
	 * @param baseMethod The shadow map sampling method used to sample individual cascades (fe: HardShadowMapMethod, SoftShadowMapMethod)
	 * @param fadeRatio The amount of shadow fading to the outer shadow area. A value of 1 would mean the shadows start fading from the camera's near plane.
	 */
	public function new(baseMethod:SimpleShadowMapMethodBase, fadeRatio:Float = .1)
	{
		super(baseMethod.castingLight);
		_baseMethod = baseMethod;
		_fadeRatio = fadeRatio;
		_nearShadowMapper = Std.instance(_castingLight.shadowMapper,NearDirectionalShadowMapper);
		if (_nearShadowMapper == null)
			throw new Error("NearShadowMapMethod requires a light that has a NearDirectionalShadowMapper instance assigned to shadowMapper.");
		_baseMethod.addEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated);
	}
	
	private function get_baseMethod():SimpleShadowMapMethodBase
	{
		return _baseMethod;
	}

	private function set_baseMethod(value:SimpleShadowMapMethodBase):SimpleShadowMapMethodBase
	{
		if (_baseMethod == value)
			return _baseMethod;
		_baseMethod.removeEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated);
		_baseMethod = value;
		_baseMethod.addEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated, false, 0, true);
		invalidateShaderProgram();
		return _baseMethod;
	}

	override public function initConstants(vo:MethodVO):Void
	{
		super.initConstants(vo);
		_baseMethod.initConstants(vo);

		var fragmentData:Vector<Float> = vo.fragmentData;
		var index:Int = vo.secondaryFragmentConstantsIndex;
		fragmentData[index + 2] = 0;
		fragmentData[index + 3] = 1;
	}

	override public function initVO(vo:MethodVO):Void
	{
		_baseMethod.initVO(vo);
		vo.needsProjection = true;
	}

	override public function dispose():Void
	{
		_baseMethod.removeEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated);
	}

	override private function get_alpha():Float
	{
		return _baseMethod.alpha;
	}

	override private function set_alpha(value:Float):Float
	{
		return _baseMethod.alpha = value;
	}

	override private function get_epsilon():Float
	{
		return _baseMethod.epsilon;
	}

	override private function set_epsilon(value:Float):Float
	{
		return _baseMethod.epsilon = value;
	}

	/**
	 * The amount of shadow fading to the outer shadow area. A value of 1 would mean the shadows start fading from the camera's near plane.
	 */
	public var fadeRatio(get,set):Float;
	private function get_fadeRatio():Float
	{
		return _fadeRatio;
	}

	private function set_fadeRatio(value:Float):Float
	{
		return _fadeRatio = value;
	}

	override public function getFragmentCode(vo:MethodVO, regCache:ShaderRegisterCache, targetReg:ShaderRegisterElement):String
	{
		var code:String = _baseMethod.getFragmentCode(vo, regCache, targetReg);
		var dataReg:ShaderRegisterElement = regCache.getFreeFragmentConstant();
		var temp:ShaderRegisterElement = regCache.getFreeFragmentSingleTemp();
		vo.secondaryFragmentConstantsIndex = dataReg.index * 4;

		code += "abs " + temp + ", " + _sharedRegisters.projectionFragment + ".w\n" +
			"sub " + temp + ", " + temp + ", " + dataReg + ".x\n" +
			"mul " + temp + ", " + temp + ", " + dataReg + ".y\n" +
			"sat " + temp + ", " + temp + "\n" +
			"sub " + temp + ", " + dataReg + ".w," + temp + "\n" +
			"sub " + targetReg + ".w, " + dataReg + ".w," + targetReg + ".w\n" +
			"mul " + targetReg + ".w, " + targetReg + ".w, " + temp + "\n" +
			"sub " + targetReg + ".w, " + dataReg + ".w," + targetReg + ".w\n";

		return code;
	}

	/**
	 * @inheritDoc
	 */
	override public function activate(vo:MethodVO, stage3DProxy:Stage3DProxy):Void
	{
		_baseMethod.activate(vo, stage3DProxy);
	}

	override public function deactivate(vo:MethodVO, stage3DProxy:Stage3DProxy):Void
	{
		_baseMethod.deactivate(vo, stage3DProxy);
	}

	override public function setRenderState(vo:MethodVO, renderable:IRenderable, stage3DProxy:Stage3DProxy, camera:Camera3D):Void
	{
		// todo: move this to activate (needs camera)
		var near:Float = camera.lens.near;
		var d:Float = camera.lens.far - near;
		var maxDistance:Float = _nearShadowMapper.coverageRatio;
		var minDistance:Float = maxDistance * (1 - _fadeRatio);

		maxDistance = near + maxDistance * d;
		minDistance = near + minDistance * d;

		var fragmentData:Vector<Float> = vo.fragmentData;
		var index:Int = vo.secondaryFragmentConstantsIndex;
		fragmentData[index] = minDistance;
		fragmentData[index + 1] = 1 / (maxDistance - minDistance);
		_baseMethod.setRenderState(vo, renderable, stage3DProxy, camera);
	}

	/**
	 * @inheritDoc
	 */
	override public function getVertexCode(vo:MethodVO, regCache:ShaderRegisterCache):String
	{
		return _baseMethod.getVertexCode(vo, regCache);
	}


	/**
	 * @inheritDoc
	 */
	override public function reset():Void
	{
		_baseMethod.reset();
	}


	override public function cleanCompilationData():Void
	{
		super.cleanCompilationData();
		_baseMethod.cleanCompilationData();
	}

	/**
	 * @inheritDoc
	 */
	override private function set_sharedRegisters(value:ShaderRegisterData):ShaderRegisterData
	{
		return super.sharedRegisters = _baseMethod.sharedRegisters = value;
	}

	/**
	 * Called when the base method's shader code is invalidated.
	 */
	private function onShaderInvalidated(event:ShadingMethodEvent):Void
	{
		invalidateShaderProgram();
	}
}