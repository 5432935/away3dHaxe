﻿package a3d.entities.extrusions
{
	import flash.geom.Point;
	import flash.geom.Vector3D;
	
	import a3d.bounds.BoundingVolumeBase;
	import a3d.core.base.Geometry;
	import a3d.core.base.SubGeometry;
	import a3d.core.base.SubMesh;
	import a3d.core.base.data.UV;
	import a3d.core.base.data.Vertex;
	import a3d.entities.Mesh;
	import a3d.materials.MaterialBase;
	import a3d.materials.utils.MultipleMaterials;
	import a3d.tools.helpers.MeshHelper;

	class LinearExtrude extends Mesh
	{
		public static inline var X_AXIS:String = "x";
		public static inline var Y_AXIS:String = "y";
		public static inline var Z_AXIS:String = "z";

		private const LIMIT:UInt = 196605;
		private const EPS:Float = .0001;

		private var _varr:Vector<Vertex>;
		private var _varr2:Vector<Vertex>;
		private var _uvarr:Vector<UV>;
		private var _subdivision:UInt;
		private var _coverAll:Bool;
		private var _flip:Bool;
		private var _closePath:Bool;
		private var _axis:String;
		private var _offset:Float;
		private var _materials:MultipleMaterials;
		private var _activeMaterial:MaterialBase;
		private var _centerMesh:Bool;
		private var _thickness:Float;
		private var _thicknessSubdivision:UInt;
		private var _ignoreSides:String;

		private var _geomDirty:Bool = true;
		private var _subGeometry:SubGeometry;
		private var _MaterialsSubGeometries:Vector<SubGeometryList>;
		private var _uva:UV;
		private var _uvb:UV;
		private var _uvc:UV;
		private var _uvd:UV;
		// TODO: not used
		// private var _va:Vertex;
		// private var _vb:Vertex;
		// private var _vc:Vertex;
		// private var _vd:Vertex;
		private var _maxIndProfile:UInt;
		private var _uvs:Vector<Float>;
		private var _vertices:Vector<Float>;
		private var _indices:Vector<UInt>;
		private var _aVectors:Vector<Vector3D>;
		private var _baseMax:Float;
		private var _baseMin:Float;

		/**
		 *  Class LinearExtrusion generates walls like meshes with or without thickness from a series of Vector3D's
		 *
		 *@param		material						[optional] MaterialBase. The LatheExtrude (Mesh) material. Optional in constructor, material must be set before LatheExtrude object is render.
		 * @param		vectors						[optional] Vector.&lt;Vector3D&gt;. A series of Vector3D's representing the profile information to be repeated/rotated around a given axis.
		 * @param		axis							[optional] String. The axis to elevate along: X_AXIS, Y_AXIS or Z_AXIS. Default is LinearExtrusion.Y_AXIS.
		 * @param		offset							[optional] Number. The elevation offset along the defined axis.
		 * @param		subdivision					[optional] uint. The subdivision of the geometry between 2 vector3D. Default is 32.
		 * @param		coverAll						[optional] Bool. The way the uv mapping is spreaded across the shape. True covers an entire side of the geometry while false covers per segments. Default is false.
		 * @param		thickness					[optional] Number. If the shape must simulate a thickness. Default is 0.
		 * @param		thicknessSubdivision	[optional] uint. If thickness is higher than 0. Defines the subdivision of the thickness (top, left, right, bottom). Default is 3;
		 * @param		materials					[optional] MultipleMaterials. Allows multiple material support when thickness is set higher to 1. Default is null.
		 * properties as MaterialBase are: bottom, top, left, right, front and back.
		 * @param		centerMesh				[optional] Bool. If the geometry needs to be recentered in its own object space. If the position after generation is set to 0,0,0, the object would be centered in worldspace. Default is false.
		 * @param		closePath					[optional] Bool. Defines if the last entered vector needs to be linked with the first one to form a closed shape. Default is false.
		 * @param		ignoreSides				[optional] String. To prevent the generation of sides if thickness is set higher than 0. To avoid the bottom ignoreSides = "bottom", avoiding both top and bottom: ignoreSides = "bottom, top". Strings options: bottom, top, left, right, front and back. Default is "".
		 * @param		flip							[optional] Bool. If the faces must be reversed depending on Vector3D's orientation. Default is false.
		 */

		public function LinearExtrude(material:MaterialBase = null, vectors:Vector<Vector3D> = null, axis:String = LinearExtrude.Y_AXIS, offset:Float = 10, subdivision:UInt = 3, coverAll:Bool = false,
			thickness:Float = 0, thicknessSubdivision:UInt = 3, materials:MultipleMaterials = null, centerMesh:Bool = false, closePath:Bool = false, ignoreSides:String = "", flip:Bool = false)
		{
			var geom:Geometry = new Geometry();
			_subGeometry = new SubGeometry();

			if (!material && materials && materials.front)
				material = materials.front;
			super(geom, material);

			_aVectors = vectors;
			_axis = axis;
			_offset = offset;
			_coverAll = coverAll;
			_flip = flip;
			_centerMesh = centerMesh;
			_thickness = Math.abs(thickness);
			this.subdivision = subdivision;
			this.thicknessSubdivision = thicknessSubdivision;
			_ignoreSides = ignoreSides;
			_closePath = closePath;

			if (materials)
				this.materials = materials;
			if (_closePath && ignoreSides != "")
				this.ignoreSides = ignoreSides;
		}

		private function buildExtrude():Void
		{

			if (!_aVectors.length || _aVectors.length < 2)
				throw new Error("LinearExtrusion error: at least 2 vector3D required!");
			if (_closePath)
				_aVectors.push(new Vector3D(_aVectors[0].x, _aVectors[0].y, _aVectors[0].z));

			_maxIndProfile = _aVectors.length * 9;
			_MaterialsSubGeometries = null;
			_geomDirty = false;
			initHolders();

			generate();

			if (_vertices.length > 0)
			{
				_subGeometry.updateVertexData(_vertices);
				_subGeometry.updateIndexData(_indices);
				_subGeometry.updateUVData(_uvs);
				this.geometry.addSubGeometry(_subGeometry);
			}

			if (_MaterialsSubGeometries && _MaterialsSubGeometries.length > 0)
			{
				var sglist:SubGeometryList;
				var sg:SubGeometry;
				for (var i:UInt = 1; i < _MaterialsSubGeometries.length; ++i)
				{
					sglist = _MaterialsSubGeometries[i];
					sg = sglist.subGeometry;
					if (sg && sglist.vertices.length > 0)
					{
						this.geometry.addSubGeometry(sg);
						this.subMeshes[this.subMeshes.length - 1].material = sglist.material;
						sg.updateVertexData(sglist.vertices);
						sg.updateIndexData(sglist.indices);
						sg.updateUVData(sglist.uvs);
					}
				}
			}

			if (_centerMesh)
				MeshHelper.recenter(this);

			_varr = _varr2 = null;
			_uvarr = null;
		}

		/**
		 * Defines the axis used for the extrusion. Defaults to "y".
		 */
		private inline function get_axis():String
		{
			return _axis;
		}

		private inline function set_axis(val:String):Void
		{
			if (_axis == val)
				return;

			_axis = val;
			invalidateGeometry();
		}

		/**
		 * An optional MultipleMaterials object that defines left, right, front, back, top and bottom materials to be set on the resulting lathe extrusion.
		 */
		private inline function get_materials():MultipleMaterials
		{
			return _materials;
		}

		private inline function set_materials(val:MultipleMaterials):Void
		{
			_materials = val;

			if (_materials.front && this.material != _materials.front)
				this.material = _materials.front;

			invalidateGeometry();
		}


		/**
		 * Defines the subdivisions created in the mesh for the total number of revolutions. Defaults to 2, minimum 2.
		 */
		private inline function get_subdivision():UInt
		{
			return _subdivision;
		}

		private inline function set_subdivision(val:UInt):Void
		{
			val = (val < 3) ? 3 : val;
			if (_subdivision == val)
				return;
			_subdivision = val;
			invalidateGeometry();
		}

		/**
		 * Defines if the texture(s) should be stretched to cover the entire mesh or per step between segments. Defaults to true.
		 */
		private inline function get_coverAll():Bool
		{
			return _coverAll;
		}

		private inline function set_coverAll(val:Bool):Void
		{
			if (_coverAll == val)
				return;

			_coverAll = val;
			invalidateGeometry();
		}

		/**
		 * Defines if the generated faces should be inversed. Default false.
		 */
		private inline function get_flip():Bool
		{
			return _flip;
		}

		private inline function set_flip(val:Bool):Void
		{
			if (_flip == val)
				return;

			_flip = val;
			invalidateGeometry();
		}

		/**
		 * Defines whether the mesh is recentered of not after generation
		 */
		private inline function get_centerMesh():Bool
		{
			return _centerMesh;
		}

		private inline function set_centerMesh(val:Bool):Void
		{
			if (_centerMesh == val)
				return;

			_centerMesh = val;

			if (_centerMesh && _subGeometry.vertexData.length > 0)
			{
				MeshHelper.recenter(this);
			}
			else
			{
				invalidateGeometry();
			}
		}

		/**
		 * Defines the _thickness of the resulting lathed geometry. Defaults to 0 (single face).
		 */
		private inline function get_thickness():Float
		{
			return _thickness;
		}

		private inline function set_thickness(val:Float):Void
		{
			val = Math.abs(val);
			if (_thickness == val)
				return;

			_thickness = val;
			invalidateGeometry();
		}

		/**
		 * Defines the subdivision for the top, bottom, right and left if thickness is set higher to 0. Defaults to 1.
		 */
		private inline function get_thicknessSubdivision():UInt
		{
			return _thicknessSubdivision;
		}

		private inline function set_thicknessSubdivision(val:UInt):Void
		{
			val = (val < 3) ? 3 : val;
			if (_thicknessSubdivision == val)
				return;

			_thicknessSubdivision = val;
			invalidateGeometry();
		}

		/**
		 * Defines if the top, bottom, left, right, front or back of the the extrusion is left open.
		 */
		private inline function get_ignoreSides():String
		{
			return _ignoreSides;
		}

		private inline function set_ignoreSides(val:String):Void
		{
			_ignoreSides = val;
			if (_closePath)
			{
				if (_ignoreSides.indexOf("left") == -1)
					_ignoreSides += "left,";
				if (_ignoreSides.indexOf("right") == -1)
					_ignoreSides += "right";
			}
			invalidateGeometry();
		}

		/**
		 * @inheritDoc
		 */
		override private inline function get_bounds():BoundingVolumeBase
		{
			if (_geomDirty)
				buildExtrude();

			return super.bounds;
		}

		/**
		 * @inheritDoc
		 */
		override private inline function get_geometry():Geometry
		{
			if (_geomDirty)
				buildExtrude();

			return super.geometry;
		}

		/**
		 * @inheritDoc
		 */
		override private inline function get_subMeshes():Vector<SubMesh>
		{
			if (_geomDirty)
				buildExtrude();

			return super.subMeshes;
		}

		private function addFace(v0:Vertex, v1:Vertex, v2:Vertex, uv0:UV, uv1:UV, uv2:UV, mat:MaterialBase, invertU:Bool = false):Void
		{
			var subGeom:SubGeometry;
			var uvs:Vector<Float>;
			var vertices:Vector<Float>;
			// TODO: not used
			// var normals:Vector<Float>;
			var indices:Vector<UInt>;
			var sglist:SubGeometryList;

			if (_activeMaterial != mat && _materials)
			{
				sglist = getSubGeometryListFromMaterial(mat);
				_subGeometry = subGeom = sglist.subGeometry;
				_uvs = uvs = sglist.uvs;
				_vertices = vertices = sglist.vertices;
				_indices = indices = sglist.indices;
			}
			else
			{

				subGeom = _subGeometry;
				uvs = _uvs;
				vertices = _vertices;
				indices = _indices;
			}

			if (vertices.length + 9 > LIMIT)
			{
				subGeom.updateVertexData(vertices);
				subGeom.updateIndexData(indices);
				subGeom.updateUVData(uvs);
				this.geometry.addSubGeometry(subGeom);
				this.subMeshes[this.subMeshes.length - 1].material = mat;

				subGeom = new SubGeometry();
				subGeom.autoDeriveVertexTangents = true;
				subGeom.autoDeriveVertexNormals = true;

				if (_MaterialsSubGeometries && _MaterialsSubGeometries.length > 1)
				{
					sglist = getSubGeometryListFromMaterial(mat);
					sglist.subGeometry = _subGeometry = subGeom;
					sglist.uvs = _uvs = uvs = new Vector<Float>();
					sglist.vertices = _vertices = vertices = new Vector<Float>();
					sglist.indices = _indices = indices = new Vector<UInt>();

				}
				else
				{

					_subGeometry = subGeom;
					uvs = _uvs = new Vector<Float>();
					vertices = _vertices = new Vector<Float>();
					indices = _indices = new Vector<UInt>();
				}
			}

			var ind:UInt = vertices.length / 3;

			if (invertU)
			{
				uvs.push(1 - uv0.u, uv0.v, 1 - uv1.u, uv1.v, 1 - uv2.u, uv2.v);
			}
			else
			{
				uvs.push(uv0.u, uv0.v, uv1.u, uv1.v, uv2.u, uv2.v);
			}
			vertices.push(v0.x, v0.y, v0.z, v1.x, v1.y, v1.z, v2.x, v2.y, v2.z);

			indices.push(ind, ind + 1, ind + 2);
		}

		private function generate():Void
		{
			var i:UInt;
			var j:UInt;
			var increase:Float = _offset / _subdivision;

			var baseMaxX:Float = _aVectors[0].x;
			var baseMinX:Float = _aVectors[0].x;
			var baseMaxY:Float = _aVectors[0].y;
			var baseMinY:Float = _aVectors[0].y;
			var baseMaxZ:Float = _aVectors[0].z;
			var baseMinZ:Float = _aVectors[0].z;

			for (i = 1; i < _aVectors.length; i++)
			{
				baseMaxX = Math.max(_aVectors[i].x, baseMaxX);
				baseMinX = Math.min(_aVectors[i].x, baseMinX);
				baseMaxY = Math.max(_aVectors[i].y, baseMaxY);
				baseMinY = Math.min(_aVectors[i].y, baseMinY);
				baseMaxZ = Math.max(_aVectors[i].z, baseMaxZ);
				baseMinZ = Math.min(_aVectors[i].z, baseMinZ);
			}

			var offset:Float = 0;

			switch (_axis)
			{
				case X_AXIS:
					_baseMax = Math.abs(baseMaxX) - Math.abs(baseMinX);
					if (baseMinZ > 0 && baseMaxZ > 0)
					{
						_baseMin = baseMaxZ - baseMinZ;
						offset = -baseMinZ;
					}
					else if (baseMinZ < 0 && baseMaxZ < 0)
					{
						_baseMin = Math.abs(baseMinZ - baseMaxZ);
						offset = -baseMinZ;
					}
					else
					{
						_baseMin = Math.abs(baseMaxZ) + Math.abs(baseMinZ);
						offset = Math.abs(baseMinZ) + ((baseMaxZ < 0) ? -baseMaxZ : 0);
					}
				
				case Y_AXIS:
					_baseMax = Math.abs(baseMaxY) - Math.abs(baseMinY);
					if (baseMinX > 0 && baseMaxX > 0)
					{
						_baseMin = baseMaxX - baseMinX;
						offset = -baseMinX;
					}
					else if (baseMinX < 0 && baseMaxX < 0)
					{
						_baseMin = Math.abs(baseMinX - baseMaxX);
						offset = -baseMinX;
					}
					else
					{
						_baseMin = Math.abs(baseMaxX) + Math.abs(baseMinX);
						offset = Math.abs(baseMinX) + ((baseMaxX < 0) ? -baseMaxX : 0);
					}
				
				case Z_AXIS:
					_baseMax = Math.abs(baseMaxZ) - Math.abs(baseMinZ);
					if (baseMinY > 0 && baseMaxY > 0)
					{
						_baseMin = baseMaxY - baseMinY;
						offset = -baseMinY;
					}
					else if (baseMinY < 0 && baseMaxY < 0)
					{
						_baseMin = Math.abs(baseMinY - baseMaxY);
						offset = -baseMinY;
					}
					else
					{
						_baseMin = Math.abs(baseMaxY) + Math.abs(baseMinY);
						offset = Math.abs(baseMinY) + ((baseMaxY < 0) ? -baseMaxY : 0);
					}
			}

			var aLines:Array;
			var prop1:String;
			var prop2:String;
			var prop3:String;
			var vector:Vertex = new Vertex();
			if (_thickness != 0)
			{
				var aListsides:Array = ["top", "bottom", "right", "left", "front", "back"];
				var renderSide:RenderSide = new RenderSide();

				for (i = 0; i < aListsides.length; ++i)
					renderSide[aListsides[i]] = (_ignoreSides.indexOf(aListsides[i]) == -1);

				switch (_axis)
				{
					case X_AXIS:
						prop1 = Z_AXIS;
						prop2 = Y_AXIS;
						prop3 = X_AXIS;
						
					case Y_AXIS:
						prop1 = X_AXIS;
						prop2 = Z_AXIS;
						prop3 = Y_AXIS;
					
					case Z_AXIS:
						prop1 = Y_AXIS;
						prop2 = X_AXIS;
						prop3 = Z_AXIS;
				}

				aLines = buildThicknessPoints(prop1, prop2);

				var points:FourPoints;

				var vector2:Vertex = new Vertex();
				var vector3:Vertex = new Vertex();
				var vector4:Vertex = new Vertex();

				for (i = 0; i < aLines.length; i++)
				{

					points = FourPoints(aLines[i]);

					if (i == 0)
					{
						vector[prop1] = points.pt2.x;
						vector[prop2] = points.pt2.y;
						vector[prop3] = _aVectors[0][prop3];
						_varr.push(new Vertex(vector.x, vector.y, vector.z));

						vector2[prop1] = points.pt1.x;
						vector2[prop2] = points.pt1.y;
						vector2[prop3] = _aVectors[0][prop3];
						_varr2.push(new Vertex(vector2.x, vector2.y, vector2.z));

						elevate(vector, vector2, increase);

						if (aLines.length == 1)
						{

							vector3[prop1] = points.pt4.x;
							vector3[prop2] = points.pt4.y;
							vector3[prop3] = _aVectors[0][prop3];
							_varr.push(new Vertex(vector3.x, vector3.y, vector3.z));

							vector4[prop1] = points.pt3.x;
							vector4[prop2] = points.pt3.y;
							vector4[prop3] = _aVectors[0][prop3];
							_varr2.push(new Vertex(vector4.x, vector4.y, vector4.z));

							elevate(vector3, vector4, increase);
						}

					}
					else if (i == aLines.length - 1)
					{

						vector[prop1] = points.pt2.x;
						vector[prop2] = points.pt2.y;
						vector[prop3] = _aVectors[i][prop3];
						_varr.push(new Vertex(vector.x, vector.y, vector.z));

						vector2[prop1] = points.pt1.x;
						vector2[prop2] = points.pt1.y;
						vector2[prop3] = _aVectors[i][prop3];
						_varr2.push(new Vertex(vector2.x, vector2.y, vector2.z));

						elevate(vector, vector2, increase);

						vector3[prop1] = points.pt4.x;
						vector3[prop2] = points.pt4.y;
						vector3[prop3] = _aVectors[i][prop3];
						_varr.push(new Vertex(vector3.x, vector3.y, vector3.z));

						vector4[prop1] = points.pt3.x;
						vector4[prop2] = points.pt3.y;
						vector4[prop3] = _aVectors[i][prop3];
						_varr2.push(new Vertex(vector4.x, vector4.y, vector4.z));

						elevate(vector3, vector4, increase);

					}
					else
					{

						vector[prop1] = points.pt2.x;
						vector[prop2] = points.pt2.y;
						vector[prop3] = _aVectors[i][prop3];
						_varr.push(new Vertex(vector.x, vector.y, vector.z));

						vector2[prop1] = points.pt1.x;
						vector2[prop2] = points.pt1.y;
						vector2[prop3] = _aVectors[i][prop3];
						_varr2.push(new Vertex(vector2.x, vector2.y, vector2.z));

						elevate(vector, vector2, increase);
					}
				}

			}
			else
			{

				for (i = 0; i < _aVectors.length; i++)
				{
					vector.x = _aVectors[i].x;
					vector.y = _aVectors[i].y;
					vector.z = _aVectors[i].z;
					_varr.push(new Vertex(vector.x, vector.y, vector.z));

					for (j = 0; j < _subdivision; j++)
					{
						vector[_axis] += increase;
						_varr.push(new Vertex(vector.x, vector.y, vector.z));
					}
				}
			}

			var index:UInt = 0;
			var mat:MaterialBase;

			if (_thickness > 0)
			{
				var v1a:Vertex;
				var v1b:Vertex;
				var v1c:Vertex;
				var v2a:Vertex;
				var v2b:Vertex;
				var v2c:Vertex;
				var v3a:Vertex;
				var v3b:Vertex;
				var v3c:Vertex;
				var v4b:Vertex;
				var v4c:Vertex;
			}

			var step:Float = 1 / (_aVectors.length - 1);

			var vindex:UInt;

			for (i = 0; i < _aVectors.length - 1; ++i)
			{

				if (_coverAll)
				{
					_uva.u = _uvb.u = step * i;
					_uvc.u = _uvd.u = _uvb.u + step;
				}
				else
				{
					_uva.u = 0;
					_uvb.u = 0;
					_uvc.u = 1;
					_uvd.u = 1;
				}

				for (j = 0; j < _subdivision; ++j)
				{

					_uva.v = _uvd.v = 1 - (j / _subdivision);
					_uvb.v = _uvc.v = 1 - (j + 1) / _subdivision;

					vindex = index + j;
					if (_thickness == 0)
					{

						if (_flip)
						{
							addFace(_varr[vindex + 1], _varr[vindex], _varr[vindex + _subdivision + 2], _uvb, _uva, _uvc, this.material);
							addFace(_varr[vindex + _subdivision + 2], _varr[vindex], _varr[vindex + _subdivision + 1], _uvc, _uva, _uvd, this.material);
						}
						else
						{
							addFace(_varr[vindex], _varr[vindex + 1], _varr[vindex + _subdivision + 2], _uva, _uvb, _uvc, this.material);
							addFace(_varr[vindex], _varr[vindex + _subdivision + 2], _varr[vindex + _subdivision + 1], _uva, _uvc, _uvd, this.material);
						}

					}
					else
					{
						//half side 1
						v1a = _varr[vindex];
						v1b = _varr[vindex + 1];
						v1c = _varr[vindex + _subdivision + 2];
						v2a = _varr[vindex];
						v2b = _varr[vindex + _subdivision + 2];
						v2c = _varr[vindex + _subdivision + 1];

						//half side 2
						v3a = _varr2[vindex];
						v3b = _varr2[vindex + 1];
						v3c = _varr2[vindex + _subdivision + 2];
						v4b = _varr2[vindex + _subdivision + 2];
						v4c = _varr2[vindex + _subdivision + 1];

						//right
						if (renderSide.right)
						{
							mat = (materials && materials.right) ? materials.right : this.material;
							if (_flip)
							{
								addFace(v1a, v1b, v1c, _uva, _uvb, _uvc, mat);
								addFace(v2a, v2b, v2c, _uva, _uvc, _uvd, mat);
							}
							else
							{
								addFace(v1b, v1a, v1c, _uvb, _uva, _uvc, mat);
								addFace(v2b, v2a, v2c, _uvc, _uva, _uvd, mat);
							}
						}

						//left
						if (renderSide.left)
						{
							mat = (materials && materials.left) ? materials.left : this.material;
							if (_flip)
							{
								addFace(v4c, v3b, v3a, _uvd, _uvb, _uva, mat, true);
								addFace(v4c, v4b, v3b, _uvd, _uvc, _uvb, mat, true);
							}
							else
							{
								addFace(v3b, v4c, v3a, _uvb, _uvd, _uva, mat, true);
								addFace(v4b, v4c, v3b, _uvc, _uvd, _uvb, mat, true);
							}
						}

						//back
						if (i == 0 && renderSide.back)
						{
							mat = (materials && materials.back) ? materials.back : this.material;
							if (_flip)
							{
								addFace(v3a, v3b, v1b, _uva, _uvb, _uvc, mat);
								addFace(v3a, v1b, v1a, _uva, _uvc, _uvd, mat);
							}
							else
							{
								addFace(v3b, v3a, v1b, _uvb, _uva, _uvc, mat);
								addFace(v1b, v3a, v1a, _uvc, _uva, _uvd, mat);
							}
						}

						//bottom
						if (j == 0 && renderSide.bottom)
						{
							mat = (materials && materials.bottom) ? materials.bottom : this.material;
							addThicknessSubdivision([v4c, v3a], [v2c, v1a], _uvd.u, _uvb.u, mat);
						}

						//top
						if (j == _subdivision - 1 && renderSide.top)
						{
							mat = (materials && materials.top) ? materials.top : this.material;
							addThicknessSubdivision([v3b, v3c], [v1b, v1c], _uva.u, _uvc.u, mat);
						}

						//front 
						if (i == _aVectors.length - 2 && renderSide.front)
						{
							mat = (materials && materials.front) ? materials.front : this.material;
							if (_flip)
							{
								addFace(v2c, v2b, v3c, _uva, _uvb, _uvc, mat);
								addFace(v2c, v3c, v4c, _uva, _uvc, _uvd, mat);
							}
							else
							{
								addFace(v2b, v2c, v3c, _uvb, _uva, _uvc, mat);
								addFace(v3c, v2c, v4c, _uvc, _uva, _uvd, mat);
							}
						}

					}
				}

				index += _subdivision + 1;
			}
		}

		private function addThicknessSubdivision(points1:Array, points2:Array, u1:Float, u2:Float, mat:MaterialBase):Void
		{
			var i:UInt;
			var j:UInt;

			var stepx:Float;
			var stepy:Float;
			var stepz:Float;

			var va:Vertex;
			var vb:Vertex;
			var vc:Vertex;
			var vd:Vertex;

			var index:UInt = 0;
			var v1:Float = 0;
			var v2:Float = 0;
			var tmp:Array = [];

			for (i = 0; i < points1.length; ++i)
			{
				stepx = (points2[i].x - points1[i].x) / _thicknessSubdivision;
				stepy = (points2[i].y - points1[i].y) / _thicknessSubdivision;
				stepz = (points2[i].z - points1[i].z) / _thicknessSubdivision;

				for (j = 0; j < _thicknessSubdivision + 1; ++j)
					tmp.push(new Vertex(points1[i].x + (stepx * j), points1[i].y + (stepy * j), points1[i].z + (stepz * j)));

			}

			for (i = 0; i < points1.length - 1; ++i)
			{

				for (j = 0; j < _thicknessSubdivision; ++j)
				{

					v1 = j / _thicknessSubdivision;
					v2 = (j + 1) / _thicknessSubdivision;

					_uva.u = u1;
					_uva.v = v1;
					_uvb.u = u1;
					_uvb.v = v2;
					_uvc.u = u2;
					_uvc.v = v2;
					_uvd.u = u2;
					_uvd.v = v1;

					va = tmp[index + j];
					vb = tmp[(index + j) + 1];
					vc = tmp[((index + j) + (_thicknessSubdivision + 2))];
					vd = tmp[((index + j) + (_thicknessSubdivision + 1))];

					if (!_flip)
					{
						addFace(va, vb, vc, _uva, _uvb, _uvc, mat);
						addFace(va, vc, vd, _uva, _uvc, _uvd, mat);
					}
					else
					{
						addFace(vb, va, vc, _uvb, _uva, _uvc, mat);
						addFace(vc, va, vd, _uvc, _uva, _uvd, mat);
					}
				}
				index += _subdivision + 1;
			}

		}

		private function elevate(v0:Object, v1:Object, increase:Float):Void
		{
			for (var i:UInt = 0; i < _subdivision; ++i)
			{
				v0[_axis] += increase;
				v1[_axis] += increase;
				_varr.push(new Vertex(v0[X_AXIS], v0[Y_AXIS], v0[Z_AXIS]));
				_varr2.push(new Vertex(v1[X_AXIS], v1[Y_AXIS], v1[Z_AXIS]));
			}
		}

		private function buildThicknessPoints(prop1:String, prop2:String):Array
		{
			var anchors:Array = [];
			var lines:Array = [];

			for (var i:UInt = 0; i < _aVectors.length - 1; ++i)
			{

				if (_aVectors[i][prop1] == 0 && _aVectors[i][prop2] == 0)
					_aVectors[i][prop1] = EPS;

				if (_aVectors[i + 1][prop2] && _aVectors[i][prop2] == _aVectors[i + 1][prop2])
					_aVectors[i + 1][prop2] += EPS;

				if (_aVectors[i][prop1] && _aVectors[i][prop1] == _aVectors[i + 1][prop1])
					_aVectors[i + 1][prop1] += EPS;

				anchors.push(defineAnchors(_aVectors[i], _aVectors[i + 1], prop1, prop2));
			}

			var totallength:UInt = anchors.length;
			var pointResult:FourPoints;

			if (totallength > 1)
			{

				for (i = 0; i < totallength; ++i)
				{

					if (i < totallength)
					{
						pointResult = definelines(i, anchors[i], anchors[i + 1], lines);
					}
					else
					{
						pointResult = definelines(i, anchors[i], anchors[i - 1], lines);
					}

					if (pointResult != null)
						lines.push(pointResult);
				}

			}
			else
			{

				var fourPoints:FourPoints = new FourPoints();
				var anchorFP:FourPoints = anchors[0];
				fourPoints.pt1 = anchorFP.pt1;
				fourPoints.pt2 = anchorFP.pt2;
				fourPoints.pt3 = anchorFP.pt3;
				fourPoints.pt4 = anchorFP.pt4;
				lines = [fourPoints];
			}

			return lines;
		}

		private function definelines(index:UInt, point1:FourPoints, point2:FourPoints = null, lines:Array = null):FourPoints
		{
			var tmppt:FourPoints;
			var fourPoints:FourPoints = new FourPoints();

			if (point2 == null)
			{
				tmppt = lines[index - 1];
				fourPoints.pt1 = tmppt.pt3;
				fourPoints.pt2 = tmppt.pt4;
				fourPoints.pt3 = point1.pt3;
				fourPoints.pt4 = point1.pt4;

				return fourPoints;
			}

			var line1:Line = buildObjectLine(point1.pt1.x, point1.pt1.y, point1.pt3.x, point1.pt3.y);
			var line2:Line = buildObjectLine(point1.pt2.x, point1.pt2.y, point1.pt4.x, point1.pt4.y);
			var line3:Line = buildObjectLine(point2.pt1.x, point2.pt1.y, point2.pt3.x, point2.pt3.y);
			var line4:Line = buildObjectLine(point2.pt2.x, point2.pt2.y, point2.pt4.x, point2.pt4.y);

			var cross1:Point = lineIntersect(line3, line1);
			var cross2:Point = lineIntersect(line2, line4);

			if (cross1 != null && cross2 != null)
			{

				if (index == 0)
				{
					fourPoints.pt1 = point1.pt1;
					fourPoints.pt2 = point1.pt2;
					fourPoints.pt3 = cross1;
					fourPoints.pt4 = cross2;

					return fourPoints;
				}

				tmppt = lines[index - 1];
				fourPoints.pt1 = tmppt.pt3;
				fourPoints.pt2 = tmppt.pt4;
				fourPoints.pt3 = cross1;
				fourPoints.pt4 = cross2;

				return fourPoints;

			}
			else
			{
				return null;
			}
		}


		private function defineAnchors(base:Vector3D, baseEnd:Vector3D, prop1:String, prop2:String):FourPoints
		{
			var angle:Float = (Math.atan2(base[prop2] - baseEnd[prop2], base[prop1] - baseEnd[prop1]) * 180) / Math.PI;
			angle -= 270;
			var angle2:Float = angle + 180;

			var fourPoints:FourPoints = new FourPoints();
			fourPoints.pt1 = new Point(base[prop1], base[prop2]);
			fourPoints.pt2 = new Point(base[prop1], base[prop2]);
			fourPoints.pt3 = new Point(baseEnd[prop1], baseEnd[prop2]);
			fourPoints.pt4 = new Point(baseEnd[prop1], baseEnd[prop2]);

			var radius:Float = _thickness * .5;

			fourPoints.pt1.x = fourPoints.pt1.x + Math.cos(-angle / 180 * Math.PI) * radius;
			fourPoints.pt1.y = fourPoints.pt1.y + Math.sin(angle / 180 * Math.PI) * radius;

			fourPoints.pt2.x = fourPoints.pt2.x + Math.cos(-angle2 / 180 * Math.PI) * radius;
			fourPoints.pt2.y = fourPoints.pt2.y + Math.sin(angle2 / 180 * Math.PI) * radius;

			fourPoints.pt3.x = fourPoints.pt3.x + Math.cos(-angle / 180 * Math.PI) * radius;
			fourPoints.pt3.y = fourPoints.pt3.y + Math.sin(angle / 180 * Math.PI) * radius;

			fourPoints.pt4.x = fourPoints.pt4.x + Math.cos(-angle2 / 180 * Math.PI) * radius;
			fourPoints.pt4.y = fourPoints.pt4.y + Math.sin(angle2 / 180 * Math.PI) * radius;

			return fourPoints;
		}

		private function buildObjectLine(origX:Float, origY:Float, endX:Float, endY:Float):Line
		{
			var line:Line = new Line();
			line.ax = origX;
			line.ay = origY;
			line.bx = endX - origX;
			line.by = endY - origY;

			return line;
		}

		private function lineIntersect(Line1:Line, Line2:Line):Point
		{
			Line1.bx = (Line1.bx == 0) ? EPS : Line1.bx;
			Line2.bx = (Line2.bx == 0) ? EPS : Line2.bx;

			var a1:Float = Line1.by / Line1.bx;
			var b1:Float = Line1.ay - a1 * Line1.ax;
			var a2:Float = Line2.by / Line2.bx;
			var b2:Float = Line2.ay - a2 * Line2.ax;
			var nzero:Float = ((a1 - a2) == 0) ? EPS : a1 - a2;
			var ptx:Float = (b2 - b1) / (nzero);
			var pty:Float = a1 * ptx + b1;

			if (isFinite(ptx) && isFinite(pty))
			{
				return new Point(ptx, pty);
			}
			else
			{
				trace("infinity");
				return null;
			}
		}

		private function initHolders():Void
		{
			if (!_uva)
			{
				_uva = new UV(0, 0);
				_uvb = new UV(0, 0);
				_uvc = new UV(0, 0);
				_uvd = new UV(0, 0);
			}

			_varr = new Vector<Vertex>();
			_varr2 = new Vector<Vertex>();
			_uvarr = new Vector<UV>();
			_uvs = new Vector<Float>();
			_vertices = new Vector<Float>();
			_indices = new Vector<UInt>();

			if (_materials)
			{
				_MaterialsSubGeometries = new Vector<SubGeometryList>();
				var sglist:SubGeometryList = new SubGeometryList();
				_MaterialsSubGeometries.push(sglist);
				sglist.subGeometry = new SubGeometry();
				_subGeometry = sglist.subGeometry;

				sglist.uvs = _uvs = new Vector<Float>();
				sglist.vertices = _vertices = new Vector<Float>();
				sglist.indices = _indices = new Vector<UInt>();
				sglist.material = this.material;
				if (sglist.material.name == null)
					sglist.material.name = "baseMaterial";

			}
			else
			{
				_subGeometry.autoDeriveVertexNormals = true;
				_subGeometry.autoDeriveVertexTangents = true;
			}
		}

		private function getSubGeometryListFromMaterial(mat:MaterialBase):SubGeometryList
		{
			var sglist:SubGeometryList;

			for (var i:UInt = 0; i < _MaterialsSubGeometries.length; ++i)
			{
				if (_MaterialsSubGeometries[i].material == mat)
				{
					sglist = _MaterialsSubGeometries[i];
					break;
				}
			}

			if (!sglist)
			{
				sglist = new SubGeometryList();
				_MaterialsSubGeometries.push(sglist);
				sglist.subGeometry = new SubGeometry();
				sglist.uvs = new Vector<Float>();
				sglist.vertices = new Vector<Float>();
				sglist.indices = new Vector<UInt>();
				sglist.material = mat;
			}

			return sglist;
		}

		/**
		 * Invalidates the geometry, causing it to be rebuilded when requested.
		 */
		private function invalidateGeometry():Void
		{
			if (_geomDirty)
				return;
			_geomDirty = true;
			invalidateBounds();
		}

	}
}
import flash.geom.Point;

import a3d.core.base.SubGeometry;
import a3d.materials.MaterialBase;

class SubGeometryList
{
	public var id:UInt;
	public var uvs:Vector<Float>;
	public var vertices:Vector<Float>;
	public var indices:Vector<UInt>;
	public var subGeometry:SubGeometry;
	public var material:MaterialBase;
}

class RenderSide
{
	public var top:Bool;
	public var bottom:Bool;
	public var right:Bool;
	public var left:Bool;
	public var front:Bool;
	public var back:Bool;
}

class Line
{
	public var ax:Float;
	public var ay:Float;
	public var bx:Float;
	public var by:Float;
}

class FourPoints
{
	public var pt1:Point;
	public var pt2:Point;
	public var pt3:Point;
	public var pt4:Point;
}
