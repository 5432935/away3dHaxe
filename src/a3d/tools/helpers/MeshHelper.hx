package a3d.tools.helpers;

import flash.geom.Matrix3D;
import flash.geom.Vector3D;
import flash.utils.Dictionary;
import flash.Vector;


import a3d.core.base.CompactSubGeometry;
import a3d.core.base.Geometry;
import a3d.core.base.ISubGeometry;
import a3d.core.base.Object3D;
import a3d.core.base.SubGeometry;
import a3d.core.base.data.UV;
import a3d.core.base.data.Vertex;
import a3d.entities.Mesh;
import a3d.entities.ObjectContainer3D;
import a3d.materials.MaterialBase;
import a3d.materials.utils.DefaultMaterialManager;
import a3d.tools.utils.Bounds;
import a3d.tools.utils.GeomUtil;



/**
 * Helper Class for the Mesh object <code>MeshHelper</code>
 * A series of methods usually usefull for mesh manipulations
 */

class MeshHelper
{
	private static inline var LIMIT:UInt = 196605;

	/**
	 * Returns the boundingRadius of an Entity of a Mesh.
	 * @param mesh		Mesh. The mesh to get the boundingRadius from.
	 */
	public static function boundingRadius(mesh:Mesh):Float
	{
		var radius:Float;
		try
		{
			radius = Math.max((mesh.maxX - mesh.minX) * Object3D(mesh).scaleX, (mesh.maxY - mesh.minY) * Object3D(mesh).scaleY, (mesh.maxZ - mesh.minZ) * Object3D(mesh).scaleZ);
		}
		catch (e:Error)
		{
			Bounds.getMeshBounds(mesh);
			radius = Math.max((Bounds.maxX - Bounds.minX) * Object3D(mesh).scaleX, (Bounds.maxY - Bounds.minY) * Object3D(mesh).scaleY, (Bounds.maxZ - Bounds.minZ) * Object3D(mesh).scaleZ);
		}

		return radius * .5;
	}

	/**
	 * Returns the boundingRadius of a ObjectContainer3D
	 * @param container		ObjectContainer3D. The ObjectContainer3D and its children to get the boundingRadius from.
	 */
	public static function boundingRadiusContainer(container:ObjectContainer3D):Float
	{
		Bounds.getObjectContainerBounds(container);
		var radius:Float = Math.max((Bounds.maxX - Bounds.minX) * Object3D(container).scaleX, (Bounds.maxY - Bounds.minY) * Object3D(container).scaleY, (Bounds.maxZ - Bounds.minZ) * Object3D(container).
			scaleZ);
		return radius * .5;
	}

	/**
	 * Recenter geometry
	 * @param mesh				Mesh. The Mesh to recenter in its own objectspace
	 * @param keepPosition	Bool. KeepPosition applys the offset to the object position. Object is "visually" at same position.
	 */
	public static function recenter(mesh:Mesh, keepPosition:Bool = true):Void
	{
		Bounds.getMeshBounds(mesh);

		var dx:Float = (Bounds.minX + Bounds.maxX) * .5;
		var dy:Float = (Bounds.minY + Bounds.maxY) * .5;
		var dz:Float = (Bounds.minZ + Bounds.maxZ) * .5;

		applyPosition(mesh, -dx, -dy, -dz);

		if (!keepPosition)
		{
			mesh.x -= dx;
			mesh.y -= dy;
			mesh.z -= dz;
		}
	}

	/**
	 * Recenter geometry of all meshes found into container
	 * @param mesh				Mesh. The Mesh to recenter in its own objectspace
	 * @param keepPosition	Bool. KeepPosition applys the offset to the object position. Object is "visually" at same position.
	 */
	public static function recenterContainer(obj:ObjectContainer3D, keepPosition:Bool = true):Void
	{
		var child:ObjectContainer3D;

		if (Std.is(obj,Mesh) && ObjectContainer3D(obj).numChildren == 0)
			recenter(Mesh(obj), keepPosition);

		for (var i:UInt = 0; i < ObjectContainer3D(obj).numChildren; ++i)
		{
			child = ObjectContainer3D(obj).getChildAt(i);
			recenterContainer(child, keepPosition);
		}

	}

