package cloud.commands
{
	import cloud.DBNetworkUtils;
	import cloud.events.DBCloudEvent;
	import cloud.events.DBURLLoaderEvent;
	
	import flash.events.IEventDispatcher;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	
	public class DBNC_LoadLatestVersion extends DBNetworkCommandBase
	{
		private static const APIURL:String = "/api/latestversion.html";
		
		public function DBNC_LoadLatestVersion(data:Object=null, target:IEventDispatcher=null)
		{
			super(data, target);
			
			successEvent = DBCloudEvent.LOAD_LATESTVERSION_SUCCESS;
			failedEvent = DBCloudEvent.LOAD_LATESTVERSION_FAILED;
			
			request = new URLRequest(DBNetworkUtils.serverURL + APIURL);
			request.method = URLRequestMethod.GET;
		}
		
		override protected function loader_onSuccess(event:DBURLLoaderEvent):void
		{
			try
			{
				outputData = event.target.data;
			}
			catch(error:Error)
			{
				outputData = null;
			}
			commandFinished();
		}
	}
}