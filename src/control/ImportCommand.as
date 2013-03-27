package control
{
	import dragonBones.utils.BytesType;
	
	import flash.display.BitmapData;
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.system.LoaderContext;
	import flash.utils.ByteArray;
	
	import message.Message;
	import message.MessageDispatcher;
	
	import model.ImportDataProxy;
	import model.SkeletonXMLProxy;
	
	import modifySWF.combine;
	
	import utils.BitmapDataUtil;
	import utils.PNGEncoder;
	
	public class ImportCommand
	{
		public static const instance:ImportCommand = new ImportCommand();
		
		private var _isMerge:Boolean;
		private var _loaderContext:LoaderContext;
		private var _skeletonXMLProxy:SkeletonXMLProxy;
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
		
		public function importFileData(isMerge:Boolean, url:String = null):void
		{
			if(LoadFLADataCommand.instance.isLoading)
			{
				return;
			}
			_isMerge = isMerge;
			
			MessageDispatcher.addEventListener(MessageDispatcher.LOAD_FILEDATA_COMPLETE, loadCommandHandler);
			
			LoadFileDataCommand.instance.load(url);
		}
		
		private function loadCommandHandler(e:Message):void
		{
			switch(e.type)
			{
				case MessageDispatcher.LOAD_FLA_COMPLETE:
				case MessageDispatcher.LOAD_FILEDATA_COMPLETE:
					_isExportedSource = e.type == MessageDispatcher.LOAD_FILEDATA_COMPLETE;
					_skeletonXMLProxy = e.parameters[0] as SkeletonXMLProxy;
					var textureBytes:ByteArray = e.parameters[1] as ByteArray;
					if(_isMerge)
					{
						switch(BytesType.getType(ImportDataProxy.getInstance().textureBytes))
						{
							case BytesType.SWF:
								//mergeSWF
								ImportDataProxy.getInstance().skeletonXMLProxy.merge(_skeletonXMLProxy);
								
								_skeletonXMLProxy = ImportDataProxy.getInstance().skeletonXMLProxy;
								textureBytes = combine(
									ImportDataProxy.getInstance().textureBytes, 
									textureBytes,
									_skeletonXMLProxy.modifySubTextureSize(null)
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
			e.target.removeEventListener(Event.COMPLETE, loaderCompleteHandler);
			
			var bitmapData:BitmapData = new BitmapData(
				_skeletonXMLProxy.textureAtlasWidth,
				_skeletonXMLProxy.textureAtlasHeight,
				true,
				0xFF00FF
			);
			bitmapData.draw(e.target.content);
			
			var mergedBitmapData:BitmapData = mergeBitmapData(
				ImportDataProxy.getInstance().textureAtlas.bitmapData,
				bitmapData, 
				ImportDataProxy.getInstance().skeletonXMLProxy,
				_skeletonXMLProxy
			);
			
			bitmapData.dispose();
			
			MessageDispatcher.dispatchEvent(
				MessageDispatcher.IMPORT_COMPLETE, 
				ImportDataProxy.getInstance().skeletonXMLProxy, 
				PNGEncoder.encode(mergedBitmapData), 
				mergedBitmapData, 
				_isExportedSource
			);
		}
		
		private function mergeBitmapData(rawBitmapData:BitmapData, addBitmapData:BitmapData, rawSkeletonXMLProxy:SkeletonXMLProxy, addSkeletonXMLProxy:SkeletonXMLProxy):BitmapData
		{
			var rawSubBitmapDataDic:Object = BitmapDataUtil.getSubBitmapDataDic(
				rawBitmapData, 
				rawSkeletonXMLProxy.getSubTextureRectDic()
			);
			var addSubBitmapDataDic:Object = BitmapDataUtil.getSubBitmapDataDic(
				addBitmapData, 
				addSkeletonXMLProxy.getSubTextureRectDic()
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
			
			rawSkeletonXMLProxy.merge(addSkeletonXMLProxy);
			
			return BitmapDataUtil.getMergeBitmapData(
				rawSubBitmapDataDic,
				rawSkeletonXMLProxy.getSubTextureRectDic(),
				rawSkeletonXMLProxy.textureAtlasWidth,
				rawSkeletonXMLProxy.textureAtlasHeight
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
				_skeletonXMLProxy, 
				_textureBytes, 
				content, 
				_isExportedSource
			);
		}
	}
}