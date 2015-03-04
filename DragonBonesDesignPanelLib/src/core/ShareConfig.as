package core
{
	import flash.events.IEventDispatcher;
	
	import core.controller.ControlCommand;
	import core.controller.CreateAnimationToFlashCommand;
	import core.controller.ExportFileCommand;
	import core.controller.ImportFLACommand;
	import core.controller.ImportFileCommand;
	import core.controller.ModelCommand;
	import core.controller.MultipleImportAndExportCommand;
	import core.controller.RemoveArmatureCommand;
	import core.controller.SettingStartupCommand;
	import core.controller.ViewCommand;
	import core.events.ControllerEvent;
	import core.events.MediatorEvent;
	import core.events.ModelEvent;
	import core.mediator.AnimationControlViewMediator;
	import core.mediator.ArmaturesPanelMediator;
	import core.mediator.BoneControlViewMediator;
	import core.model.ImportModel;
	import core.model.ParsedModel;
	import core.service.ImportDataToExportDataService;
	import core.service.ImportFLAService;
	import core.service.ImportFileService;
	import core.service.JSFLService;
	import core.service.LoadTextureAtlasBytesService;
	import core.view.AnimationControlView;
	import core.view.ArmaturesPanel;
	import core.view.BoneControlView;
	
	import light.net.LocalConnectionClientService;
	import light.net.LocalConnectionServerService;
	
	import robotlegs.bender.extensions.eventCommandMap.api.IEventCommandMap;
	import robotlegs.bender.extensions.mediatorMap.api.IMediatorMap;
	import robotlegs.bender.framework.api.IConfig;
	import robotlegs.bender.framework.api.IInjector;
	import robotlegs.bender.mxml.ContextBuilderTag;
	
	public final class ShareConfig implements IConfig
	{
		//
		public static const HOST:String = "_DragonBonesDesignPanelLocalConnection";
		
		//
		public static const IMPORT_MODEL:String = "importModel";
		public static const EXPORT_MODEL:String = "exportModel";
		
		[Inject]
		public var injector:IInjector;
		
		[Inject]
		public var dispatcher:IEventDispatcher;
		
		[Inject]
		public var mediatorMap:IMediatorMap;
		
		[Inject]
		public var commandMap:IEventCommandMap;
		
		// 
		public var parsedModel:ParsedModel;
		
		//
		private var _contextBuilderTag:ContextBuilderTag;
		
		
		public function configure():void
		{
			//model
			parsedModel = new ParsedModel();
			injector.injectInto(parsedModel);
			
			injector.map(core.model.ImportModel, IMPORT_MODEL).asSingleton();
			injector.map(core.model.ImportModel, EXPORT_MODEL).asSingleton();
			injector.map(core.model.ParsedModel).toValue(parsedModel);
			
			
			//view
			mediatorMap.map(core.view.AnimationControlView).toMediator(core.mediator.AnimationControlViewMediator);
			mediatorMap.map(core.view.BoneControlView).toMediator(core.mediator.BoneControlViewMediator);
			mediatorMap.map(core.view.ArmaturesPanel).toMediator(core.mediator.ArmaturesPanelMediator);
			
			
			//controller
			commandMap.map(core.events.ControllerEvent.SETTING_STARTUP).toCommand(core.controller.SettingStartupCommand);
			
			commandMap.map(core.events.ModelEvent.PARSED_MODEL_ANIMATION_DATA_CHANGE).toCommand(core.controller.ModelCommand);
			commandMap.map(core.events.ModelEvent.PARSED_MODEL_TIMELINE_DATA_CHANGE).toCommand(core.controller.ModelCommand);
			commandMap.map(core.events.ModelEvent.PARSED_MODEL_BONE_PARENT_CHANGE).toCommand(core.controller.ModelCommand);
			
			commandMap.map(core.events.ControllerEvent.IMPORT_FLA).toCommand(core.controller.ImportFLACommand);
			commandMap.map(core.events.ControllerEvent.IMPORT_FILE).toCommand(core.controller.ImportFileCommand);
			commandMap.map(core.events.ControllerEvent.EXPORT_FILE).toCommand(core.controller.ExportFileCommand);
			commandMap.map(core.events.ControllerEvent.REMOVE_ARMATURE).toCommand(core.controller.RemoveArmatureCommand);
			
			commandMap.map(core.events.ControllerEvent.MULTIPLE_IMPORT_AND_EXPORT).toCommand(core.controller.MultipleImportAndExportCommand);
			commandMap.map(core.events.ControllerEvent.CREATE_ANIMATION_TO_FLASH).toCommand(core.controller.CreateAnimationToFlashCommand);
			
			commandMap.map(core.events.ControllerEvent.IMPORT_COMPLETE).toCommand(core.controller.ControlCommand);
			commandMap.map(core.events.ControllerEvent.EXPORT_COMPLETE).toCommand(core.controller.ControlCommand);
			
			commandMap.map(core.events.MediatorEvent.UPDATE_FLA_ARMATURE).toCommand(core.controller.ViewCommand);
			commandMap.map(core.events.MediatorEvent.REMOVE_ARMATURE).toCommand(core.controller.ViewCommand);
			
			
			
			// service
			var server:LocalConnectionServerService;
			if(JSFLService.isAvailable)
			{
				server = new LocalConnectionServerService();
			}
			
			var client:LocalConnectionClientService = new LocalConnectionClientService();
			
			var jsflService:JSFLService = new JSFLService();
			
			injector.map(LocalConnectionServerService).toValue(server);
			injector.map(LocalConnectionClientService).toValue(client);
			
			injector.map(core.service.LoadTextureAtlasBytesService).asSingleton();
			injector.map(core.service.JSFLService).toValue(jsflService);
			
			injector.map(core.service.ImportFLAService).asSingleton();
			injector.map(core.service.ImportFileService).asSingleton();
			injector.map(core.service.ImportDataToExportDataService).asSingleton();
			
			injector.injectInto(jsflService);
			
			
			
			
			if (server)
			{
				server.host = HOST;
				server.on();
			}
			
			client.host = HOST;
			client.on();
			jsflService.on();
			
			
			(injector.getInstance(IEventDispatcher) as IEventDispatcher)
				.dispatchEvent(
					new ControllerEvent(ControllerEvent.SETTING_STARTUP)
				);
		}
	}
}