	/**
	 * Applys the rotation values of a mesh in object space and resets rotations to zero.
	 * @param mesh				Mesh. The Mesh to alter
	 */
	public static function applyRotations(mesh:Mesh):Void
	{
		var i:UInt, j:UInt, len:UInt, vStride:UInt, vOffs:UInt, nStride:UInt, nOffs:UInt;
		var geometry:Geometry = mesh.geometry;
		var geometries:Vector<ISubGeometry> = geometry.subGeometries;
		var vertices:Vector<Float>;
		var normals:Vector<Float>;
		var numSubGeoms:UInt = geometries.length;
		var subGeom:ISubGeometry;
		var t:Matrix3D = mesh.transform.clone();
		t.appendScale(1 / mesh.scaleX, 1 / mesh.scaleY, 1 / mesh.scaleZ);
		var holder:Vector3D = new Vector3D();

		for (i = 0; i < numSubGeoms; ++i)
		{
			subGeom = ISubGeometry(geometries[i]);
			vertices = subGeom.vertexData;
			vOffs = subGeom.vertexOffset;
			vStride = subGeom.vertexStride;
			normals = subGeom.vertexNormalData;
			nOffs = subGeom.vertexNormalOffset;
			nStride = subGeom.vertexNormalStride;
			len = subGeom.numVertices;

			for (j = 0; j < len; j++)
			{
				//verts
				holder.x = vertices[vOffs + j * vStride + 0];
				holder.y = vertices[vOffs + j * vStride + 1];
				holder.z = vertices[vOffs + j * vStride + 2];

				holder = t.deltaTransformVector(holder);

				vertices[vOffs + j * vStride + 0] = holder.x;
				vertices[vOffs + j * vStride + 1] = holder.y;
				vertices[vOffs + j * vStride + 2] = holder.z;
				//norms
				holder.x = normals[nOffs + j * nStride + 0];
				holder.y = normals[nOffs + j * nStride + 1];
				holder.z = normals[nOffs + j * nStride + 2];

				holder = t.deltaTransformVector(holder);
				holder.normalize();

				normals[nOffs + j * nStride + 0] = holder.x;
				normals[nOffs + j * nStride + 1] = holder.y;
				normals[nOffs + j * nStride + 2] = holder.z;
			}

			if (Std.is(subGeom,CompactSubGeometry))
			{
				CompactSubGeometry(subGeom).updateData(vertices);
			}
			else
			{
				SubGeometry(subGeom).updateVertexData(vertices);
				SubGeometry(subGeom).updateVertexNormalData(normals);
			}
		}

		mesh.rotationX = mesh.rotationY = mesh.rotationZ = 0;
	}

	/**
	 * Applys the rotation values of each mesh found into an ObjectContainer3D
	 * @param obj				ObjectContainer3D. The ObjectContainer3D to alter
	 */
	public static function applyRotationsContainer(obj:ObjectContainer3D):Void
	{
		var child:ObjectContainer3D;

		if (Std.is(obj,Mesh) && ObjectContainer3D(obj).numChildren == 0)
			applyRotations(Mesh(obj));

		for (var i:UInt = 0; i < ObjectContainer3D(obj).numChildren; ++i)
		{
			child = ObjectContainer3D(obj).getChildAt(i);
			applyRotationsContainer(child);
		}

	}

