package control
{
	import com.adobe.serialization.json.JSON;
	
	import dragonBones.objects.DataParser;
	import dragonBones.objects.DecompressedData;
	import dragonBones.utils.BytesType;
	import dragonBones.utils.ConstValues;
	import dragonBones.utils.checkBytesTailisXML;
	
	import flash.display.BitmapData;
	import flash.display.Loader;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.geom.Rectangle;
	import flash.net.FileFilter;
	import flash.net.FileReference;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.system.LoaderContext;
	import flash.utils.ByteArray;
	
	import message.MessageDispatcher;
	
	import model.XMLDataProxy;
	
	import utils.BitmapDataUtil;
	import utils.GlobalConstValues;
	import utils.PNGEncoder;
	import utils.formatSpineData;
	import utils.objectToXML;
	
	import zero.zip.Zip;
	import zero.zip.ZipFile;

	public class LoadFileDataCommand
	{
		public static const instance:LoadFileDataCommand = new LoadFileDataCommand();
		
		private static const FILE_FILTER_ARRAY:Array = [new FileFilter("Exported data", "*." + String(["swf", "dbswf", "png", "zip"]).replace(/\,/g, ";*."))];
	
		private var _fileREF:FileReference;
		private var _urlLoader:URLLoader;
		private var _loaderContext:LoaderContext;
		
		private var _xmlDataProxy:XMLDataProxy;
		private var _bitmapData:BitmapData;
		
		private var _isLoading:Boolean;
		public function isLoading():Boolean
		{
			return _isLoading;
		}
		
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
					MessageDispatcher.dispatchEvent(MessageDispatcher.LOAD_FILEDATA_PROGRESS, progressEvent.bytesLoaded / progressEvent.bytesTotal);
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
						var decompressedData:DecompressedData = DataParser.decompressData(fileData);
						_xmlDataProxy = new XMLDataProxy();
						if(!(decompressedData.dragonBonesData is XML))
						{
							decompressedData.dragonBonesData = objectToXML(decompressedData.dragonBonesData, ConstValues.DRAGON_BONES);
						}
						_xmlDataProxy.xml = decompressedData.dragonBonesData as XML;
						if(!(decompressedData.textureAtlasData is XML))
						{
							decompressedData.textureAtlasData = objectToXML(decompressedData.textureAtlasData, ConstValues.TEXTURE_ATLAS);
						}
						_xmlDataProxy.textureAtlasXML = decompressedData.textureAtlasData as XML;
						MessageDispatcher.dispatchEvent(MessageDispatcher.LOAD_FILEDATA_COMPLETE, _xmlDataProxy, decompressedData.textureBytes);
						return;
					}
					catch(_e:Error)
					{
						break;
					}
				case BytesType.ZIP:
					try
					{
						var zip:Zip = new Zip();
						zip.decode(fileData);
						_xmlDataProxy = new XMLDataProxy();
						
						var images:Object;
						var object:Object;
						var spineArmatures:Object;
						var name:String;
						for each(var zipFile:ZipFile in zip.fileV)
						{
							if(!zipFile.isDirectory)
							{
								if(
									zipFile.name == GlobalConstValues.DRAGON_BONES_DATA_NAME + GlobalConstValues.XML_SUFFIX ||
									zipFile.name == GlobalConstValues.DRAGON_BONES_DATA_NAME + GlobalConstValues.JSON_SUFFIX
								)
								{
									if(checkBytesTailisXML(zipFile.data))
									{
										_xmlDataProxy.xml = XML(zipFile.data);
									}
									else
									{
										object = com.adobe.serialization.json.JSON.decode(zipFile.data.toString());
										_xmlDataProxy.xml = objectToXML(object, ConstValues.DRAGON_BONES);
									}
								}
								else if(
									zipFile.name == GlobalConstValues.TEXTURE_ATLAS_DATA_NAME + GlobalConstValues.XML_SUFFIX ||
									zipFile.name == GlobalConstValues.TEXTURE_ATLAS_DATA_NAME + GlobalConstValues.JSON_SUFFIX
								)
								{
									if(checkBytesTailisXML(zipFile.data))
									{
										_xmlDataProxy.textureAtlasXML = XML(zipFile.data);
									}
									else
									{
										object = com.adobe.serialization.json.JSON.decode(zipFile.data.toString());
										_xmlDataProxy.textureAtlasXML = objectToXML(object, ConstValues.TEXTURE_ATLAS);
									}
								}
								else if(zipFile.name.indexOf(GlobalConstValues.TEXTURE_ATLAS_DATA_NAME) == 0)
								{
									if(zipFile.name.indexOf("/") > 0)
									{
										name = zipFile.name.replace(/\.\w+$/,"");
										name = name.substr(GlobalConstValues.TEXTURE_ATLAS_DATA_NAME.length + 1);
										if(!images)
										{
											images = {};
										}
										images[name] = zipFile.data;
									}
									else
									{
										var textureBytes:ByteArray = zipFile.data;
									}
								}
								else if(zipFile.name.indexOf(GlobalConstValues.SPINE_FOLDER) == 0)
								{
									if(!spineArmatures)
									{
										spineArmatures = {};
									}
									name = zipFile.name.replace(/\.\w+$/,"");
									name = name.substr(GlobalConstValues.SPINE_FOLDER.length + 1);
									object = com.adobe.serialization.json.JSON.decode(zipFile.data.toString());
									spineArmatures[name] = object;
								}
							}
						}
						zip.clear();
						
						if(spineArmatures)
						{
							_xmlDataProxy.xml = formatSpineData(spineArmatures, null);
						}
						
						if(textureBytes)
						{
							//_textureBytes
							MessageDispatcher.dispatchEvent(MessageDispatcher.LOAD_FILEDATA_COMPLETE, _xmlDataProxy, textureBytes);
							return;
						}
						else if(images)
						{
							BitmapDataUtil.byteArrayMapToBitmapDataMap(images, bitmapDataMapComplete);
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
		
		private function bitmapDataMapComplete(bitmapDataMap:Object):void
		{
			var rectMap:Object = {};
			for(var name:String in bitmapDataMap)
			{
				var bitmapData:BitmapData = bitmapDataMap[name];
				var rect:Rectangle = new Rectangle(0, 0, bitmapData.width, bitmapData.height);
				rectMap[name] = rect;
			}
			_xmlDataProxy.createTextureAtlas(rectMap);
				
			MessageDispatcher.dispatchEvent(
				MessageDispatcher.LOAD_FILEDATA_COMPLETE, 
				_xmlDataProxy, 
				PNGEncoder.encode(
					BitmapDataUtil.getMergeBitmapData(
						bitmapDataMap,
						_xmlDataProxy.getSubTextureRectMap(),
						_xmlDataProxy.textureAtlasWidth,
						_xmlDataProxy.textureAtlasHeight
					)
				)
			);
		}
	}
}