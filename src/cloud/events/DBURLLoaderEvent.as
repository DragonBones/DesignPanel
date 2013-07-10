package cloud.events
{
	import flash.events.Event;
	
	public class DBURLLoaderEvent extends Event
	{
		public static const SUCCESS:String = "DBURLLoaderEvent:SUCCESS";
		public static const FAILED:String = "DBURLLoaderEvent:FAILED";
		public static const CLOSED:String = "DBURLLoaderEvent:CLOSED";
		
		public var data:Object;
		public function DBURLLoaderEvent(type:String, d:Object = null, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
			data = d;
		}
	}
}