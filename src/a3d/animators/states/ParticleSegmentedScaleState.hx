package a3d.animators.states;

import a3d.arcane;
import a3d.animators.data.AnimationRegisterCache;
import a3d.animators.data.AnimationSubGeometry;
import a3d.animators.nodes.ParticleSegmentedScaleNode;
import a3d.animators.ParticleAnimator;
import a3d.cameras.Camera3D;
import a3d.core.base.IRenderable;
import a3d.core.managers.Stage3DProxy;
import flash.geom.Vector3D;
import flash.Vector.Vector;


class ParticleSegmentedScaleState extends ParticleStateBase
{
	private var _startScale:Vector3D;
	private var _endScale:Vector3D;
	private var _segmentPoints:Vector<Vector3D>;
	private var _numSegmentPoint:Int;
	
	
	private var _scaleData:Vector<Float>;
	
	/**
	 * Defines the start scale of the state, when in global mode.
	 */
	public var startScale(get, set):Vector3D;
	private function get_startScale():Vector3D
	{
		return _startScale;
	}
	
	private function set_startScale(value:Vector3D):Vector3D
	{
		_startScale = value;
		
		updateScaleData();
		
		return _startScale;
	}
	
	/**
	 * Defines the end scale of the state, when in global mode.
	 */
	public var endScale(get, set):Vector3D;
	private function get_endScale():Vector3D
	{
		return _endScale;
	}
	private function set_endScale(value:Vector3D):Vector3D
	{
		_endScale = value;
		updateScaleData();
		
		return _endScale;
	}
	
	/**
	 * Defines the number of segments.
	 */
	public var numSegmentPoint(get, null):Int;
	private function get_numSegmentPoint():Int
	{
		return _numSegmentPoint;
	}
	
	/**
	 * Defines the key points of Scale
	 */
	public var segmentPoints(get, set):Vector<Vector3D>;
	private function get_segmentPoints():Vector<Vector3D>
	{
		return _segmentPoints;
	}
	
	private function set_segmentPoints(value:Vector<Vector3D>):Vector<Vector3D>
	{
		_segmentPoints = value;
		updateScaleData();
		return _segmentPoints;
	}
	
	
	public function new(animator:ParticleAnimator, particleSegmentedScaleNode:ParticleSegmentedScaleNode)
	{
		super(animator, particleSegmentedScaleNode);
		
		_startScale = particleSegmentedScaleNode._startScale;
		_endScale = particleSegmentedScaleNode._endScale;
		_segmentPoints = particleSegmentedScaleNode._segmentScales;
		_numSegmentPoint = particleSegmentedScaleNode._numSegmentPoint;
		updateScaleData();
	}
	
	override public function setRenderState(stage3DProxy:Stage3DProxy, renderable:IRenderable, animationSubGeometry:AnimationSubGeometry, animationRegisterCache:AnimationRegisterCache, camera:Camera3D) : Void
	{
		animationRegisterCache.setVertexConstFromVector(animationRegisterCache.getRegisterIndex(_animationNode, ParticleSegmentedScaleNode.START_INDEX), _scaleData);
	}
	
	private function updateScaleData():Void
	{
		var _timeLifeData:Vector<Float> = new Vector<Float>;
		_scaleData = new Vector<Float>;
		var i:Int;
		for (i in 0..._numSegmentPoint)
		{
			if (i == 0)
				_timeLifeData.push(_segmentPoints[i].w);
			else
				_timeLifeData.push(_segmentPoints[i].w - _segmentPoints[i - 1].w);
		}
		if (_numSegmentPoint == 0)
			_timeLifeData.push(1);
		else
			_timeLifeData.push(1 - _segmentPoints[i - 1].w);
			
		_scaleData.push(_startScale.x , _startScale.y , _startScale.z , 0);
		for (i in 0..._numSegmentPoint)
		{
			if (i == 0)
				_scaleData.push((_segmentPoints[i].x - _startScale.x)/_timeLifeData[i] , (_segmentPoints[i].y - _startScale.y)/_timeLifeData[i] , (_segmentPoints[i].z - _startScale.z)/_timeLifeData[i] , _timeLifeData[i]);
			else
				_scaleData.push((_segmentPoints[i].x - _segmentPoints[i - 1].x)/_timeLifeData[i] , (_segmentPoints[i].y - _segmentPoints[i - 1].y)/_timeLifeData[i] , (_segmentPoints[i].z - _segmentPoints[i - 1].z)/_timeLifeData[i] , _timeLifeData[i]);
		}
		if (_numSegmentPoint == 0)
			_scaleData.push(_endScale.x - _startScale.x , _endScale.y - _startScale.y , _endScale.z - _startScale.z , 1);
		else
			_scaleData.push((_endScale.x - _segmentPoints[i - 1].x) / _timeLifeData[i] , (_endScale.y - _segmentPoints[i - 1].y) / _timeLifeData[i] , (_endScale.z - _segmentPoints[i - 1].z) / _timeLifeData[i] , _timeLifeData[i]);
			
	}
}