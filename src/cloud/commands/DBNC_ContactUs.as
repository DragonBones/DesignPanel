package cloud.commands
{
	import cloud.awayeffect.AEClient;
	import cloud.events.DBCloudEvent;
	import cloud.events.DBURLLoaderEvent;
	
	import flash.events.IEventDispatcher;
	
	public class DBNC_ContactUs extends DBNetworkCommandBase
	{
		private static const APIURL:String = "/api/feedback";
		
		public function DBNC_ContactUs(data:Object=null, target:IEventDispatcher=null)
		{
			super(data, target);
			
			successEvent = DBCloudEvent.CONTACT_US_SUCCESS;
			failedEvent = DBCloudEvent.CONTACT_US_FAILED;
			
			request = AEClient.contactUsURLRequest({name: inputData.name,
													email: inputData.email,
													comment: inputData.message,
													subscribe: 1,
													donate: 0,
													attend: 0,
													tool:"DragonBones",
													from: "DesignPanel"});
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