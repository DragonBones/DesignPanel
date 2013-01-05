package control
{
	import dragonBones.objects.DecompressedData;
	import dragonBones.objects.XMLDataParser;
	import dragonBones.utils.BytesType;
	import dragonBones.utils.ConstValues;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Loader;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	import flash.net.FileFilter;
	import flash.net.FileReference;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.system.LoaderContext;
	import flash.utils.ByteArray;
	
	import message.MessageDispatcher;
	
	import utils.GlobalConstValues;
	import utils.PNGEncoder;
	
	import zero.zip.Zip;
	import zero.zip.ZipFile;

	public class LoadFileDataCommand
	{
		public static const instance:LoadFileDataCommand = new LoadFileDataCommand();
		
		private static const FILE_FILTER_ARRAY:Array = [new FileFilter("Exported data", "*." + String(["swf", "png", "zip"]).replace(/\,/g, ";*."))];
		private static var _helpMatirx:Matrix = new Matrix();
		private static var _helpRect:Rectangle = new Rectangle();
		
		private var _fileREF:FileReference;
		private var _urlLoader:URLLoader;
		private var _isLoading:Boolean;
		private var _loaderContext:LoaderContext;
		
		private var _skeletonXML:XML;
		private var _textureAtlasXML:XML;
		private var _bitmapData:BitmapData;
		private var _textureBytes:ByteArray;
		
		public function LoadFileDataCommand()
		{
			_fileREF = new FileReference();
			_urlLoader = new URLLoader();
			_loaderContext = new LoaderContext(false)
			_loaderContext.allowCodeImport = true;
		}
		
		public function load(url:String = null):void
		{
			if(_isLoading)
			{
				return;
			}
			if(url)
			{
				_isLoading = true;
				MessageDispatcher.dispatchEvent(MessageDispatcher.LOAD_FILEDATA);
				_urlLoader.addEventListener(IOErrorEvent.IO_ERROR, onURLLoaderHandler);
				_urlLoader.addEventListener(ProgressEvent.PROGRESS, onURLLoaderHandler);
				_urlLoader.addEventListener(Event.COMPLETE, onURLLoaderHandler);
				_urlLoader.dataFormat = URLLoaderDataFormat.BINARY;
				_urlLoader.load(new URLRequest(url));
			}
			else
			{
				_fileREF.addEventListener(Event.SELECT, onFileHaneler);
				_fileREF.browse(FILE_FILTER_ARRAY);
			}
		}
	
		private function onURLLoaderHandler(e:Event):void
		{
			switch(e.type)
			{
				case IOErrorEvent.IO_ERROR:
					_urlLoader.removeEventListener(Event.COMPLETE, onURLLoaderHandler);
					_urlLoader.removeEventListener(IOErrorEvent.IO_ERROR, onURLLoaderHandler);
					_urlLoader.removeEventListener(ProgressEvent.PROGRESS, onURLLoaderHandler);
					_isLoading = false;
					MessageDispatcher.dispatchEvent(MessageDispatcher.LOAD_FILEDATA_ERROR);
					break;
				case ProgressEvent.PROGRESS:
					var progressEvent:ProgressEvent = e as ProgressEvent;
					MessageDispatcher.dispatchEvent(MessageDispatcher.LOAD_FILEDATA_PROGRESS, progressEvent.bytesLoaded / progressEvent.bytesTotal );
					break;
				case Event.COMPLETE:
					_urlLoader.removeEventListener(Event.COMPLETE, onURLLoaderHandler);
					_urlLoader.removeEventListener(IOErrorEvent.IO_ERROR, onURLLoaderHandler);
					_urlLoader.removeEventListener(ProgressEvent.PROGRESS, onURLLoaderHandler);
					setData(e.target.data);
					break;
			}
		}
		
		private function onFileHaneler(e:Event):void
		{
			switch(e.type)
			{
				case Event.SELECT:
					_isLoading = true;
					MessageDispatcher.dispatchEvent(MessageDispatcher.LOAD_FILEDATA);
					_fileREF.removeEventListener(Event.SELECT, onFileHaneler);
					_fileREF.addEventListener(Event.COMPLETE, onFileHaneler);
					_fileREF.load();
					break;
				case Event.COMPLETE:
					_fileREF.removeEventListener(Event.COMPLETE, onFileHaneler);
					setData(_fileREF.data);
					break;
			}
		}
		
		private function setData(fileData:ByteArray):void
		{
			_isLoading = false;
			var dataType:String = BytesType.getType(fileData);
			switch(dataType)
			{
				case BytesType.SWF:
				case BytesType.PNG:
				case BytesType.JPG:
					try
					{
						var decompressedData:DecompressedData = XMLDataParser.decompressData(fileData);
						_skeletonXML = decompressedData.skeletonXML;
						_textureAtlasXML = decompressedData.textureAtlasXML;
						_textureBytes = decompressedData.textureBytes;
						loadTextureData(_textureBytes);
						return;
					}
					catch(_e:Error)
					{
						break;
					}
				case BytesType.ZIP:
					try
					{
						_textureBytes = null;
						
						var images:Object;
						var zip:Zip = new Zip();
						zip.decode(fileData);
						
						for each(var zipFile:ZipFile in zip.fileV)
						{
							if(!zipFile.isDirectory)
							{
								if(zipFile.name == GlobalConstValues.SKELETON_XML_NAME)
								{
									_skeletonXML = XML(zipFile.data);
								}
								else if(zipFile.name == GlobalConstValues.TEXTURE_ATLAS_XML_NAME)
								{
									_textureAtlasXML = XML(zipFile.data);
								}
								else if(zipFile.name.indexOf(GlobalConstValues.TEXTURE_NAME) == 0)
								{
									if(zipFile.name.indexOf("/") > 0)
									{
										var name:String = zipFile.name.replace(/\.\w+$/,"");
										name = name.split("/").pop();
										if(!images)
										{
											images = {};
										}
										images[name] = zipFile.data;
									}
									else
									{
										_textureBytes = zipFile.data;
									}
								}
							}
						}
						zip.clear();
						if(_textureBytes)
						{
							loadTextureData(_textureBytes);
							return;
						}
						else if(images)
						{
							spliceBitmapData(images);
							return;
						}
						break;
					}
					catch(_e:Error)
					{
						break;
					}
				default:
					break;
			}
			MessageDispatcher.dispatchEvent(MessageDispatcher.LOAD_FILEDATA_ERROR);
		}
		
		private function loadTextureData(textureBytes:ByteArray):void
		{
			var loader:Loader = new Loader();
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE, loaderCompleteHandler);
			loader.loadBytes(textureBytes, _loaderContext);
		}
		
		private function loaderCompleteHandler(e:Event):void
		{
			e.target.removeEventListener(Event.COMPLETE, loaderCompleteHandler);
			var content:Object = e.target.content;
			if (content is Bitmap)
			{
				content = (content as Bitmap).bitmapData;
			}
			else
			{
				content = (content as Sprite).getChildAt(0);
			}
			MessageDispatcher.dispatchEvent(MessageDispatcher.LOAD_FILEDATA_COMPLETE, _skeletonXML, _textureAtlasXML, content, _textureBytes);
		}
		
		private var _images:Object;
		private var _imageName:String;
		
		private function spliceBitmapData(images:Object):void
		{
			_images = images;
			_bitmapData = new BitmapData(
				int(_textureAtlasXML.attribute(ConstValues.A_WIDTH)),
				int(_textureAtlasXML.attribute(ConstValues.A_HEIGHT)),
				true,
				0xFF00FF
			);
			
			spliceBitmapDataStep(null);
		}
		
		private function spliceBitmapDataStep(e:Event):void
		{
			if(e)
			{
				e.target.removeEventListener(Event.COMPLETE, spliceBitmapDataStep);
				var bitmap:Bitmap = e.target.content as Bitmap;
				var subTextureXML:XML = XMLDataParser.getElementsByAttribute(_textureAtlasXML.elements(ConstValues.SUB_TEXTURE), ConstValues.A_NAME, _imageName)[0];
				if(subTextureXML)
				{
					_helpRect.x = int(subTextureXML.attribute(ConstValues.A_X));
					_helpRect.y = int(subTextureXML.attribute(ConstValues.A_Y));
					_helpRect.width = int(subTextureXML.attribute(ConstValues.A_WIDTH));
					_helpRect.height = int(subTextureXML.attribute(ConstValues.A_HEIGHT));
					_helpMatirx.tx = _helpRect.x;
					_helpMatirx.ty = _helpRect.y;
					_bitmapData.draw(bitmap.bitmapData, _helpMatirx, null, null, _helpRect);
				}
			}
			for (var name:String in _images)
			{
				var imageBytes:ByteArray = _images[name];
				_imageName = name;
				delete _images[_imageName];
				break;
			}
			if(!imageBytes)
			{
				try
				{
					_textureBytes = PNGEncoder.encode(_bitmapData);
					MessageDispatcher.dispatchEvent(MessageDispatcher.LOAD_FILEDATA_COMPLETE, _skeletonXML, _textureAtlasXML, _bitmapData, _textureBytes);
				}
				catch(e:Error)
				{
					MessageDispatcher.dispatchEvent(MessageDispatcher.LOAD_FILEDATA_ERROR);
				}
				return;
			}
			var loader:Loader = new Loader();
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE, spliceBitmapDataStep);
			loader.loadBytes(imageBytes, _loaderContext);
		}
	}
}