	/**
	 * Applys the scaleX, scaleY and scaleZ scale factors to the mesh vertices. Resets the mesh scaleX, scaleY and scaleZ properties to 1;
	 * @param mesh				Mesh. The Mesh to rescale
	 * @param scaleX			Number. The scale factor to apply on all vertices x values.
	 * @param scaleY			Number. The scale factor to apply on all vertices y values.
	 * @param scaleZ			Number. The scale factor to apply on all vertices z values.
	 * @param parent			ObjectContainer3D. If a parent is set, the position of children is also scaled
	 */
	public static function applyScales(mesh:Mesh, scaleX:Float, scaleY:Float, scaleZ:Float, parent:ObjectContainer3D = null):Void
	{
		if (scaleX == 1 && scaleY == 1 && scaleZ == 1)
			return;

		if (mesh.animator)
		{
			mesh.scaleX = scaleX;
			mesh.scaleY = scaleY;
			mesh.scaleZ = scaleZ;
			return;
		}

		var i:UInt, j:UInt, len:UInt, vStride:UInt, vOffs:UInt;
		var geometry:Geometry = mesh.geometry;
		var geometries:Vector<ISubGeometry> = geometry.subGeometries;
		var vertices:Vector<Float>;
		var numSubGeoms:UInt = geometries.length;
		var subGeom:ISubGeometry;

		for (i = 0; i < numSubGeoms; ++i)
		{
			subGeom = ISubGeometry(geometries[i]);
			vOffs = subGeom.vertexOffset;
			vStride = subGeom.vertexStride;
			vertices = subGeom.vertexData;
			len = subGeom.numVertices;

			for (j = 0; j < len; j++)
			{
				vertices[vOffs + j * vStride + 0] *= scaleX;
				vertices[vOffs + j * vStride + 1] *= scaleY;
				vertices[vOffs + j * vStride + 2] *= scaleZ;
			}

			if (Std.is(subGeom,CompactSubGeometry))
				CompactSubGeometry(subGeom).updateData(vertices);
			else
				SubGeometry(subGeom).updateVertexData(vertices);
		}

		mesh.scaleX = mesh.scaleY = mesh.scaleZ = 1;

		if (parent)
		{
			mesh.x *= scaleX;
			mesh.y *= scaleY;
			mesh.z *= scaleZ;
		}
	}

	/**
	 * Applys the scale properties values of each mesh found into an ObjectContainer3D
	 * @param obj				ObjectContainer3D. The ObjectContainer3D to alter
	 * @param scaleX			Number. The scale factor to apply on all vertices x values.
	 * @param scaleY			Number. The scale factor to apply on all vertices y values.
	 * @param scaleZ			Number. The scale factor to apply on all vertices z values.
	 */
	public static function applyScalesContainer(obj:ObjectContainer3D, scaleX:Float, scaleY:Float, scaleZ:Float, parent:ObjectContainer3D = null):Void
	{
		parent = parent;

		var child:ObjectContainer3D;

		if (Std.is(obj,Mesh) && ObjectContainer3D(obj).numChildren == 0)
			applyScales(Mesh(obj), scaleX, scaleY, scaleZ, obj);

		for (var i:UInt = 0; i < ObjectContainer3D(obj).numChildren; ++i)
		{
			child = ObjectContainer3D(obj).getChildAt(i);
			applyScalesContainer(child, scaleX, scaleY, scaleZ, obj);
		}
	}

	/**
	 * Applys an offset to a mesh at vertices level
	 * @param mesh				Mesh. The Mesh to offset
	 * @param dx					Number. The offset along the x axis
	 * @param dy					Number. The offset along the y axis
	 * @param dz					Number. The offset along the z axis
	 */
	public static function applyPosition(mesh:Mesh, dx:Float, dy:Float, dz:Float):Void
	{
		var i:UInt, j:UInt, len:UInt, vStride:UInt, vOffs:UInt;
		var geometry:Geometry = mesh.geometry;
		var geometries:Vector<ISubGeometry> = geometry.subGeometries;
		var vertices:Vector<Float>;
		var numSubGeoms:UInt = geometries.length;
		var subGeom:ISubGeometry;

		for (i = 0; i < numSubGeoms; ++i)
		{
			subGeom = ISubGeometry(geometries[i]);
			vOffs = subGeom.vertexOffset;
			vStride = subGeom.vertexStride;
			vertices = subGeom.vertexData;
			len = subGeom.numVertices;

			for (j = 0; j < len; j++)
			{
				vertices[vOffs + j * vStride + 0] += dx;
				vertices[vOffs + j * vStride + 1] += dy;
				vertices[vOffs + j * vStride + 2] += dz;
			}

			if (Std.is(subGeom,CompactSubGeometry))
				CompactSubGeometry(subGeom).updateData(vertices);
			else
				SubGeometry(subGeom).updateVertexData(vertices);
		}

		mesh.x -= dx;
		mesh.y -= dy;
		mesh.z -= dz;
	}

	/**
	 * Clones a Mesh
	 * @param mesh				Mesh. The mesh to clone
	 * @param newname		[optional] String. new name for the duplicated mesh. Default = "";
	 *
	 * @ returns Mesh
	 */
	public static function clone(mesh:Mesh, newName:String = ""):Mesh
	{
		var geometry:Geometry = mesh.geometry.clone();
		var newMesh:Mesh = new Mesh(geometry, mesh.material);
		newMesh.name = newName;

		return newMesh;
	}

