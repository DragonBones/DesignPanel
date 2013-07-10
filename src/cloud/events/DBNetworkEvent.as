package cloud.events
{
	import flash.events.Event;
	
	public class DBNetworkEvent extends Event
	{
		public static const INITED:String = "DBNetworkEvent:INITED";
		public static const STATUS_CHANGED:String = "DBNetworkEvent:STATUS_CHANGED";
		public function DBNetworkEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
	}
}