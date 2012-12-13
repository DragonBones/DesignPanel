package model
{
	import flash.errors.IllegalOperationError;
	import flash.net.SharedObject;
	
	import mx.collections.ArrayCollection;
	import mx.resources.ResourceManager;
	
	import message.Message;
	import message.MessageDispatcher;
	
	[Bindable]
	public class SettingDataProxy
	{
		public static const DATA_IMPORT_ID:String = "dataImportID";
		public static const DATA_EXPORT_ID:String = "dataExportID";
		
		public static const LANGUAGE_ID:String = "languageID";
		public static const BONE_HIGHLIGHT_COLOR:String = "boneHighlightColor";
		public static const BACKGROUND_COLOR:String = "backgoundColor";
		
		private static const SHARE_LOCAL:String = "DragonBones/SkeletonDesignPanel/V1";
		
		
		private static var _instance:SettingDataProxy;
		public static function getInstance():SettingDataProxy
		{
			if(!_instance)
			{
				_instance = new SettingDataProxy();
			}
			return _instance;
		}
		
		private var _shareObject:SharedObject;
		
		private var _dataImportID:int = 0;
		public function get dataImportID():int
		{
			return _dataImportID;
		}
		public function set dataImportID(value:int):void
		{
			_dataImportID = value < 0 ? 0 : value;
			setData(DATA_IMPORT_ID, _dataImportID);
		}
		public var dataImportArrayCollection:ArrayCollection = new ArrayCollection([]);
		
		public var textureMaxWidthID:int = 0;
		public function get textureMaxWidth():int
		{
			if(textureMaxWidthID == 0)
			{
				return 0;
			}
			return int(textureMaxWidthArrayCollection.getItemAt(textureMaxWidthID));
		}
		public var textureMaxWidthArrayCollection:ArrayCollection = new ArrayCollection(["Auto size", 128, 256, 512, 1024, 2048, 4096]);
		
		public var texturePadding:int = 2;
		
		public var textureSortID:int = 0;
		public var textureSortArrayCollection:ArrayCollection = new ArrayCollection(["MaxRects"]);
		
		private var _dataExportID:int = 0;
		public function get dataExportID():int
		{
			return _dataExportID;
		}
		public function set dataExportID(value:int):void
		{
			_dataExportID = value;
			setData(DATA_EXPORT_ID, _dataExportID);
		}
		public var dataExportArrayCollectio:ArrayCollection = new ArrayCollection([]);
		
		private var _languageID:int = -1;
		public function get languageID():int
		{
			return _languageID;
		}
		public function set languageID(value:int):void
		{
			_languageID = value;
			ResourceManager.getInstance().localeChain = [languageArrayCollection[_languageID].value];
			
			dataImportArrayCollection.source.length = 0;
			dataImportArrayCollection.source.push(ResourceManager.getInstance().getString('resources','allLibraryItems'));
			dataImportArrayCollection.source.push(ResourceManager.getInstance().getString('resources','selectedItems'));
			dataImportArrayCollection.source.push(ResourceManager.getInstance().getString('resources','exportedData'));
			
			dataExportArrayCollectio.source.length = 0;
			dataExportArrayCollectio.source.push(ResourceManager.getInstance().getString('resources','SWFwithXML'));
			dataExportArrayCollectio.source.push(ResourceManager.getInstance().getString('resources','PNGwithXML'));
			dataExportArrayCollectio.source.push(ResourceManager.getInstance().getString('resources','ZIPwithXMLAndSWF'));
			dataExportArrayCollectio.source.push(ResourceManager.getInstance().getString('resources','ZIPwithXMLAndPNG'));
			dataExportArrayCollectio.source.push(ResourceManager.getInstance().getString('resources','ZIPwithXMLAndPNGs'));
			
			setData(LANGUAGE_ID, _languageID);
		}
		public var languageArrayCollection:ArrayCollection = new ArrayCollection([
			{label:"English", value:"en_US"}, 
			{label:"中文", value:"zh_CN"},
			{label:"Français", value:"fr_FR"},
			{label:"日本語", value:"ja_JP"}
		]);
		
		private var _boneHighlightColor:uint;
		public function get boneHighlightColor():uint
		{
			return _boneHighlightColor;
		}
		public function set boneHighlightColor(value:uint):void
		{
			_boneHighlightColor = value;
			setData(BONE_HIGHLIGHT_COLOR, _boneHighlightColor);
		}
		
		private var _backgroundColor:uint;
		public function get backgroundColor():uint
		{
			return _backgroundColor;
		}
		public function set backgroundColor(value:uint):void
		{
			_backgroundColor = value;
			setData(BACKGROUND_COLOR, _backgroundColor);
		}
		
		public function SettingDataProxy()
		{
			if (_instance)
			{
				throw new IllegalOperationError("Singleton already constructed!");
			}
			
			_shareObject = SharedObject.getLocal(SHARE_LOCAL, "/");
			
			_dataImportID = hasData(DATA_IMPORT_ID)?getData(DATA_IMPORT_ID):0;
			_dataExportID = hasData(DATA_EXPORT_ID)?getData(DATA_EXPORT_ID):0;
			
			_boneHighlightColor = hasData(BONE_HIGHLIGHT_COLOR)?getData(BONE_HIGHLIGHT_COLOR):0xFF0000;
			
			if(hasData(LANGUAGE_ID))
			{
				languageID = getData(LANGUAGE_ID);
			}
			else if (JSFLProxy.getInstance().isAvailable)
			{
				MessageDispatcher.addEventListener(LANGUAGE_ID, jsflProxyHandler);
				JSFLProxy.getInstance().runJSFLCode(LANGUAGE_ID, "fl.languageCode;");
			}
			else
			{
				languageID = 0;
			}
		}
		
		private function jsflProxyHandler(e:Message):void
		{
			switch(e.type)
			{
				case LANGUAGE_ID:
					MessageDispatcher.removeEventListener(LANGUAGE_ID, jsflProxyHandler);
					var languageCode:String = e.parameters[0];
					var length:int = languageArrayCollection.length;
					for(var i:int = 0; i < length; i++)
					{
						if(languageArrayCollection[i].value == languageCode)
						{
							languageID = i;
							break;
						}
					}
					break;
			}
		}
		
		/**
		 * Determine if key is exist
		 */
		public function hasData(key:String):Boolean
		{
			return Boolean(key in _shareObject.data);
		}
		
		/**
		 * Get data by key
		 */
		public function getData(key:String):*
		{
			return _shareObject.data[key];
		}
		
		/**
		 * Set data by key and value
		 */
		public function setData(key:String, value:*):void
		{
			if(_shareObject.data[key] != value)
			{
				_shareObject.data[key] = value;
				_shareObject.flush();
				MessageDispatcher.dispatchEvent(MessageDispatcher.SETTING_DATA_CHANGE, key, value);
			}
		}
		
	}
	
}