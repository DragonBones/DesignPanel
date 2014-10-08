package core.events
{
	import flash.events.Event;
	
	public final class ViewEvent extends Event
	{
		public static const BONE_SELECTED_CHANGE:String = "BONE_SELECTED_CHANGE";
		public static const BONE_PARENT_CHANGE:String = "BONE_PARENT_CHANGE";
		public static const ARMATURE_ANIMATION_CHANGE:String = "ARMATURE_ANIMATION_CHANGE";
		
		public var data:*;
		
		public function ViewEvent(type:String, data:* = null, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
			
			this.data = data;
		}
	}
}