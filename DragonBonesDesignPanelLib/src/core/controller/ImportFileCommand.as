package core.controller
{
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.URLLoaderDataFormat;
	
	import core.events.ControllerEvent;
	import core.events.ServiceEvent;
	import core.model.ImportModel;
	import core.model.vo.ImportVO;
	import core.service.ImportFileService;
	import core.suppotClass._BaseCommand;
	
	import light.managers.RequestManager;
	
	public final class ImportFileCommand extends _BaseCommand
	{
		[Inject]
		public var event:ControllerEvent;
		
		[Inject]
		public var importFileService:ImportFileService;
		
		[Inject (name="importModel")]
		public var importModel:ImportModel;
		
		private var _importVO:ImportVO;
		
		override public function execute():void
		{
			this.directCommandMap.detain(this);
			
			_importVO = event.data;
			
			if(_importVO.url)
			{
				RequestManager.getInstance().load(_importVO.url, loadHandler, true, null, null, null, null, URLLoaderDataFormat.BINARY);
			}
			else if(_importVO.typeFilter)
			{
				RequestManager.getInstance().browse(_importVO.typeFilter, loadHandler);
			}
		}
		
		private function loadHandler(e:Event):void
		{
			switch(e.type)
			{
				case Event.CANCEL:
					this.dispatcher.dispatchEvent(new ControllerEvent(ControllerEvent.IMPORT_CANCLE));
					this.directCommandMap.release(this);
					break;
				
				case IOErrorEvent.IO_ERROR:
					this.dispatcher.dispatchEvent(new ControllerEvent(ControllerEvent.IMPORT_ERROR, e));
					this.directCommandMap.release(this);
					break;
				
				case SecurityErrorEvent.SECURITY_ERROR:
					this.dispatcher.dispatchEvent(new ControllerEvent(ControllerEvent.IMPORT_ERROR, e));
					this.directCommandMap.release(this);
					break;
				
				case ProgressEvent.PROGRESS:
					this.dispatcher.dispatchEvent(new ControllerEvent(ControllerEvent.IMPORT_PROGRESS, e));
					break;
				
				case Event.COMPLETE:
					importFileService.addEventListener(ImportFileService.IMPORT_FILE_ERROR, serviceHandler);
					importFileService.addEventListener(ImportFileService.IMPORT_FILE_COMPLETE, serviceHandler);
					_importVO.data = e.target.data;
					importFileService.startImport(_importVO);
					break;
			}
		}
		
		private function serviceHandler(e:Event):void
		{
			importFileService.removeEventListener(ImportFileService.IMPORT_FILE_ERROR, serviceHandler);
			importFileService.removeEventListener(ImportFileService.IMPORT_FILE_COMPLETE, serviceHandler);
			switch(e.type)
			{
				case ImportFileService.IMPORT_FILE_ERROR:
					this.dispatcher.dispatchEvent(new ControllerEvent(ControllerEvent.IMPORT_ERROR, e));
					break;
				
				case ImportFileService.IMPORT_FILE_COMPLETE:
					this.dispatcher.dispatchEvent(new ControllerEvent(ControllerEvent.IMPORT_COMPLETE, (e as ServiceEvent).data));
					break;
			}
			
			this.directCommandMap.release(this);
		}
	}
}