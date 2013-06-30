package a3d.entities.primitives;


/**
 * A UV Cone primitive mesh.
 */
class ConeGeometry extends CylinderGeometry
{

	/**
	 * The radius of the bottom end of the cone.
	 */
	private function get_radius():Float
	{
		return _bottomRadius;
	}

	private function set_radius(value:Float):Void
	{
		_bottomRadius = value;
		invalidateGeometry();
	}

	/**
	 * Creates a new Cone object.
	 * @param radius The radius of the bottom end of the cone
	 * @param height The height of the cone
	 * @param segmentsW Defines the number of horizontal segments that make up the cone. Defaults to 16.
	 * @param segmentsH Defines the number of vertical segments that make up the cone. Defaults to 1.
	 * @param yUp Defines whether the cone poles should lay on the Y-axis (true) or on the Z-axis (false).
	 */
	public function new(radius:Float = 50, height:Float = 100, segmentsW:UInt = 16, segmentsH:UInt = 1, closed:Bool = true, yUp:Bool = true)
	{
		super(0, radius, height, segmentsW, segmentsH, false, closed, true, yUp);
	}
}
