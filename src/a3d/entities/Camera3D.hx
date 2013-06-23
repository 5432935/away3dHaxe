package a3d.entities;

import flash.geom.Matrix3D;
import flash.geom.Vector3D;


import a3d.bounds.BoundingVolumeBase;
import a3d.bounds.NullBounds;
import a3d.entities.lenses.LensBase;
import a3d.entities.lenses.PerspectiveLens;
import a3d.core.partition.CameraNode;
import a3d.core.partition.EntityNode;
import a3d.events.CameraEvent;
import a3d.events.LensEvent;
import a3d.io.library.assets.AssetType;
import a3d.math.Matrix3DUtils;
import a3d.math.Plane3D;



/**
 * A Camera3D object represents a virtual camera through which we view the scene.
 */
class Camera3D extends Entity
{
	private var _viewProjection:Matrix3D = new Matrix3D();
	private var _viewProjectionDirty:Bool = true;
	private var _lens:LensBase;
	private var _frustumPlanes:Vector<Plane3D>;
	private var _frustumPlanesDirty:Bool = true;

	/**
	 * Creates a new Camera3D object
	 * @param lens An optional lens object that will perform the projection. Defaults to PerspectiveLens.
	 *
	 * @see a3d.cameras.lenses.PerspectiveLens
	 */
	public function new(lens:LensBase = null)
	{
		super();

		//setup default lens
		_lens = lens || new PerspectiveLens();
		_lens.addEventListener(LensEvent.MATRIX_CHANGED, onLensMatrixChanged);

		//setup default frustum planes
		_frustumPlanes = new Vector<Plane3D>(6, true);

		for (var i:Int = 0; i < 6; ++i)
			_frustumPlanes[i] = new Plane3D();

		z = -1000;
	}

	override private function getDefaultBoundingVolume():BoundingVolumeBase
	{
		return new NullBounds();
	}

	override private inline function get_assetType():String
	{
		return AssetType.CAMERA;
	}

	private function onLensMatrixChanged(event:LensEvent):Void
	{
		_viewProjectionDirty = true;
		_frustumPlanesDirty = true;

		dispatchEvent(event);
	}

	/**
	 *
	 */
	private inline function get_frustumPlanes():Vector<Plane3D>
	{
		if (_frustumPlanesDirty)
			updateFrustum();

		return _frustumPlanes;
	}

	private function updateFrustum():Void
	{
		var a:Float, b:Float, c:Float;
		//var d : Number;
		var c11:Float, c12:Float, c13:Float, c14:Float;
		var c21:Float, c22:Float, c23:Float, c24:Float;
		var c31:Float, c32:Float, c33:Float, c34:Float;
		var c41:Float, c42:Float, c43:Float, c44:Float;
		var p:Plane3D;
		var raw:Vector<Float> = Matrix3DUtils.RAW_DATA_CONTAINER;
		var invLen:Float;
		viewProjection.copyRawDataTo(raw);

		c11 = raw[0];
		c12 = raw[4];
		c13 = raw[8];
		c14 = raw[12];
		c21 = raw[1];
		c22 = raw[5];
		c23 = raw[9];
		c24 = raw[13];
		c31 = raw[2];
		c32 = raw[6];
		c33 = raw[10];
		c34 = raw[14];
		c41 = raw[3];
		c42 = raw[7];
		c43 = raw[11];
		c44 = raw[15];

		// left plane
		p = _frustumPlanes[0];
		a = c41 + c11;
		b = c42 + c12;
		c = c43 + c13;
		invLen = 1 / Math.sqrt(a * a + b * b + c * c);
		p.a = a * invLen;
		p.b = b * invLen;
		p.c = c * invLen;
		p.d = -(c44 + c14) * invLen;

		// right plane
		p = _frustumPlanes[1];
		a = c41 - c11;
		b = c42 - c12;
		c = c43 - c13;
		invLen = 1 / Math.sqrt(a * a + b * b + c * c);
		p.a = a * invLen;
		p.b = b * invLen;
		p.c = c * invLen;
		p.d = (c14 - c44) * invLen;

		// bottom
		p = _frustumPlanes[2];
		a = c41 + c21;
		b = c42 + c22;
		c = c43 + c23;
		invLen = 1 / Math.sqrt(a * a + b * b + c * c);
		p.a = a * invLen;
		p.b = b * invLen;
		p.c = c * invLen;
		p.d = -(c44 + c24) * invLen;

		// top
		p = _frustumPlanes[3];
		a = c41 - c21;
		b = c42 - c22;
		c = c43 - c23;
		invLen = 1 / Math.sqrt(a * a + b * b + c * c);
		p.a = a * invLen;
		p.b = b * invLen;
		p.c = c * invLen;
		p.d = (c24 - c44) * invLen;

		// near
		p = _frustumPlanes[4];
		a = c31;
		b = c32;
		c = c33;
		invLen = 1 / Math.sqrt(a * a + b * b + c * c);
		p.a = a * invLen;
		p.b = b * invLen;
		p.c = c * invLen;
		p.d = -c34 * invLen;

		// far
		p = _frustumPlanes[5];
		a = c41 - c31;
		b = c42 - c32;
		c = c43 - c33;
		invLen = 1 / Math.sqrt(a * a + b * b + c * c);
		p.a = a * invLen;
		p.b = b * invLen;
		p.c = c * invLen;
		p.d = (c34 - c44) * invLen;

		_frustumPlanesDirty = false;
	}

