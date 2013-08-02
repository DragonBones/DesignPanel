package cloud
{
	import cloud.events.DBURLLoaderEvent;
	import cloud.events.DBURLLoaderManagerEvent;
	
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.net.URLRequest;
	
	public class DBURLLoaderManager extends EventDispatcher
	{
		public static var instance:DBURLLoaderManager = new DBURLLoaderManager();
		private var _requestList:Array = new Array();
		private var _loaderList:Array = new Array();
		
		public function DBURLLoaderManager(target:IEventDispatcher=null)
		{
			super(target);
			initLoaderList();
		}
		
		public function loadRequest(request:URLRequest):void
		{
			if(request == null)
			{
				return;
			}
			if(!assignRequestForLoader(request))
			{
				_requestList.push(request);
			}
		}
		
		private function initLoaderList():void
		{
			for(var i:int = 0; i < 5; i++)
			{
				_loaderList.push(createLoader());
			}
		}
		
		private function createLoader():DBURLLoader
		{
			var loader:DBURLLoader = new DBURLLoader();
			loader.addEventListener(DBURLLoaderEvent.CLOSED, loader_onClosed);
			return loader;
		}
		
		private function loader_onClosed(event:DBURLLoaderEvent):void
		{
			_loaderList.push(createLoader());
			assignRequestForLoader();
		}
		
		private function assignRequestForLoader(request:URLRequest = null, loader:DBURLLoader = null):Boolean
		{
			if(loader == null)
			{
				loader = getNextFreeLoader();
			}
			if(loader == null)
			{
				return false;
			}
			
			if(request == null)
			{
				request = getNextRequest();
			}
			if(request == null)
			{
				_loaderList.push(loader);
				return false;
			}
			
			var data:Object = {loader:loader, request:request};
			
			dispatchEvent(new DBURLLoaderManagerEvent(DBURLLoaderManagerEvent.LOAD_START, data));
			loader.load(request);
			return true;
		}
		
		private function getNextFreeLoader():DBURLLoader
		{
			return _loaderList.pop();
		}
		
		private function getNextRequest():URLRequest
		{
			return _requestList.pop();
		}
	}
}