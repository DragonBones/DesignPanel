package core.events
{
	import flash.events.Event;
	
	public final class ServiceEvent extends Event
	{
		public var data:*;
		public function ServiceEvent(type:String, data:* = null, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
			this.data = data;
		}
	}
}