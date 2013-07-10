package cloud.events
{
	import flash.events.Event;
	
	public class DBCloudEvent extends Event
	{
		public static const INITED:String = "DBCloudEvent:INITED";
		
		public static const LOAD_LATESTVERSION_SUCCESS:String = "AECloudEvent:LOAD_LATESTVERSION_SUCCESS";
		public static const LOAD_LATESTVERSION_FAILED:String = "AECloudEvent:LOAD_LATESTVERSION_FAILED";
		
		
		
		public static const TEST_TIMEBOMB_SUCCESS:String = "AECloudEvent:TEST_TIMEBOMB_SUCCESS";
		
		public static const LOAD_SERVER_TIME_SUCCESS:String = "AECloudEvent:LOAD_SERVER_TIME_SUCCESS";
		public static const LOAD_SERVER_TIME_FAILED:String = "AECloudEvent:LOAD_SERVER_TIME_FAILED";
		
		public static const LOGIN_START:String = "AECloudEvent:LOGIN_START";
		public static const LOGIN_END:String = "AECloudEvent:LOGIN_END";
		
		public static const LOGIN_SUCCESS:String = "AECloudEvent:LOGIN_SUCCESS";
		public static const LOGIN_FAILED:String = "AECloudEvent:LOGIN_FAILED";
		
		public static const LOGOUT_SUCCESS:String = "AECloudEvent:LOGOUT_SUCCESS";

		public static const USER_PROFILE_SUCCESS:String = "AECloudEvent:USER_PROFILE_SUCCESS";
		public static const USER_PROFILE_FAILED:String = "AECloudEvent:USER_PROFILE_FAILED";
		
		public static const USER_NEWSFEED_SUCCESS:String = "AECloudEvent:USER_NEWSFEED_SUCCESS";
		public static const USER_NEWSFEED_FAILED:String = "AECloudEvent:USER_NEWSFEED_FAILED";
		
		public static const POPULAR_USERS_SUCCESS:String = "AECloudEvent:POPULAR_USERS_SUCCESS";
		public static const POPULAR_USERS_FAILED:String = "AECloudEvent:POPULAR_USERS_FAILED";
		
		public static const USER_PROJECTS_SUCCESS:String = "AECloudEvent:USER_PROJECTS_SUCCESS";
		public static const USER_PROJECTS_FAILED:String = "AECloudEvent:USER_PROJECTS_FAILED";
		
		public static const UPLOAD_PIC_SUCCESS:String = "AECloudEvent:UPLOAD_PIC_SUCCESS";
		public static const UPLOAD_PIC_FAILED:String = "AECloudEvent:UPLOAD_PIC_FAILED";
		
		public static const UPLOAD_ATTACHMENT_SUCCESS:String = "AECloudEvent:UPLOAD_ATTACHMENT_SUCCESS";
		public static const UPLOAD_ATTACHMENT_FAILED:String = "AECloudEvent:UPLOAD_ATTACHMENT_FAILED";
		
		public static const UPLOAD_PROJECT_START:String = "AECloudEvent:UPLOAD_PROJECT_START";
		public static const UPLOAD_PROJECT_END:String = "AECloudEvent:UPLOAD_PROJECT_END";
		
		public static const UPLOAD_PROJECT_SUCCESS:String = "AECloudEvent:UPLOAD_PROJECT_SUCCESS";
		public static const UPLOAD_PROJECT_FAILED:String = "AECloudEvent:UPLOAD_PROJECT_FAILED";
		
		public static const DOWNLOAD_PROJECT_SUCCESS:String = "AECloudEvent:DOWNLOAD_PROJECT_SUCCESS";
		public static const DOWNLOAD_PROJECT_FAILED:String = "AECloudEvent:DOWNLOAD_PROJECT_FAILED";
		
		public static const GET_TIME_SUCCESS:String = "AECloudEvent:GET_TIME_SUCCESS";
		public static const GET_TIME_FAILED:String = "AECloudEvent:GET_TIME_FAILED";
		
		public static const LOAD_ABOUT_SUCCESS:String = "AECloudEvent:LOAD_ABOUT_SUCCESS";
		public static const LOAD_ABOUT_FAILED:String = "AECloudEvent:LOAD_ABOUT_FAILED";
		
		public static const SEND_LOG_SUCCESS:String = "AECloudEvent:SEND_LOG_SUCCESS";
		public static const SEND_LOG_FAILED:String = "AECloudEvent:SEND_LOG_FAILED";
		
		public static const SEND_SINAWEIBO_SUCCESS:String = "AECloudEvent:SEND_SINAWEIBO_SUCCESS";
		public static const SEND_SINAWEIBO_FAILED:String = "AECloudEvent:SEND_SINAWEIBO_FAILED";
		
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