package a3d.entities.lenses;

import a3d.math.Plane3D;
import a3d.events.LensEvent;
import flash.Vector;

import flash.geom.Matrix3D;

import flash.geom.Vector3D;



class ObliqueNearPlaneLens extends LensBase
{
	private var _baseLens:LensBase;
	private var _plane:Plane3D;

	public function new(baseLens:LensBase, plane:Plane3D)
	{
		super();
		this.baseLens = baseLens;
		this.plane = plane;
	}

	override private function get_frustumCorners():Vector<Float>
	{
		return _baseLens.frustumCorners;
	}

	override private function get_near():Float
	{
		return _baseLens.near;
	}

	override private function set_near(value:Float):Float
	{
		return _baseLens.near = value;
	}

	override private function get_far():Float
	{
		return _baseLens.far;
	}

	override private function set_far(value:Float):Float
	{
		return _baseLens.far = value;
	}

	override private function get_aspectRatio():Float
	{
		return _baseLens.aspectRatio;
	}

	override private function set_aspectRatio(value:Float):Float
	{
		return _baseLens.aspectRatio = value;
	}

	public var plane(get, set):Plane3D;
	private inline function get_plane():Plane3D
	{
		return _plane;
	}

	private inline function set_plane(value:Plane3D):Plane3D
	{
		_plane = value;
		invalidateMatrix();
		return _plane;
	}

	public var baseLens(null, set):LensBase;
	private inline function set_baseLens(value:LensBase):LensBase
	{
		if (_baseLens)
			_baseLens.removeEventListener(LensEvent.MATRIX_CHANGED, onLensMatrixChanged);

		_baseLens = value;

		if (_baseLens)
			_baseLens.addEventListener(LensEvent.MATRIX_CHANGED, onLensMatrixChanged);

		invalidateMatrix();
		
		return _baseLens;
	}

	private function onLensMatrixChanged(event:LensEvent):Void
	{
		invalidateMatrix();
	}

	override private function updateMatrix():Void
	{
		_matrix.copyFrom(_baseLens.matrix);

		var cx:Float = _plane.a;
		var cy:Float = _plane.b;
		var cz:Float = _plane.c;
		var cw:Float = -_plane.d + .05;
		var signX:Float = cx >= 0 ? 1 : -1;
		var signY:Float = cy >= 0 ? 1 : -1;
		var p:Vector3D = new Vector3D(signX, signY, 1, 1);
		var inverse:Matrix3D = _matrix.clone();
		inverse.invert();
		var q:Vector3D = inverse.transformVector(p);
		_matrix.copyRowTo(3, p);
		var a:Float = (q.x * p.x + q.y * p.y + q.z * p.z + q.w * p.w) / (cx * q.x + cy * q.y + cz * q.z + cw * q.w);
		_matrix.copyRowFrom(2, new Vector3D(cx * a, cy * a, cz * a, cw * a));
	}
}
