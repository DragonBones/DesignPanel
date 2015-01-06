package core.service
{
	import com.adobe.serialization.json.JSON;
	
	import core.SettingManager;
	import core.events.ServiceEvent;
	import core.model.ImportModel;
	import core.model.vo.ExportVO;
	import core.model.vo.ImportVO;
	import core.suppotClass._BaseService;
	import core.utils.BitmapDataUtil;
	import core.utils.DataFormatUtils;
	import core.utils.DataUtils;
	import core.utils.GlobalConstValues;
	import core.utils.OptimizeDataUtils;
	import core.utils.PNGEncoder;
	
	import dragonBones.core.DragonBones;
	import dragonBones.objects.DataParser;
	import dragonBones.utils.ConstValues;
	
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	import flash.utils.ByteArray;
	
	import light.managers.ErrorManager;
	
	import zero.zip.Zip;
	
	public final class ImportDataToExportDataService extends _BaseService
	{
		public static const IMPORT_TO_EXPORT_ERROR:String = "IMPORT_TO_EXPORT_ERROR";
		public static const IMPORT_TO_EXPORT_COMPLETE:String = "IMPORT_TO_EXPORT_COMPLETE";
		
		[Inject (name='exportModel')]
		public var importModel:ImportModel;
		
		private var _exportVO:ExportVO;
		
		public function ImportDataToExportDataService()
		{
			
		}
		
		public function export(importVO:ImportVO, exportVO:ExportVO):void
		{
			importModel.vo = importVO.clone();
			_exportVO = exportVO;
			
			//更新skeleton,textureAtalsConfig的name
			importModel.name = _exportVO.name || importModel.name;
			_exportVO.name = importModel.name;
			
			// set export vo values
			SettingManager.getInstance().setExportVOValues(_exportVO);
			
			// only skeleton
			if(importModel.vo.skeleton && !importModel.vo.textureAtlasConfig)
			{
				var retult:ByteArray = new ByteArray();
				retult.writeObject(importModel.vo.skeleton);
				
				_exportVO.name += "." + GlobalConstValues.XML_SUFFIX;
				
				exportSave(retult);
				return;
			}
			
			if(_exportVO.textureAtlasType == GlobalConstValues.TEXTURE_ATLAS_TYPE_SWF)
			{
				//swf格式的动画数据缩放没有意义
				_exportVO.scale = 1;
			}
			else if(_exportVO.scale != 1)
			{
				scaleData(_exportVO.scale);
			}
			
			if(_exportVO.configType == GlobalConstValues.CONFIG_TYPE_MERGED)
			{
				if (exportDataMerged())
				{
					return;
				}
			}
			else
			{
				if (exportZip())
				{
					return;
				}
				
			}
			
			light.managers.ErrorManager.getInstance().dispatchErrorEvent(this, IMPORT_TO_EXPORT_ERROR);
		}
		
		private function scaleData(scale:Number):void
		{
			var subBitmapDataMap:Object;
			var movieClip:MovieClip = importModel.vo.textureAtlasSWF as MovieClip;
			if(movieClip && movieClip.totalFrames >= 3)
			{
				//第一帧是textureAtlas，最后一帧是空，如果大于等于3帧，说明有至少一个贴图，否则可能是shape贴图
				subBitmapDataMap = {};
				var helpMatrix:Matrix = new Matrix();
				for each (var displayXML:XML in importModel.getSubTextureList())
				{
					var displayName:String = displayXML.@[ConstValues.A_NAME];
					movieClip.gotoAndStop(movieClip.totalFrames);
					movieClip.gotoAndStop(displayName);
					var subDisplay:DisplayObject = movieClip.getChildAt(0);
					
					if(scale < 1)
					{
						var rectOffSet:Rectangle = subDisplay.getBounds(subDisplay);
						helpMatrix.tx = -rectOffSet.x;
						helpMatrix.ty = -rectOffSet.y;
						
						var subBitmapData:BitmapData = new BitmapData(subDisplay.width, subDisplay.height, true, 0xFF00FF);
						subBitmapData.draw(subDisplay, helpMatrix);
						subBitmapDataMap[displayName] = subBitmapData;
					}
					else
					{
						subBitmapDataMap[displayName] = subDisplay;
					}
				}
			}
			else
			{
				subBitmapDataMap = 
					BitmapDataUtil.getSubBitmapDataDic(
						importModel.vo.textureAtlas,
						importModel.getSubTextureRectMap()
					);
			}
			
			importModel.scaleData(scale);
			
			importModel.vo.textureAtlas = 
				BitmapDataUtil.getMergeBitmapData(
					subBitmapDataMap,
					importModel.getSubTextureRectMap(),
					importModel.textureAtlasWidth,
					importModel.textureAtlasHeight,
					scale
				);
		}
		
		private function exportDataMerged():Boolean
		{
			var textureAtlasBytes:ByteArray;
			if (
				_exportVO.textureAtlasType == GlobalConstValues.TEXTURE_ATLAS_TYPE_SWF &&
				importModel.vo.textureAtlasType == GlobalConstValues.TEXTURE_ATLAS_TYPE_SWF
			)
			{
				_exportVO.name += "." + GlobalConstValues.DBSWF_SUFFIX;
				textureAtlasBytes = importModel.vo.textureAtlasBytes;
			}
			else
			{
				_exportVO.name += "." + GlobalConstValues.PNG_SUFFIX;
				textureAtlasBytes = getPNGBytes();
			}
			exportSave(
				DataParser.compressData(
					DataFormatUtils.xmlToObject(importModel.vo.skeleton, GlobalConstValues.XML_LIST_NAMES), 
					DataFormatUtils.xmlToObject(importModel.vo.textureAtlasConfig, GlobalConstValues.XML_LIST_NAMES), 
					textureAtlasBytes
				)
			);
			return true;
		}
		
		private function exportZip():Boolean
		{
			var zip:Zip = new Zip();
			var date:Date = new Date();
			
			zipTextureAtlas(zip, date);
			zipDragonBonesData(zip, date);
			
			_exportVO.name += "." + GlobalConstValues.ZIP_SUFFIX;
			exportSave(zip.encode());
			zip.clear();
			return true;
		}
	
		private function zipDragonBonesData(zip:Zip, date:Date):void
		{
			var objData:Object;
			if( _exportVO.dataType == GlobalConstValues.DATA_TYPE_PARENT && 
				importModel.vo.dataType == GlobalConstValues.DATA_TYPE_GLOBAL)
			{
				objData = DataFormatUtils.xmlToObject(importModel.vo.skeleton, GlobalConstValues.XML_LIST_NAMES);
				objData[ConstValues.A_IS_GLOBAL] = 0;
				objData[ConstValues.A_VERSION] = DragonBones.PARENT_COORDINATE_DATA_VERSION;
				DataUtils.convertDragonBonesDataToRelativeObject(objData);
			}
			
			if(_exportVO.enableDataOptimization)
			{
				if(!objData)
				{
					objData = DataFormatUtils.xmlToObject(importModel.vo.skeleton, GlobalConstValues.XML_LIST_NAMES);
				}
				OptimizeDataUtils.optimizeData(objData);
			}
			
			var dataToZip:Object;
			var fileName:String = _exportVO.dragonBonesFileName + ".";
			
			_exportVO.dragonBonesFileName = _exportVO.dragonBonesFileName || GlobalConstValues.DRAGON_BONES_DATA_NAME;
			switch (_exportVO.configType)
			{
				case GlobalConstValues.CONFIG_TYPE_XML:
					if(objData)
					{
						dataToZip = DataFormatUtils.objectToXML(objData).toXMLString();
					}
					else
					{
						dataToZip = importModel.vo.skeleton.toXMLString();
					}
					fileName += GlobalConstValues.XML_SUFFIX;
					break;
				
				case GlobalConstValues.CONFIG_TYPE_JSON:
					if(objData)
					{
						dataToZip = com.adobe.serialization.json.JSON.encode(objData);
					}
					else
					{
						dataToZip = com.adobe.serialization.json.JSON.encode(DataFormatUtils.xmlToObject(importModel.vo.skeleton, GlobalConstValues.XML_LIST_NAMES));
					}
					fileName += GlobalConstValues.JSON_SUFFIX;
					break;
				
				case GlobalConstValues.CONFIG_TYPE_AMF3:
					var bytes:ByteArray = new ByteArray();
					if(objData)
					{
						bytes.writeObject(objData);
					}
					else
					{
						bytes.writeObject(DataFormatUtils.xmlToObject(importModel.vo.skeleton, GlobalConstValues.XML_LIST_NAMES));
					}
					bytes.compress();
					dataToZip = bytes;
					fileName += GlobalConstValues.AMF3_SUFFIX;
					break;
			}
			
			if(dataToZip)
			{
				zip.add(dataToZip, fileName, date);
			}
		}
		
		private function zipTextureAtlas(zip:Zip, date:Date):void
		{
			if(_exportVO.textureAtlasType == GlobalConstValues.TEXTURE_ATLAS_TYPE_PNGS)
			{
				var subBitmapDataMap:Object = BitmapDataUtil.getSubBitmapDataDic(
					importModel.vo.textureAtlas, 
					importModel.getSubTextureRectMap()
				);
				
				// update texture folder name and add subtextures to zip
				_exportVO.subTextureFolderName = _exportVO.subTextureFolderName || GlobalConstValues.TEXTURE_ATLAS_DATA_NAME;
				for (var subTextureName:String in subBitmapDataMap)
				{
					var subBitmapData:BitmapData = subBitmapDataMap[subTextureName];
					zip.add(
						PNGEncoder.encode(subBitmapData), 
						_exportVO.subTextureFolderName + "/" + subTextureName + "." + GlobalConstValues.PNG_SUFFIX, 
						date
					);
					subBitmapData.dispose();
				}
			}
			else
			{
				var textureAtlasBytes:ByteArray;
				_exportVO.textureAtlasFileName = _exportVO.textureAtlasFileName || GlobalConstValues.TEXTURE_ATLAS_DATA_NAME;
				
				if(_exportVO.textureAtlasType == GlobalConstValues.TEXTURE_ATLAS_TYPE_SWF &&
					importModel.vo.textureAtlasType == GlobalConstValues.TEXTURE_ATLAS_TYPE_SWF)
				{
					_exportVO.textureAtlasFileName += "." + GlobalConstValues.SWF_SUFFIX;
					textureAtlasBytes = importModel.vo.textureAtlasBytes;
				}
				else
				{
					_exportVO.textureAtlasFileName += "." + GlobalConstValues.PNG_SUFFIX;
					textureAtlasBytes = getPNGBytes();
				}
				
				zip.add(textureAtlasBytes, _exportVO.textureAtlasFileName, date);
				importModel.textureAtlasPath = (_exportVO.textureAtlasPath || "") + _exportVO.textureAtlasFileName;
				zipTextureAtlasData(zip, date);
			}
		}
		
		private function zipTextureAtlasData(zip:Zip, date:Date):void
		{
			_exportVO.textureAtlasConfigFileName = _exportVO.textureAtlasConfigFileName || GlobalConstValues.TEXTURE_ATLAS_DATA_NAME;
			switch (_exportVO.configType)
			{
				case GlobalConstValues.CONFIG_TYPE_XML:
					zip.add(
						importModel.vo.textureAtlasConfig.toXMLString(),
						_exportVO.textureAtlasConfigFileName + "." + GlobalConstValues.XML_SUFFIX, 
						date
					);
					break;
				
				case GlobalConstValues.CONFIG_TYPE_JSON:
					zip.add(
						com.adobe.serialization.json.JSON.encode(DataFormatUtils.xmlToObject(importModel.vo.textureAtlasConfig, GlobalConstValues.XML_LIST_NAMES)), 
						_exportVO.textureAtlasConfigFileName + "." + GlobalConstValues.JSON_SUFFIX, 
						date
					);
					break;
				
				case GlobalConstValues.CONFIG_TYPE_AMF3:
					var bytes:ByteArray = new ByteArray();
					bytes.writeObject(DataFormatUtils.xmlToObject(importModel.vo.textureAtlasConfig, GlobalConstValues.XML_LIST_NAMES));
					bytes.compress();
					zip.add(
						bytes, 
						_exportVO.textureAtlasConfigFileName + "." + GlobalConstValues.AMF3_SUFFIX, 
						date
					);
					break;
			}
		}
		
		private function getPNGBytes():ByteArray
		{
			if(_exportVO.enableBackgroundColor)
			{
				var bitmapData:BitmapData = new BitmapData(importModel.vo.textureAtlas.width, importModel.vo.textureAtlas.height, false, _exportVO.backgroundColor);
				bitmapData.draw(importModel.vo.textureAtlas);
				
				var byteArray:ByteArray = PNGEncoder.encode(bitmapData);
				bitmapData.dispose();
				return byteArray;
			}
			
			return PNGEncoder.encode(importModel.vo.textureAtlas);
		}
		
		private function exportSave(fileData:ByteArray):void
		{
			//缩放后的bitmapData需要dispose
			this.dispatchEvent(new ServiceEvent(IMPORT_TO_EXPORT_COMPLETE, [fileData, _exportVO, importModel.vo]));
		}
	}
}