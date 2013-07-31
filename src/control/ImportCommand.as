package control
{
	import dragonBones.utils.BytesType;
	
	import flash.display.BitmapData;
	import flash.display.Loader;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.system.LoaderContext;
	import flash.utils.ByteArray;
	
	import message.Message;
	import message.MessageDispatcher;
	
	import model.ImportDataProxy;
	import model.XMLDataProxy;
	
	import modifySWF.combine;
	
	import utils.BitmapDataUtil;
	import utils.PNGEncoder;
	
	public class ImportCommand
	{
		public static const instance:ImportCommand = new ImportCommand();
		
		private var _isMerge:Boolean;
		private var _loaderContext:LoaderContext;
		private var _xmlDataProxy:XMLDataProxy;
		private var _textureBytes:ByteArray;
		private var _isExportedSource:Boolean;
		
		public function ImportCommand()
		{
			_loaderContext = new LoaderContext(false)
			_loaderContext.allowCodeImport = true;
		}
		
		public function importFLAData(isMerge:Boolean, isSelectedInFLALibrary:Boolean, armatureNames:Vector.<String> = null):void
		{
			if(LoadFLADataCommand.instance.isLoading)
			{
				return;
			}
			_isMerge = isMerge;
			MessageDispatcher.addEventListener(MessageDispatcher.LOAD_FLA_COMPLETE, loadCommandHandler);
			
			LoadFLADataCommand.instance.load(isSelectedInFLALibrary, armatureNames);
		}
		
		public function importFileData(isMerge:Boolean, url:String = null, fileType:int = 0):void
		{
			if(LoadFLADataCommand.instance.isLoading)
			{
				return;
			}
			_isMerge = isMerge;
			
			MessageDispatcher.addEventListener(MessageDispatcher.LOAD_FILEDATA_COMPLETE, loadCommandHandler);
			
			LoadFileDataCommand.instance.load(url, fileType);
		}
		
		private function loadCommandHandler(e:Message):void
		{
			switch(e.type)
			{
				case MessageDispatcher.LOAD_FLA_COMPLETE:
				case MessageDispatcher.LOAD_FILEDATA_COMPLETE:
					_isExportedSource = e.type == MessageDispatcher.LOAD_FILEDATA_COMPLETE;
					_xmlDataProxy = e.parameters[0] as XMLDataProxy;
					var textureBytes:ByteArray = e.parameters[1] as ByteArray;
					if(_isMerge)
					{
						switch(BytesType.getType(ImportDataProxy.getInstance().textureBytes))
						{
							case BytesType.SWF:
								//mergeSWF
								ImportDataProxy.getInstance().xmlDataProxy.merge(_xmlDataProxy);
								
								_xmlDataProxy = ImportDataProxy.getInstance().xmlDataProxy;
								
								textureBytes = combine(
									ImportDataProxy.getInstance().textureBytes, 
									textureBytes,
									_xmlDataProxy.getTextureAtlasXMLWithPivot()
								);
								loadTextureBytes(textureBytes);
								break;
							default:
								loadMergeBitmapData(textureBytes);
								break;
						}
					}
					else
					{
						loadTextureBytes(textureBytes);
					}
					break;
			}
		}
		
		private function loadMergeBitmapData(textureBytes:ByteArray):void
		{
			var loader:Loader = new Loader();
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE, addLoaderCompleteHandler);
			loader.loadBytes(textureBytes, _loaderContext);
		}
		
		private function addLoaderCompleteHandler(e:Event):void
		{
			e.target.removeEventListener(Event.COMPLETE, addLoaderCompleteHandler);
			
			var bitmapData:BitmapData = e.target.content as BitmapData;
			/*
			var bitmapData:BitmapData = new BitmapData(
				_xmlDataProxy.textureAtlasWidth,
				_xmlDataProxy.textureAtlasHeight,
				true,
				0xFF00FF
			);
			bitmapData.draw(e.target.content);
			*/
			
			var mergedBitmapData:BitmapData = mergeBitmapData(
				ImportDataProxy.getInstance().textureAtlas.bitmapData,
				bitmapData, 
				ImportDataProxy.getInstance().xmlDataProxy,
				_xmlDataProxy
			);
			
			//bitmapData.dispose();
			
			MessageDispatcher.dispatchEvent(
				MessageDispatcher.IMPORT_COMPLETE, 
				ImportDataProxy.getInstance().xmlDataProxy, 
				PNGEncoder.encode(mergedBitmapData), 
				mergedBitmapData, 
				_isExportedSource
			);
		}
		
		private function mergeBitmapData(rawBitmapData:BitmapData, addBitmapData:BitmapData, rawProxy:XMLDataProxy, addProxy:XMLDataProxy):BitmapData
		{
			var rawSubBitmapDataDic:Object = BitmapDataUtil.getSubBitmapDataDic(
				rawBitmapData, 
				rawProxy.getSubTextureRectMap()
			);
			var addSubBitmapDataDic:Object = BitmapDataUtil.getSubBitmapDataDic(
				addBitmapData, 
				addProxy.getSubTextureRectMap()
			);
			
			for(var subTextureName:String in addSubBitmapDataDic)
			{
				var subBitmapData:BitmapData = rawSubBitmapDataDic[subTextureName];
				if(subBitmapData)
				{
					subBitmapData.dispose();
				}
				rawSubBitmapDataDic[subTextureName] = addSubBitmapDataDic[subTextureName];
			}
			
			rawProxy.merge(addProxy);
			
			return BitmapDataUtil.getMergeBitmapData(
				rawSubBitmapDataDic,
				rawProxy.getSubTextureRectMap(),
				rawProxy.textureAtlasWidth,
				rawProxy.textureAtlasHeight
			);
		}
		
		private function loadTextureBytes(textureBytes:ByteArray):void
		{
			_textureBytes = textureBytes;
			var loader:Loader = new Loader();
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE, loaderCompleteHandler);
			loader.loadBytes(_textureBytes, _loaderContext);
		}
		
		private function loaderCompleteHandler(e:Event):void
		{
			e.target.removeEventListener(Event.COMPLETE, loaderCompleteHandler);
			var content:Object = e.target.content.bitmapData;
			if (!content)
			{
				content = (e.target.content as Sprite).getChildAt(0);
				content.stop();
			}
			MessageDispatcher.dispatchEvent(
				MessageDispatcher.IMPORT_COMPLETE, 
				_xmlDataProxy, 
				_textureBytes, 
				content, 
				_isExportedSource
			);
		}
	}
}