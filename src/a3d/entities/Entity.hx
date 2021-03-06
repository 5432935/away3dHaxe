package a3d.entities;

import a3d.bounds.AxisAlignedBoundingBox;
import a3d.bounds.BoundingVolumeBase;
import a3d.core.partition.EntityNode;
import a3d.core.partition.Partition3D;
import a3d.core.pick.IPickingCollider;
import a3d.core.pick.PickingCollisionVO;
import a3d.errors.AbstractMethodError;
import a3d.io.library.assets.AssetType;
import a3d.math.FMatrix3D;
import flash.geom.Vector3D;


/**
 * The Entity class provides an abstract base class for all scene graph objects that are considered having a
 * "presence" in the scene, in the sense that it can be considered an actual object with a position and a size (even
 * if infinite or idealised), rather than a grouping.
 * Entities can be partitioned in a space partitioning system and in turn collected by an EntityCollector.
 *
 * @see a3d.partition.Partition3D
 * @see a3d.core.traverse.EntityCollector
 */
class Entity extends ObjectContainer3D
{
	/**
	 * Used by the shader-based picking system to determine whether a separate render pass is made in order
	 * to offer more details for the picking collision object, including local position, normal vector and uv value.
	 * Defaults to false.
	 *
	 * @see a3d.core.pick.ShaderPicker
	 */
	public var shaderPickingDetails(get,set):Bool;
	/**
	 * Defines whether or not the object will be moved or animated at runtime. This property is used by some partitioning systems to improve performance.
	 * Warning: if set to true, they may not be processed by certain partition systems using static visibility lists, unless they're specifically assigned to the visibility list.
	 */
	public var staticNode(get,set):Bool;
	/**
	 * Returns a unique picking collision value object for the entity.
	 */
	public var pickingCollisionVO(get,null):PickingCollisionVO;
	/**
	 *
	 */
	public var showBounds(get, set):Bool;
	
	/**
	 * The bounding volume approximating the volume occupied by the Entity.
	 */
	public var bounds(get,set):BoundingVolumeBase;
	public var worldBounds(get,null):BoundingVolumeBase;
	/**
	 * Used by the raycast-based picking system to determine how the geometric contents of an entity are processed
	 * in order to offer more details for the picking collision object, including local position, normal vector and uv value.
	 * Defaults to null.
	 *
	 * @see a3d.core.pick.RaycastPicker
	 */
	public var pickingCollider(get,set):IPickingCollider;
	
	private var _showBounds:Bool;
	private var _partitionNode:EntityNode;
	private var _boundsIsShown:Bool;
	private var _shaderPickingDetails:Bool;

	private var _pickingCollisionVO:PickingCollisionVO;
	private var _pickingCollider:IPickingCollider;
	private var _staticNode:Bool;

	private var _bounds:BoundingVolumeBase;
	private var _boundsInvalid:Bool;
	private var _worldBounds:BoundingVolumeBase;
	private var _worldBoundsInvalid:Bool;

	/**
	 * Creates a new Entity object.
	 */
	public function new()
	{
		super();
		_boundsIsShown = false;
		_boundsInvalid = true;
		_worldBoundsInvalid = true;
		_bounds = getDefaultBoundingVolume();
		_worldBounds = getDefaultBoundingVolume();
	}

	override private function set_ignoreTransform(value:Bool):Bool
	{
		if (_scene != null)
			_scene.invalidateEntityBounds(this);
		return super.ignoreTransform = value;
	}

	
	private function get_shaderPickingDetails():Bool
	{
		return _shaderPickingDetails;
	}

	private function set_shaderPickingDetails(value:Bool):Bool
	{
		return _shaderPickingDetails = value;
	}

	
	private function get_staticNode():Bool
	{
		return _staticNode;
	}

	private function set_staticNode(value:Bool):Bool
	{
		return _staticNode = value;
	}

	
	private function get_pickingCollisionVO():PickingCollisionVO
	{
		if (_pickingCollisionVO == null)
			_pickingCollisionVO = new PickingCollisionVO(this);

		return _pickingCollisionVO;
	}

	//private function set_pickingCollisionVO(value:PickingCollisionVO):PickingCollisionVO
	//{
	//  return _pickingCollisionVO = value;
	//}

