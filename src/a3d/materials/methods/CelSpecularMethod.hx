package a3d.materials.methods;


import a3d.core.managers.Stage3DProxy;
import a3d.materials.compilation.ShaderRegisterCache;
import a3d.materials.compilation.ShaderRegisterData;
import a3d.materials.compilation.ShaderRegisterElement;
import flash.Vector;



/**
 * CelSpecularMethod provides a shading method to add specular cel (cartoon) shading.
 */
class CelSpecularMethod extends CompositeSpecularMethod
{
	/**
	 * The smoothness of the highlight edge.
	 */
	public var smoothness(get,set):Float;
	/**
	 * The threshold at which the specular highlight should be shown.
	 */
	public var specularCutOff(get, set):Float;
	
	private var _dataReg:ShaderRegisterElement;
	private var _smoothness:Float = .1;
	private var _specularCutOff:Float = .1;

	/**
	 * Creates a new CelSpecularMethod object.
	 * @param specularCutOff The threshold at which the specular highlight should be shown.
	 * @param baseSpecularMethod An optional specular method on which the cartoon shading is based. If ommitted, BasicSpecularMethod is used.
	 */
	public function new(specularCutOff:Float = .5, baseSpecularMethod:BasicSpecularMethod = null)
	{
		super(clampSpecular, baseSpecularMethod);
		_specularCutOff = specularCutOff;
	}

	
	private function get_smoothness():Float
	{
		return _smoothness;
	}

	private function set_smoothness(value:Float):Float
	{
		return _smoothness = value;
	}

	
	private function get_specularCutOff():Float
	{
		return _specularCutOff;
	}

	private function set_specularCutOff(value:Float):Float
	{
		return _specularCutOff = value;
	}

	/**
	 * @inheritDoc
	 */
	override public function activate(vo:MethodVO, stage3DProxy:Stage3DProxy):Void
	{
		super.activate(vo, stage3DProxy);
		var index:Int = vo.secondaryFragmentConstantsIndex;
		var data:Vector<Float> = vo.fragmentData;
		data[index] = _smoothness;
		data[index + 1] = _specularCutOff;
	}

	/**
	 * @inheritDoc
	 */
	override public function cleanCompilationData():Void
	{
		super.cleanCompilationData();
		_dataReg = null;
	}

	/**
	 * Snaps the specular shading strength of the wrapped method to zero or one, depending on whether or not it exceeds the specularCutOff
	 * @param vo The MethodVO used to compile the current shader.
	 * @param t The register containing the specular strength in the "w" component, and either the half-vector or the reflection vector in "xyz".
	 * @param regCache The register cache used for the shader compilation.
	 * @param sharedRegisters The shared register data for this shader.
	 * @return The AGAL fragment code for the method.
	 */
	private function clampSpecular(methodVO:MethodVO, target:ShaderRegisterElement, regCache:ShaderRegisterCache, sharedRegisters:ShaderRegisterData):String
	{
		return "sub " + target + ".y, " + target + ".w, " + _dataReg + ".y\n" + // x - cutoff
				"div " + target + ".y, " + target + ".y, " + _dataReg + ".x\n" + // (x - cutoff)/epsilon
				"sat " + target + ".y, " + target + ".y\n" +
				"sge " + target + ".w, " + target + ".w, " + _dataReg + ".y\n" +
				"mul " + target + ".w, " + target + ".w, " + target + ".y\n";
	}

	/**
	 * @inheritDoc
	 */
	override public function getFragmentPreLightingCode(vo:MethodVO, regCache:ShaderRegisterCache):String
	{
		_dataReg = regCache.getFreeFragmentConstant();
		vo.secondaryFragmentConstantsIndex = _dataReg.index * 4;
		return super.getFragmentPreLightingCode(vo, regCache);
	}
}
