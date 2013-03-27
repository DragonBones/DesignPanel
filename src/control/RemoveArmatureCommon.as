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
	import model.SkeletonXMLProxy;
	
	import modifySWF.tirm;
	
	import utils.BitmapDataUtil;
	import utils.PNGEncoder;

	public class RemoveArmatureCommon
	{
		public static const instance:RemoveArmatureCommon = new RemoveArmatureCommon();
		
		private var _loaderContext:LoaderContext;
		
		private var _skeletonXMLProxy:SkeletonXMLProxy;
		private var _textureBytes:ByteArray;
		
		public function RemoveArmatureCommon()
		{
			_loaderContext = new LoaderContext(false)
			_loaderContext.allowCodeImport = true;
		}
		
		public function removeArmature(armatureName:String):Boolean
		{
			var rawSkeletonXMLProxy:SkeletonXMLProxy = ImportDataProxy.getInstance().skeletonXMLProxy;
			_skeletonXMLProxy = rawSkeletonXMLProxy.copy();
			if(!_skeletonXMLProxy.removeArmature(armatureName))
			{
				return false;
			}
			
			if(ImportDataProxy.getInstance().textureAtlas.movieClip)
			{
				loadTextureBytes(
					tirm(
						ImportDataProxy.getInstance().textureBytes, 
						_skeletonXMLProxy.modifySubTextureSize(null)
					)
				);
			}
			else
			{
				var subBitmapDataDic:Object = BitmapDataUtil.getSubBitmapDataDic(
					ImportDataProxy.getInstance().textureAtlas.bitmapData, 
					rawSkeletonXMLProxy.getSubTextureRectDic()
				);
				
				var rectDic:Object = _skeletonXMLProxy.getSubTextureRectDic();
				
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
					_skeletonXMLProxy.textureAtlasWidth, 
					_skeletonXMLProxy.textureAtlasHeight
				);
				
				MessageDispatcher.dispatchEvent(
					MessageDispatcher.IMPORT_COMPLETE, 
					_skeletonXMLProxy, 
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
				_skeletonXMLProxy, 
				_textureBytes, 
				content, 
				ImportDataProxy.getInstance().isExportedSource
			);
		}
	}
}