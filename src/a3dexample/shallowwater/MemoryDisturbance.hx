package a3dexample.shallowwater;


import flash.geom.Vector3D;
import flash.Lib;
import flash.Vector.Vector;

class MemoryDisturbance
{
	private var _disturbances:Vector<Vector3D>;
	private var _targetTime:Int;
	private var _elapsedTime:Int;
	private var _startTime:Int;
	private var _concluded:Bool;
	private var _growthRate:Float;
	private var _growth:Float;

	/*
	 time is the time that the disturbance will last.
	 if -1, disturbance lasts until manually concluded.
	 */
	public function new(time:Int, speed:Float)
	{
		_targetTime = time;
		_startTime = Lib.getTimer();
		_disturbances = new Vector<Vector3D>();
		_growth = 0;
		_growthRate = speed;
	}

	public var growth(get, null):Float;
	public function get_growth():Float
	{
		return _growth;
	}

	public var disturbances(get, null):Vector<Vector3D>;
	public function get_disturbances():Vector<Vector3D>
	{
		return _disturbances;
	}

	public function addDisturbance(x:Int, y:Int, displacement:Float):Void
	{
		_disturbances.push(new Vector3D(x, y, displacement));
	}

	public function update():Void
	{
		if (_concluded)
			return;

		_growth += _growthRate;
		_growth = _growth > 1 ? 1 : _growth;

		if (_targetTime < 0)
			return;

		_elapsedTime = Lib.getTimer() - _startTime;

		if (_elapsedTime >= _targetTime)
			_concluded = true;
	}

	public var concluded(get, set):Bool;
	public function get_concluded():Bool
	{
		return _concluded;
	}

	public function set_concluded(value:Bool):Bool
	{
		return _concluded = value;
	}
}
