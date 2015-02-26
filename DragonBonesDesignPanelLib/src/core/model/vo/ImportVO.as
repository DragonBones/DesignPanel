package core.model.vo
{
	import flash.display.BitmapData;
	import flash.display.DisplayObjectContainer;
	import flash.utils.ByteArray;
	
	import core.utils.GlobalConstValues;

	public final class ImportVO
	{
		//导入数据的唯一标识
		public var id:String = null;
		
		//数据的名称
		public var name:String = null;
		
		//数据的url
		public var url:String = null;
		
		//
		public var typeFilter:Array = null;
		
		//数据的导入类型，allLibraryItemsselected, LibraryItems, exportedData
		public var importType:String = null;
		
		//配置文件类型，amf3，json，xml
		public var configType:String = null;
		
		//资源贴图类型，swf，png，pngs
		public var textureAtlasType:String = null;
		
		//数据类型，相对数据，绝对数据
		public var dataType:String = null;
		
		//只导入数组中存在的
		public var flaItems:Vector.<String> = null;
		
		//是否在倒入完成后合并
		public var isToMerge:Boolean = false;
		
		//加载的原始数据
		public var data:ByteArray = null;
		
		//
		public var textureAtlasWidth:uint = 0;
		public var textureAtlasPadding:uint = 0;
		public var fadeInTime:Number = 0;
		
		public var skeleton:XML = null;
		public var textureAtlasConfig:XML = null;
		public var textureAtlasBytes:ByteArray = null;
		
		public var textureAtlasSWF:DisplayObjectContainer = null
		public var textureAtlas:BitmapData = null;
		
		public function get isImportFromFLA():Boolean
		{
			return importType == GlobalConstValues.IMPORT_TYPE_FLA_ALL_LIBRARY_ITEMS || importType == GlobalConstValues.IMPORT_TYPE_FLA_SELECTED_LIBRARY_ITEMS;
		}
		
		public function ImportVO()
		{
			textureAtlasWidth = 0;
			textureAtlasPadding = 2;
		}
		
		public function dispose():void
		{
			data = null;
			skeleton = null;
			textureAtlasConfig = null;
			textureAtlasSWF = null;
			
			if(textureAtlasBytes)
			{
				textureAtlasBytes.clear();
				textureAtlasBytes = null;
			}
			
			if(textureAtlas)
			{
				textureAtlas.dispose();
				textureAtlas = null;
			}
		}
		
		public function clone():ImportVO
		{
			var importVO:ImportVO = new ImportVO();
			
			importVO.id = id;
			importVO.name = name;
			importVO.url = url;
			importVO.importType = importType;
			importVO.configType = configType;
			importVO.textureAtlasType = textureAtlasType;
			importVO.dataType = dataType;
			importVO.typeFilter = typeFilter;
			importVO.flaItems = flaItems;
			importVO.isToMerge = isToMerge;
			importVO.textureAtlasWidth = textureAtlasWidth;
			importVO.textureAtlasPadding = textureAtlasPadding;
			importVO.fadeInTime = fadeInTime;
			
			if(skeleton)
			{
				importVO.skeleton = skeleton.copy();
			}
			if(textureAtlasConfig)
			{
				importVO.textureAtlasConfig = textureAtlasConfig.copy();
			}
			
			
			// 是否需要深度拷贝
			importVO.data = data;
			importVO.textureAtlasBytes = textureAtlasBytes;
			importVO.textureAtlasSWF = textureAtlasSWF;
			importVO.textureAtlas = textureAtlas;
			
			return importVO;
		}
	}
}