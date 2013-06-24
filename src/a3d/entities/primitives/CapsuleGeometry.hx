package a3d.entities.primitives;

import a3d.core.base.CompactSubGeometry;

/**
 * A Capsule primitive mesh.
 */
class CapsuleGeometry extends PrimitiveBase
{
	private var _radius:Float;
	private var _height:Float;
	private var _segmentsW:UInt;
	private var _segmentsH:UInt;
	private var _yUp:Bool;

	/**
	 * Creates a new Capsule object.
	 * @param radius The radius of the capsule.
	 * @param height The height of the capsule.
	 * @param segmentsW Defines the number of horizontal segments that make up the capsule. Defaults to 16.
	 * @param segmentsH Defines the number of vertical segments that make up the capsule. Defaults to 15. Must be uneven value.
	 * @param yUp Defines whether the capsule poles should lay on the Y-axis (true) or on the Z-axis (false).
	 */
	public function CapsuleGeometry(radius:Float = 50, height:Float = 100, segmentsW:UInt = 16, segmentsH:UInt = 15, yUp:Bool = true)
	{
		super();

		_radius = radius;
		_height = height;
		_segmentsW = segmentsW;
		_segmentsH = (segmentsH % 2 == 0) ? segmentsH + 1 : segmentsH;
		_yUp = yUp;
	}

	/**
	* @inheritDoc
	*/
	override private function buildGeometry(target:CompactSubGeometry):Void
	{
		var data:Vector<Float>;
		var indices:Vector<UInt>;
		var i:UInt, j:UInt, triIndex:UInt;
		var numVerts:UInt = (_segmentsH + 1) * (_segmentsW + 1);
		var stride:UInt = target.vertexStride;
		var skip:UInt = stride - 9;
		var index:UInt = 0;
		var startIndex:UInt;
		var comp1:Float, comp2:Float, t1:Float, t2:Float;

		if (numVerts == target.numVertices)
		{
			data = target.vertexData;
			indices = target.indexData || new Vector<UInt>((_segmentsH - 1) * _segmentsW * 6, true);

		}
		else
		{
			data = new Vector<Float>(numVerts * stride, true);
			indices = new Vector<UInt>((_segmentsH - 1) * _segmentsW * 6, true);
			invalidateUVs();
		}

		for (j = 0; j <= _segmentsH; ++j)
		{

			var horangle:Float = Math.PI * j / _segmentsH;
			var z:Float = -_radius * Math.cos(horangle);
			var ringradius:Float = _radius * Math.sin(horangle);
			startIndex = index;

			for (i = 0; i <= _segmentsW; ++i)
			{
				var verangle:Float = 2 * Math.PI * i / _segmentsW;
				var x:Float = ringradius * Math.cos(verangle);
				var offset:Float = j > _segmentsH / 2 ? _height / 2 : -_height / 2;
				var y:Float = ringradius * Math.sin(verangle);
				var normLen:Float = 1 / Math.sqrt(x * x + y * y + z * z);
				var tanLen:Float = Math.sqrt(y * y + x * x);

				if (_yUp)
				{
					t1 = 0;
					t2 = tanLen > .007 ? x / tanLen : 0;
					comp1 = -z;
					comp2 = y;

				}
				else
				{
					t1 = tanLen > .007 ? x / tanLen : 0;
					t2 = 0;
					comp1 = y;
					comp2 = z;
				}

				if (i == _segmentsW)
				{

					data[index++] = data[startIndex];
					data[index++] = data[startIndex + 1];
					data[index++] = data[startIndex + 2];
					data[index++] = (data[startIndex + 3] + (x * normLen)) * .5;
					data[index++] = (data[startIndex + 4] + (comp1 * normLen)) * .5;
					data[index++] = (data[startIndex + 5] + (comp2 * normLen)) * .5;
					data[index++] = (data[startIndex + 6] + (tanLen > .007 ? -y / tanLen : 1)) * .5;
					data[index++] = (data[startIndex + 7] + t1) * .5;
					data[index++] = (data[startIndex + 8] + t2) * .5;

				}
				else
				{
					// vertex
					data[index++] = x;
					data[index++] = (_yUp) ? comp1 - offset : comp1;
					data[index++] = (_yUp) ? comp2 : comp2 + offset;
					// normal
					data[index++] = x * normLen;
					data[index++] = comp1 * normLen;
					data[index++] = comp2 * normLen;
					// tangent
					data[index++] = tanLen > .007 ? -y / tanLen : 1;
					data[index++] = t1;
					data[index++] = t2;
				}

				if (i > 0 && j > 0)
				{
					var a:Int = (_segmentsW + 1) * j + i;
					var b:Int = (_segmentsW + 1) * j + i - 1;
					var c:Int = (_segmentsW + 1) * (j - 1) + i - 1;
					var d:Int = (_segmentsW + 1) * (j - 1) + i;

					if (j == _segmentsH)
					{
						data[index - 9] = data[startIndex];
						data[index - 8] = data[startIndex + 1];
						data[index - 7] = data[startIndex + 2];

						indices[triIndex++] = a;
						indices[triIndex++] = c;
						indices[triIndex++] = d;

					}
					else if (j == 1)
					{
						indices[triIndex++] = a;
						indices[triIndex++] = b;
						indices[triIndex++] = c;

					}
					else
					{
						indices[triIndex++] = a;
						indices[triIndex++] = b;
						indices[triIndex++] = c;
						indices[triIndex++] = a;
						indices[triIndex++] = c;
						indices[triIndex++] = d;
					}
				}

				index += skip;
			}
		}

		target.updateData(data);
		target.updateIndexData(indices);
	}

