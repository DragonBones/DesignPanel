package message
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	
	public class MessageDispatcher extends EventDispatcher
	{
		static public const LOAD_FLADATA:String = "loadFladata";
		static public const LOAD_FLADATA_ERROR:String = "loadFladataError";
		static public const LOAD_ARMATURE_DATA:String = "loadArmatureData";
		static public const LOAD_ARMATURE_DATA_COMPLETE:String = "loadArmatureDataComplete";
		static public const LOAD_TEXTURE_DATA_COMPLETE:String = "loadTextureDataComplete";
		static public const LOAD_TEXTURE_DATA:String = "loadTextureData";
		static public const LOAD_FLA_COMPLETE:String = "loadFLAComplete";
		
		static public const LOAD_FILEDATA:String = "loadFiledata";
		static public const LOAD_FILEDATA_ERROR:String = "loadFiledataError";
		static public const LOAD_FILEDATA_PROGRESS:String = "loadFiledataProgress";
		static public const LOAD_FILEDATA_COMPLETE:String = "loadFiledataComplete";
		
		static public const MERGE_BITMAPDATA_COMPLETE:String = "mergeBitmapDataComplete";
		static public const IMPORT_COMPLETE:String = "importComplete";
		
		static public const SAVE_ANIMATION_START:String = "saveAnimationStart";
		static public const SAVE_ANIMATION_ERROR:String = "saveAnimationError";
		static public const SAVE_ANIMATION_PROGRESS:String = "saveAnimationProgress";
		static public const SAVE_ANIMATION_COMPLETE:String = "saveAnimationComplete";
		
		static public const EXPORT:String = "export";
		static public const EXPORT_CANCEL:String = "exportCancel";
		static public const EXPORT_ERROR:String = "exportError";
		static public const EXPORT_COMPLETE:String = "exportComplete";
		
		public static const FLA_TEXTURE_ATLAS_SWF_LOADED:String = "flaTextureAtlasSWFLoaded";
		
		public static const SETTING_DATA_CHANGE:String = "settingDataChange";
		
		public static const CHANGE_IMPORT_DATA:String = "chagneImportData";
		public static const SELECT_ARMATURE:String = "selectArmature";
		public static const SELECT_ANIMATION:String = "selectAnimation";
		public static const SELECT_BONE:String = "selectBone";
		public static const CHANGE_BONE_PARENT:String = "changeBoneParent";
		public static const CHANGE_ANIMATION_DATA:String = "changeAnimationData";
		public static const CHANGE_TRANSFORM_TIMELINE_DATA:String = "changeTransformTimelineData";
		
		private static var instance:MessageDispatcher = new MessageDispatcher();
		
		public static function dispatchEvent(_type:String, ... args):void
		{
			var _event:Message = new Message(_type);
			_event.parameters = args;
			instance.dispatchEvent(_event);
		}
		
		public static function addEventListener(_type:String, _listener:Function):void
		{
			instance.addEventListener(_type, _listener);
		}
		
		public static function removeEventListener(_type:String, _listener:Function):void
		{
			instance.removeEventListener(_type, _listener);
		}
		
		public function MessageDispatcher()
		{
			super(this);
		}
	}
}
