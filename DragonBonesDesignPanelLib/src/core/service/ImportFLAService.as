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
		
		private static const GET_ARMATURE_LIST:String = "GET_ARMATURE_LIST";
		private static const GENERATE_ARMATURE:String = "GENERATE_ARMATURE";
		private static const CLEAR_TEXTURE_SWFITEM:String = "CLEAR_TEXTURE_SWFITEM";
		private static const ADD_SUB_TEXTURE_TO_SWFITEM:String = "ADD_SUB_TEXTURE_TO_SWFITEM";
		private static const EXPORT_SWF:String = "EXPORT_SWF";
		private static const COPY_ANIMATION:String = "COPY_ANIMATION";
		
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
			
			//Load bone elements from Flash Pro
			jsflService.addEventListener(GET_ARMATURE_LIST, getArmatureListHandler);
			jsflService.addEventListener(JSFLService.JSFL_CONNECTION_ERROR, jsflConnectionErrorHandler);
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
			jsflService.runJSFLMethod(GET_ARMATURE_LIST, "db.getArmatureList", domID, isSelected, armatureNames);
		}
		
		private function getArmature(domID:String, armatureName:String, dragonBonesData:XML, fadeInTime:Number, mergeLayersInFolder:Boolean = false):void
		{
			jsflService.runJSFLMethod(GENERATE_ARMATURE, "db.getArmature", domID, armatureName, dragonBonesData, fadeInTime, mergeLayersInFolder);
		}
		
		private function clearTextureSWFItem(domID:String):void
		{
			jsflService.runJSFLMethod(CLEAR_TEXTURE_SWFITEM, "db.clearTextureSWFItem", domID);
		}
		
		private function addSubTextureToSWFItem(domID:String, textureName:String):void
		{
			jsflService.runJSFLMethod(ADD_SUB_TEXTURE_TO_SWFITEM, "db.addTextureToSWFItem", domID, textureName);
		}
		
		private function exportSWF(domID:String):void
		{
			jsflService.runJSFLMethod(EXPORT_SWF, "db.exportSWF", domID);
		}
		
		private function getArmatureListHandler(e:ServiceEvent):void
		{
			jsflService.removeEventListener(GET_ARMATURE_LIST, getArmatureListHandler);
			
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
				jsflService.addEventListener(GENERATE_ARMATURE, readNextArmatureHandler);
				getArmature(importModel.vo.id, armatureName, _dragonBonesData, importModel.vo.fadeInTime);
			}
			else
			{
				//load texture complete, start to place texture
				jsflService.addEventListener(CLEAR_TEXTURE_SWFITEM, clearTextureAtlasSWFHandler);
				clearTextureSWFItem(importModel.vo.id);
			}
		}
		
		private function readNextArmatureHandler(e:ServiceEvent):void
		{
			jsflService.removeEventListener(GENERATE_ARMATURE, readNextArmatureHandler);
			
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
			jsflService.removeEventListener(CLEAR_TEXTURE_SWFITEM, clearTextureAtlasSWFHandler);
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
				jsflService.addEventListener(ADD_SUB_TEXTURE_TO_SWFITEM, readNextSubTextureHandler);
				addSubTextureToSWFItem(importModel.vo.id, subTextureName);
			}
			else
			{
				jsflService.addEventListener(EXPORT_SWF, exportSWFHandler);
				exportSWF(importModel.vo.id);
			}
		}
		
		private function readNextSubTextureHandler(e:ServiceEvent):void
		{
			jsflService.removeEventListener(ADD_SUB_TEXTURE_TO_SWFITEM, readNextSubTextureHandler);
			
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
			jsflService.removeEventListener(EXPORT_SWF, exportSWFHandler);
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