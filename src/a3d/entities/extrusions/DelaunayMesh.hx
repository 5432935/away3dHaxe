﻿// The Delaunay triangulation code used in this class is adapted for Away from the work done by: 
// Paul Bourke's, triangulate.c (http://local.wasp.uwa.edu.au/~pbourke/papers/triangulate/triangulate.c)
// Zachary Forest Johnson

package a3d.entities.extrusions;

import flash.geom.Vector3D;
import flash.Vector;

import a3d.bounds.BoundingVolumeBase;
import a3d.core.base.Geometry;
import a3d.core.base.SubGeometry;
import a3d.core.base.SubMesh;
import a3d.core.base.data.UV;
import a3d.entities.Mesh;
import a3d.materials.MaterialBase;
import a3d.tools.helpers.MeshHelper;

class DelaunayMesh extends Mesh
{
	public static inline var PLANE_XZ:String = "xz";
	public static inline var PLANE_XY:String = "xy";
	public static inline var PLANE_ZY:String = "zy";

	private const LIMIT:UInt = 196605;
	private const EPS:Float = .0001;
	private const MAXRAD:Float = 1.2;

	private var _circle:Vector3D;
	private var _vectors:Vector<Vector3D>;
	private var _subGeometry:SubGeometry;
	private var _sortProp:String;
	private var _loopProp:String;

	private var _uvs:Vector<Float>;
	private var _vertices:Vector<Float>;
	private var _indices:Vector<UInt>;
	private var _normals:Vector<Float>;
	private var _geomDirty:Bool = true;

	private var _centerMesh:Bool;
	private var _plane:String;
	private var _flip:Bool;
	private var _smoothSurface:Bool;

	private var _axis0Min:Float;
	private var _axis0Max:Float;
	private var _axis1Min:Float;
	private var _axis1Max:Float;

	private var _tmpNormal:Vector3D;
	private var _normal0:Vector3D;
	private var _normal1:Vector3D;
	private var _normal2:Vector3D;

	/*
	* Class DelaunayMesh generates (and becomes) a mesh from a vector of vector3D's . <code>DelaunayMesh</code>
	*@param	material				MaterialBase. The material for the resulting mesh.
	*@param	vectors				Vector<Vector3D> A series of vector3d's defining the surface of the shape.
	*@param	plane					[optional] String. The destination plane: can be DelaunayMesh.PLANE_XY, DelaunayMesh.PLANE_XZ or DelaunayMesh.PLANE_ZY. Default is xz plane.
	*@param	centerMesh		[optional] Bool. If the final mesh must be centered. Default is false.
	*@param	flip					[optional] Bool. If the faces need to be inverted. Default is false.
	*@param	smoothSurface	[optional] Bool. If the surface finished needs to smooth or flat. Default is true, a smooth finish.
	*/
	public function new(material:MaterialBase, vectors:Vector<Vector3D>, plane:String = PLANE_XZ, centerMesh:Bool = false, flip:Bool = false, smoothSurface:Bool = true)
	{
		var geom:Geometry = new Geometry();
		_subGeometry = new SubGeometry();
		geom.addSubGeometry(_subGeometry);
		super(geom, material);

		_vectors = vectors;
		_centerMesh = centerMesh;
		_plane = plane;
		_flip = flip;
		_smoothSurface = smoothSurface;
	}

	/**
	* The "cloud" of vector3d's to compose the mesh
	*/
	private function get_vectors():Vector<Vector3D>
	{
		return _vectors;
	}

	private function set_vectors(val:Vector<Vector3D>):Void
	{
		if (_vectors.length < 3)
			return;

		_vectors = val;
		invalidateGeometry();
	}

	/**
	* Defines if the surface of the mesh must be smoothed or not. Default value is true.
	*/
	private function get_smoothSurface():Bool
	{
		return _smoothSurface;
	}

	private function set_smoothSurface(val:Bool):Void
	{
		if (_smoothSurface == val)
			return;

		_smoothSurface = val;
		invalidateGeometry();
	}

	/**
	* Defines the projection plane for the class. Default is xz.
	*/
	private function get_plane():String
	{
		return _plane;
	}

	private function set_plane(val:String):Void
	{
		if (_plane == val)
			return;
		if (val != PLANE_XZ && val != PLANE_XY && val != PLANE_ZY)
			return;

		_plane = val;
		invalidateGeometry();
	}

