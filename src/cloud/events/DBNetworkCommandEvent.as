package cloud.events
{
	import flash.events.Event;
	
	public class DBNetworkCommandEvent extends Event
	{
		public static const FINISHED:String = "AENetworkCommandEvent:FINISHED";
		public function DBNetworkCommandEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
	}
}