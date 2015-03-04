package core.events
{
	import flash.events.Event;
	
	public final class ControllerEvent extends Event
	{
		public static const STARTUP:String = "startup";
		
		public static const SETTING_STARTUP:String = "settingStartup";
		
		public static const IMPORT_FLA:String = "importFLA";
		public static const IMPORT_FILE:String = "importFile";
		public static const EXPORT_FILE:String = "exportFile";
		
		public static const IMPORT_CANCLE:String = "importCancle";
		public static const IMPORT_ERROR:String = "importError";
		public static const IMPORT_PROGRESS:String = "importProgress";
		public static const IMPORT_COMPLETE:String = "importComplete";
		
		public static const EXPORT_CANCEL:String = "exportCancle";
		public static const EXPORT_ERROR:String = "exportError";
		public static const EXPORT_COMPLETE:String = "exportComplete";
		
		public static const REMOVE_ARMATURE:String = "removeArmature";
		
		public static const CREATE_ANIMATION_TO_FLASH:String = "createAnimationToFlash";
		public static const MULTIPLE_IMPORT_AND_EXPORT:String = "multipleImportAndExport";
		
		public var data:*;
		
		public function ControllerEvent(type:String, data:* = null, bubbles:Boolean = false, cancelable:Boolean = false)
		{
			super(type, bubbles, cancelable);
			
			this.data = data;
		}
	}
}