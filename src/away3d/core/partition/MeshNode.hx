package away3d.core.partition;

import away3d.core.base.SubMesh;
import away3d.core.traverse.PartitionTraverser;
import away3d.entities.Mesh;
import flash.Vector;

/**
 * MeshNode is a space partitioning leaf node that contains a Mesh object.
 */
class MeshNode extends EntityNode
{
	/**
	 * The mesh object contained in the partition node.
	 */
	public var mesh(get, null):Mesh;
	
	private var _mesh:Mesh;

	/**
	 * Creates a new MeshNode object.
	 * @param mesh The mesh to be contained in the node.
	 */
	public function new(mesh:Mesh)
	{
		super(mesh);
		_mesh = mesh; // also keep a stronger typed reference
	}

	
	private inline function get_mesh():Mesh
	{
		return _mesh;
	}

	/**
	 * @inheritDoc
	 */
	override public function acceptTraverser(traverser:PartitionTraverser):Void
	{
		if (traverser.enterNode(this))
		{
			super.acceptTraverser(traverser);
			
			var subs:Vector<SubMesh> = _mesh.subMeshes;
			for(i in 0...subs.length)
				traverser.applyRenderable(subs[i]);
		}
	}

}
