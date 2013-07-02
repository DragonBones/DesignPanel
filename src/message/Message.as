package message{
	import flash.events.Event;
	
	public final class Message extends Event{
		public var parameters:Array;
		public function Message(type:String, ...args){
			super(type, false, false);
			if(args.length > 0)
			{
				parameters = args;
			}
		}
		
		override public function clone():Event {
			var _event:Message = new Message(type);
			_event.parameters = parameters;
			return _event;
		}
	}
}