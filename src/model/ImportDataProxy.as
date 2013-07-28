package model
{
	import dragonBones.core.dragonBones_internal;
	import dragonBones.factorys.NativeFactory;
	import dragonBones.objects.ArmatureData;
	import dragonBones.objects.SkeletonData;
	import dragonBones.objects.XMLDataParser;
	import dragonBones.textures.NativeTextureAtlas;
	
	import flash.errors.IllegalOperationError;
	import flash.utils.ByteArray;
	
	import message.MessageDispatcher;
	
	import mx.collections.ArrayCollection;
	
	use namespace dragonBones_internal;
	
	[Bindable]
	/**
	 * Manage imported data
	 */
	public class ImportDataProxy
	{
		private static const DATA_NAME:String = "importName";
		
		private static var _instance:ImportDataProxy
		public static function getInstance():ImportDataProxy
		{
			if(!_instance)
			{
				_instance = new ImportDataProxy();
			}
			return _instance;
		}
		
		public var armaturesAC:ArrayCollection;
		
		public var isExportedSource:Boolean;
		
		private var _factory:NativeFactory;
		public function get factory():NativeFactory
		{
			return _factory;
		}
		
		private var _xmlDataProxy:XMLDataProxy;
		public function get xmlDataProxy():XMLDataProxy
		{
			return _xmlDataProxy;
		}
		
		public var armatureProxy:ArmatureProxy;
		
		private var _data:SkeletonData;
		public function get data():SkeletonData
		{
			return _data;
		}
		
		private var _textureAtlas:NativeTextureAtlas;
		public function get textureAtlas():NativeTextureAtlas
		{
			return _textureAtlas;
		}
		
		private var _textureBytes:ByteArray;
		public function get textureBytes():ByteArray
		{
			return _textureBytes;
		}
		
		public function ImportDataProxy()
		{
			if (_instance) 
			{
				throw new IllegalOperationError("Singleton already constructed!");
			}
			
			armaturesAC = new ArrayCollection();
			_factory = new NativeFactory();
			_factory.fillBitmapSmooth = true;
			
			armatureProxy = new ArmatureProxy();
			armatureProxy.factory = _factory;
		}
		
		public function setData(xmlDataProxy:XMLDataProxy, textureBytes:ByteArray, textureData:Object, isExportedSource:Boolean):void
		{
			if(_data)
			{
				_factory.removeSkeletonData(DATA_NAME);
				_data.dispose();
			}
			
			if(_textureAtlas)
			{
				_factory.removeTextureAtlas(DATA_NAME);
				_textureAtlas.dispose();
			}
			
			_xmlDataProxy = xmlDataProxy;
			_textureBytes = textureBytes;
			this.isExportedSource = isExportedSource;
			
			_data = XMLDataParser.parseSkeletonData(_xmlDataProxy.xml);
			_textureAtlas = new NativeTextureAtlas(textureData, _xmlDataProxy.textureAtlasXML)
			_textureAtlas.movieClipToBitmapData();
			_factory.addSkeletonData(_data, DATA_NAME);
			_factory.addTextureAtlas(_textureAtlas, DATA_NAME);
			
			armaturesAC.source = getArmatureList();
			
			MessageDispatcher.dispatchEvent(MessageDispatcher.CHANGE_IMPORT_DATA, this);
		}
		
		private function getArmatureList():Array
		{
			var armatureList:Array = [];
			for each(var armatureData:ArmatureData in _data.armatureDataList)
			{
				armatureList.push(armatureData);
			}
			return armatureList;
		}
	}
}