	/**
	* Defines if the face orientation needs to be inverted
	*/
	private function get_flip():Bool
	{
		return _flip;
	}

	private function set_flip(val:Bool):Void
	{
		if (_flip == val)
			return;

		_flip = val;
		invalidateGeometry();
	}

	/**
	* Defines whether the mesh is recentered of not after generation
	*/
	private function get_centerMesh():Bool
	{
		return _centerMesh;
	}

	private function set_centerMesh(val:Bool):Void
	{
		if (_centerMesh == val)
			return;

		_centerMesh = val;

		if (_centerMesh && _subGeometry.vertexData.length > 0)
		{
			MeshHelper.applyPosition(this, (this.minX + this.maxX) * .5, (this.minY + this.maxY) * .5, (this.minZ + this.maxZ) * .5);
		}
		else
		{
			invalidateGeometry();
		}
	}

	private function buildExtrude():Void
	{
		_geomDirty = false;
		if (_vectors && _vectors.length > 2)
		{
			initHolders();
			generate();
		}
		else
		{
			throw new Error("DelaunayMesh: minimum 3 Vector3D are required to generate a surface");
		}

		if (_centerMesh)
			MeshHelper.recenter(this);

	}

	private function initHolders():Void
	{
		_axis0Min = Infinity;
		_axis0Max = -Infinity;
		_axis1Min = Infinity;
		_axis1Max = -Infinity;

		_uvs = new Vector<Float>();
		_vertices = new Vector<Float>();
		_indices = new Vector<UInt>();

		_circle = new Vector3D();

		if (_smoothSurface)
		{
			_normals = new Vector<Float>();
			_normal0 = new Vector3D(0.0, 0.0, 0.0);
			_normal1 = new Vector3D(0.0, 0.0, 0.0);
			_normal2 = new Vector3D(0.0, 0.0, 0.0);
			_tmpNormal = new Vector3D(0.0, 0.0, 0.0);
			_subGeometry.autoDeriveVertexNormals = false;

		}
		else
		{
			_subGeometry.autoDeriveVertexNormals = true;
		}
		_subGeometry.autoDeriveVertexTangents = true;

	}

