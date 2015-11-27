package away3d.animators.states;

import away3d.animators.data.AnimationRegisterCache;
import away3d.animators.data.AnimationSubGeometry;
import away3d.animators.data.ParticlePropertiesMode;
import away3d.animators.nodes.ParticleBezierCurveNode;
import away3d.animators.ParticleAnimator;
import away3d.core.base.IRenderable;
import away3d.core.managers.Stage3DProxy;
import away3d.entities.Camera3D;
import flash.display3D.Context3DVertexBufferFormat;
import flash.geom.Vector3D;





/**
 * ...
 */
class ParticleBezierCurveState extends ParticleStateBase
{
	/**
	 * Defines the default control point of the node, used when in global mode.
	 */
	public var controlPoint(get, set):Vector3D;
	
	/**
	 * Defines the default end point of the node, used when in global mode.
	 */
	public var endPoint(get,set):Vector3D;
	
	private var _particleBezierCurveNode:ParticleBezierCurveNode;
	private var _controlPoint:Vector3D;
	private var _endPoint:Vector3D;

	public function new(animator:ParticleAnimator, particleBezierCurveNode:ParticleBezierCurveNode)
	{
		super(animator, particleBezierCurveNode);

		_particleBezierCurveNode = particleBezierCurveNode;
		_controlPoint = _particleBezierCurveNode.controlPoint;
		_endPoint = _particleBezierCurveNode.endPoint;
	}


	override public function setRenderState(stage3DProxy:Stage3DProxy, renderable:IRenderable, animationSubGeometry:AnimationSubGeometry, animationRegisterCache:AnimationRegisterCache, camera:Camera3D):Void
	{
		var controlIndex:Int = animationRegisterCache.getRegisterIndex(_animationNode, ParticleBezierCurveNode.BEZIER_CONTROL_INDEX);
		var endIndex:Int = animationRegisterCache.getRegisterIndex(_animationNode, ParticleBezierCurveNode.BEZIER_END_INDEX);

		if (_particleBezierCurveNode.mode == ParticlePropertiesMode.LOCAL_STATIC)
		{
			animationSubGeometry.activateVertexBuffer(controlIndex, _particleBezierCurveNode.dataOffset, stage3DProxy, Context3DVertexBufferFormat.FLOAT_3);
			animationSubGeometry.activateVertexBuffer(endIndex, _particleBezierCurveNode.dataOffset + 3, stage3DProxy, Context3DVertexBufferFormat.FLOAT_3);
		}
		else
		{
			animationRegisterCache.setVertexConst(controlIndex, _controlPoint.x, _controlPoint.y, _controlPoint.z);
			animationRegisterCache.setVertexConst(endIndex, _endPoint.x, _endPoint.y, _endPoint.z);
		}
	}
	
	private function get_controlPoint():Vector3D
	{
		return _controlPoint;
	}

	private function set_controlPoint(value:Vector3D):Vector3D
	{
		return _controlPoint = value;
	}

	
	private function get_endPoint():Vector3D
	{
		return _endPoint;
	}

	private function set_endPoint(value:Vector3D):Vector3D
	{
		return _endPoint = value;
	}
}
