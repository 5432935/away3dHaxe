package away3d.cameras.lenses;


/**
 * FreeMatrixLens provides a projection lens that exposes a full projection matrix, rather than provide one through
 * more user-friendly settings. Whenever the matrix is updated, it needs to be reset in order to trigger an update.
 */
class FreeMatrixLens extends LensBase
{
	/**
	 * Creates a new FreeMatrixLens object.
	 */
	public function new()
	{
		super();
		_matrix.copyFrom(new PerspectiveLens().matrix);
	}

	override private function set_near(value:Float):Float
	{
		return _near = value;
	}

	override private function set_far(value:Float):Float
	{
		return _far = value;
	}

	override private function set_aspectRatio(value:Float):Float
	{
		return _aspectRatio = value;
	}

	override public function clone():LensBase
	{
		var clone:FreeMatrixLens = new FreeMatrixLens();
		clone._matrix.copyFrom(_matrix);
		clone._near = _near;
		clone._far = _far;
		clone._aspectRatio = _aspectRatio;
		clone.invalidateMatrix();
		return clone;
	}

	override private function updateMatrix():Void
	{
		_matrixInvalid = false;
	}
}