	/**
	 * Inverts the faces of all the Meshes into an ObjectContainer3D
	 * @param obj		ObjectContainer3D. The ObjectContainer3D to invert.
	 */
	public static function invertFacesInContainer(obj:ObjectContainer3D):Void
	{
		var child:ObjectContainer3D;

		if (Std.is(obj,Mesh) && ObjectContainer3D(obj).numChildren == 0)
			invertFaces(Mesh(obj));

		for (var i:UInt = 0; i < ObjectContainer3D(obj).numChildren; ++i)
		{
			child = ObjectContainer3D(obj).getChildAt(i);
			invertFacesInContainer(child);
		}

	}

	/**
	 * Inverts the faces of a Mesh
	 * @param mesh		Mesh. The Mesh to invert.
	 * @param invertUV		Bool. If the uvs are inverted too. Default is false;
	 */
	public static function invertFaces(mesh:Mesh, invertU:Bool = false):Void
	{
		var i:UInt, j:UInt, len:UInt, tStride:UInt, tOffs:UInt, nStride:UInt, nOffs:UInt, uStride:UInt, uOffs:UInt;
		var geometry:Geometry = mesh.geometry;
		var geometries:Vector<ISubGeometry> = geometry.subGeometries;
		var indices:Vector<UInt>;
		var indicesC:Vector<UInt>;
		var normals:Vector<Float>;
		var tangents:Vector<Float>;
		var uvs:Vector<Float>;
		var numSubGeoms:UInt = geometries.length;
		var subGeom:ISubGeometry;

		for (i = 0; i < numSubGeoms; ++i)
		{
			subGeom = ISubGeometry(geometries[i]);
			indices = subGeom.indexData;
			indicesC = subGeom.indexData.concat();

			normals = subGeom.vertexNormalData;
			nOffs = subGeom.vertexNormalOffset;
			nStride = subGeom.vertexNormalStride;

			uvs = subGeom.UVData;
			uOffs = subGeom.UVOffset;
			uStride = subGeom.UVStride;
			len = subGeom.numVertices;

			tangents = subGeom.vertexTangentData;
			tOffs = subGeom.vertexTangentOffset;
			tStride = subGeom.vertexTangentStride;

			for (i = 0; i < indices.length; i += 3)
			{
				indices[i + 0] = indicesC[i + 2];
				indices[i + 1] = indicesC[i + 1];
				indices[i + 2] = indicesC[i + 0];
			}

			for (j = 0; j < len; j++)
			{

				normals[nOffs + j * nStride + 0] *= -1;
				normals[nOffs + j * nStride + 1] *= -1;
				normals[nOffs + j * nStride + 2] *= -1;

				tangents[tOffs + j * tStride + 0] *= -1;
				tangents[tOffs + j * tStride + 1] *= -1;
				tangents[tOffs + j * tStride + 2] *= -1;

				if (invertU)
					uvs[uOffs + j * uStride + 0] = 1 - uvs[uOffs + j * uStride + 0];

			}

			if (Std.is(subGeom,CompactSubGeometry))
			{
				CompactSubGeometry(subGeom).updateData(subGeom.vertexData);
			}
			else
			{
				SubGeometry(subGeom).updateIndexData(indices);
				SubGeometry(subGeom).updateVertexNormalData(normals);
				SubGeometry(subGeom).updateVertexTangentData(tangents);
				SubGeometry(subGeom).updateUVData(uvs);
			}
		}
	}