	private function addFace(v0:Vector3D, v1:Vector3D, v2:Vector3D, uv0:UV, uv1:UV, uv2:UV):Void
	{
		var subGeom:SubGeometry = _subGeometry;
		var uvs:Vector<Float> = _uvs;
		var vertices:Vector<Float> = _vertices;
		var indices:Vector<UInt> = _indices;

		if (_smoothSurface)
			var normals:Vector<Float> = _normals;

		if (vertices.length + 9 > LIMIT)
		{
			subGeom.updateVertexData(vertices);
			subGeom.updateIndexData(indices);
			subGeom.updateUVData(uvs);

			if (_smoothSurface)
				subGeom.updateVertexNormalData(normals);

			this.geometry.addSubGeometry(subGeom);

			subGeom = _subGeometry = new SubGeometry();
			subGeom.autoDeriveVertexTangents = true;

			uvs = _uvs = new Vector<Float>();
			vertices = _vertices = new Vector<Float>();
			indices = _indices = new Vector<UInt>();

			if (!_smoothSurface)
			{
				subGeom.autoDeriveVertexNormals = true;
			}
			else
			{
				subGeom.autoDeriveVertexNormals = false;
				normals = _normals = new Vector<Float>();
			}

			subGeom.autoDeriveVertexTangents = true;
		}

		var bv0:Bool;
		var bv1:Bool;
		var bv2:Bool;

		var ind0:UInt;
		var ind1:UInt;
		var ind2:UInt;

		if (_smoothSurface)
		{
			var uvind:UInt;
			var uvindV:UInt;
			var vind:UInt;
			var vindb:UInt;
			var vindz:UInt;
			var ind:UInt;
			var indlength:UInt = indices.length;
			calcNormal(v0, v1, v2);
			var ab:Float;

			if (indlength > 0)
			{

				for (var i:UInt = indlength - 1; i > 0; --i)
				{
					ind = indices[i];
					vind = ind * 3;
					vindb = vind + 1;
					vindz = vind + 2;
					uvind = ind * 2;
					uvindV = uvind + 1;

					if (bv0 && bv1 && bv2)
						break;

					if (!bv0 && vertices[vind] == v0.x && vertices[vindb] == v0.y && vertices[vindz] == v0.z)
					{

						_tmpNormal.x = normals[vind];
						_tmpNormal.y = normals[vindb];
						_tmpNormal.z = normals[vindz];
						ab = Vector3D.angleBetween(_tmpNormal, _normal0);

						if (ab < MAXRAD)
						{
							_normal0.x = (_tmpNormal.x + _normal0.x) * .5;
							_normal0.y = (_tmpNormal.y + _normal0.y) * .5;
							_normal0.z = (_tmpNormal.z + _normal0.z) * .5;

							bv0 = true;
							ind0 = ind;
							continue;
						}
					}

					if (!bv1 && vertices[vind] == v1.x && vertices[vindb] == v1.y && vertices[vindz] == v1.z)
					{

						_tmpNormal.x = normals[vind];
						_tmpNormal.y = normals[vindb];
						_tmpNormal.z = normals[vindz];
						ab = Vector3D.angleBetween(_tmpNormal, _normal1);

						if (ab < MAXRAD)
						{
							_normal1.x = (_tmpNormal.x + _normal1.x) * .5;
							_normal1.y = (_tmpNormal.y + _normal1.y) * .5;
							_normal1.z = (_tmpNormal.z + _normal1.z) * .5;

							bv1 = true;
							ind1 = ind;
							continue;
						}
					}

					if (!bv2 && vertices[vind] == v2.x && vertices[vindb] == v2.y && vertices[vindz] == v2.z)
					{

						_tmpNormal.x = normals[vind];
						_tmpNormal.y = normals[vindb];
						_tmpNormal.z = normals[vindz];
						ab = Vector3D.angleBetween(_tmpNormal, _normal2);

						if (ab < MAXRAD)
						{

							_normal2.x = (_tmpNormal.x + _normal2.x) * .5;
							_normal2.y = (_tmpNormal.y + _normal2.y) * .5;
							_normal2.z = (_tmpNormal.z + _normal2.z) * .5;

							bv2 = true;
							ind2 = ind;
							continue;
						}

					}
				}
			}
		}

		if (!bv0)
		{
			ind0 = vertices.length / 3;
			vertices.push(v0.x, v0.y, v0.z);
			uvs.push(uv0.u, uv0.v);
			if (_smoothSurface)
				normals.push(_normal0.x, _normal0.y, _normal0.z);
		}

		if (!bv1)
		{
			ind1 = vertices.length / 3;
			vertices.push(v1.x, v1.y, v1.z);
			uvs.push(uv1.u, uv1.v);
			if (_smoothSurface)
				normals.push(_normal1.x, _normal1.y, _normal1.z);
		}

		if (!bv2)
		{
			ind2 = vertices.length / 3;
			vertices.push(v2.x, v2.y, v2.z);
			uvs.push(uv2.u, uv2.v);
			if (_smoothSurface)
				normals.push(_normal2.x, _normal2.y, _normal2.z);
		}

		indices.push(ind0, ind1, ind2);
	}

