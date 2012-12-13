package control
{
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
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
		
		private var _loaderContext:LoaderContext;
		
		private var _textureAtlasXML:XML;
		private var _textureBytes:ByteArray;
		
		public function FLAExportSWFCommand()
		{
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
				var loader:Loader = new Loader();
				loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, loaderHandler);
				loader.contentLoaderInfo.addEventListener(Event.COMPLETE, loaderHandler);
				loader.load(new URLRequest(swfURL), _loaderContext);
			}
		}
		
		private function loaderHandler(e:Event):void
		{
			var loaderInfo:LoaderInfo = e.target as LoaderInfo;
			loaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, loaderHandler);
			loaderInfo.removeEventListener(Event.COMPLETE, loaderHandler);
			switch(e.type)
			{
				case IOErrorEvent.IO_ERROR:
					MessageDispatcher.dispatchEvent(IOErrorEvent.IO_ERROR);
					break;
				case Event.COMPLETE:
					var content:MovieClip = (loaderInfo.content as Sprite).getChildAt(0) as MovieClip;
					content.stop();
					_textureBytes = make(loaderInfo.bytes, _textureAtlasXML);
					MessageDispatcher.dispatchEvent(MessageDispatcher.FLA_TEXTURE_ATLAS_SWF_LOADED, content, _textureBytes);
					break;
			}
		}
	}
}