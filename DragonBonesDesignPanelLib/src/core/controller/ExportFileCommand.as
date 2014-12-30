package core.controller
{
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	
	import core.events.ControllerEvent;
	import core.events.ServiceEvent;
	import core.model.vo.ExportVO;
	import core.service.ImportDataToExportDataService;
	import core.suppotClass._BaseCommand;
	
	import light.managers.RequestManager;
	
	public final class ExportFileCommand extends _BaseCommand
	{
		[Inject]
		public var event:ControllerEvent;
		
		[Inject]
		public var importDataToExportDataService:ImportDataToExportDataService;
		
		override public function execute():void
		{
			this.directCommandMap.detain(this);
			
			importDataToExportDataService.addEventListener(ImportDataToExportDataService.IMPORT_TO_EXPORT_COMPLETE, serviceHandler);
			importDataToExportDataService.export(event.data[0], event.data[1]);
		}
		
		private function serviceHandler(e:ServiceEvent):void
		{
			importDataToExportDataService.removeEventListener(ImportDataToExportDataService.IMPORT_TO_EXPORT_COMPLETE, serviceHandler);
			switch(e.type)
			{
				case ImportDataToExportDataService.IMPORT_TO_EXPORT_COMPLETE:
					RequestManager.getInstance().save(e.data[0], (e.data[1] as ExportVO).name, saveHandler);
					break;
			}
		}
		
		private function saveHandler(e:Event):void
		{
			switch(e.type)
			{
				case Event.CANCEL:
					this.dispatcher.dispatchEvent(new ControllerEvent(ControllerEvent.EXPORT_CANCEL));
					break;
				
				case IOErrorEvent.IO_ERROR:
					this.dispatcher.dispatchEvent(new ControllerEvent(ControllerEvent.EXPORT_ERROR, e));
					break;
				
				case Event.COMPLETE:
					this.dispatcher.dispatchEvent(new ControllerEvent(ControllerEvent.EXPORT_COMPLETE));
					break;
			}
			
			this.directCommandMap.release(this);
		}
	}
}