	/**
	 * Build a Mesh from Vectors
	 * @param vertices				Vector.&lt;Number&gt;. The vertices Vector.&lt;Number&gt;, must hold a multiple of 3 numbers.
	 * @param indices				Vector.&lt;uint&gt;. The indices Vector.&lt;uint&gt;, holding the face order
	 * @param uvs					[optional] Vector.&lt;Number&gt;. The uvs Vector, must hold a series of numbers of (vertices.length/3 * 2) entries. If none is set, default uv's are applied
	 * if no uv's are defined, default uv mapping is set.
	 * @param name					[optional] String. new name for the generated mesh. Default = "";
	 * @param material				[optional] MaterialBase. new name for the duplicated mesh. Default = null;
	 * @param shareVertices		[optional] Bool. Defines if the vertices are shared or not. When true surface gets a smoother appearance when exposed to light. Default = true;
	 * @param useDefaultMap	[optional] Bool. Defines if the mesh receives the default engine map if no material is passes. Default = true;
	 *
	 * @ returns Mesh
	 */
	public static function build(vertices:Vector<Float>, indices:Vector<UInt>, uvs:Vector<Float> = null, name:String = "", material:MaterialBase = null, shareVertices:Bool = true, useDefaultMap:Bool =
		true, useCompactSubGeometry:Bool = true):Mesh
	{
		var i:UInt;

		if (useCompactSubGeometry)
		{
			var subGeoms:Vector<ISubGeometry> = GeomUtil.fromVectors(vertices, indices, uvs, null, null, null, null);
			var geometry:Geometry = new Geometry();

			for (i = 0; i < subGeoms.length; i++)
			{
				subGeoms[i].autoDeriveVertexNormals = true;
				subGeoms[i].autoDeriveVertexTangents = true;
				geometry.addSubGeometry(subGeoms[i]);
			}

			material = (!material) ? DefaultMaterialManager.getDefaultMaterial() : material;
			var m:Mesh = new Mesh(geometry, material);

			if (name != "")
				m.name = name;
			return m;
		}
		else
		{
			var subGeom:SubGeometry = new SubGeometry();
			subGeom.autoDeriveVertexNormals = true;
			subGeom.autoDeriveVertexTangents = true;
			geometry = new Geometry();
			geometry.addSubGeometry(subGeom);

			material = (!material && useDefaultMap) ? DefaultMaterialManager.getDefaultMaterial() : material;
			m = new Mesh(geometry, material);

			if (name != "")
				m.name = name;

			var nvertices:Vector<Float> = new Vector<Float>();
			var nuvs:Vector<Float> = new Vector<Float>();
			var nindices:Vector<UInt> = new Vector<UInt>();

			var defaultUVS:Vector<Float> = Vector<Float>([0, 1, .5, 0, 1, 1, .5, 0]);
			var uvid:UInt = 0;

			if (shareVertices)
			{
				var dShared:Dictionary = new Dictionary();
				var uv:UV = new UV();
				var ref:String;
			}

			var uvind:UInt;
			var vind:UInt;
			var ind:UInt;
			//var j:UInt;
			var vertex:Vertex = new Vertex();

			for (i = 0; i < indices.length; ++i)
			{
				ind = indices[i] * 3;
				vertex.x = vertices[ind];
				vertex.y = vertices[ind + 1];
				vertex.z = vertices[ind + 2];

				if (nvertices.length == LIMIT)
				{
					subGeom.updateVertexData(nvertices);
					subGeom.updateIndexData(nindices);
					subGeom.updateUVData(nuvs);

					if (shareVertices)
					{
						dShared = null;
						dShared = new Dictionary();
					}

					subGeom = new SubGeometry();
					subGeom.autoDeriveVertexNormals = true;
					subGeom.autoDeriveVertexTangents = true;
					geometry.addSubGeometry(subGeom);

					uvid = 0;

					nvertices = new Vector<Float>();
					nindices = new Vector<UInt>();
					nuvs = new Vector<Float>();
				}

				vind = nvertices.length / 3;
				uvind = indices[i] * 2;

				if (shareVertices)
				{
					uv.u = uvs[uvind];
					uv.v = uvs[uvind + 1];
					ref = vertex.toString() + uv.toString();
					if (dShared[ref])
					{
						nindices[nindices.length] = dShared[ref];
						continue;
					}
					dShared[ref] = vind;
				}

				nindices[nindices.length] = vind;
				nvertices.push(vertex.x, vertex.y, vertex.z);

				if (!uvs || uvind > uvs.length - 2)
				{
					nuvs.push(defaultUVS[uvid], defaultUVS[uvid + 1]);
					uvid = (uvid + 2 > 3) ? 0 : uvid += 2;

				}
				else
				{
					nuvs.push(uvs[uvind], uvs[uvind + 1]);
				}
			}

			if (shareVertices)
				dShared = null;

			subGeom.updateVertexData(nvertices);
			subGeom.updateIndexData(nindices);
			subGeom.updateUVData(nuvs);

			return m;
		}
	}

