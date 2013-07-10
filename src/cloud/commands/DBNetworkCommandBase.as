package cloud.commands
{
	import cloud.DBCloud;
	import cloud.DBURLLoader;
	import cloud.DBURLLoaderManager;
	import cloud.events.DBCloudEvent;
	import cloud.events.DBNetworkCommandEvent;
	import cloud.events.DBURLLoaderEvent;
	import cloud.events.DBURLLoaderManagerEvent;
	
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.net.URLRequest;
	
	public class DBNetworkCommandBase extends EventDispatcher
	{
		public var outputData:Object;
		public var inputData:Object;
		
		protected var loader:DBURLLoader;
		protected var request:URLRequest;
		protected var loaderSuccessCallBack:Function;
		protected var loaderFailedCallBack:Function;
		protected var successEvent:String;
		protected var failedEvent:String;
		
		public function DBNetworkCommandBase(data:Object = null, target:IEventDispatcher=null)
		{
			super(target);
			inputData = data;
		}
		
		public function execute():void
		{
			DBURLLoaderManager.instance.addEventListener(DBURLLoaderManagerEvent.LOAD_START, loaderManager_onLoadStart);
			DBURLLoaderManager.instance.loadRequest(request);
		}
		
		protected function loaderManager_onLoadStart(event:DBURLLoaderManagerEvent):void
		{
			if(event.data.request != request)
			{
				return;
			}
			DBURLLoaderManager.instance.removeEventListener(DBURLLoaderManagerEvent.LOAD_START, loaderManager_onLoadStart);
			loader = event.data.loader as DBURLLoader;
			loader.addEventListener(DBURLLoaderEvent.SUCCESS, loader_onSuccess);
			loader.addEventListener(DBURLLoaderEvent.FAILED, loader_onFailed);
		}
		
		protected function loader_onSuccess(event:DBURLLoaderEvent):void
		{
			commandFinished();
		}
		
		protected function loader_onFailed(event:DBURLLoaderEvent):void
		{
			outputData = null;
			commandFinished();
		}
		
		protected function commandFinished():void
		{
			loader.removeEventListener(DBURLLoaderEvent.SUCCESS, loader_onSuccess);
			loader.removeEventListener(DBURLLoaderEvent.FAILED, loader_onFailed);
			
			if(outputData != null)
			{
				DBCloud.instance.dispatchEvent(new DBCloudEvent(successEvent, this));
			}
			else
			{
				trace("Command Failed: "+failedEvent);
				DBCloud.instance.dispatchEvent(new DBCloudEvent(failedEvent, this));
			}
			dispatchEvent(new DBNetworkCommandEvent(DBNetworkCommandEvent.FINISHED));
		}
	}
}