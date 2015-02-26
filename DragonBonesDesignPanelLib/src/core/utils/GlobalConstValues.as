package core.utils
{
	import dragonBones.core.DragonBones;
	import dragonBones.utils.ConstValues;
	
	import flash.net.FileFilter;
	import flash.utils.ByteArray;
	
	public class GlobalConstValues 
	{
		// import type
		public static const IMPORT_TYPE_NONE:String = "none";
		public static const IMPORT_TYPE_FLA_ALL_LIBRARY_ITEMS:String = "allLibraryItems";
		public static const IMPORT_TYPE_FLA_SELECTED_LIBRARY_ITEMS:String = "selectedItems";
		public static const IMPORT_TYPE_EXPORTED:String = "exportedData";
		
		//configType
		public static const CONFIG_TYPE_MERGED:String = "dataMerged";
		public static const CONFIG_TYPE_AMF3:String = "dataAmf3";
		public static const CONFIG_TYPE_XML:String = "dataXml";
		public static const CONFIG_TYPE_JSON:String = "dataJson";
		
		// texture atlas type
		public static const TEXTURE_ATLAS_TYPE_SWF:String = "textureSwf";
		public static const TEXTURE_ATLAS_TYPE_PNG:String = "texturePng";
		public static const TEXTURE_ATLAS_TYPE_PNGS:String = "texturePngs";
		
		//dataType
		public static const DATA_TYPE_GLOBAL:String = "dataTypeGlobal";
		public static const DATA_TYPE_PARENT:String = "dataTypeParent";
		
		// suffix
		public static const XML_SUFFIX:String = "xml";
		public static const JSON_SUFFIX:String = "json";
		public static const AMF3_SUFFIX:String = "amf3";
		public static const SWF_SUFFIX:String = "swf";
		public static const PNG_SUFFIX:String = "png";
		public static const DBSWF_SUFFIX:String = "dbswf";
		public static const ZIP_SUFFIX:String = "zip";
		public static const JPG_SUFFIX:String = "jpg";
		public static const ATF_SUFFIX:String = "atf";
		
		// file name
		public static const DRAGON_BONES_DATA_NAME:String = "skeleton";
		public static const TEXTURE_ATLAS_DATA_NAME:String = "texture";
		
		public static const SPINE_FOLDER:String = "spine";
		
		//
		public static const A_MATRIX3D:String = "matrix3D";
		
		// file filter
		public static const FILE_FILTER_ARRAY:Array = [new FileFilter("Exported Data", "*." + String([XML_SUFFIX, JSON_SUFFIX, AMF3_SUFFIX, SWF_SUFFIX, PNG_SUFFIX, DBSWF_SUFFIX, ZIP_SUFFIX]).replace(/\,/g, ";*."))];
		
		//
		public static const XML_LIST_NAMES:Vector.<String> = 
			new <String>[
				ConstValues.ARMATURE,
				ConstValues.BONE,
				ConstValues.SKIN,
				ConstValues.SLOT,
				ConstValues.DISPLAY,
				ConstValues.ANIMATION,
				ConstValues.TIMELINE,
				ConstValues.FRAME,
				ConstValues.SUB_TEXTURE,
				ConstValues.ELLIPSE,
				ConstValues.RECTANGLE
			];
		
		
		public static function getFileType(bytes:ByteArray):String
		{
			var type:String = null;
			var b1:uint = bytes[0];
			var b2:uint = bytes[1];
			var b3:uint = bytes[2];
			var b4:uint = bytes[3];
			
			if ((b1 == 0x46 || b1 == 0x43 || b1 == 0x5A) && b2 == 0x57 && b3 == 0x53)
			{
				//CWS FWS ZWS
				type = SWF_SUFFIX;
			}
			else if (b1 == 0x89 && b2 == 0x50 && b3 == 0x4E && b4 == 0x47)
			{
				//89 50 4e 47 0d 0a 1a 0a
				type = PNG_SUFFIX;
			}
			else if (b1 == 0xFF)
			{
				type = JPG_SUFFIX;
			}
			else if (b1 == 0x41 && b2 == 0x54 && b3 == 0x46)
			{
				type = ATF_SUFFIX;
			}
			else if (b1 == 0x50 && b2 == 0x4B)
			{
				type = ZIP_SUFFIX;
			}
			
			return type;
		}
		
		private static var _versionNumber:int = -1;
		public static function get versionNumber():Number
		{
			if(_versionNumber == -1)
			{
				_versionNumber = 0;
				var versionArray:Array = DragonBones.VERSION.split(".");
				
				for(var i:int=0; i < versionArray.length; i++)
				{
					_versionNumber += versionArray[i] * Math.pow(100, versionArray.length - i - 1);
				}
			}
			
			return _versionNumber;
		}
	}
}