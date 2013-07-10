package cloud
{
	import cloud.events.DBURLLoaderEvent;
	
	import flash.events.Event;
	import flash.events.HTTPStatusEvent;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	
	public class DBURLLoader extends URLLoader
	{
		public var isBusy:Boolean = false;
		
		public function DBURLLoader(request:URLRequest=null)
		{
			super(request);
			addEventListener(Event.COMPLETE, completeHandler);
			addEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
			
			addEventListener(HTTPStatusEvent.HTTP_STATUS, httpStatusVal);
			addEventListener(SecurityErrorEvent.SECURITY_ERROR, SecurityHandler);
			addEventListener(ProgressEvent.PROGRESS, loadProgress);
		}
		
		override public function load(urlrequest:URLRequest):void
		{
			trace("Load URL: " + urlrequest.url);
			isBusy = true;
			try
			{
				super.load(urlrequest);
			}
			catch(error:Error)
			{
				trace("Unable to load URL:" + urlrequest.url + ". Error message:" + error.message);
				dispatchEvent(new DBURLLoaderEvent(DBURLLoaderEvent.FAILED));
				close();
			}
		}
		
		override public function close():void
		{
			super.close();
			isBusy = false;
			dispatchEvent(new DBURLLoaderEvent(DBURLLoaderEvent.CLOSED));
		}
		
		private function completeHandler(event:Event):void
		{
			dispatchEvent(new DBURLLoaderEvent(DBURLLoaderEvent.SUCCESS));
			close();
		}
		
		protected function ioErrorHandler(event:IOErrorEvent):void
		{
			trace("ioError: " + event.text);
			dispatchEvent(new DBURLLoaderEvent(DBURLLoaderEvent.FAILED));
			close();
		}
		
		protected function httpStatusVal(event:HTTPStatusEvent):void
		{
			if(String(event.status) != "200")
			{
				trace("HTTP status: " + String(event.status));	
			}
		}
		
		protected function SecurityHandler(event:SecurityErrorEvent):void
		{
			trace("Security: " + event.toString());
		}
		
		protected function loadProgress(event:ProgressEvent):void
		{
			//trace("progress loaded:" + event.bytesLoaded + ", total: " + event.bytesTotal);
		}
	}
}