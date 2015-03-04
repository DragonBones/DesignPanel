package core.controller
{
	import core.SettingManager;
	import core.events.ControllerEvent;
	import core.events.MediatorEvent;
	import core.model.ParsedModel;
	import core.model.vo.ImportVO;
	import core.suppotClass._BaseCommand;
	import core.utils.GlobalConstValues;
	
	public final class ViewCommand extends _BaseCommand
	{
		[Inject]
		public var parsedModel:ParsedModel;
		
		[Inject]
		public var event:MediatorEvent;
		
		private var _settingManager:SettingManager;
		
		override public function execute():void
		{
			_settingManager = SettingManager.getInstance();
			
			switch(event.type)
			{
				case MediatorEvent.UPDATE_FLA_ARMATURE:
					if(parsedModel.vo.importVO)
					{
						var importVO:ImportVO = new ImportVO();
						_settingManager.setImportVOValues(importVO);
						importVO.importType = GlobalConstValues.IMPORT_TYPE_FLA_ALL_LIBRARY_ITEMS;
						importVO.isToMerge = true;
						importVO.id = parsedModel.vo.importVO.id;
						importVO.flaItems = new Vector.<String>;
						importVO.flaItems.push(event.data);
						this.dispatcher.dispatchEvent(new ControllerEvent(ControllerEvent.IMPORT_FLA, importVO));
					}
					
					break;
				
				case MediatorEvent.REMOVE_ARMATURE:
					this.dispatcher.dispatchEvent(new ControllerEvent(ControllerEvent.REMOVE_ARMATURE, event.data));
					break;
				
			}
		}
	}
}