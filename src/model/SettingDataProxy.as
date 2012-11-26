package model
{
	import flash.errors.IllegalOperationError;
	
	import mx.collections.ArrayCollection;
	
	[Bindable]
	public class SettingDataProxy
	{
		private static const DATA_IMPORT_ID:String = "dataImportID";
		private static const DATA_EXPORT_ID:String = "dataExportID";
		
		private static var _instance:SettingDataProxy;
		public static function getInstance():SettingDataProxy
		{
			if(!_instance)
			{
				_instance = new SettingDataProxy();
			}
			return _instance;
		}
		
		private var _dataImportID:int = 0;
		public function get dataImportID():int
		{
			return _dataImportID;
		}
		public function set dataImportID(value:int):void
		{
			_dataImportID = value < 0 ? 0 : value;
			ShareObjectDataProxy.getInstance().setData(DATA_IMPORT_ID, _dataImportID);
		}
		
		public var textureMaxWidthID:int = 0;
		public var textureMaxWidthAC:ArrayCollection = new ArrayCollection(["Auto size", 128, 256, 512, 1024, 2048, 4096]);
		public function get textureMaxWidth():int
		{
			if(textureMaxWidthID == 0)
			{
				return 0;
			}
			return int(textureMaxWidthAC.getItemAt(textureMaxWidthID));
		}
		
		public var texturePadding:int = 2;
		
		public var textureSortID:int = 0;
		public var textureSortAC:ArrayCollection = new ArrayCollection(["MaxRects"]);
		
		private var _dataExportID:int = 0;
		public function get dataExportID():int
		{
			return _dataExportID;
		}
		
		public function set dataExportID(value:int):void
		{
			_dataExportID = value;
			ShareObjectDataProxy.getInstance().setData(DATA_EXPORT_ID, _dataExportID);
		}
		
		public function SettingDataProxy()
		{
			if (_instance)
			{
				throw new IllegalOperationError("Singleton already constructed!");
			}
			
			if(ShareObjectDataProxy.getInstance().hasData(DATA_IMPORT_ID))
			{
				_dataImportID = int(ShareObjectDataProxy.getInstance().getData(DATA_IMPORT_ID));
			}
			else
			{
				_dataImportID = 0;
			}
			
			if(ShareObjectDataProxy.getInstance().hasData(DATA_EXPORT_ID))
			{
				_dataExportID = int(ShareObjectDataProxy.getInstance().getData(DATA_EXPORT_ID));
			}
			else
			{
				_dataExportID = 0;
			}
		}
		
	}
	
}