	/**
	 * Splits the subgeometries of a given mesh in a series of new meshes
	 * @param mesh					Mesh. The mesh to split in a series of independant meshes from its subgeometries.
	 * @param disposeSource		Bool. If the mesh source must be destroyed after the split. Default is false;
	 *
	 * @ returns Vector..&lt;Mesh&gt;
	 */
	public static function splitMesh(mesh:Mesh, disposeSource:Bool = false):Vector<Mesh>
	{
		var meshes:Vector<Mesh> = new Vector<Mesh>();
		var geometries:Vector<ISubGeometry> = mesh.geometry.subGeometries;
		var numSubGeoms:UInt = geometries.length;

		if (numSubGeoms == 1)
		{
			meshes.push(mesh);
			return meshes;
		}

		if (Std.is(geometries[0],ompactSubGeometry))
			return splitMeshCsg(mesh, disposeSource);

		var vertices:Vector<Float>;
		var indices:Vector<UInt>;
		var uvs:Vector<Float>;
		var normals:Vector<Float>;
		var tangents:Vector<Float>;
		var subGeom:ISubGeometry;

		var nGeom:Geometry;
		var nSubGeom:SubGeometry;
		var nm:Mesh;

		var nMeshMat:MaterialBase;
		var j:UInt = 0;

		for (var i:UInt = 0; i < numSubGeoms; ++i)
		{
			if (Std.is(geometries[0],SubGeometry))
				subGeom = SubGeometry(geometries[i]);

			vertices = subGeom.vertexData;
			indices = subGeom.indexData;
			uvs = subGeom.UVData;

			try
			{
				normals = subGeom.vertexNormalData;
				subGeom.autoDeriveVertexNormals = false;
			}
			catch (e:Error)
			{
				subGeom.autoDeriveVertexNormals = true;
				normals = new Vector<Float>();
				j = 0;
				while (j < vertices.length)
					normals[j++] = 0.0;
			}

			try
			{
				tangents = subGeom.vertexTangentData;
				subGeom.autoDeriveVertexTangents = false;
			}
			catch (e:Error)
			{
				subGeom.autoDeriveVertexTangents = true;
				tangents = new Vector<Float>();
				j = 0;
				while (j < vertices.length)
					tangents[j++] = 0.0;
			}

			vertices.fixed = false;
			indices.fixed = false;
			uvs.fixed = false;
			normals.fixed = false;
			tangents.fixed = false;

			nGeom = new Geometry();
			nm = new Mesh(nGeom, mesh.subMeshes[i].material ? mesh.subMeshes[i].material : nMeshMat);

			nSubGeom = new SubGeometry();
			nSubGeom.updateVertexData(vertices);
			nSubGeom.updateIndexData(indices);
			nSubGeom.updateUVData(uvs);
			nSubGeom.updateVertexNormalData(normals);
			nSubGeom.updateVertexTangentData(tangents);

			nGeom.addSubGeometry(nSubGeom);

			meshes.push(nm);
		}

		if (disposeSource)
			mesh = null;

		return meshes;
	}

	private static function splitMeshCsg(mesh:Mesh, disposeSource:Bool = false):Vector<Mesh>
	{
		var meshes:Vector<Mesh> = new Vector<Mesh>();
		var geometries:Vector<ISubGeometry> = mesh.geometry.subGeometries;
		var numSubGeoms:UInt = geometries.length;

		if (numSubGeoms == 1)
		{
			meshes.push(mesh);
			return meshes;
		}

		//var vertices:Vector<Float>;
		//var indices:Vector<UInt>;
		var subGeom:ISubGeometry;

		var nGeom:Geometry;
		var nSubGeom:CompactSubGeometry;
		var nm:Mesh;

		var nMeshMat:MaterialBase;

		for (var i:UInt = 0; i < numSubGeoms; ++i)
		{
			subGeom = CompactSubGeometry(geometries[i]);

			nGeom = new Geometry();
			nm = new Mesh(nGeom, mesh.subMeshes[i].material ? mesh.subMeshes[i].material : nMeshMat);

			nSubGeom = new CompactSubGeometry();
			nSubGeom.updateData(subGeom.vertexData);
			nSubGeom.updateIndexData(subGeom.indexData);

			nGeom.addSubGeometry(nSubGeom);

			meshes.push(nm);
		}

		if (disposeSource)
			mesh = null;

		return meshes;
	}

}
