package plugin
{
	import flash.events.IEventDispatcher;
	
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
			
			//controller
			
			/*
			(injector.getInstance(IEventDispatcher) as IEventDispatcher)
				.dispatchEvent(
					new ControllerEvent(ControllerEvent.STARTUP)
				);
			*/
		}
	}
}