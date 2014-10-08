package core.suppotClass
{
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	
	import robotlegs.bender.framework.api.IInjector;

	public class _BaseService extends EventDispatcher
	{
		[Inject]
		public var injector:IInjector;
		
		[Inject]
		public var dispatcher:IEventDispatcher;
	}
}