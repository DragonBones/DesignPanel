package utils{
	import dragonBones.utils.ConstValues;
	
	public class GlobalConstValues {
		public static const SWF_SUFFIX:String = ".dbswf";
		public static const PNG_SUFFIX:String = ".png";
		public static const ZIP_SUFFIX:String = ".zip";
		public static const XML_SUFFIX:String = ".xml";
		public static const JSON_SUFFIX:String = ".json";
		public static const DRAGON_BONES_DATA_NAME:String = "skeleton";
		public static const TEXTURE_ATLAS_DATA_NAME:String = "texture";
		public static const SPINE_FOLDER:String = "spine";
		
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
				ConstValues.SUB_TEXTURE
			];
	}
}