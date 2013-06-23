package a3d.core.partition
{
	import a3d.core.traverse.PartitionTraverser;
	import a3d.entities.lights.PointLight;

	/**
	 * LightNode is a space partitioning leaf node that contains a LightBase object.
	 */
	class PointLightNode extends EntityNode
	{
		private var _light:PointLight;

		/**
		 * Creates a new LightNode object.
		 * @param light The light to be contained in the node.
		 */
		public function PointLightNode(light:PointLight)
		{
			super(light);
			_light = light;
		}

		/**
		 * The light object contained in this node.
		 */
		private inline function get_light():PointLight
		{
			return _light;
		}

		/**
		 * @inheritDoc
		 */
		override public function acceptTraverser(traverser:PartitionTraverser):Void
		{
			if (traverser.enterNode(this))
			{
				super.acceptTraverser(traverser);
				traverser.applyPointLight(_light);
			}
		}
	}
}
