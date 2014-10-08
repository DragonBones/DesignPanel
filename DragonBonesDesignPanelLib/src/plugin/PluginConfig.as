package plugin
{
	import flash.events.IEventDispatcher;
	
	import core.events.ControllerEvent;
	import core.events.MediatorEvent;
	
	import plugin.controller.ControlCommand;
	import plugin.controller.StartupCommand;
	import plugin.controller.ViewCommand;
	import plugin.mediator.ArmaturesPanelMediator;
	import plugin.view.ArmaturesPanel;
	
	import robotlegs.bender.extensions.eventCommandMap.api.IEventCommandMap;
	import robotlegs.bender.extensions.mediatorMap.api.IMediatorMap;
	import robotlegs.bender.framework.api.IConfig;
	import robotlegs.bender.framework.api.IInjector;
	
	public final class PluginConfig implements IConfig
	{
		[Inject]
		public var injector:IInjector;
		
		[Inject]
		public var dispatcher:IEventDispatcher;
		
		[Inject]
		public var mediatorMap:IMediatorMap;
		
		[Inject]
		public var commandMap:IEventCommandMap;
		
		public function configure():void
		{
			//model
			
			//view
			mediatorMap.map(plugin.view.ArmaturesPanel).toMediator(plugin.mediator.ArmaturesPanelMediator);
			
			//control
			commandMap.map(core.events.ControllerEvent.STARTUP).toCommand(plugin.controller.StartupCommand);
			
			commandMap.map(core.events.ControllerEvent.IMPORT_COMPLETE).toCommand(plugin.controller.ControlCommand);
			commandMap.map(core.events.ControllerEvent.EXPORT_COMPLETE).toCommand(plugin.controller.ControlCommand);
			
			commandMap.map(core.events.MediatorEvent.UPDATE_FLA_ARMATURE).toCommand(plugin.controller.ViewCommand);
			commandMap.map(core.events.MediatorEvent.REMOVE_ARMATURE).toCommand(plugin.controller.ViewCommand);
			
			(injector.getInstance(IEventDispatcher) as IEventDispatcher)
				.dispatchEvent(
					new ControllerEvent(ControllerEvent.STARTUP)
				);
		}
	}
}