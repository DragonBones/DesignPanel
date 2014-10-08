package core.suppotClass
{
	import flash.events.IEventDispatcher;
	
	import robotlegs.bender.framework.api.IInjector;
	
	public class _BaseModel
	{
		[Inject]
		public var injector:IInjector;
		
		[Inject]
		public var dispatcher:IEventDispatcher;
	}
}