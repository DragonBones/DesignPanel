package control
{
	import dragonBones.objects.XMLDataParser;
	import dragonBones.utils.ConstValues;
	
	import flash.display.BitmapData;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.geom.Matrix;
	import flash.net.FileReference;
	import flash.utils.ByteArray;
	
	import message.Message;
	import message.MessageDispatcher;
	
	import model.ImportDataProxy;
	import model.JSFLProxy;
	import model.SkeletonXMLProxy;
	
	import utils.BitmapDataUtil;
	import utils.GlobalConstValues;
	import utils.PNGEncoder;
	
	import zero.zip.Zip;
	
	public class ExportDataCommand
	{
		public static const instance:ExportDataCommand = new ExportDataCommand();
		
		
		private var _fileREF:FileReference;
		private var _exportType:uint;
		private var _isExporting:Boolean;
		private var _exportScale:Number;
		
		private var _importDataProxy:ImportDataProxy;
		
		private var _skeletonXMLProxy:SkeletonXMLProxy;
		private var _bitmapData:BitmapData;
		
		public function ExportDataCommand()
		{
			_fileREF = new FileReference();
			
			_importDataProxy = ImportDataProxy.getInstance();
		}
		
		public function export(exportType:uint, exportScale:Number):void
		{
			if(_isExporting)
			{
				return;
			}
			_isExporting = true;
			_exportType = exportType;
			_exportScale = exportScale;
			exportStart();
		}
		
		private function exportStart():void
		{
			var dataBytes:ByteArray;
			var zip:Zip;
			var date:Date;
			
			_skeletonXMLProxy = _importDataProxy.skeletonXMLProxy;
			_bitmapData = _importDataProxy.textureAtlas.bitmapData;
			
			if(_exportScale != 1 && _exportType != 4)
			{
				_skeletonXMLProxy = _skeletonXMLProxy.copy();
				var subBitmapDataDic:Object = BitmapDataUtil.getSubBitmapDataDic(
					_bitmapData,
					_skeletonXMLProxy.getSubTextureRectDic(),
					_exportScale
				);
				_skeletonXMLProxy.scaleData(_exportScale);
				
				_bitmapData = BitmapDataUtil.getMergeBitmapData(
					subBitmapDataDic,
					_skeletonXMLProxy.getSubTextureRectDic(),
					_skeletonXMLProxy.textureAtlasWidth,
					_skeletonXMLProxy.textureAtlasHeight
				);
			}
			
			switch(_exportType)
			{
				case 0:
					try
					{
						dataBytes = getSWFBytes();
						if(dataBytes)
						{
							exportSave(
								XMLDataParser.compressData(
									_skeletonXMLProxy.skeletonXML, 
									_skeletonXMLProxy.textureAtlasXML, 
									dataBytes
								), 
								_importDataProxy.skeletonName + GlobalConstValues.OUTPUT_SUFFIX + GlobalConstValues.SWF_SUFFIX
							);
							return;
						}
						break;
					}
					catch(_e:Error)
					{
						break;
					}
				case 1:
					try
					{
						dataBytes = getPNGBytes();
						if(dataBytes)
						{
							exportSave(
								XMLDataParser.compressData(
									_skeletonXMLProxy.skeletonXML, 
									_skeletonXMLProxy.textureAtlasXML, 
									dataBytes
								), 
								_importDataProxy.skeletonName + GlobalConstValues.OUTPUT_SUFFIX + GlobalConstValues.PNG_SUFFIX
							);
							return;
						}
						break;
					}
					catch(_e:Error)
					{
						break;
					}
				case 2:
				case 3:
					try
					{
						if(_exportType == 2)
						{
							dataBytes = getSWFBytes();
						}
						else
						{
							dataBytes = getPNGBytes();
						}
						
						if(dataBytes)
						{
							date = new Date();
							zip = new Zip();
							zip.add(
								dataBytes, 
								GlobalConstValues.TEXTURE_NAME + (_exportType == 2?GlobalConstValues.SWF_SUFFIX:GlobalConstValues.PNG_SUFFIX),
								date
							);
							zip.add(
								_skeletonXMLProxy.skeletonXML.toXMLString(), 
								GlobalConstValues.SKELETON_XML_NAME, 
								date
							);
							zip.add(
								_skeletonXMLProxy.textureAtlasXML.toXMLString(), 
								GlobalConstValues.TEXTURE_ATLAS_XML_NAME, 
								date
							);
							exportSave(
								zip.encode(), 
								_importDataProxy.skeletonName + GlobalConstValues.OUTPUT_SUFFIX + GlobalConstValues.ZIP_SUFFIX
							);
							zip.clear();
							return;
						}
						break;
					}
					catch(_e:Error)
					{
						break;
					}
				case 4:
					try
					{
						date = new Date();
						zip = new Zip();
						
						if(_skeletonXMLProxy == _importDataProxy.skeletonXMLProxy)
						{
							_skeletonXMLProxy = _skeletonXMLProxy.copy();
						}
						_skeletonXMLProxy.changePath();
						
						
						subBitmapDataDic = BitmapDataUtil.getSubBitmapDataDic(
							_bitmapData, 
							_skeletonXMLProxy.getSubTextureRectDic(),
							_exportScale
						);
						for(var subTextureName:String in subBitmapDataDic)
						{
							var subBitmapData:BitmapData = subBitmapDataDic[subTextureName];
							zip.add(
								PNGEncoder.encode(subBitmapData), 
								GlobalConstValues.TEXTURE_NAME + "/" + subTextureName + GlobalConstValues.PNG_SUFFIX, 
								date
							);
							subBitmapData.dispose();
						}
						
						zip.add(
							_skeletonXMLProxy.skeletonXML.toXMLString(), 
							GlobalConstValues.SKELETON_XML_NAME, 
							date
						);
						zip.add(
							_skeletonXMLProxy.textureAtlasXML.toXMLString(), 
							GlobalConstValues.TEXTURE_ATLAS_XML_NAME, 
							date
						);
						
						exportSave(
							zip.encode(), 
							_importDataProxy.skeletonName + GlobalConstValues.OUTPUT_SUFFIX + GlobalConstValues.ZIP_SUFFIX
						);
						zip.clear();
						return;
					}
					catch(_e:Error)
					{
						break;
					}
				default:
					break;
			}
			_isExporting = false;
			MessageDispatcher.dispatchEvent(MessageDispatcher.EXPORT_ERROR);
		}
		
		private function getSWFBytes():ByteArray
		{
			if(_importDataProxy.textureAtlas.movieClip)
			{
				return _importDataProxy.textureBytes;
			}
			return null;
		}
		
		private function getPNGBytes():ByteArray
		{
			if(_importDataProxy.textureAtlas.movieClip)
			{
				return PNGEncoder.encode(_bitmapData);
			}
			else
			{
				if(_bitmapData && _bitmapData != _importDataProxy.textureAtlas.bitmapData)
				{
					return PNGEncoder.encode(_bitmapData);
				}
				return _importDataProxy.textureBytes;
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
					if(_bitmapData && _bitmapData != _importDataProxy.textureAtlas.bitmapData)
					{
						_bitmapData.dispose();
						_bitmapData = null;
					}
					MessageDispatcher.dispatchEvent(MessageDispatcher.EXPORT_COMPLETE);
					break;
			}
		}
	}
}