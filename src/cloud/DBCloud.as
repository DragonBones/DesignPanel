package cloud
{
	import cloud.commands.*;
	import cloud.events.DBCloudEvent;
	import cloud.events.DBNetworkCommandEvent;
	import cloud.events.DBNetworkEvent;
	
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	
	public class DBCloud extends EventDispatcher
	{
		public static var instance:DBCloud = new DBCloud();
		
		public var initialized:Boolean = false;
		public var ifNeedUpdate:int = 0;
		
		public function DBCloud(target:IEventDispatcher=null)
		{
			super(target);
		}
		
		public function init():void
		{	
			DBNetworkUtils.instance.addEventListener(DBNetworkEvent.INITED, network_onInit);
			DBNetworkUtils.instance.init();
		}
		
		public function checkOnlineStatus():void
		{
			DBNetworkUtils.instance.testNetwork();
		}
		
		private function network_onInit(event:DBNetworkEvent = null):void
		{
			DBNetworkUtils.instance.removeEventListener(DBNetworkEvent.INITED, network_onInit);
			initializeComplete();
		}
		
		private function initializeComplete():void
		{
			trace("Cloud InitializeComplete");
			initialized = true;
			dispatchEvent(new DBCloudEvent(DBCloudEvent.INITED));
		}
		
		private function createCommand(command:DBNetworkCommandBase, func:Function):DBNetworkCommandBase
		{
			command.addEventListener(DBNetworkCommandEvent.FINISHED, func);
			return command;
		}
		
		public function loadLatestVersion():void
		{
			if(ifNeedUpdate == 0)
			{
				new DBNC_LoadLatestVersion().execute();
			}
		}
		
		public function loadOnlineHelp():void
		{
			new DBNC_LoadOnlineHelp().execute();
		}
		
		public function loadAbout():void
		{
			new DBNC_LoadAbout().execute();
		}
		
		public function loadHelpUs():void
		{
			new DBNC_LoadHelpUs().execute();
		}
		
		public function cotactUs(data:Object):void
		{
			new DBNC_ContactUs(data).execute();
		}
	}
}