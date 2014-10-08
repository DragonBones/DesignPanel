package core.service
{
	import com.adobe.serialization.json.JSON;
	
	import flash.display.BitmapData;
	import flash.geom.Rectangle;
	import flash.utils.ByteArray;
	
	import core.events.ServiceEvent;
	import core.model.ImportModel;
	import core.model.vo.ImportVO;
	import core.suppotClass._BaseService;
	import core.utils.BitmapDataUtil;
	import core.utils.GlobalConstValues;
	import core.utils.objectToXML;
	
	import dragonBones.objects.DataParser;
	import dragonBones.objects.DecompressedData;
	import dragonBones.utils.ConstValues;
	
	import light.managers.ErrorManager;
	
	import zero.zip.Zip;
	import zero.zip.ZipFile;
	
	public final class ImportFileService extends _BaseService
	{
		public static const IMPORT_FILE_ERROR:String = "IMPORT_FILE_ERROR";
		public static const IMPORT_FILE_COMPLETE:String = "IMPORT_FILE_COMPLETE";
		
		[Inject (name="importModel")]
		public var importModel:ImportModel;
		
		[Inject]
		public var loadTextureAtlasBytesService:LoadTextureAtlasBytesService;
		
		private var _isWorking:Boolean;
		// private var _spineObject:Object;
		
		public function ImportFileService()
		{
		}
		
		public function startImport(importVO:ImportVO):void
		{
			if(_isWorking)
			{
				return;
			}
			
			_isWorking = true;
			// _spineObject = null;
			importModel.vo = importVO;
			importModel.vo.configType = GlobalConstValues.CONFIG_TYPE_XML;
			
			var dataType:String = GlobalConstValues.getFileType(importModel.vo.data);
			if (!dataType && importModel.vo.url)
			{
				dataType = importModel.vo.url.split(".").pop();
			}
			
			switch(dataType)
			{
				case GlobalConstValues.SWF_SUFFIX:
				case GlobalConstValues.PNG_SUFFIX:
					if (importMergedData(dataType))
					{
						return;
					}
					break;
					
				case GlobalConstValues.ZIP_SUFFIX:
					if (importZipData(dataType))
					{
						return;
					}
					break;
					
				case GlobalConstValues.XML_SUFFIX:
					importModel.vo.skeleton = XML(importModel.vo.data);    // xml decode error
					importModel.formatXML();
					importComplete();
					return;
				
				case GlobalConstValues.JSON_SUFFIX:
					var json:Object = com.adobe.serialization.json.JSON.decode(importModel.vo.data.toString());    // json decode error
					importModel.vo.skeleton = objectToXML(json, ConstValues.DRAGON_BONES);    // object to xml error
					importModel.formatXML();
					importComplete();
					return;
				
				case GlobalConstValues.AMF3_SUFFIX:
					var amf3:ByteArray = new ByteArray();
					amf3.writeBytes(importModel.vo.data);
					amf3.uncompress()    // uncompress error;
					var object:Object = amf3.readObject();
					importModel.vo.skeleton = objectToXML(object, ConstValues.DRAGON_BONES);
					importModel.formatXML();
					importComplete();
					return;
				
				default:
					break;
			}
			
			_isWorking = false;
			light.managers.ErrorManager.getInstance().dispatchErrorEvent(this, IMPORT_FILE_ERROR, IMPORT_FILE_ERROR);
		}
		
		private function importMergedData(dataType:String):Boolean
		{
			try
			{
				importModel.vo.textureAtlasType = (dataType == GlobalConstValues.SWF_SUFFIX)? GlobalConstValues.TEXTURE_ATLAS_TYPE_SWF: GlobalConstValues.TEXTURE_ATLAS_TYPE_PNG;
				
				var decompressedData:DecompressedData = DataParser.decompressData(importModel.vo.data);    // decompress error
				if(!(decompressedData.dragonBonesData is XML))
				{
					decompressedData.dragonBonesData = objectToXML(decompressedData.dragonBonesData, ConstValues.DRAGON_BONES);    // object to xml error
				}
				importModel.vo.skeleton = decompressedData.dragonBonesData as XML;
				importModel.formatXML();
				
				if(!(decompressedData.textureAtlasData is XML))
				{
					decompressedData.textureAtlasData = objectToXML(decompressedData.textureAtlasData, ConstValues.TEXTURE_ATLAS);    // object to xml error
				}
				importModel.vo.textureAtlasConfig = decompressedData.textureAtlasData as XML;
				importModel.vo.textureAtlasBytes = decompressedData.textureBytes;
				
				// asynchronous
				loadTextureAtlasBytesService.addEventListener(LoadTextureAtlasBytesService.TEXTURE_ATLAS_BYTES_LOAD_COMPLETE, loadTextureAtlasBytesHandler);
				loadTextureAtlasBytesService.load(importModel.vo);
				return true;
			}
			catch(err:Error)
			{
			}
			return false;
		}
		
		private function importZipData(dataType:String):Boolean
		{
			try
			{
				var zip:Zip = new Zip();
				zip.decode(importModel.vo.data);    // zip decode error
				
				var subTextures:Object;
				for each (var zipFile:ZipFile in zip.fileV)
				{
					if (zipFile.isDirectory)
					{
						// pass directory
						continue;
					}
					
					// check file type in zip by file suffix
					var fileName:String = zipFile.name;
					var fileType:String = fileName.split(".").pop();
					
					switch (fileType)
					{
						case GlobalConstValues.XML_SUFFIX:
							var xml:XML = XML(zipFile.data.toString());    // xml decode error
							if (xml[ConstValues.ARMATURE].length() > 0)
							{
								importModel.vo.skeleton = xml;
								importModel.formatXML();
							}
							else if (xml[ConstValues.SUB_TEXTURE].length() > 0)
							{
								importModel.vo.textureAtlasConfig = xml;
							}
							break;
						
						case GlobalConstValues.JSON_SUFFIX:
							var json:Object = com.adobe.serialization.json.JSON.decode(zipFile.data.toString());    // json decode error
							if (json[ConstValues.ARMATURE])
							{
								importModel.vo.skeleton = objectToXML(json, ConstValues.DRAGON_BONES);
								importModel.formatXML();
							}
							else if (json[ConstValues.SUB_TEXTURE])
							{
								importModel.vo.textureAtlasConfig = objectToXML(json, ConstValues.TEXTURE_ATLAS);
							}
							else if (0)
							{
								// spine
								/*if(zipFile.name.indexOf(GlobalConstValues.SPINE_FOLDER) == 0)
								{
									//spine文件夹
									if(!_spineObject)
									{
										_spineObject = {};
									}
									name = zipFile.name.replace(/\.\w+$/,"");
									name = name.substr(GlobalConstValues.SPINE_FOLDER.length + 1);
									object = com.adobe.serialization.json.JSON.decode(zipFile.data.toString());
									_spineObject[name] = object;
								}*/
							}
							
							break;
						
						case GlobalConstValues.AMF3_SUFFIX:
							var amf3:ByteArray = new ByteArray();
							amf3.writeBytes(zipFile.data);
							amf3.uncompress()    // uncompress error;
							var object:Object = amf3.readObject();
							
							if (object[ConstValues.ARMATURE])
							{
								importModel.vo.skeleton = objectToXML(object, ConstValues.DRAGON_BONES);
								importModel.formatXML();
							}
							else if (object[ConstValues.SUB_TEXTURE])
							{
								importModel.vo.textureAtlasConfig = objectToXML(object, ConstValues.TEXTURE_ATLAS);
							}
							break;
						
						case GlobalConstValues.SWF_SUFFIX:
							importModel.vo.textureAtlasType = GlobalConstValues.TEXTURE_ATLAS_TYPE_SWF;
							importModel.vo.textureAtlasBytes = zipFile.data;
							break;
						
						case GlobalConstValues.PNG_SUFFIX:
							importModel.vo.textureAtlasType = GlobalConstValues.TEXTURE_ATLAS_TYPE_PNG;
							if (fileName.indexOf("/") > 0)
							{
								//texture文件夹
								fileName = zipFile.name.replace(/\.\w+$/, "");
								fileName = fileName.substr(GlobalConstValues.TEXTURE_ATLAS_DATA_NAME.length + 1);
								if(!subTextures)
								{
									subTextures = {};
								}
								subTextures[fileName] = zipFile.data;
							}
							else
							{
								importModel.vo.textureAtlasBytes = zipFile.data;
							}
							break;
					}
				}
				zip.clear();
				
				if (!importModel.vo.skeleton)
				{
					return false;
				}
				
				if (importModel.vo.textureAtlasBytes)
				{
					if (importModel.vo.textureAtlasConfig)
					{
						// asynchronous
						loadTextureAtlasBytesService.addEventListener(LoadTextureAtlasBytesService.TEXTURE_ATLAS_BYTES_LOAD_COMPLETE, loadTextureAtlasBytesHandler);
						loadTextureAtlasBytesService.load(importModel.vo);
					}
					else
					{
						importComplete();
					}
				}
				else if (subTextures)
				{
					// asynchronous
					BitmapDataUtil.byteArrayMapToBitmapDataMap(subTextures, bitmapDataMapComplete);
				}
				
				return true;
			}
			catch (err:Error)
			{
			}
			return false;
		}
		
		private function loadTextureAtlasBytesHandler(e:ServiceEvent):void
		{
			loadTextureAtlasBytesService.removeEventListener(LoadTextureAtlasBytesService.TEXTURE_ATLAS_BYTES_LOAD_COMPLETE, loadTextureAtlasBytesHandler);
			//importModel.vo已经被loadTextureAtlasBytesService填充过
			//importModel.vo.textureAtlas;
			//importModel.vo.textureAtlasSWF;
			importComplete();
		}
		
		private function bitmapDataMapComplete(bitmapDataMap:Object):void
		{
			var rectMap:Object = {};
			for (var name:String in bitmapDataMap)
			{
				var bitmapData:BitmapData = bitmapDataMap[name];
				var rect:Rectangle = new Rectangle(0, 0, bitmapData.width, bitmapData.height);
				rectMap[name] = rect;
			}
			
			/*if(_spineObject)
			{
				importModel.vo.name = importModel.vo.name || "spine";
				importModel.createTextureAtlas(rectMap, null, importModel.vo.name);
				importModel.vo.skeleton = formatSpineData(_spineObject, importModel.vo.textureAtlasConfig, importModel.vo.name);
			}
			else
			{*/
				importModel.createTextureAtlas(rectMap);
			//}
			
			importModel.vo.textureAtlas = 
				BitmapDataUtil.getMergeBitmapData(
					bitmapDataMap,
					importModel.getSubTextureRectMap(),
					importModel.textureAtlasWidth,
					importModel.textureAtlasHeight
				);
			
			importComplete();
		}
		
		private function importComplete():void
		{
			_isWorking = false;
			this.dispatchEvent(new ServiceEvent(IMPORT_FILE_COMPLETE, importModel.vo));
		}
	}
}