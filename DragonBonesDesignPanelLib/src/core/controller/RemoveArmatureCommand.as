package core.controller
{
	import core.events.ControllerEvent;
	import core.events.ServiceEvent;
	import core.model.ImportModel;
	import core.model.ParsedModel;
	import core.service.LoadTextureAtlasBytesService;
	import core.suppotClass._BaseCommand;
	import core.utils.GlobalConstValues;
	
	import modifySWF.tirm;
	
	import core.utils.BitmapDataUtil;
	import core.utils.PNGEncoder;
	
	public final class RemoveArmatureCommand extends _BaseCommand
	{
		[Inject]
		public var loadTextureAtlasBytesService:LoadTextureAtlasBytesService;
		
		[Inject]
		public var parsedModel:ParsedModel;
		
		[Inject]
		public var event:ControllerEvent;
		
		override public function execute():void
		{
			var currentImportModel:ImportModel = new ImportModel();
			currentImportModel.vo = parsedModel.vo.importVO.clone();
			
			var rawRectMap:Object = currentImportModel.getSubTextureRectMap();
			
			if(!currentImportModel.removeArmatureByName(event.data))
			{
				return;
			}
			
			
			if(currentImportModel.vo.textureAtlasType == GlobalConstValues.TEXTURE_ATLAS_TYPE_SWF)
			{
				currentImportModel.vo.textureAtlasBytes = 
					tirm
					(
						currentImportModel.vo.textureAtlasBytes,
						currentImportModel.getTextureAtlasWithPivot()
					);
				
				loadTextureAtlasBytesService.addEventListener(LoadTextureAtlasBytesService.TEXTURE_ATLAS_BYTES_LOAD_COMPLETE, textureAtlasBytesHandler);
				loadTextureAtlasBytesService.load(currentImportModel.vo);
				this.directCommandMap.detain(this);
			}
			else
			{
				var subBitmapDataMap:Object = 
					BitmapDataUtil.getSubBitmapDataDic(
						currentImportModel.vo.textureAtlas, 
						rawRectMap
					);
				
				var rectMap:Object = currentImportModel.getSubTextureRectMap();
				
				for(var subTextureName:String in subBitmapDataMap)
				{
					if(!rectMap[subTextureName])
					{
						delete subBitmapDataMap[subTextureName];
						continue;
					}
				}
				
				//currentImportModel.vo.textureAtlas 会被 parseModel回收
				currentImportModel.vo.textureAtlas = 
					BitmapDataUtil.getMergeBitmapData(
						subBitmapDataMap, 
						rectMap, 
						currentImportModel.textureAtlasWidth, 
						currentImportModel.textureAtlasHeight
					);
				
				currentImportModel.vo.textureAtlasBytes = PNGEncoder.encode(currentImportModel.vo.textureAtlas);
				
				this.dispatcher.dispatchEvent(new ControllerEvent(ControllerEvent.IMPORT_COMPLETE, currentImportModel.vo));
			}
		}
		
		private function textureAtlasBytesHandler(e:ServiceEvent):void
		{
			loadTextureAtlasBytesService.removeEventListener(LoadTextureAtlasBytesService.TEXTURE_ATLAS_BYTES_LOAD_COMPLETE, textureAtlasBytesHandler);
			this.dispatcher.dispatchEvent(new ControllerEvent(ControllerEvent.IMPORT_COMPLETE, e.data));
			this.directCommandMap.release(this);
		}
	}
}