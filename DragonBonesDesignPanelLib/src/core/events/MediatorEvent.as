package core.events
{
	import flash.events.Event;
	
	public final class MediatorEvent extends Event
	{
		public static const UPDATE_FLA_ARMATURE:String = "v_updateFlaArmature";
		public static const REMOVE_ARMATURE:String = "v_removeArmature";
		
		public static const ROLL_OVER_BONE:String = "v_rollOverBone";
		public static const ROLL_OUT_BONE:String = "v_rollOutBone";
		
		public var mediator:Object;
		public var data:*;
		
		public function MediatorEvent(type:String, mediator:Object = null, data:* = null, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
			this.mediator = mediator;
			this.data = data;
		}
	}
}