	/**
	 * Tests if a collision occurs before shortestCollisionDistance, using the data stored in PickingCollisionVO.
	 * @param shortestCollisionDistance
	 * @return
	 */
	public function collidesBefore(shortestCollisionDistance:Float, findClosest:Bool):Bool
	{
		return true;
	}

	
	private function get_showBounds():Bool
	{
		return _showBounds;
	}

	private function set_showBounds(value:Bool):Bool
	{
		if (value == _showBounds)
			return _showBounds;

		_showBounds = value;

		if (_showBounds)
			addBounds();
		else
			removeBounds();
			
		return _showBounds;
	}

	/**
	 * @inheritDoc
	 */
	override private function get_minX():Float
	{
		if (_boundsInvalid)
			updateBounds();

		return _bounds.min.x;
	}

	/**
	 * @inheritDoc
	 */
	override private function get_minY():Float
	{
		if (_boundsInvalid)
			updateBounds();

		return _bounds.min.y;
	}

	/**
	 * @inheritDoc
	 */
	override private function get_minZ():Float
	{
		if (_boundsInvalid)
			updateBounds();

		return _bounds.min.z;
	}

	/**
	 * @inheritDoc
	 */
	override private function get_maxX():Float
	{
		if (_boundsInvalid)
			updateBounds();

		return _bounds.max.x;
	}

	/**
	 * @inheritDoc
	 */
	override private function get_maxY():Float
	{
		if (_boundsInvalid)
			updateBounds();

		return _bounds.max.y;
	}

	/**
	 * @inheritDoc
	 */
	override private function get_maxZ():Float
	{
		if (_boundsInvalid)
			updateBounds();

		return _bounds.max.z;
	}

	
	private function get_bounds():BoundingVolumeBase
	{
		if (_boundsInvalid)
			updateBounds();

		return _bounds;
	}

	private function set_bounds(value:BoundingVolumeBase):BoundingVolumeBase
	{
		removeBounds();
		_bounds = value;
		_worldBounds = value.clone();
		invalidateBounds();
		if (_showBounds)
			addBounds();
			
		return _bounds;
	}

	
	private function get_worldBounds():BoundingVolumeBase
	{
		if (_worldBoundsInvalid)
			updateWorldBounds();

		return _worldBounds;
	}

	private function updateWorldBounds():Void
	{
		_worldBounds.transformFrom(bounds, sceneTransform);
		_worldBoundsInvalid = false;
	}

	/**
	 * @inheritDoc
	 */
	override private function set_implicitPartition(value:Partition3D):Partition3D
	{
		if (value == _implicitPartition)
			return implicitPartition;

		if (_implicitPartition != null)
			notifyPartitionUnassigned();

		super.implicitPartition = value;

		notifyPartitionAssigned();
		
		return implicitPartition;
	}

	/**
	 * @inheritDoc
	 */
	override private function set_scene(value:Scene3D):Scene3D
	{
		if (value == _scene)
			return _scene;

		if (_scene != null)
			_scene.unregisterEntity(this);

		// callback to notify object has been spawned. Casts to please FDT
		if (value != null)
			value.registerEntity(this);

		super.scene = value;
		
		return _scene;
	}

	override private function get_assetType():String
	{
		return AssetType.ENTITY;
	}

	
	private function get_pickingCollider():IPickingCollider
	{
		return _pickingCollider;
	}

	private function set_pickingCollider(value:IPickingCollider):IPickingCollider
	{
		return _pickingCollider = value;
	}

	/**
	 * Gets a concrete EntityPartition3DNode subclass that is associated with this Entity instance
	 */
	public function getEntityPartitionNode():EntityNode
	{
		if (_partitionNode == null)
			_partitionNode = createEntityPartitionNode();
		return _partitionNode;
	}

