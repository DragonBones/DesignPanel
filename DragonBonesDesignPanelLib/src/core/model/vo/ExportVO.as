package core.model.vo
{
	public final class ExportVO
	{
		public var textureAtlasType:String = null;
		public var configType:String = null;
		public var dataType:String = null;
		public var enableDataOptimization:Boolean = false;
		public var scale:Number = 1;
		public var enableBackgroundColor:Boolean = false;
		public var backgroundColor:uint = 0xff00ff;
		
		
		public var name:String = null;
		public var dragonBonesFileName:String = null;
		public var textureAtlasConfigFileName:String = null;
		public var textureAtlasFileName:String = null;
		public var subTextureFolderName:String = null;
		
		//
		public var exportPath:String = null;
		
		private var _textureAtlasPath:String = null;
		public function get textureAtlasPath():String
		{
			return _textureAtlasPath || "";
		}
		public function set textureAtlasPath(value:String):void
		{
			if (value)
			{
				_textureAtlasPath = value
					.replace(/\\/g,"/")
					.replace(/\/+$/,"")
					+"/";
			}
			else
			{
				_textureAtlasPath = null;
			}
		}
	}
}