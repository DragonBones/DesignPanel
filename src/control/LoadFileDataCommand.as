package control{
	import dragonBones.objects.SkeletonAndTextureAtlasData;
	import dragonBones.utils.BytesType;
	import dragonBones.utils.ConstValues;
	import dragonBones.utils.uncompressionData;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Loader;
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

	public class LoadFileDataCommand{
		private static const FILE_FILTER_ARRAY:Array = [new FileFilter("Exported data", "*." + String(["swf", "png", "zip"]).replace(/\,/g, ";*."))];
		private static var helpMatirx:Matrix = new Matrix();
		private static var helpRect:Rectangle = new Rectangle();
		
		public static var instance:LoadFileDataCommand = new LoadFileDataCommand();
		
		private var fileREF:FileReference;
		private var urlLoader:URLLoader;
		private var isLoading:Boolean;
		
		public function LoadFileDataCommand(){
			fileREF = new FileReference();
			urlLoader = new URLLoader();
		}
		
		public function load(_url:String = null):void{
			if(isLoading){
				return;
			}
			if(_url){
				isLoading = true;
				MessageDispatcher.dispatchEvent(MessageDispatcher.LOAD_FILEDATA);
				urlLoader.addEventListener(IOErrorEvent.IO_ERROR, onURLLoaderHandler);
				urlLoader.addEventListener(ProgressEvent.PROGRESS, onURLLoaderHandler);
				urlLoader.addEventListener(Event.COMPLETE, onURLLoaderHandler);
				urlLoader.dataFormat = URLLoaderDataFormat.BINARY;
				urlLoader.load(new URLRequest(_url));
			}else{
				fileREF.addEventListener(Event.SELECT, onFileHaneler);
				fileREF.browse(FILE_FILTER_ARRAY);
			}
		}
	
		private function onURLLoaderHandler(_e:Event):void{
			switch(_e.type){
				case IOErrorEvent.IO_ERROR:
					urlLoader.removeEventListener(Event.COMPLETE, onURLLoaderHandler);
					urlLoader.removeEventListener(IOErrorEvent.IO_ERROR, onURLLoaderHandler);
					urlLoader.removeEventListener(ProgressEvent.PROGRESS, onURLLoaderHandler);
					isLoading = false;
					MessageDispatcher.dispatchEvent(MessageDispatcher.LOAD_FILEDATA_ERROR);
					break;
				case ProgressEvent.PROGRESS:
					var _progressEvent:ProgressEvent = _e as ProgressEvent;
					MessageDispatcher.dispatchEvent(MessageDispatcher.LOAD_FILEDATA_PROGRESS, _progressEvent.bytesLoaded / _progressEvent.bytesTotal );
					break;
				case Event.COMPLETE:
					urlLoader.removeEventListener(Event.COMPLETE, onURLLoaderHandler);
					urlLoader.removeEventListener(IOErrorEvent.IO_ERROR, onURLLoaderHandler);
					urlLoader.removeEventListener(ProgressEvent.PROGRESS, onURLLoaderHandler);
					setData(_e.target.data);
					break;
			}
		}
		
		private function onFileHaneler(_e:Event):void{
			switch(_e.type){
				case Event.SELECT:
					isLoading = true;
					MessageDispatcher.dispatchEvent(MessageDispatcher.LOAD_FILEDATA);
					fileREF.removeEventListener(Event.SELECT, onFileHaneler);
					fileREF.addEventListener(Event.COMPLETE, onFileHaneler);
					fileREF.load();
					break;
				case Event.COMPLETE:
					fileREF.removeEventListener(Event.COMPLETE, onFileHaneler);
					setData(fileREF.data);
					break;
			}
		}
		
		private function setData(_data:ByteArray):void{
			isLoading = false;
			var _dataType:String = BytesType.getType(_data);
			var _sat:SkeletonAndTextureAtlasData;
			switch(_dataType){
				case BytesType.SWF:
				case BytesType.PNG:
				case BytesType.JPG:
					try{
						_sat = dragonBones.utils.uncompressionData(_data);
						MessageDispatcher.dispatchEvent(MessageDispatcher.LOAD_FILEDATA_COMPLETE, true, _sat.skeletonData, _sat.textureAtlasData);
						_sat.dispose();
						break;
					}catch(_e:Error){
					}
				case BytesType.ZIP:
					try{
						var _skeletonXML:XML;
						var _textureAtlasXML:XML;
						var _textureBytes:ByteArray;
						var _images:Object;
						var _zip:Zip = new Zip();
						_zip.decode(_data);
						
						for each(var _zipFile:ZipFile in _zip.fileV){
							if(!_zipFile.isDirectory){
								if(_zipFile.name == GlobalConstValues.SKELETON_XML_NAME){
									_skeletonXML = XML(_zipFile.data);
								}else if(_zipFile.name == GlobalConstValues.TEXTURE_ATLAS_XML_NAME){
									_textureAtlasXML = XML(_zipFile.data);
								}else if(_zipFile.name.indexOf(GlobalConstValues.TEXTURE_NAME) == 0){
									if(_zipFile.name.indexOf("/") > 0){
										var _name:String = _zipFile.name.replace(/\.\w+$/,"");
										_name = _name.split("/").pop();
										if(!_images){
											_images = {};
										}
										_images[_name] = _zipFile.data;
									}else{
										_textureBytes = _zipFile.data;
									}
								}
							}
						}
						_zip.clear();
						if(_textureBytes){
							_sat = new SkeletonAndTextureAtlasData(_skeletonXML, _textureAtlasXML, _textureBytes);
							MessageDispatcher.dispatchEvent(MessageDispatcher.LOAD_FILEDATA_COMPLETE, true, _sat.skeletonData, _sat.textureAtlasData);
							_sat.dispose();
							break;
						}else if(_images){
							spliceBitmapData(_skeletonXML, _textureAtlasXML, _images);
							break;
						}
					}catch(_e:Error){
					}
				default:
					MessageDispatcher.dispatchEvent(MessageDispatcher.LOAD_FILEDATA_ERROR);
					break;
			}
		}
		
		private var tempSkeletonXML:XML;
		private var tempTextureAtlasXML:XML;
		private var tempImages:Object;
		private var tempBitmapData:BitmapData;
		private var tempImageName:String;
		
		private function spliceBitmapData(_skeletonXML:XML, _textureAtlasXML:XML, _imageDatas:Object):void{
			tempSkeletonXML = _skeletonXML;
			tempTextureAtlasXML = _textureAtlasXML;
			tempImages = _imageDatas;
			if(tempBitmapData){
				tempBitmapData.dispose();
			}
			tempBitmapData = new BitmapData(
				int(tempTextureAtlasXML.attribute(ConstValues.A_WIDTH)),
				int(tempTextureAtlasXML.attribute(ConstValues.A_HEIGHT)),
				true,
				0xFF00FF
			);
			
			spliceBitmapDataStep(null);
		}
		
		private function spliceBitmapDataStep(_e:Event):void{
			if(_e){
				_e.target.removeEventListener(Event.COMPLETE, spliceBitmapDataStep);
				var _bitmap:Bitmap = _e.target.content as Bitmap;
				if (_bitmap) {
					var _subTextureXML:XML = tempTextureAtlasXML.elements(ConstValues.SUB_TEXTURE).(attribute(ConstValues.A_NAME) == tempImageName)[0];
					if(_subTextureXML){
						helpRect.x = int(_subTextureXML.attribute(ConstValues.A_X));
						helpRect.y = int(_subTextureXML.attribute(ConstValues.A_Y));
						helpRect.width = int(_subTextureXML.attribute(ConstValues.A_WIDTH));
						helpRect.height = int(_subTextureXML.attribute(ConstValues.A_HEIGHT));
						helpMatirx.tx = helpRect.x;
						helpMatirx.ty = helpRect.y;
						tempBitmapData.draw(_bitmap.bitmapData, helpMatirx, null, null, helpRect);
					}
				}
			}
			for (var _name:String in tempImages){
				var _imageData:ByteArray = tempImages[_name];
				tempImageName = _name;
				delete tempImages[tempImageName];
				break;
			}
			if(!_imageData){
				try{
					var _sat:SkeletonAndTextureAtlasData = new SkeletonAndTextureAtlasData(tempSkeletonXML, tempTextureAtlasXML, PNGEncoder.encode(tempBitmapData));
					tempBitmapData.dispose();
					MessageDispatcher.dispatchEvent(MessageDispatcher.LOAD_FILEDATA_COMPLETE, true, _sat.skeletonData, _sat.textureAtlasData);
					_sat.dispose();
				}catch(_e:Error){
					MessageDispatcher.dispatchEvent(MessageDispatcher.LOAD_FILEDATA_ERROR);
				}
				return;
			}
			var _loader:Loader = new Loader();
			var _loaderContext:LoaderContext = new LoaderContext(false);
			_loaderContext.allowCodeImport = true;
			_loader.contentLoaderInfo.addEventListener(Event.COMPLETE, spliceBitmapDataStep);
			_loader.loadBytes(_imageData, _loaderContext);
		}
	}
}