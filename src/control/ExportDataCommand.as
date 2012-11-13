package control{
	import dragonBones.objects.TextureAtlasData;
	import dragonBones.objects.XMLDataParser;
	import dragonBones.utils.BytesType;
	import dragonBones.utils.ConstValues;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.geom.Matrix;
	import flash.net.FileReference;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;
	
	import makeswfs.make;
	
	import message.Message;
	import message.MessageDispatcher;
	
	import model.ImportDataProxy;
	import model.JSFLProxy;
	
	import utils.GlobalConstValues;
	import utils.PNGEncoder;
	
	import zero.zip.Zip;
	
	public class ExportDataCommand{
		public static var instance:ExportDataCommand = new ExportDataCommand();
		
		private static var helpMatirx:Matrix = new Matrix();
		
		private var fileREF:FileReference;
		private var exportType:uint;
		private var isExporting:Boolean;
		private var urlLoader:URLLoader;
		
		private var importDataProxy:ImportDataProxy;
		private var textureAtlasData:TextureAtlasData;
		
		public function ExportDataCommand(){
			fileREF = new FileReference();
			urlLoader = new URLLoader();
			
			importDataProxy = ImportDataProxy.getInstance();
		}
		
		public function export(_exportType:uint):void{
			if(isExporting){
				return;
			}
			isExporting = true;
			exportType = _exportType;
			if(textureAtlasData){
				textureAtlasData.dispose();
			}
			textureAtlasData = null;
			if(importDataProxy.isTextureChanged){
				MessageDispatcher.addEventListener(JSFLProxy.EXPORT_SWF, jsflProxyHandler);
				JSFLProxy.getInstance().exportSWF();
			}else{
				exportStart();
			}
		}
		
		private function jsflProxyHandler(_e:Message):void{
			MessageDispatcher.removeEventListener(JSFLProxy.EXPORT_SWF, jsflProxyHandler);
			var _result:String = _e.parameters[0];
			urlLoader.addEventListener(Event.COMPLETE, onURLLoaderCompleteHandler);
			urlLoader.dataFormat = URLLoaderDataFormat.BINARY;
			urlLoader.load(new URLRequest(_result));
		}
		
		private function onURLLoaderCompleteHandler(_e:Event):void{
			urlLoader.removeEventListener(Event.COMPLETE, onURLLoaderCompleteHandler);
			textureAtlasData = dragonBones.objects.XMLDataParser.parseTextureAtlasData(importDataProxy.textureAtlasXML, make(_e.target.data, importDataProxy.textureAtlasXML));
			textureAtlasData.addEventListener(Event.COMPLETE, exportStart);
		}
		
		private function exportStart(e:Event = null):void{
			var _textureData:TextureAtlasData = textureAtlasData || importDataProxy.textureData;
			var _data:ByteArray;
			var _bitmap:Bitmap;
			var _zip:Zip;
			var _date:Date;
			
			switch(exportType){
				case 0:
					try{
						_data = getSWFBytes(_textureData);
						if(_data){
							exportSave(XMLDataParser.compressionData(importDataProxy.skeletonXML, importDataProxy.textureAtlasXML, _data), importDataProxy.skeletonName + GlobalConstValues.OUTPUT_SUFFIX + GlobalConstValues.SWF_SUFFIX);
							break;
						}
					}catch(_e:Error){
					}
				case 1:
					try{
						_data = getPNGBytes(_textureData);
						if(_data){
							exportSave(XMLDataParser.compressionData(importDataProxy.skeletonXML, importDataProxy.textureAtlasXML, _data), importDataProxy.skeletonName + GlobalConstValues.OUTPUT_SUFFIX + GlobalConstValues.PNG_SUFFIX);
							break;
						}
					}catch(_e:Error){
					}
				case 2:
				case 3:
					try{
						if(exportType == 2){
							_data = getSWFBytes(_textureData);
						}else{
							_data = getPNGBytes(_textureData);
						}
						if(_data){
							_date = new Date();
							_zip = new Zip();
							_zip.add(_data, GlobalConstValues.TEXTURE_NAME + (exportType == 2?GlobalConstValues.SWF_SUFFIX:GlobalConstValues.PNG_SUFFIX), _date);
							_zip.add(importDataProxy.skeletonXML.toXMLString(), GlobalConstValues.SKELETON_XML_NAME, _date);
							_zip.add(importDataProxy.textureAtlasXML.toXMLString(), GlobalConstValues.TEXTURE_ATLAS_XML_NAME, _date);
							exportSave(_zip.encode(), importDataProxy.skeletonName + GlobalConstValues.OUTPUT_SUFFIX + GlobalConstValues.ZIP_SUFFIX);
							_zip.clear();
							break;
						}
					}catch(_e:Error){
					}
				case 4:
					try{
						_bitmap = _textureData.bitmap;
						if(_bitmap){
							_date = new Date();
							_zip = new Zip();
							var _skeletonXML:XML = importDataProxy.skeletonXML.copy();
							var _textureAtlasXML:XML = importDataProxy.textureAtlasXML.copy();
							var _subTextureName:String;
							for each(var _displayXML:XML in _skeletonXML.elements(ConstValues.ARMATURES).elements(ConstValues.ARMATURE).elements(ConstValues.BONE).elements(ConstValues.DISPLAY)){
								_subTextureName = _displayXML.attribute(ConstValues.A_NAME);
								_subTextureName = _subTextureName.split("/").join("-");
								_displayXML[ConstValues.AT + ConstValues.A_NAME] = _subTextureName;
							}
							for each(var _subTextureXML:XML in _textureAtlasXML.elements(ConstValues.SUB_TEXTURE)){
								helpMatirx.tx = -int(_subTextureXML.attribute(ConstValues.A_X));
								helpMatirx.ty = -int(_subTextureXML.attribute(ConstValues.A_Y));
								var _width:int = int(_subTextureXML.attribute(ConstValues.A_WIDTH));
								var _height:int = int(_subTextureXML.attribute(ConstValues.A_HEIGHT));
								
								var _bitmapData:BitmapData = new BitmapData(_width, _height, true, 0xFF00FF);
								_bitmapData.draw(_bitmap.bitmapData, helpMatirx);
								_subTextureName = _subTextureXML.attribute(ConstValues.A_NAME);
								_subTextureName = _subTextureName.split("/").join("-");
								_subTextureXML[ConstValues.AT + ConstValues.A_NAME] = _subTextureName;
								_zip.add(PNGEncoder.encode(_bitmapData), GlobalConstValues.TEXTURE_NAME + "/" + _subTextureName + GlobalConstValues.PNG_SUFFIX, _date);
								_bitmapData.dispose();
							}
							
							_zip.add(_skeletonXML.toXMLString(), GlobalConstValues.SKELETON_XML_NAME, _date);
							_zip.add(_textureAtlasXML.toXMLString(), GlobalConstValues.TEXTURE_ATLAS_XML_NAME, _date);
							
							exportSave(_zip.encode(), importDataProxy.skeletonName + GlobalConstValues.OUTPUT_SUFFIX + GlobalConstValues.ZIP_SUFFIX);
							_zip.clear();
							break;
						}
					}catch(_e:Error){
					}
				default:
					isExporting = false;
					MessageDispatcher.dispatchEvent(MessageDispatcher.EXPORT_ERROR);
					break;
			}
		}
		
		private function getSWFBytes(_textureData:TextureAtlasData):ByteArray{
			if(_textureData.dataType == BytesType.SWF){
				return _textureData.rawData;
			}
			return null;
		}
		
		private function getPNGBytes(_textureData:TextureAtlasData):ByteArray{
			if(_textureData.dataType == BytesType.SWF){
				return PNGEncoder.encode(_textureData.bitmap.bitmapData);
			}else if(_textureData.dataType != BytesType.ATF){
				return _textureData.rawData;
			}
			return null;
		}
		
		private function exportSave(_data:ByteArray, _name:String):void{
			MessageDispatcher.dispatchEvent(MessageDispatcher.EXPORT, _name);
			fileREF.addEventListener(Event.CANCEL, onFileSaveHandler);
			fileREF.addEventListener(Event.COMPLETE, onFileSaveHandler);
			fileREF.addEventListener(IOErrorEvent.IO_ERROR, onFileSaveHandler);
			fileREF.save(_data, _name);
		}
		
		private function onFileSaveHandler(_e:Event):void{
			fileREF.removeEventListener(Event.CANCEL, onFileSaveHandler);
			fileREF.removeEventListener(Event.COMPLETE, onFileSaveHandler);
			fileREF.removeEventListener(IOErrorEvent.IO_ERROR, onFileSaveHandler);
			isExporting = false;
			switch(_e.type){
				case Event.CANCEL:
					MessageDispatcher.dispatchEvent(MessageDispatcher.EXPORT_CANCEL);
					break;
				case IOErrorEvent.IO_ERROR:
					MessageDispatcher.dispatchEvent(MessageDispatcher.EXPORT_ERROR);
					break;
				case Event.COMPLETE:
					importDataProxy.isTextureChanged = false;
					MessageDispatcher.dispatchEvent(MessageDispatcher.EXPORT_COMPLETE);
					break;
			}
		}
	}
}