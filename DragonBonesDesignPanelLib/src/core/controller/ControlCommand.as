package core.controller
{
	import core.events.ControllerEvent;
	import core.model.ParsedModel;
	import core.model.vo.ImportVO;
	import core.suppotClass._BaseCommand;
	
	public final class ControlCommand extends _BaseCommand
	{
		[Inject]
		public var event:ControllerEvent;
		
		[Inject]
		public var parsedModel:ParsedModel;
		
		override public function execute():void
		{
			var importVO:ImportVO;
			
			switch(event.type)
			{
				case ControllerEvent.IMPORT_COMPLETE:
					importVO = event.data;
					parsedModel.setDataFromImport(importVO);
					break;
			}
		}
	}
}