	/**
	 * @inheritDoc
	 */
	override private function buildUVs(target:CompactSubGeometry):Void
	{
		var i:Int, j:Int;
		var index:UInt;
		var data:Vector<Float>;
		var stride:UInt = target.UVStride;
		var UVlen:UInt = (_segmentsH + 1) * (_segmentsW + 1) * stride;
		var skip:UInt = stride - 2;

		if (target.UVData && UVlen == target.UVData.length)
		{
			data = target.UVData;
		}
		else
		{
			data = new Vector<Float>(UVlen, true);
			invalidateGeometry();
		}

		index = target.UVOffset;
		for (j = 0; j <= _segmentsH; ++j)
		{
			for (i = 0; i <= _segmentsW; ++i)
			{
				data[index++] = i / _segmentsW;
				data[index++] = j / _segmentsH;
				index += skip;
			}
		}

		target.updateData(data);
	}

	/**
	 * The radius of the capsule.
	 */
	private inline function get_radius():Float
	{
		return _radius;
	}

	private inline function set_radius(value:Float):Void
	{
		_radius = value;
		invalidateGeometry();
	}

	/**
	 * The height of the capsule.
	 */
	private inline function get_height():Float
	{
		return _height;
	}

	private inline function set_height(value:Float):Void
	{
		_height = value;
		invalidateGeometry();
	}

	/**
	 * Defines the number of horizontal segments that make up the capsule. Defaults to 16.
	 */
	private inline function get_segmentsW():UInt
	{
		return _segmentsW;
	}

	private inline function set_segmentsW(value:UInt):Void
	{
		_segmentsW = value;
		invalidateGeometry();
		invalidateUVs();
	}

	/**
	 * Defines the number of vertical segments that make up the capsule. Defaults to 15. Must be uneven.
	 */
	private inline function get_segmentsH():UInt
	{
		return _segmentsH;
	}

	private inline function set_segmentsH(value:UInt):Void
	{
		_segmentsH = (value % 2 == 0) ? value + 1 : value;
		invalidateGeometry();
		invalidateUVs();
	}

	/**
	 * Defines whether the capsule poles should lay on the Y-axis (true) or on the Z-axis (false).
	 */
	private inline function get_yUp():Bool
	{
		return _yUp;
	}

	private inline function set_yUp(value:Bool):Void
	{
		_yUp = value;
		invalidateGeometry();
	}
}
