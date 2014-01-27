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
		public static const importArrayCollectionSource:Array = new Array('allLibraryItems','selectedItems','exportedData', "spineData");
		public static const exportArrayCollectionSource:Array = new Array('swf','png','swf+xml','png+xml','pngs+xml','swf+json','png+json','pngs+json');
		
		public static const DATA_IMPORT_ID:String = "dataImportID";
		public static const DATA_EXPORT_ID:String = "dataExportID";
		public static const EXPORT_SCALE_ID:String = "exportScaleID";
		public static const EXPORT_BACKGROUND_COLOR:String = "exportBackgoundColor";
		
		public static const MERGE_LAYERS_IN_FOLDER:String = "mergeLayersInfolder";
		
		public static const LANGUAGE_ID:String = "languageID";
		public static const BONE_HIGHLIGHT_COLOR:String = "boneHighlightColor";
		public static const BACKGROUND_COLOR:String = "backgoundColor";
		
		public static const USERNAME:String = "userName";
		public static const USEREMAIL:String = "userEmail";
		
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
		
		public function get dataImportID():int
		{
			return hasData(DATA_IMPORT_ID)?getData(DATA_IMPORT_ID):0;
		}
		public function set dataImportID(value:int):void
		{
			value = value < 0 ? 0 : value;
			setData(DATA_IMPORT_ID, value);
		}
		public var dataImportArrayCollection:ArrayCollection = new ArrayCollection([]);
		
		public function get mergeLayersInFolder():Boolean
		{
			return hasData(MERGE_LAYERS_IN_FOLDER)?getData(MERGE_LAYERS_IN_FOLDER):false;
		}
		public function set mergeLayersInFolder(value:Boolean):void
		{
			setData(MERGE_LAYERS_IN_FOLDER, value);
		}
		
		public var textureMaxWidthID:int;
		public function get textureMaxWidth():int
		{
			if(textureMaxWidthID == 0)
			{
				return 0;
			}
			return int(textureMaxWidthArrayCollection.getItemAt(textureMaxWidthID));
		}
		public var textureMaxWidthArrayCollection:ArrayCollection = new ArrayCollection(["AutoSize", 128, 256, 512, 1024, 2048, 4096]);
		
		public var texturePadding:int = 2;
		
		public var textureSortID:int = 0;
		public var textureSortArrayCollection:ArrayCollection = new ArrayCollection(["MaxRects"]);
		
		public function get dataExportID():int
		{
			return hasData(DATA_EXPORT_ID)?getData(DATA_EXPORT_ID):0;
		}
		public function set dataExportID(value:int):void
		{
			setData(DATA_EXPORT_ID, value);
		}
		
		public function get exportScaleID():int
		{
			return hasData(EXPORT_SCALE_ID)?getData(EXPORT_SCALE_ID):5;
		}
		public function set exportScaleID(value:int):void
		{
			if(value < 0)
			{
				value = 7;
			}
			setData(EXPORT_SCALE_ID, value);
		}
		
		public var dataExportArrayCollection:ArrayCollection = new ArrayCollection([]);
		
		public function get languageID():int
		{
			return hasData(LANGUAGE_ID)?getData(LANGUAGE_ID):0;
		}
		public function set languageID(value:int):void
		{
			updateLanguage(value);
			setData(LANGUAGE_ID, value);
		}
		public var languageArrayCollection:ArrayCollection = new ArrayCollection([
			{label:"English", value:"en_US"}, 
			{label:"中文", value:"zh_CN"},
			{label:"Français", value:"fr_FR"},
			{label:"日本語", value:"ja_JP"}
		]);
		
		public function get boneHighlightColor():uint
		{
			return hasData(BONE_HIGHLIGHT_COLOR)?getData(BONE_HIGHLIGHT_COLOR):0xFF0000;
		}
		public function set boneHighlightColor(value:uint):void
		{
			setData(BONE_HIGHLIGHT_COLOR, value);
		}
		
		public function get backgroundColor():uint
		{
			return hasData(BACKGROUND_COLOR)?getData(BACKGROUND_COLOR):0xFFFFFFFF;
		}
		public function set backgroundColor(value:uint):void
		{
			setData(BACKGROUND_COLOR, value);
		}
		
		public function get userName():String
		{
			return hasData(USERNAME)?getData(USERNAME):"";
		}
		public function set userName(value:String):void
		{
			setData(USERNAME, value);
		}
		
		public function get userEmail():String
		{
			return hasData(USEREMAIL)?getData(USEREMAIL):"";;;
		}
		public function set userEmail(value:String):void
		{
			setData(USEREMAIL, value);
		}
		
		public function SettingDataProxy()
		{
			if (_instance)
			{
				throw new IllegalOperationError("Singleton already constructed!");
			}
			
			_shareObject = SharedObject.getLocal(SHARE_LOCAL, "/");
			
			if(hasData(LANGUAGE_ID))
			{
				updateLanguage(languageID);
			}
			else if (JSFLProxy.isAvailable)
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
							return;
						}
					}
					languageID = 0;
					break;
			}
		}
		
		private function updateLanguage(value:int):void
		{
			ResourceManager.getInstance().localeChain = [languageArrayCollection[value].value];
			
			dataImportArrayCollection.source.length = 0;
			dataImportArrayCollection.source.push(ResourceManager.getInstance().getString('resources', String(importArrayCollectionSource[0])));
			dataImportArrayCollection.source.push(ResourceManager.getInstance().getString('resources', String(importArrayCollectionSource[1])));
			dataImportArrayCollection.source.push(ResourceManager.getInstance().getString('resources', String(importArrayCollectionSource[2])));
			dataImportArrayCollection.source.push(ResourceManager.getInstance().getString('resources', String(importArrayCollectionSource[3])));
			
			dataExportArrayCollection.source.length = 0;
			dataExportArrayCollection.source.push(ResourceManager.getInstance().getString('resources', String(exportArrayCollectionSource[0])));
			dataExportArrayCollection.source.push(ResourceManager.getInstance().getString('resources', String(exportArrayCollectionSource[1])));
			dataExportArrayCollection.source.push(ResourceManager.getInstance().getString('resources', String(exportArrayCollectionSource[2])));
			dataExportArrayCollection.source.push(ResourceManager.getInstance().getString('resources', String(exportArrayCollectionSource[3])));
			dataExportArrayCollection.source.push(ResourceManager.getInstance().getString('resources', String(exportArrayCollectionSource[4])));
			dataExportArrayCollection.source.push(ResourceManager.getInstance().getString('resources', String(exportArrayCollectionSource[5])));
			dataExportArrayCollection.source.push(ResourceManager.getInstance().getString('resources', String(exportArrayCollectionSource[6])));
			dataExportArrayCollection.source.push(ResourceManager.getInstance().getString('resources', String(exportArrayCollectionSource[7])));
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