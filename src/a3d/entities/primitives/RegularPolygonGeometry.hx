package a3d.entities.primitives;


/**
 * A UV RegularPolygon primitive mesh.
 */
class RegularPolygonGeometry extends CylinderGeometry
{
	
	/**
	 * The radius of the regular polygon.
	 */
	public var radius(get, set):Float;
	private function get_radius():Float
	{
		return _bottomRadius;
	}

	private function set_radius(value:Float):Float
	{
		_bottomRadius = value;
		invalidateGeometry();
		return _bottomRadius;
	}


	/**
	 * The number of sides of the regular polygon.
	 */
	public var sides(get, set):Int;
	private function get_sides():Int
	{
		return _segmentsW;
	}

	private function set_sides(value:Int):Int
	{
		return segmentsW = value;
	}

	/**
	 * The number of subdivisions from the edge to the center of the regular polygon.
	 */
	public var subdivisions(get, set):Int;
	private function get_subdivisions():Int
	{
		return _segmentsH;
	}

	private function set_subdivisions(value:Int):Int
	{
		return segmentsH = value;
	}

	/**
	 * Creates a new RegularPolygon disc object.
	 * @param radius The radius of the regular polygon
	 * @param sides Defines the number of sides of the regular polygon.
	 * @param yUp Defines whether the regular polygon should lay on the Y-axis (true) or on the Z-axis (false).
	 */
	public function new(radius:Float = 100, sides:Int = 16, yUp:Bool = true)
	{
		super(radius, 0, 0, sides, 1, true, false, false, yUp);
	}
}
