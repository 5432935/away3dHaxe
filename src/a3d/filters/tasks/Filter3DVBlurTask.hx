package a3d.filters.tasks;

import a3d.core.managers.Stage3DProxy;
import a3d.entities.Camera3D;
import flash.display3D.Context3DProgramType;
import flash.display3D.textures.Texture;
import flash.Vector;


class Filter3DVBlurTask extends Filter3DTaskBase
{
	private static var MAX_AUTO_SAMPLES:Int = 15;
	
	public var amount(get, set):Int;
	public var stepSize(get, set):Int;
	
	private var _amount:Int;
	private var _data:Vector<Float>;
	private var _stepSize:Int = 1;
	private var _realStepSize:Float;

	/**
	 *
	 * @param amount
	 * @param stepSize The distance between samples. Set to -1 to autodetect with acceptable quality.
	 */
	public function new(amount:Int, stepSize:Int = -1)
	{
		super();
		_amount = amount;
		_data = Vector.ofArray([0., 0, 0, 1]);
		this.stepSize = stepSize;
	}

	
	private function get_amount():Int
	{
		return _amount;
	}

	private function set_amount(value:Int):Int
	{
		if (value == _amount)
			return _amount;
		_amount = value;

		invalidateProgram3D();
		updateBlurData();
		
		return _amount;
	}

	
	private function get_stepSize():Int
	{
		return _stepSize;
	}

	private function set_stepSize(value:Int):Int
	{
		if (value == _stepSize)
			return _stepSize;
		_stepSize = value;
		calculateStepSize();
		invalidateProgram3D();
		updateBlurData();
		return _stepSize;
	}

	override private function getFragmentCode():String
	{
		var code:String;
		var numSamples:Int = 1;

		code = "mov ft0, v0	\n" +
			"sub ft0.y, v0.y, fc0.x\n";

		code += "tex ft1, ft0, fs0 <2d,linear,clamp>\n";

		var x:Float = _realStepSize; 
		while (x <= _amount)
		{
			code += "add ft0.y, ft0.y, fc0.y	\n";
			code += "tex ft2, ft0, fs0 <2d,linear,clamp>\n" +
				"add ft1, ft1, ft2 \n";
			++numSamples;
			x += _realStepSize;
		}

		code += "mul oc, ft1, fc0.z";

		_data[2] = 1 / numSamples;

		return code;
	}

	override public function activate(stage3DProxy:Stage3DProxy, camera3D:Camera3D, depthTexture:Texture):Void
	{
		stage3DProxy.context3D.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, _data, 1);
	}

	override private function updateTextures(stage:Stage3DProxy):Void
	{
		super.updateTextures(stage);

		updateBlurData();
	}

	private function updateBlurData():Void
	{
		// todo: must be normalized using view size ratio instead of texture
		var invH:Float = 1 / _textureHeight;

		_data[0] = _amount * .5 * invH;
		_data[1] = _realStepSize * invH;
	}

	private function calculateStepSize():Void
	{
		_realStepSize = _stepSize > 0 ? _stepSize :
			(_amount > MAX_AUTO_SAMPLES ? _amount / MAX_AUTO_SAMPLES : 1);
	}
}
