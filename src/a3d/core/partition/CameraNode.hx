package a3d.core.partition
{
	import a3d.entities.Camera3D;
	import a3d.core.traverse.PartitionTraverser;

	/**
	 * CameraNode is a space partitioning leaf node that contains a Camera3D object.
	 */
	class CameraNode extends EntityNode
	{
		/**
		 * Creates a new CameraNode object.
		 * @param camera The camera to be contained in the node.
		 */
		public function CameraNode(camera:Camera3D)
		{
			super(camera);
		}

		/**
		 * @inheritDoc
		 */
		override public function acceptTraverser(traverser:PartitionTraverser):Void
		{
			// todo: dead end for now, if it has a debug mesh, then sure accept that
		}
	}
}
