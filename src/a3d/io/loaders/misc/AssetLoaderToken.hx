package a3d.io.loaders.misc;

import a3d.io.loaders.AssetLoader;
import flash.events.EventDispatcher;





/**
 * Dispatched when a full resource (including dependencies) finishes loading.
 *
 * @eventType a3d.events.LoaderEvent
 */
@:meta(Eventname = "resourceComplete", type = "a3d.events.LoaderEvent")

/**
 * Dispatched when a single dependency (which may be the main file of a resource)
 * finishes loading.
 *
 * @eventType a3d.events.LoaderEvent
 */
@:meta(Eventname = "dependencyComplete", type = "a3d.events.LoaderEvent")

/**
 * Dispatched when an error occurs during loading.
 *
 * @eventType a3d.events.LoaderEvent
 */
@:meta(Eventname = "loadError", type = "a3d.events.LoaderEvent")

/**
 * Dispatched when any asset finishes parsing. Also see specific events for each
 * individual asset type (meshes, materials et c.)
 *
 * @eventType a3d.events.AssetEvent
 */
@:meta(Eventname = "assetComplete", type = "a3d.events.AssetEvent")

/**
 * Dispatched when a geometry asset has been constructed from a resource.
 *
 * @eventType a3d.events.AssetEvent
 */
@:meta(Eventname = "geometryComplete", type = "a3d.events.AssetEvent")

/**
 * Dispatched when a skeleton asset has been constructed from a resource.
 *
 * @eventType a3d.events.AssetEvent
 */
@:meta(Eventname = "skeletonComplete", type = "a3d.events.AssetEvent")

/**
 * Dispatched when a skeleton pose asset has been constructed from a resource.
 *
 * @eventType a3d.events.AssetEvent
 */
@:meta(Eventname = "skeletonPoseComplete", type = "a3d.events.AssetEvent")

/**
 * Dispatched when a container asset has been constructed from a resource.
 *
 * @eventType a3d.events.AssetEvent
 */
@:meta(Eventname = "containerComplete", type = "a3d.events.AssetEvent")

/**
 * Dispatched when an animation set has been constructed from a group of animation state resources.
 *
 * @eventType a3d.events.AssetEvent
 */
@:meta(Eventname = "animationSetComplete", type = "a3d.events.AssetEvent")

/**
 * Dispatched when an animation state has been constructed from a group of animation node resources.
 *
 * @eventType a3d.events.AssetEvent
 */
@:meta(Eventname = "animationStateComplete", type = "a3d.events.AssetEvent")

/**
 * Dispatched when an animation node has been constructed from a resource.
 *
 * @eventType a3d.events.AssetEvent
 */
@:meta(Eventname = "animationNodeComplete", type = "a3d.events.AssetEvent")

/**
 * Dispatched when an animation state transition has been constructed from a group of animation node resources.
 *
 * @eventType a3d.events.AssetEvent
 */
@:meta(Eventname = "stateTransitionComplete", type = "a3d.events.AssetEvent")

/**
 * Dispatched when a texture asset has been constructed from a resource.
 *
 * @eventType a3d.events.AssetEvent
 */
@:meta(Eventname = "textureComplete", type = "a3d.events.AssetEvent")

/**
 * Dispatched when a material asset has been constructed from a resource.
 *
 * @eventType a3d.events.AssetEvent
 */
@:meta(Eventname = "materialComplete", type = "a3d.events.AssetEvent")

/**
 * Dispatched when a animator asset has been constructed from a resource.
 *
 * @eventType a3d.events.AssetEvent
 */
@:meta(Eventname = "animatorComplete", type = "a3d.events.AssetEvent")


/**
 * Instances of this class are returned as tokens by loading operations
 * to provide an object on which events can be listened for in cases where
 * the actual asset loader is not directly available (e.g. when using the
 * AssetLibrary to perform the load.)
 *
 * By listening for events on this class instead of directly on the
 * AssetLibrary, one can distinguish different loads from each other.
 *
 * The token will dispatch all events that the original AssetLoader dispatches,
 * while not providing an interface to obstruct the load and is as such a
 * safer return value for loader wrappers than the loader itself.
*/
class AssetLoaderToken extends EventDispatcher
{
	public var loader:AssetLoader;

	public function new(loader:AssetLoader)
	{
		super();
		this.loader = loader;
	}


	override public function addEventListener(type:String, listener:Dynamic, useCapture:Bool = false, priority:Int = 0, useWeakReference:Bool = false):Void
	{
		loader.addEventListener(type, listener, useCapture, priority, useWeakReference);
	}


	override public function removeEventListener(type:String, listener:Dynamic, useCapture:Bool = false):Void
	{
		loader.removeEventListener(type, listener, useCapture);
	}


	override public function hasEventListener(type:String):Bool
	{
		return loader.hasEventListener(type);
	}


	override public function willTrigger(type:String):Bool
	{
		return loader.willTrigger(type);
	}
}