	private function generate():Void
	{
		getVectorsBounds();

		var w:Float = _axis0Max - _axis0Min;
		var h:Float = _axis1Max - _axis1Min;

		var offW:Float = (_axis0Min > 0) ? -_axis0Min : Math.abs(_axis0Min);
		var offH:Float = (_axis1Min > 0) ? -_axis1Min : Math.abs(_axis1Min);

		var uv0:UV = new UV();
		var uv1:UV = new UV();
		var uv2:UV = new UV();

		var v0:Vector3D;
		var v1:Vector3D;
		var v2:Vector3D;

		var limit:UInt = _vectors.length;

		if (limit > 3)
		{
			var nVectors:Vector<Vector3D> = new Vector<Vector3D>();
			nVectors = _vectors.sort(sortFunction);

			var i:UInt;
			var j:UInt;
			var k:UInt;
			var v:Vector<Tri> = new Vector<Tri>();
			var nv:UInt = nVectors.length;

			for (i in 0...(nv * 3))
				v[i] = new Tri();

			var bList:Vector<Bool> = new Vector<Bool>();
			var edges:Array = [];
			var nEdge:UInt = 0;
			var maxTris:UInt = 4 * nv;
			var maxEdges:UInt = nv * 2;

			for (i in 0...maxTris)
				bList[i] = false;

			var inside:Bool;
			var valA:Float;
			var valB:Float;
			var x1:Float;
			var y1:Float;
			var x2:Float;
			var y2:Float;
			var x3:Float;
			var y3:Float;
			// TODO: not used
			// var xc:Float;
			// TODO: not used
			// var yc:Float;

			var sortMin:Float;
			var sortMax:Float;
			var loopMin:Float;
			var loopMax:Float;
			var sortMid:Float;
			var loopMid:Float;
			var ntri:UInt = 1;

			for (i in 0...maxEdges)
				edges[i] = new Edge();

			sortMin = nVectors[0][_sortProp];
			loopMin = nVectors[0][_loopProp];
			sortMax = sortMin;
			loopMax = loopMin;

			for (i in 1...nv)
			{
				if (nVectors[i][_sortProp] < sortMin)
					sortMin = nVectors[i][_sortProp];
				if (nVectors[i][_sortProp] > sortMax)
					sortMax = nVectors[i][_sortProp];
				if (nVectors[i][_loopProp] < loopMin)
					loopMin = nVectors[i][_loopProp];
				if (nVectors[i][_loopProp] > loopMax)
					loopMax = nVectors[i][_loopProp];
			}

			var da:Float = sortMax - sortMin;
			var db:Float = loopMax - loopMin;
			var dmax:Float = (da > db) ? da : db;
			sortMid = (sortMax + sortMin) * .5;
			loopMid = (loopMax + loopMin) * .5;

			nVectors[nv] = new Vector3D(0.0, 0.0, 0.0);
			nVectors[nv + 1] = new Vector3D(0.0, 0.0, 0.0);
			nVectors[nv + 2] = new Vector3D(0.0, 0.0, 0.0);

			var offset:Float = 2.0;
			nVectors[nv + 0][_sortProp] = sortMid - offset * dmax;
			nVectors[nv + 0][_loopProp] = loopMid - dmax;

			nVectors[nv + 1][_sortProp] = sortMid;
			nVectors[nv + 1][_loopProp] = loopMid + offset * dmax;

			nVectors[nv + 2][_sortProp] = sortMid + offset * dmax;
			nVectors[nv + 2][_loopProp] = loopMid - dmax;

			v[0].v0 = nv;
			v[0].v1 = nv + 1;
			v[0].v2 = nv + 2;
			bList[0] = false;

			for (i in 0...nv)
			{

				valA = vectors[i][_sortProp];
				valB = vectors[i][_loopProp];
				nEdge = 0;

				for (j  in 0...ntri)
				{

					if (bList[j])
						continue;

					x1 = nVectors[v[j].v0][_sortProp];
					y1 = nVectors[v[j].v0][_loopProp];
					x2 = nVectors[v[j].v1][_sortProp];
					y2 = nVectors[v[j].v1][_loopProp];
					x3 = nVectors[v[j].v2][_sortProp];
					y3 = nVectors[v[j].v2][_loopProp];

					inside = circumCircle(valA, valB, x1, y1, x2, y2, x3, y3);

					if (_circle.x + _circle.z < valA)
						bList[j] = true;

					if (inside)
					{
						if (nEdge + 3 >= maxEdges)
						{
							maxEdges += 3;
							edges.push(new Edge(), new Edge(), new Edge());
						}
						edges[nEdge].v0 = v[j].v0;
						edges[nEdge].v1 = v[j].v1;
						edges[nEdge + 1].v0 = v[j].v1;
						edges[nEdge + 1].v1 = v[j].v2;
						edges[nEdge + 2].v0 = v[j].v2;
						edges[nEdge + 2].v1 = v[j].v0;
						nEdge += 3;
						ntri--;
						v[j].v0 = v[ntri].v0;
						v[j].v1 = v[ntri].v1;
						v[j].v2 = v[ntri].v2;
						bList[j] = bList[ntri];
						j--;

					}
				}

				for (j  in 0...nEdge - 1)
				{

					for (k in (j+1)...nEdge)
					{

						if ((edges[j].v0 == edges[k].v1) && (edges[j].v1 == edges[k].v0))
							edges[j].v0 = edges[j].v1 = edges[k].v0 = edges[k].v1 = -1;

						if ((edges[j].v0 == edges[k].v0) && (edges[j].v1 == edges[k].v1))
							edges[j].v0 = edges[j].v1 = edges[k].v0 = edges[k].v1 = -1;
					}
				}

				for (j in 0...nEdge)
				{

					if (edges[j].v0 == -1 || edges[j].v1 == -1)
						continue;

					if (ntri >= maxTris)
						continue;

					v[ntri].v0 = edges[j].v0;
					v[ntri].v1 = edges[j].v1;
					v[ntri].v2 = i;

					bList[ntri] = false;

					ntri++;
				}
			}

			for (i in 0...ntri)
			{

				if (v[i].v0 == v[i].v1 && v[i].v1 == v[i].v2)
					continue;

				if ((v[i].v0 >= limit || v[i].v1 >= limit || v[i].v2 >= limit))
				{
					v[i] = v[ntri - 1];
					ntri--;
					i--;
					continue;
				}

				v0 = nVectors[v[i].v0];
				v1 = nVectors[v[i].v1];
				v2 = nVectors[v[i].v2];

				uv0.u = (v0[_loopProp] + offW) / w;
				uv0.v = 1 - (v0[_sortProp] + offH) / h;

				uv1.u = (v1[_loopProp] + offW) / w;
				uv1.v = 1 - (v1[_sortProp] + offH) / h;

				uv2.u = (v2[_loopProp] + offW) / w;
				uv2.v = 1 - (v2[_sortProp] + offH) / h;

				if (_flip)
				{
					addFace(v0, v1, v2, uv0, uv1, uv2);
				}
				else
				{
					addFace(v1, v0, v2, uv1, uv0, uv2);
				}

			}

			if (_smoothSurface)
				_subGeometry.updateVertexNormalData(_normals);

			for (i in 0...v.length)
				v[i] = null;

			v = null;
			nVectors = null;

		}
		else
		{

			v0 = _vectors[0];
			v1 = _vectors[1];
			v2 = _vectors[2];

			_vertices.push(v0.x, v0.y, v0.z, v1.x, v1.y, v1.z, v2.x, v2.y, v2.z);

			uv0.u = (v0[_loopProp] + offW) / w;
			uv0.v = 1 - (v0[_sortProp] + offH) / h;

			uv1.u = (v1[_loopProp] + offW) / w;
			uv1.v = 1 - (v1[_sortProp] + offH) / h;

			uv2.u = (v2[_loopProp] + offW) / w;
			uv2.v = 1 - (v2[_sortProp] + offH) / h;

			_uvs.push(uv0.u, uv0.v, uv1.u, uv1.v, uv2.u, uv2.v);

			if (_flip)
			{
				_indices.push(1, 0, 2);
			}
			else
			{
				_indices.push(0, 1, 2);
			}

			_subGeometry.autoDeriveVertexNormals = true;
		}

		_subGeometry.updateVertexData(_vertices);
		_subGeometry.updateIndexData(_indices);
		_subGeometry.updateUVData(_uvs);

	}