	/**
	 * @inheritDoc
	 */
	override private function invalidateSceneTransform():Void
	{
		super.invalidateSceneTransform();

		_viewProjectionDirty = true;
		_frustumPlanesDirty = true;
	}

	/**
	 * @inheritDoc
	 */
	override private function updateBounds():Void
	{
		_bounds.nullify();

		_boundsInvalid = false;
	}

	/**
	 * @inheritDoc
	 */
	override private function createEntityPartitionNode():EntityNode
	{
		return new CameraNode(this);
	}

	/**
	 * The lens used by the camera to perform the projection;
	 */
	private inline function get_lens():LensBase
	{
		return _lens;
	}

	private inline function set_lens(value:LensBase):Void
	{
		if (_lens == value)
			return;

		if (value == null)
			throw new Error("Lens cannot be null!");

		_lens.removeEventListener(LensEvent.MATRIX_CHANGED, onLensMatrixChanged);

		_lens = value;

		_lens.addEventListener(LensEvent.MATRIX_CHANGED, onLensMatrixChanged);

		dispatchEvent(new CameraEvent(CameraEvent.LENS_CHANGED, this));
	}

	/**
	 * The view projection matrix of the camera.
	 */
	private inline function get_viewProjection():Matrix3D
	{
		if (_viewProjectionDirty)
		{
			_viewProjection.copyFrom(inverseSceneTransform);
			_viewProjection.append(_lens.matrix);
			_viewProjectionDirty = false;
		}

		return _viewProjection;
	}

	/**
	 * Calculates the scene position of the given normalized coordinates in screen space.
	 *
	 * @param nX The normalised x coordinate in screen space, -1 corresponds to the left edge of the viewport, 1 to the right.
	 * @param nY The normalised y coordinate in screen space, -1 corresponds to the top edge of the viewport, 1 to the bottom.
	 * @param sZ The z coordinate in screen space, representing the distance into the screen.
	 * @return The scene position of the given screen coordinates.
	 */
	public function unproject(nX:Float, nY:Float, sZ:Float):Vector3D
	{
		return sceneTransform.transformVector(lens.unproject(nX, nY, sZ));
	}

	/**
	 * Calculates the ray in scene space from the camera to the given normalized coordinates in screen space.
	 *
	 * @param nX The normalised x coordinate in screen space, -1 corresponds to the left edge of the viewport, 1 to the right.
	 * @param nY The normalised y coordinate in screen space, -1 corresponds to the top edge of the viewport, 1 to the bottom.
	 * @param sZ The z coordinate in screen space, representing the distance into the screen.
	 * @return The ray from the camera to the scene space position of the given screen coordinates.
	 */
	public function getRay(nX:Float, nY:Float, sZ:Float):Vector3D
	{
		return sceneTransform.deltaTransformVector(lens.unproject(nX, nY, sZ));
	}

	/**
	 * Calculates the normalised position in screen space of the given scene position.
	 *
	 * @param point3d the position vector of the scene coordinates to be projected.
	 * @return The normalised screen position of the given scene coordinates.
	 */
	public function project(point3d:Vector3D):Vector3D
	{
		return lens.project(inverseSceneTransform.transformVector(point3d));
	}
}
