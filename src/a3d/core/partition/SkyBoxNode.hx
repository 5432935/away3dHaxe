package a3d.core.partition;

import a3d.core.traverse.PartitionTraverser;
import a3d.math.Plane3D;
import a3d.entities.primitives.SkyBox;

/**
 * SkyBoxNode is a space partitioning leaf node that contains a SkyBox object.
 */
class SkyBoxNode extends EntityNode
{
	private var _skyBox:SkyBox;

	/**
	 * Creates a new SkyBoxNode object.
	 * @param skyBox The SkyBox to be contained in the node.
	 */
	public function new(skyBox:SkyBox)
	{
		super(skyBox);
		_skyBox = skyBox;
	}

	/**
	 * @inheritDoc
	 */
	override public function acceptTraverser(traverser:PartitionTraverser):Void
	{
		if (traverser.enterNode(this))
		{
			super.acceptTraverser(traverser);
			traverser.applySkyBox(_skyBox);
		}
	}


	override public function isInFrustum(planes:Vector<Plane3D>, numPlanes:Int):Bool
	{
		planes = planes;
		numPlanes = numPlanes;
		return true;
	}
}