	public function isIntersectingRay(rayPosition:Vector3D, rayDirection:Vector3D):Bool
	{
		if (pickingCollisionVO.localRayPosition == null) 
			pickingCollisionVO.localRayPosition = new Vector3D();
		if (pickingCollisionVO.localRayDirection == null)
			pickingCollisionVO.localRayDirection = new Vector3D();
		if (pickingCollisionVO.localNormal == null) 
			pickingCollisionVO.localNormal = new Vector3D();

		// convert ray to entity space
		var localRayPosition:Vector3D = pickingCollisionVO.localRayPosition;
		var localRayDirection:Vector3D = pickingCollisionVO.localRayDirection;
		
		FMatrix3D.transformVector(inverseSceneTransform, rayPosition, localRayPosition);
		FMatrix3D.deltaTransformVector(inverseSceneTransform, rayDirection, localRayDirection);

		// check for ray-bounds collision
		var rayEntryDistance:Float = bounds.rayIntersection(localRayPosition, localRayDirection, pickingCollisionVO.localNormal);
		if (rayEntryDistance < 0)
			return false;
		
		// Store collision data.
		pickingCollisionVO.rayEntryDistance = rayEntryDistance;
		pickingCollisionVO.rayPosition = rayPosition;
		pickingCollisionVO.rayDirection = rayDirection;
		pickingCollisionVO.rayOriginIsInsideBounds = rayEntryDistance == 0;
		
		return true;
	}

	/**
	 * Factory method that returns the current partition node. Needs to be overridden by concrete subclasses
	 * such as Mesh to return the correct concrete subtype of EntityPartition3DNode (for Mesh = MeshPartition3DNode,
	 * most IRenderables (particles fe) would return RenderablePartition3DNode, I suppose)
	 */
	private function createEntityPartitionNode():EntityNode
	{
		throw new AbstractMethodError();
	}

	/**
	 * Creates the default bounding box to be used by this type of Entity.
	 * @return
	 */
	private function getDefaultBoundingVolume():BoundingVolumeBase
	{
		// point lights should be using sphere bounds
		// directional lights should be using null bounds
		return new AxisAlignedBoundingBox();
	}

	/**
	 * Updates the bounding volume for the object. Overriding methods need to set invalid flag to false!
	 */
	private function updateBounds():Void
	{
		throw new AbstractMethodError();
	}

	/**
	 * @inheritDoc
	 */
	override private function invalidateSceneTransform():Void
	{
		if (!_ignoreTransform)
		{
			super.invalidateSceneTransform();
			_worldBoundsInvalid = true;
			notifySceneBoundsInvalid();
		}
	}

	/**
	 * Invalidates the bounding volume, causing to be updated when requested.
	 */
	private function invalidateBounds():Void
	{
		_boundsInvalid = true;
		_worldBoundsInvalid = true;
		notifySceneBoundsInvalid();
	}

	override private function updateMouseChildren():Void
	{
		// If there is a parent and this child does not have a triangle collider, use its parent's triangle collider.
		if (_parent != null && pickingCollider == null)
		{
			if (Std.is(_parent,Entity))
			{
				var collider:IPickingCollider = Std.instance(_parent,Entity).pickingCollider;
				if (collider != null)
				{
					pickingCollider = collider;
				}
			}
		}

		super.updateMouseChildren();
	}

	/**
	 * Notify the scene that the global scene bounds have changed, so it can be repartitioned.
	 */
	private function notifySceneBoundsInvalid():Void
	{
		if (_scene != null)
			_scene.invalidateEntityBounds(this);
	}

	/**
	 * Notify the scene that a new partition was assigned.
	 */
	private function notifyPartitionAssigned():Void
	{
		if (_scene != null)
			_scene.registerPartition(this); //_onAssignPartitionCallback(this);
	}

	/**
	 * Notify the scene that a partition was unassigned.
	 */
	private function notifyPartitionUnassigned():Void
	{
		if (_scene != null)
			_scene.unregisterPartition(this);
	}

	private function addBounds():Void
	{
		if (!_boundsIsShown)
		{
			_boundsIsShown = true;
			addChild(_bounds.boundingRenderable);
		}
	}

	private function removeBounds():Void
	{
		if (_boundsIsShown)
		{
			_boundsIsShown = false;
			removeChild(_bounds.boundingRenderable);
			_bounds.disposeRenderable();
		}
	}

	public function internalUpdate():Void
	{
		if (controller != null)
			controller.update();
	}
}
