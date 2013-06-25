package a3d.core.managers;


import flash.events.TouchEvent;
import flash.geom.Vector3D;
import flash.utils.Dictionary;
import flash.Vector;


import a3d.core.pick.IPicker;
import a3d.core.pick.PickingCollisionVO;
import a3d.core.pick.PickingType;
import a3d.entities.ObjectContainer3D;
import a3d.entities.View3D;
import a3d.events.TouchEvent3D;



class Touch3DManager
{
	private var _updateDirty:Bool = true;
	private var _nullVector:Vector3D = new Vector3D();
	private var _numTouchPoints:UInt;
	private var _touchPoint:TouchPoint;
	private var _collidingObject:PickingCollisionVO;
	private var _previousCollidingObject:PickingCollisionVO;
	private static var _collidingObjectFromTouchId:Dictionary;
	private static var _previousCollidingObjectFromTouchId:Dictionary;
	private static var _queuedEvents:Vector<TouchEvent3D> = new Vector<TouchEvent3D>();

	private var _touchPoints:Vector<TouchPoint>;
	private var _touchPointFromId:Dictionary;

	private var _touchMoveEvent:TouchEvent = new TouchEvent(TouchEvent.TOUCH_MOVE);

	private var _forceTouchMove:Bool;
	private var _touchPicker:IPicker = PickingType.RAYCAST_FIRST_ENCOUNTERED;
	private var _view:View3D;

	public function new()
	{
		super();
		_touchPoints = new Vector<TouchPoint>();
		_touchPointFromId = new Dictionary();
		_collidingObjectFromTouchId = new Dictionary();
		_previousCollidingObjectFromTouchId = new Dictionary();
	}

	// ---------------------------------------------------------------------
	// Interface.
	// ---------------------------------------------------------------------

	public function updateCollider():Void
	{

		if (_forceTouchMove || _updateDirty)
		{ // If forceTouchMove is off, and no 2D Touch events dirty the update, don't update either.
			for (i in 0..._numTouchPoints)
			{
				_touchPoint = _touchPoints[i];
				_collidingObject = _touchPicker.getViewCollision(_touchPoint.x, _touchPoint.y, _view);
				_collidingObjectFromTouchId[_touchPoint.id] = _collidingObject;
			}
		}
	}

	public function fireTouchEvents():Void
	{

		var i:UInt;
		var len:UInt;
		var event:TouchEvent3D;
		var dispatcher:ObjectContainer3D;

		for (i in 0..._numTouchPoints)
		{
			_touchPoint = _touchPoints[i];
			// If colliding object has changed, queue over/out events.
			_collidingObject = _collidingObjectFromTouchId[_touchPoint.id];
			_previousCollidingObject = _previousCollidingObjectFromTouchId[_touchPoint.id];
			if (_collidingObject != _previousCollidingObject)
			{
				if (_previousCollidingObject)
					queueDispatch(TouchEvent3D.TOUCH_OUT, _touchMoveEvent, _previousCollidingObject, _touchPoint);
				if (_collidingObject)
					queueDispatch(TouchEvent3D.TOUCH_OVER, _touchMoveEvent, _collidingObject, _touchPoint);
			}
			// Fire Touch move events here if forceTouchMove is on.
			if (_forceTouchMove && _collidingObject)
			{
				queueDispatch(TouchEvent3D.TOUCH_MOVE, _touchMoveEvent, _collidingObject, _touchPoint);
			}
		}

		// Dispatch all queued events.
		len = _queuedEvents.length;
		for (i in 0...len)
		{

			// Only dispatch from first implicitly enabled object ( one that is not a child of a TouchChildren = false hierarchy ).
			event = _queuedEvents[i];
			dispatcher = event.object;

			while (dispatcher && !dispatcher.ancestorsAllowMouseEnabled)
				dispatcher = dispatcher.parent;

			if (dispatcher)
				dispatcher.dispatchEvent(event);
		}
		_queuedEvents.length = 0;

		_updateDirty = false;

		for (i in 0..._numTouchPoints)
		{
			_touchPoint = _touchPoints[i];
			_previousCollidingObjectFromTouchId[_touchPoint.id] = _collidingObjectFromTouchId[_touchPoint.id];
		}
	}

	public function enableTouchListeners(view:View3D):Void
	{
		view.addEventListener(TouchEvent.TOUCH_BEGIN, onTouchBegin);
		view.addEventListener(TouchEvent.TOUCH_MOVE, onTouchMove);
		view.addEventListener(TouchEvent.TOUCH_END, onTouchEnd);
	}