	private function sortFunction(v0:Vector3D, v1:Vector3D):Int
	{
		var a:Float = v0[_sortProp];
		var b:Float = v1[_sortProp];
		if (a == b)
			return 0;
		else if (a < b)
			return 1;
		else
			return -1;
	}

	private function calcNormal(v0:Vector3D, v1:Vector3D, v2:Vector3D):Void
	{
		var da1:Float = v2.x - v0.x;
		var db1:Float = v2.y - v0.y;
		var dz1:Float = v2.z - v0.z;
		var da2:Float = v1.x - v0.x;
		var db2:Float = v1.y - v0.y;
		var dz2:Float = v1.z - v0.z;

		var cx:Float = dz1 * db2 - db1 * dz2;
		var cy:Float = da1 * dz2 - dz1 * da2;
		var cz:Float = db1 * da2 - da1 * db2;
		var d:Float = 1 / Math.sqrt(cx * cx + cy * cy + cz * cz);

		_normal0.x = _normal1.x = _normal2.x = cx * d;
		_normal0.y = _normal1.y = _normal2.y = cy * d;
		_normal0.z = _normal1.z = _normal2.z = cz * d;
	}

	private function getVectorsBounds():Void
	{
		var i:UInt;
		var v:Vector3D;
		switch (_plane)
		{
			case PLANE_XZ:
				_sortProp = "z";
				_loopProp = "x";
				for (i in 0..._vectors.length)
				{
					v = _vectors[i];
					if (v.x < _axis0Min)
						_axis0Min = v.x;
					if (v.x > _axis0Max)
						_axis0Max = v.x;
					if (v.z < _axis1Min)
						_axis1Min = v.z;
					if (v.z > _axis1Max)
						_axis1Max = v.z;
				}
				

			case PLANE_XY:
				_sortProp = "y";
				_loopProp = "x";
				for (i in 0..._vectors.length)
				{
					v = _vectors[i];
					if (v.x < _axis0Min)
						_axis0Min = v.x;
					if (v.x > _axis0Max)
						_axis0Max = v.x;
					if (v.y < _axis1Min)
						_axis1Min = v.y;
					if (v.y > _axis1Max)
						_axis1Max = v.y;
				}
			case PLANE_ZY:
				_sortProp = "y";
				_loopProp = "z";
				for (i in 0..._vectors.length)
				{
					v = _vectors[i];
					if (v.z < _axis0Min)
						_axis0Min = v.z;
					if (v.z > _axis0Max)
						_axis0Max = v.z;
					if (v.y < _axis1Min)
						_axis1Min = v.y;
					if (v.y > _axis1Max)
						_axis1Max = v.y;
				}

		}
	}


