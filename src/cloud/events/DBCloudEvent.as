package cloud.events
{
	import flash.events.Event;
	
	public class DBCloudEvent extends Event
	{
		public static const INITED:String = "DBCloudEvent:INITED";
		
		public static const LOAD_LATESTVERSION_SUCCESS:String = "DBCloudEvent:LOAD_LATESTVERSION_SUCCESS";
		public static const LOAD_LATESTVERSION_FAILED:String = "DBCloudEvent:LOAD_LATESTVERSION_FAILED";
		
		public static const LOAD_ONLINEHELP_SUCCESS:String = "DBCloudEvent:LOAD_ONLINEHELP_SUCCESS";
		public static const LOAD_ONLINEHELP_FAILED:String = "DBCloudEvent:LOAD_ONLINEHELP_FAILED";
		
		public var _data:Object;
		
		public function DBCloudEvent(type:String, data:Object=null, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
			_data = data;
		}
		
		public function get data():Object
		{
			return _data;
		}
	}
}