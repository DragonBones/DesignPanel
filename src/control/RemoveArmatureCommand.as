package control
{
	import flash.display.BitmapData;
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.system.LoaderContext;
	import flash.utils.ByteArray;
	
	import message.MessageDispatcher;
	
	import model.ImportDataProxy;
	import model.XMLDataProxy;
	
	import modifySWF.tirm;
	
	import utils.BitmapDataUtil;
	import utils.PNGEncoder;

	public class RemoveArmatureCommand
	{
		public static const instance:RemoveArmatureCommand = new RemoveArmatureCommand();
		
		private var _loaderContext:LoaderContext;
		
		private var _xmlDataProxy:XMLDataProxy;
		private var _textureBytes:ByteArray;
		
		public function RemoveArmatureCommand()
		{
			_loaderContext = new LoaderContext(false)
			_loaderContext.allowCodeImport = true;
		}
		
		public function removeArmature(armatureName:String):Boolean
		{
			var rawXMLDataProxy:XMLDataProxy = ImportDataProxy.getInstance().xmlDataProxy;
			_xmlDataProxy = rawXMLDataProxy.clone();
			if(!_xmlDataProxy.removeArmature(armatureName))
			{
				return false;
			}
			
			if(ImportDataProxy.getInstance().textureAtlas.movieClip)
			{
				loadTextureBytes(
					tirm(
						ImportDataProxy.getInstance().textureBytes, 
						_xmlDataProxy.getTextureAtlasXMLWithPivot()
					)
				);
			}
			else
			{
				var subBitmapDataDic:Object = BitmapDataUtil.getSubBitmapDataDic(
					ImportDataProxy.getInstance().textureAtlas.bitmapData, 
					rawXMLDataProxy.getSubTextureRectMap()
				);
				
				var rectDic:Object = _xmlDataProxy.getSubTextureRectMap();
				
				for(var subTextureName:String in subBitmapDataDic)
				{
					if(!rectDic[subTextureName])
					{
						delete subBitmapDataDic[subTextureName];
						continue;
					}
				}
				
				var bitmapData:BitmapData = BitmapDataUtil.getMergeBitmapData(
					subBitmapDataDic, 
					rectDic, 
					_xmlDataProxy.textureAtlasWidth, 
					_xmlDataProxy.textureAtlasHeight
				);
				
				MessageDispatcher.dispatchEvent(
					MessageDispatcher.IMPORT_COMPLETE, 
					_xmlDataProxy, 
					PNGEncoder.encode(bitmapData), 
					bitmapData, 
					false
				);
			}
			
			return true;
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
			var content:Object = (e.target.content as Sprite).getChildAt(0);
			content.stop();
			
			MessageDispatcher.dispatchEvent(
				MessageDispatcher.IMPORT_COMPLETE, 
				_xmlDataProxy, 
				_textureBytes, 
				content, 
				ImportDataProxy.getInstance().isExportedSource
			);
		}
	}
}