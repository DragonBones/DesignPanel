package core.service
{
	import core.SettingManager;
	import core.events.ServiceEvent;
	import core.model.ImportModel;
	import core.model.vo.ImportVO;
	import core.suppotClass._BaseService;
	import core.utils.GlobalConstValues;
	
	import dragonBones.utils.ConstValues;
	
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.events.Event;
	import flash.geom.Rectangle;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	
	import light.managers.ErrorManager;
	import light.managers.RequestManager;
	
	import modifySWF.modify;
	
	public final class ImportFLAService extends _BaseService
	{
		public static const IMPORT_FLA_COMPLETE:String = "IMPORT_FLA_COMPLETE";
		public static const IMPORT_FLA_ERROR:String = "IMPORT_FLA_ERROR";
		
		public static const IMPORT_ARMATURE:String = "IMPORT_ARMATURE";
		public static const IMPORT_ARMATURE_ERROR:String = "IMPORT_ARMATURE_ERROR";
		public static const IMPORT_SUBTEXTURE:String = "IMPORT_SUBTEXTURE";
		public static const IMPORT_SUBTEXTURE_ERROR:String = "IMPORT_SUBTEXTURE_ERROR";
		
		// jsfl service error
		public static const ERROR_JSFL_SERVICE_ERROR:String = "jsflServiceError";
		public static const ERROR_NO_ACTIVE_DOM:String = "noActiveDom";
		public static const ERROR_NO_ARMATURE_IN_DOM:String = "noArmatureInDom";
		
		[Inject (name="importModel")]
		public var importModel:ImportModel;
		
		[Inject]
		public var jsflService:JSFLService;
		
		[Inject]
		public var loadTextureAtlasBytesService:LoadTextureAtlasBytesService;
		
		private var _isWorking:Boolean;
		
		private var _subTextureList:Vector.<String>;
		private var _subTextureListSuccess:Vector.<String>;
		
		private var _dragonBonesData:XML;
		
		private var _totalCounts:int;
		private var _currentLoadIndex:int;
		
		public function ImportFLAService()
		{
			init();
		}
		
		private function init():void
		{
		}
		
		public function startImport(importVO:ImportVO):void
		{
			if(_isWorking)
			{
				return;
			}
			importModel.vo = importVO;
			
			jsflService.addEventListener(JSFLService.JSFL_CONNECTION_ERROR, jsflConnectionErrorHandler);
			
			//Load bone elements from Flash Pro
			getArmatureList(
				importModel.vo.id || "",
				importModel.vo.importType == GlobalConstValues.IMPORT_TYPE_FLA_SELECTED_LIBRARY_ITEMS, 
				importModel.vo.flaItems || new Vector.<String>
			);
		}
		
		private function endImport():void
		{
			_isWorking = false;
			jsflService.removeEventListener(JSFLService.JSFL_CONNECTION_ERROR, jsflConnectionErrorHandler);
		}
		
		private function jsflConnectionErrorHandler(e:Event):void
		{
			endImport();
			light.managers.ErrorManager.getInstance().dispatchErrorEvent(this, IMPORT_FLA_ERROR, ERROR_JSFL_SERVICE_ERROR);
		}
		
		private function getArmatureList(domID:String = null, isSelected:Boolean = false, armatureNames:Vector.<String> = null):void
		{
			jsflService.runJSFLMethod(null, "db.getArmatureList", domID, isSelected, armatureNames, getArmatureListHandler);
		}
		
		private function getArmature(domID:String, armatureName:String, dragonBonesData:XML, fadeInTime:Number, mergeLayersInFolder:Boolean = false):void
		{
			jsflService.runJSFLMethod(null, "db.getArmature", domID, armatureName, dragonBonesData, fadeInTime, mergeLayersInFolder, readNextArmatureHandler);
		}
		
		private function clearTextureSWFItem(domID:String):void
		{
			jsflService.runJSFLMethod(null, "db.clearTextureSWFItem", domID, clearTextureAtlasSWFHandler);
		}
		
		private function addSubTextureToSWFItem(domID:String, textureName:String):void
		{
			jsflService.runJSFLMethod(null, "db.addTextureToSWFItem", domID, textureName, readNextSubTextureHandler);
		}
		
		private function exportSWF(domID:String):void
		{
			jsflService.runJSFLMethod(null, "db.exportSWF", domID, exportSWFHandler);
		}
		
		private function getArmatureListHandler(e:ServiceEvent):void
		{
			var result:String = e.data;
			_dragonBonesData = XML(result);
			
			//start load armature data
			importModel.vo.id = _dragonBonesData.@id;
			if(importModel.vo.id)
			{
				importModel.vo.textureAtlasType = GlobalConstValues.TEXTURE_ATLAS_TYPE_SWF;
				importModel.vo.dataType = GlobalConstValues.DATA_TYPE_GLOBAL;
				
				importModel.vo.configType = GlobalConstValues.CONFIG_TYPE_XML;
				
				importModel.vo.name = _dragonBonesData.@[ConstValues.A_NAME];
				importModel.vo.url = _dragonBonesData.@url;
				importModel.vo.skeleton = _dragonBonesData.copy();
				delete importModel.vo.skeleton.@id;
				delete importModel.vo.skeleton.@url;
				delete importModel.vo.skeleton.*;
				
				_totalCounts = _dragonBonesData[ConstValues.ARMATURE].length();
				_currentLoadIndex = 0;
				_isWorking = true;
				readNextArmature();
				SettingManager.getInstance().updateSettingAfterImportData(importModel.vo.dataType);
			}
			else
			{
				endImport();
				light.managers.ErrorManager.getInstance().dispatchErrorEvent(this, IMPORT_FLA_ERROR, result); 
			}
		}
		
		private function readNextArmature():void
		{
			if(_currentLoadIndex < _totalCounts)
			{
				var armatureXML:XML = _dragonBonesData[ConstValues.ARMATURE][_currentLoadIndex];
				var armatureName:String = armatureXML.@[ConstValues.A_NAME];
				_currentLoadIndex ++;
				if (importModel.getArmatureList(armatureName)[0])
				{
					readNextArmature();
					return;
				}
				this.dispatchEvent(new ServiceEvent(IMPORT_ARMATURE, [armatureName, _currentLoadIndex, _totalCounts]));
				getArmature(importModel.vo.id, armatureName, _dragonBonesData, importModel.vo.fadeInTime);
			}
			else
			{
				//load texture complete, start to place texture
				clearTextureSWFItem(importModel.vo.id);
			}
		}
		
		private function readNextArmatureHandler(e:ServiceEvent):void
		{
			var result:String = e.data;
			if(result != "false")
			{
				RequestManager.getInstance().load(result, armatureXMLLoadHandler);
			}
		}
		
		private function armatureXMLLoadHandler(e:Event):void
		{
			switch(e.type)
			{
				case Event.COMPLETE:
					var resultXML:XML = XML((e.target as URLLoader).data);
					for each(var armature:XML in resultXML[ConstValues.ARMATURE])
					{
						importModel.addArmature(armature);
					}
					break;
				
				default:
					light.managers.ErrorManager.getInstance().dispatchErrorEvent(this, IMPORT_ARMATURE_ERROR, e.toString()); 
					break;
			}
			
			readNextArmature();
		}
		
		private function clearTextureAtlasSWFHandler(e:ServiceEvent):void
		{
			_subTextureListSuccess = new Vector.<String>;
			_subTextureList = importModel.getSubTextureListFromDisplayList();
			_totalCounts = _subTextureList.length;
			_currentLoadIndex = 0;
			//start to place texture
			readNextSubTexture();
		}
		
		private function readNextSubTexture():void
		{
			if(_currentLoadIndex < _totalCounts)
			{
				var subTextureName:String = _subTextureList[_currentLoadIndex];
				_currentLoadIndex ++;
				this.dispatchEvent(new ServiceEvent(IMPORT_SUBTEXTURE, [subTextureName, _currentLoadIndex, _totalCounts]));
				addSubTextureToSWFItem(importModel.vo.id, subTextureName);
			}
			else if(_subTextureListSuccess.length > 0)
			{
				exportSWF(importModel.vo.id);
			}
			else
			{
				importModel.vo.textureAtlasBytes = null;
				importModel.setVersion();
				endImport();
				this.dispatchEvent(new ServiceEvent(IMPORT_FLA_COMPLETE, importModel.vo));
			}
		}
		
		private function readNextSubTextureHandler(e:ServiceEvent):void
		{
			var result:String = e.data;
			if(result == ERROR_NO_ACTIVE_DOM)
			{
				endImport();
				light.managers.ErrorManager.getInstance().dispatchErrorEvent(this, IMPORT_FLA_ERROR, ERROR_NO_ACTIVE_DOM);
			}
			else if(result == "false")
			{
				light.managers.ErrorManager.getInstance().dispatchErrorEvent(this, IMPORT_SUBTEXTURE_ERROR);
			}
			else if(result == "_notExport")
			{
				//
			}
			else
			{
				_subTextureListSuccess.push(result);
			}
			
			readNextSubTexture();
		}
		
		private function exportSWFHandler(e:ServiceEvent):void
		{
			var result:String = e.data;
			if (result == ERROR_NO_ACTIVE_DOM)
			{
				endImport();
				light.managers.ErrorManager.getInstance().dispatchErrorEvent(this, IMPORT_FLA_ERROR, ERROR_NO_ACTIVE_DOM);
			}
			else
			{
				RequestManager.getInstance().load(result, loadExportSWFHandler, false, null, null, null, null, URLLoaderDataFormat.BINARY);
			}
		}
	
		private function loadExportSWFHandler(e:Event):void
		{
			switch(e.type)
			{
				case Event.COMPLETE:
					importModel.vo.textureAtlasBytes = e.target.data;
					loadTextureAtlasBytesService.addEventListener(LoadTextureAtlasBytesService.TEXTURE_ATLAS_BYTES_LOAD_COMPLETE, swfBytesHandler);
					loadTextureAtlasBytesService.load(importModel.vo);
					break;
				
				default:
					endImport();
					light.managers.ErrorManager.getInstance().dispatchErrorEvent(this, IMPORT_FLA_ERROR, e.toString()); 
					break;
			}
		}
	
		private function swfBytesHandler(e:ServiceEvent):void
		{
			loadTextureAtlasBytesService.removeEventListener(LoadTextureAtlasBytesService.TEXTURE_ATLAS_BYTES_LOAD_COMPLETE, swfBytesHandler);
			//importModel的数据被loadTextureAtlasBytesService填充过了，e.data 既是 importModel.vo
			var content:DisplayObjectContainer = importModel.vo.textureAtlasSWF;
			
			var rectMap:Object = {};
			var i:int = content.numChildren;
			while(i --)
			{
				var eachContent:DisplayObject = content.getChildAt(i);
				var rect:Rectangle = eachContent.getBounds(eachContent);
				rectMap[_subTextureListSuccess[i]] = rect;
			}
			
			importModel.updateDisplayPivot(rectMap);
			importModel.createTextureAtlas(rectMap, _subTextureListSuccess);
			importModel.vo.textureAtlasBytes = modify(importModel.vo.textureAtlasBytes, importModel.getTextureAtlasWithPivot());
			importModel.setVersion();
			
			loadTextureAtlasBytesService.addEventListener(LoadTextureAtlasBytesService.TEXTURE_ATLAS_BYTES_LOAD_COMPLETE, textureAtlasBytesHandler);
			loadTextureAtlasBytesService.load(importModel.vo);
		}
		
		private function textureAtlasBytesHandler(e:ServiceEvent):void
		{
			loadTextureAtlasBytesService.removeEventListener(LoadTextureAtlasBytesService.TEXTURE_ATLAS_BYTES_LOAD_COMPLETE, textureAtlasBytesHandler);
			endImport();
			this.dispatchEvent(new ServiceEvent(IMPORT_FLA_COMPLETE, importModel.vo));
		}
	}
}