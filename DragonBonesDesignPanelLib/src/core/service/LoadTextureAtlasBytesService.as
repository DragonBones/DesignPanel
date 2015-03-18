package core.service
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObjectContainer;
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.system.LoaderContext;
	
	import core.events.ServiceEvent;
	import core.model.vo.ImportVO;
	import core.suppotClass._BaseService;
	import core.utils.GlobalConstValues;
	
	public final class LoadTextureAtlasBytesService extends _BaseService
	{
		public static const TEXTURE_ATLAS_BYTES_LOAD_COMPLETE:String = "TEXTURE_ATLAS_BYTES_LOAD_COMPLETE";
		public static const TEXTURE_ATLAS_BYTES_LOAD_ERROR:String = "TEXTURE_ATLAS_BYTES_LOAD_ERROR";
		
		private var _loaderContext:LoaderContext;
		private var _loader:Loader;
		private var _importVO:ImportVO;
		
		public function LoadTextureAtlasBytesService()
		{
			_loaderContext = new LoaderContext(false);
			_loaderContext.allowCodeImport = true;
		}
		
		public function load(importVO:ImportVO):void
		{
			_importVO = importVO;
			_loader = new Loader();
			
			_loader.contentLoaderInfo.addEventListener(Event.COMPLETE, loaderCompleteHandler);
			_loader.loadBytes(_importVO.textureAtlasBytes, _loaderContext);
		}
		
		private function loaderCompleteHandler(e:Event):void
		{
			var loaderInfo:LoaderInfo = e.target as LoaderInfo;
			loaderInfo.removeEventListener(Event.COMPLETE, loaderCompleteHandler);
			
			if (loaderInfo.content is Bitmap)
			{
				_importVO.textureAtlasType = GlobalConstValues.TEXTURE_ATLAS_TYPE_PNG;
				_importVO.textureAtlas = (loaderInfo.content as Bitmap).bitmapData;
				(loaderInfo.content as Bitmap).bitmapData = null;
			}
			else
			{
				_importVO.textureAtlasType = GlobalConstValues.TEXTURE_ATLAS_TYPE_SWF;
				_importVO.textureAtlasSWF = (loaderInfo.content as DisplayObjectContainer).getChildAt(0) as DisplayObjectContainer;
				if(_importVO.textureAtlasSWF is MovieClip)
				{
					(_importVO.textureAtlasSWF as MovieClip).gotoAndStop(1);
				}
				
				_importVO.textureAtlas = new BitmapData(getNearest2N(_importVO.textureAtlasSWF.width), getNearest2N(_importVO.textureAtlasSWF.height), true, 0xFF00FF);
				_importVO.textureAtlas.draw(_importVO.textureAtlasSWF);
			}
			
			this.dispatchEvent(new ServiceEvent(TEXTURE_ATLAS_BYTES_LOAD_COMPLETE, _importVO));
		}
		
		private function getNearest2N(_n:uint):uint
		{
			return _n & _n - 1?1 << _n.toString(2).length:_n;
		}
	}
}