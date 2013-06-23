package a3d.events
{
	import flash.events.Event;

	class LightEvent extends Event
	{
		public static inline var CASTS_SHADOW_CHANGE:String = "castsShadowChange";

		public function LightEvent(type:String)
		{
			super(type);
		}

		override public function clone():Event
		{
			return new LightEvent(type);
		}
	}
}
