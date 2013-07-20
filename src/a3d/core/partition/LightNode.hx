package a3d.core.partition;

import a3d.core.traverse.PartitionTraverser;
import a3d.entities.lights.LightBase;

/**
 * LightNode is a space partitioning leaf node that contains a LightBase object. Used for lights that are not of default supported type.
 */
class LightNode extends EntityNode
{
	/**
	 * The light object contained in this node.
	 */
	public var light(get, null):LightBase;
	
	private var _light:LightBase;

	/**
	 * Creates a new LightNode object.
	 * @param light The light to be contained in the node.
	 */
	public function new(light:LightBase)
	{
		super(light);
		_light = light;
	}

	
	private inline function get_light():LightBase
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
			traverser.applyUnknownLight(_light);
		}
	}
}