	/**
	 * @inheritDoc
	 */
	override private function get_bounds():BoundingVolumeBase
	{
		if (_geomDirty)
			buildExtrude();

		return super.bounds;
	}

	/**
	 * @inheritDoc
	 */
	override private function get_geometry():Geometry
	{
		if (_geomDirty)
			buildExtrude();

		return super.geometry;
	}

	/**
	 * @inheritDoc
	 */
	override private function get_subMeshes():Vector<SubMesh>
	{
		if (_geomDirty)
			buildExtrude();

		return super.subMeshes;
	}

	private function invalidateGeometry():Void
	{
		_geomDirty = true;
		invalidateBounds();
	}

	private function circumCircle(xp:Float, yp:Float, x1:Float, y1:Float, x2:Float, y2:Float, x3:Float, y3:Float):Bool
	{
		var m1:Float;
		var m2:Float;
		var mx1:Float;
		var mx2:Float;
		var my1:Float;
		var my2:Float;
		var da:Float;
		var db:Float;
		var rsqr:Float;
		var drsqr:Float;
		var xc:Float;
		var yc:Float;

		if (Math.abs(y1 - y2) < EPS && Math.abs(y2 - y3) < EPS)
			return false;

		if (Math.abs(y2 - y1) < EPS)
		{
			m2 = -(x3 - x2) / (y3 - y2);
			mx2 = (x2 + x3) * .5;
			my2 = (y2 + y3) * .5;
			xc = (x2 + x1) * .5;
			yc = m2 * (xc - mx2) + my2;

		}
		else if (Math.abs(y3 - y2) < EPS)
		{
			m1 = -(x2 - x1) / (y2 - y1);
			mx1 = (x1 + x2) * .5;
			my1 = (y1 + y2) * .5;
			xc = (x3 + x2) * .5;
			yc = m1 * (xc - mx1) + my1;

		}
		else
		{
			m1 = -(x2 - x1) / (y2 - y1);
			m2 = -(x3 - x2) / (y3 - y2);
			mx1 = (x1 + x2) * .5;
			mx2 = (x2 + x3) * .5;
			my1 = (y1 + y2) * .5;
			my2 = (y2 + y3) * .5;
			xc = (m1 * mx1 - m2 * mx2 + my2 - my1) / (m1 - m2);
			yc = m1 * (xc - mx1) + my1;
		}

		da = x2 - xc;
		db = y2 - yc;
		rsqr = da * da + db * db;

		da = xp - xc;
		db = yp - yc;
		drsqr = da * da + db * db;

		_circle.x = xc;
		_circle.y = yc;
		_circle.z = Math.sqrt(rsqr);

		return Bool(drsqr <= rsqr);
	}
}
class Tri
{
	public var v0:Int;
	public var v1:Int;
	public var v2:Int;
}

class Edge
{
	public var v0:Int;
	public var v1:Int;
}
