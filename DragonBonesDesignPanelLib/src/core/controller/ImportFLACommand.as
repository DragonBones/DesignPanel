package core.controller
{
	import flash.events.Event;
	
	import core.events.ControllerEvent;
	import core.events.ServiceEvent;
	import core.model.ImportModel;
	import core.model.ParsedModel;
	import core.model.vo.ImportVO;
	import core.service.ImportFLAService;
	import core.service.LoadTextureAtlasBytesService;
	import core.suppotClass._BaseCommand;
	
	import modifySWF.combine;
	
	public final class ImportFLACommand extends _BaseCommand
	{
		[Inject]
		public var loadTextureAtlasBytesService:LoadTextureAtlasBytesService;
		
		[Inject]
		public var importFLAService:ImportFLAService;
		
		[Inject]
		public var parsedModel:ParsedModel;
		
		[Inject (name="importModel")]
		public var importModel:ImportModel;
		
		[Inject]
		public var event:ControllerEvent;
		
		override public function execute():void
		{
			this.directCommandMap.detain(this);
			importFLAService.addEventListener(ImportFLAService.IMPORT_FLA_ERROR, serviceHandler);
			importFLAService.addEventListener(ImportFLAService.IMPORT_FLA_COMPLETE, serviceHandler);
			importFLAService.startImport(event.data);
		}
		
		private function serviceHandler(e:Event):void
		{
			importFLAService.removeEventListener(ImportFLAService.IMPORT_FLA_ERROR, serviceHandler);
			importFLAService.removeEventListener(ImportFLAService.IMPORT_FLA_COMPLETE, serviceHandler);
			switch(e.type)
			{
				case ImportFLAService.IMPORT_FLA_ERROR:
					this.dispatcher.dispatchEvent(new ControllerEvent(ControllerEvent.IMPORT_ERROR, e));
					this.directCommandMap.release(this);
					break;
				
				case ImportFLAService.IMPORT_FLA_COMPLETE:
					var importVO:ImportVO = (e as ServiceEvent).data;
					if(importVO.isToMerge)
					{
						//bitmapData 暂不合并
						var currentImportModel:ImportModel = new ImportModel();
						currentImportModel.vo = new ImportVO();
						currentImportModel.vo.skeleton = parsedModel.vo.importVO.skeleton;
						currentImportModel.vo.textureAtlasConfig = parsedModel.vo.importVO.textureAtlasConfig;
						currentImportModel.merge(importModel);
						
						importModel.vo.skeleton = currentImportModel.vo.skeleton;
						importModel.vo.textureAtlasConfig = currentImportModel.vo.textureAtlasConfig;
						
						importModel.vo.textureAtlasBytes = 
							combine(
								parsedModel.vo.importVO.textureAtlasBytes, 
								importModel.vo.textureAtlasBytes,
								importModel.getTextureAtlasWithPivot()
							);
						
						loadTextureAtlasBytesService.addEventListener(LoadTextureAtlasBytesService.TEXTURE_ATLAS_BYTES_LOAD_COMPLETE, textureAtlasBytesHandler);
						loadTextureAtlasBytesService.load(importModel.vo);
					}
					else
					{
						this.dispatcher.dispatchEvent(new ControllerEvent(ControllerEvent.IMPORT_COMPLETE, importVO));
						this.directCommandMap.release(this);
					}
					break;
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