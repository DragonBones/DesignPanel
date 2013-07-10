package cloud
{
	import cloud.commands.DBNC_LoadLatestVersion;
	import cloud.commands.DBNetworkCommandBase;
	import cloud.events.DBNetworkCommandEvent;
	import cloud.events.DBNetworkEvent;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.events.StatusEvent;
	import flash.net.URLRequest;
	
	public class DBNetworkUtils extends EventDispatcher
	{
		public static var serverURL:String = "http://dragonbones.github.io";
		
		public static var instance:DBNetworkUtils = new DBNetworkUtils();
		
		public var isInited:Boolean = false;
		private var command:DBNetworkCommandBase = null;
		private var _isNetworkAvailable:Boolean = false;
		
		public function DBNetworkUtils(target:IEventDispatcher=null)
		{
			super(target);
		}
		
		public function init():void
		{
			if(isInited)
			{
				return;
			}
			
			testNetwork();
		}
		
		public function testNetwork():void
		{
			command = new DBNC_LoadLatestVersion();
			command.addEventListener(DBNetworkCommandEvent.FINISHED, command_onFinished);
			command.execute();
		}
		
		private function command_onFinished(event:DBNetworkCommandEvent):void
		{
			command.removeEventListener(DBNetworkCommandEvent.FINISHED, command_onFinished);
			var newValue:Boolean = command.outputData != null;
			if(_isNetworkAvailable != newValue)
			{
				_isNetworkAvailable = newValue;
				dispatchEvent(new DBNetworkEvent(DBNetworkEvent.STATUS_CHANGED));
			}
			
			if(!isInited)
			{
				inited();
			}
		}
		
		private function inited():void
		{
			isInited = true;
			dispatchEvent(new DBNetworkEvent(DBNetworkEvent.INITED));
		}
		
		public function get isNetworkAvailable():Boolean
		{
			return _isNetworkAvailable;
		}
	}
}