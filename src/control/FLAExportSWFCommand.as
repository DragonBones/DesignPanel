package control
{
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.geom.Rectangle;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;
	
	import message.Message;
	import message.MessageDispatcher;
	
	import model.JSFLProxy;
	import model.SkeletonXMLProxy;
	
	import modifySWF.modify;
	
	public class FLAExportSWFCommand
	{
		public static const instance:FLAExportSWFCommand = new FLAExportSWFCommand();
		
		private var _urlLoader:URLLoader;
		
		private var _skeletonXMLProxy:SkeletonXMLProxy;
		private var _textureBytes:ByteArray;
		
		public function FLAExportSWFCommand()
		{
			_urlLoader = new URLLoader();
			_urlLoader.dataFormat = URLLoaderDataFormat.BINARY;
		}
		
		public function exportSWF(skeletonXMLProxy:SkeletonXMLProxy):void
		{
			_skeletonXMLProxy = skeletonXMLProxy;
			MessageDispatcher.addEventListener(JSFLProxy.EXPORT_SWF, jsflProxyHandler);
			JSFLProxy.getInstance().exportSWF();
		}
		
		private function jsflProxyHandler(e:Message):void
		{
			MessageDispatcher.removeEventListener(JSFLProxy.EXPORT_SWF, jsflProxyHandler);
			
			var swfURL:String = e.parameters[0];
			if(swfURL)
			{
				_urlLoader.addEventListener(IOErrorEvent.IO_ERROR, urlLoaderHandler);
				_urlLoader.addEventListener(Event.COMPLETE, urlLoaderHandler);
				_urlLoader.load(new URLRequest(swfURL));
			}
		}
		
		private function urlLoaderHandler(e:Event):void
		{
			_urlLoader.removeEventListener(IOErrorEvent.IO_ERROR, urlLoaderHandler);
			_urlLoader.removeEventListener(Event.COMPLETE, urlLoaderHandler);
			switch(e.type)
			{
				case IOErrorEvent.IO_ERROR:
					MessageDispatcher.dispatchEvent(IOErrorEvent.IO_ERROR);
					break;
				case Event.COMPLETE:
					_textureBytes = _urlLoader.data;
					
					var loader:Loader = new Loader();
					loader.contentLoaderInfo.addEventListener(Event.COMPLETE, loaderHandler);
					loader.loadBytes(_textureBytes);
					break;
			}
		}
		
		private function loaderHandler(e:Event):void
		{
			var loaderInfo:LoaderInfo = e.target as LoaderInfo;
			loaderInfo.addEventListener(Event.COMPLETE, loaderHandler);
			var content:DisplayObjectContainer = loaderInfo.content as DisplayObjectContainer;
			content = content.getChildAt(0) as DisplayObjectContainer;
			
			var length:uint = content.numChildren;
			var rectList:Vector.<Rectangle> = new Vector.<Rectangle>;
			for(var i:int = 0;i < length;i ++)
			{
				var eachContent:DisplayObject = content.getChildAt(i);
				var rect:Rectangle = eachContent.getBounds(eachContent);
				rectList.push(rect);
			}
			_textureBytes = modify(_textureBytes, _skeletonXMLProxy.modifySubTextureSize(rectList));
			
			MessageDispatcher.dispatchEvent(MessageDispatcher.FLA_TEXTURE_ATLAS_SWF_LOADED, _textureBytes);
		}
	}
}