package core.controller
{
	import core.events.ControllerEvent;
	import core.events.ServiceEvent;
	import core.SettingManager;
	import core.service.JSFLService;
	import core.suppotClass._BaseCommand;
	
	public final class SettingStartupCommand extends _BaseCommand
	{
		[Inject]
		public var event:ControllerEvent
		
		[Inject]
		public var jsflService:JSFLService;
		
		private var _settingManager:SettingManager;
		
		override public function execute():void
		{
			_settingManager = SettingManager.getInstance();
			var languageID:int = _settingManager.languageIndex;
			if(languageID >= 0)
			{
				// flash setter bug
				_settingManager.languageIndex = 1;
				_settingManager.languageIndex = 0;
				_settingManager.languageIndex = languageID;
			}
			else if (JSFLService.isAvailable)
			{
				jsflService.runJSFLCode(null, "fl.languageCode;", jsflProxyHandler);
				function jsflProxyHandler(e:ServiceEvent):void
				{
					var languageCode:String = e.data;
					var length:int = _settingManager.languageAC.length;
					for(var i:int = 0; i < length; i++)
					{
						if(_settingManager.languageAC[i].value == languageCode)
						{
							// flash setter bug
							_settingManager.languageIndex = 1;
							_settingManager.languageIndex = 0;
							_settingManager.languageIndex = i;
							return;
						}
					}
					// flash setter bug
					_settingManager.languageIndex = 1;
					_settingManager.languageIndex = 0;
				}
			}
			else
			{
				// flash setter bug
				_settingManager.languageIndex = 1;
				_settingManager.languageIndex = 0;
			}
		}
	}
}