	public function disableTouchListeners(view:View3D):Void
	{
		view.removeEventListener(TouchEvent.TOUCH_BEGIN, onTouchBegin);
		view.removeEventListener(TouchEvent.TOUCH_MOVE, onTouchMove);
		view.removeEventListener(TouchEvent.TOUCH_END, onTouchEnd);
	}

	public function dispose():Void
	{
		_touchPicker.dispose();
		_touchPoints = null;
		_touchPointFromId = null;
		_collidingObjectFromTouchId = null;
		_previousCollidingObjectFromTouchId = null;
	}

	// ---------------------------------------------------------------------
	// Private.
	// ---------------------------------------------------------------------

	private function queueDispatch(emitType:String, sourceEvent:TouchEvent, collider:PickingCollisionVO, touch:TouchPoint):Void
	{

		var event:TouchEvent3D = new TouchEvent3D(emitType);

		// 2D properties.
		event.ctrlKey = sourceEvent.ctrlKey;
		event.altKey = sourceEvent.altKey;
		event.shiftKey = sourceEvent.shiftKey;
		event.screenX = touch.x;
		event.screenY = touch.y;
		event.touchPointID = touch.id;

		// 3D properties.
		if (collider)
		{
			// Object.
			event.object = collider.entity;
			event.renderable = collider.renderable;
			// UV.
			event.uv = collider.uv;
			// Position.
			event.localPosition = collider.localPosition ? collider.localPosition.clone() : null;
			// Normal.
			event.localNormal = collider.localNormal ? collider.localNormal.clone() : null;
			// Face index.
			event.index = collider.index;
			// SubGeometryIndex.
			event.subGeometryIndex = collider.subGeometryIndex;

		}
		else
		{
			// Set all to null.
			event.uv = null;
			event.object = null;
			event.localPosition = _nullVector;
			event.localNormal = _nullVector;
			event.index = 0;
			event.subGeometryIndex = 0;
		}

		// Store event to be dispatched later.
		_queuedEvents.push(event);
	}

	// ---------------------------------------------------------------------
	// Event handlers.
	// ---------------------------------------------------------------------

	private function onTouchBegin(event:TouchEvent):Void
	{

		var touch:TouchPoint = new TouchPoint();
		touch.id = event.touchPointID;
		touch.x = event.stageX;
		touch.y = event.stageY;
		_numTouchPoints++;
		_touchPoints.push(touch);
		_touchPointFromId[touch.id] = touch;

		updateCollider(); // ensures collision check is done with correct mouse coordinates on mobile

		_collidingObject = _collidingObjectFromTouchId[touch.id];
		if (_collidingObject)
		{
			queueDispatch(TouchEvent3D.TOUCH_BEGIN, event, _collidingObject, touch);
		}

		_updateDirty = true;
	}

	private function onTouchMove(event:TouchEvent):Void
	{

		var touch:TouchPoint = _touchPointFromId[event.touchPointID];
		touch.x = event.stageX;
		touch.y = event.stageY;

		_collidingObject = _collidingObjectFromTouchId[touch.id];
		if (_collidingObject)
		{
			queueDispatch(TouchEvent3D.TOUCH_MOVE, _touchMoveEvent = event, _collidingObject, touch);
		}

		_updateDirty = true;
	}

	private function onTouchEnd(event:TouchEvent):Void
	{

		var touch:TouchPoint = _touchPointFromId[event.touchPointID];

		_collidingObject = _collidingObjectFromTouchId[touch.id];
		if (_collidingObject)
		{
			queueDispatch(TouchEvent3D.TOUCH_END, event, _collidingObject, touch);
		}

		_touchPointFromId[touch.id] = null;
		_numTouchPoints--;
		_touchPoints.splice(_touchPoints.indexOf(touch), 1);

		_updateDirty = true;
	}

	// ---------------------------------------------------------------------
	// Getters & setters.
	// ---------------------------------------------------------------------

	private inline function get_forceTouchMove():Bool
	{
		return _forceTouchMove;
	}

	private inline function set_forceTouchMove(value:Bool):Void
	{
		_forceTouchMove = value;
	}

	private inline function get_touchPicker():IPicker
	{
		return _touchPicker;
	}

	private inline function set_touchPicker(value:IPicker):Void
	{
		_touchPicker = value;
	}

	private inline function set_view(value:View3D):Void
	{
		_view = value;
	}
}

class TouchPoint
{
	public var id:Int;
	public var x:Float;
	public var y:Float;
}
