package a3d.core.data;


import flash.geom.Matrix3D;

import a3d.core.base.IRenderable;

class RenderableListItem
{
	public var next:RenderableListItem;
	public var renderable:IRenderable;

	// for faster access while sorting or rendering (cached values)
	public var materialId:Int;
	public var renderOrderId:Int;
	public var zIndex:Float;
	public var renderSceneTransform:Matrix3D;

	public var cascaded:Bool;

	public function new()
	{

	}
}
