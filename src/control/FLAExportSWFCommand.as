package control
{
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.system.LoaderContext;
	import flash.utils.ByteArray;
	
	import makeswfs.make;
	
	import message.Message;
	import message.MessageDispatcher;
	
	import model.JSFLProxy;
	
	public class FLAExportSWFCommand
	{
		public static var instance:FLAExportSWFCommand = new FLAExportSWFCommand();
		
		private var _urlLoader:URLLoader;
		private var _loaderContext:LoaderContext;
		
		private var _textureAtlasXML:XML;
		private var _textureBytes:ByteArray;
		
		public function FLAExportSWFCommand()
		{
			_urlLoader = new URLLoader();
			_urlLoader.dataFormat = URLLoaderDataFormat.BINARY;
			
			_loaderContext = new LoaderContext(false)
			_loaderContext.allowCodeImport = true;
		}
		
		public function exportSWF(textureAtlasXML:XML):void
		{
			_textureAtlasXML = textureAtlasXML;
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
					_textureBytes = make(_urlLoader.data, _textureAtlasXML);
					
					var loader:Loader = new Loader();
					loader.contentLoaderInfo.addEventListener(Event.COMPLETE, loaderCompleteHandler);
					loader.loadBytes(_textureBytes, _loaderContext);
					break;
			}
		}
		
		private function loaderCompleteHandler(e:Event):void
		{
			var loaderInfo:LoaderInfo = e.target as LoaderInfo;
			loaderInfo.removeEventListener(Event.COMPLETE, loaderCompleteHandler);
			
			var content:MovieClip = (loaderInfo.content as MovieClip).getChildAt(0) as MovieClip;
			content.stop();
			
			MessageDispatcher.dispatchEvent(MessageDispatcher.FLA_TEXTURE_ATLAS_SWF_LOADED, content, _textureBytes);
		}
	}
}