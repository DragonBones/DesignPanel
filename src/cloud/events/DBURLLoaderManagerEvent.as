package cloud.events
{
	import flash.events.Event;
	
	public class DBURLLoaderManagerEvent extends Event
	{
		public static const LOAD_START:String = "AEURLLoaderManagerEvent:LOAD_START";
		public static const LOAD_END:String = "AEURLLoaderManagerEvent:LOAD_END";
		
		public var data:Object;
		
		public function DBURLLoaderManagerEvent(type:String, d:Object, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
			data = d;
		}
	}
}