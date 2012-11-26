package control
{
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
	import flash.utils.ByteArray;
	
	import makeswfs.make;
	
	import message.Message;
	import message.MessageDispatcher;
	
	import model.ImportDataProxy;
	import model.JSFLProxy;
	
	import utils.GlobalConstValues;
	import utils.PNGEncoder;
	
	import zero.zip.Zip;
	
	public class ExportDataCommand
	{
		public static var instance:ExportDataCommand = new ExportDataCommand();
		
		private static var _helpMatirx:Matrix = new Matrix();
		
		private var _fileREF:FileReference;
		private var _exportType:uint;
		private var _isExporting:Boolean;
		
		private var _importDataProxy:ImportDataProxy;
		private var _textureAtlasData:TextureAtlasData;
		
		public function ExportDataCommand()
		{
			_fileREF = new FileReference();
			
			_importDataProxy = ImportDataProxy.getInstance();
		}
		
		public function export(exportType:uint):void
		{
			if(_isExporting)
			{
				return;
			}
			_isExporting = true;
			_exportType = exportType;
			if(_textureAtlasData)
			{
				_textureAtlasData.dispose();
			}
			_textureAtlasData = null;
			if(_importDataProxy.isTextureChanged)
			{
				MessageDispatcher.addEventListener(MessageDispatcher.FLA_TEXTURE_ATLAS_SWF_LOADED, flaExportSWFHandler);
				FLAExportSWFCommand.instance.exportSWF();
			}
			else
			{
				exportStart();
			}
		}
	
		private function flaExportSWFHandler(e:Message):void
		{
			var textureAtlasXML:XML = _importDataProxy.textureAtlasXML;
			_textureAtlasData = XMLDataParser.parseTextureAtlasData(textureAtlasXML, make(e.parameters[0], textureAtlasXML));
			_textureAtlasData.addEventListener(Event.COMPLETE, exportStart);
		}
		
		private function exportStart(e:Event = null):void
		{
			var textureAtlasData:TextureAtlasData = _textureAtlasData || _importDataProxy.textureData;
			var dataBytes:ByteArray;
			var zip:Zip;
			var date:Date;
			
			switch(_exportType)
			{
				case 0:
					try
					{
						dataBytes = getSWFBytes(textureAtlasData);
						if(dataBytes)
						{
							exportSave(XMLDataParser.compressionData(_importDataProxy.skeletonXML, _importDataProxy.textureAtlasXML, dataBytes), _importDataProxy.skeletonName + GlobalConstValues.OUTPUT_SUFFIX + GlobalConstValues.SWF_SUFFIX);
							return;
						}
					}
					catch(_e:Error)
					{
					}
				case 1:
					try
					{
						dataBytes = getPNGBytes(textureAtlasData);
						if(dataBytes)
						{
							exportSave(XMLDataParser.compressionData(_importDataProxy.skeletonXML, _importDataProxy.textureAtlasXML, dataBytes), _importDataProxy.skeletonName + GlobalConstValues.OUTPUT_SUFFIX + GlobalConstValues.PNG_SUFFIX);
							return;
						}
					}
					catch(_e:Error)
					{
					}
				case 2:
				case 3:
					try
					{
						if(_exportType == 2)
						{
							dataBytes = getSWFBytes(textureAtlasData);
						}
						else
						{
							dataBytes = getPNGBytes(textureAtlasData);
						}
						
						if(dataBytes)
						{
							date = new Date();
							zip = new Zip();
							zip.add(dataBytes, GlobalConstValues.TEXTURE_NAME + (_exportType == 2?GlobalConstValues.SWF_SUFFIX:GlobalConstValues.PNG_SUFFIX), date);
							zip.add(_importDataProxy.skeletonXML.toXMLString(), GlobalConstValues.SKELETON_XML_NAME, date);
							zip.add(_importDataProxy.textureAtlasXML.toXMLString(), GlobalConstValues.TEXTURE_ATLAS_XML_NAME, date);
							exportSave(zip.encode(), _importDataProxy.skeletonName + GlobalConstValues.OUTPUT_SUFFIX + GlobalConstValues.ZIP_SUFFIX);
							zip.clear();
							return;
						}
					}
					catch(_e:Error)
					{
					}
				case 4:
					try
					{
						var bitmap:Bitmap = textureAtlasData.bitmap;
						if(bitmap)
						{
							date = new Date();
							zip = new Zip();
							var skeletonXML:XML = _importDataProxy.skeletonXML.copy();
							var textureAtlasXML:XML = _importDataProxy.textureAtlasXML.copy();
							var subTextureName:String;
							for each(var displayXML:XML in skeletonXML.elements(ConstValues.ARMATURES).elements(ConstValues.ARMATURE).elements(ConstValues.BONE).elements(ConstValues.DISPLAY))
							{
								subTextureName = displayXML.attribute(ConstValues.A_NAME);
								subTextureName = subTextureName.split("/").join("-");
								displayXML[ConstValues.AT + ConstValues.A_NAME] = subTextureName;
							}
							
							for each(var subTextureXML:XML in textureAtlasXML.elements(ConstValues.SUB_TEXTURE))
							{
								_helpMatirx.tx = -int(subTextureXML.attribute(ConstValues.A_X));
								_helpMatirx.ty = -int(subTextureXML.attribute(ConstValues.A_Y));
								var width:int = int(subTextureXML.attribute(ConstValues.A_WIDTH));
								var height:int = int(subTextureXML.attribute(ConstValues.A_HEIGHT));
								
								var bitmapData:BitmapData = new BitmapData(width, height, true, 0xFF00FF);
								bitmapData.draw(bitmap.bitmapData, _helpMatirx);
								subTextureName = subTextureXML.attribute(ConstValues.A_NAME);
								subTextureName = subTextureName.split("/").join("-");
								subTextureXML[ConstValues.AT + ConstValues.A_NAME] = subTextureName;
								zip.add(PNGEncoder.encode(bitmapData), GlobalConstValues.TEXTURE_NAME + "/" + subTextureName + GlobalConstValues.PNG_SUFFIX, date);
								bitmapData.dispose();
							}
							
							zip.add(skeletonXML.toXMLString(), GlobalConstValues.SKELETON_XML_NAME, date);
							zip.add(textureAtlasXML.toXMLString(), GlobalConstValues.TEXTURE_ATLAS_XML_NAME, date);
							
							exportSave(zip.encode(), _importDataProxy.skeletonName + GlobalConstValues.OUTPUT_SUFFIX + GlobalConstValues.ZIP_SUFFIX);
							zip.clear();
							return;
						}
					}
					catch(_e:Error)
					{
					}
				default:
					break;
			}
			_isExporting = false;
			MessageDispatcher.dispatchEvent(MessageDispatcher.EXPORT_ERROR);
		}
		
		private function getSWFBytes(textureAtlasData:TextureAtlasData):ByteArray
		{
			if(textureAtlasData.dataType == BytesType.SWF)
			{
				return textureAtlasData.rawData;
			}
			return null;
		}
		
		private function getPNGBytes(textureAtlasData:TextureAtlasData):ByteArray
		{
			if(textureAtlasData.dataType == BytesType.SWF)
			{
				return PNGEncoder.encode(textureAtlasData.bitmap.bitmapData);
			}
			else if(textureAtlasData.dataType != BytesType.ATF)
			{
				return textureAtlasData.rawData;
			}
			return null;
		}
		
		private function exportSave(fileData:ByteArray, fileName:String):void
		{
			MessageDispatcher.dispatchEvent(MessageDispatcher.EXPORT, fileName);
			_fileREF.addEventListener(Event.CANCEL, onFileSaveHandler);
			_fileREF.addEventListener(Event.COMPLETE, onFileSaveHandler);
			_fileREF.addEventListener(IOErrorEvent.IO_ERROR, onFileSaveHandler);
			_fileREF.save(fileData, fileName);
		}
		
		private function onFileSaveHandler(e:Event):void
		{
			_fileREF.removeEventListener(Event.CANCEL, onFileSaveHandler);
			_fileREF.removeEventListener(Event.COMPLETE, onFileSaveHandler);
			_fileREF.removeEventListener(IOErrorEvent.IO_ERROR, onFileSaveHandler);
			_isExporting = false;
			switch(e.type)
			{
				case Event.CANCEL:
					MessageDispatcher.dispatchEvent(MessageDispatcher.EXPORT_CANCEL);
					break;
				case IOErrorEvent.IO_ERROR:
					MessageDispatcher.dispatchEvent(MessageDispatcher.EXPORT_ERROR);
					break;
				case Event.COMPLETE:
					_importDataProxy.isTextureChanged = false;
					MessageDispatcher.dispatchEvent(MessageDispatcher.EXPORT_COMPLETE);
					break;
			}
		}
	}
}