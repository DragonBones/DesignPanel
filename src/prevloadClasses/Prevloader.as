package prevloadClasses
{
	import adobe.utils.MMExecute;
	
	import flash.display.Loader;
	import flash.display.Sprite;
	import flash.display.Stage;
	import flash.events.Event;
	import flash.events.ProgressEvent;
	import flash.geom.Rectangle;
	import flash.system.ApplicationDomain;
	import flash.system.Capabilities;
	import flash.system.LoaderContext;
	
	import mx.events.FlexEvent;
	import mx.preloaders.IPreloaderDisplay;

	public class Prevloader extends Sprite implements IPreloaderDisplay
	{
		
		private var loader:Loader;
		private var isInitComplete:Boolean;
		private var isLoadPrevloadClassesComplete:Boolean;
		
		public function Prevloader()
		{
			
			//解决：ReferenceError: Error #1069: 在 flash.display.Stage 上找不到属性 softKeyboardRect，且没有默认值。
			Stage.prototype.softKeyboardRect = new Rectangle();
			
			//try{
			//	MMExecute('fl.trace("Prevloader,播放器版本：'+Capabilities.version+',播放器类型：'+Capabilities.playerType+'");');
			//}catch(e:Error){
			//	trace('Prevloader,播放器版本：'+Capabilities.version+',播放器类型：'+Capabilities.playerType);
			//}
		}
		
		public function initialize():void
		{
			//try{
			//	MMExecute('fl.trace("initialize");');
			//}catch(e:Error){
			//	trace("initialize");
			//}
			loader=new Loader();
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE,loadPrevloadClassesComplete);
			loader.loadBytes(new PrevloadClassesSWFData(),new LoaderContext(false,ApplicationDomain.currentDomain));
		}
		public function set preloader(preloader:Sprite):void{
			//Listen for 正在下载
			preloader.addEventListener(ProgressEvent.PROGRESS,fun);
			//Listen for 下载完成
			preloader.addEventListener(Event.COMPLETE,fun);
			//Listen for 正在初始化
			preloader.addEventListener(FlexEvent.INIT_PROGRESS,fun);
			//Listen for 初始化完成
			preloader.addEventListener(FlexEvent.INIT_COMPLETE,initComplete);
		}
		private function fun(...args):void{
			
		}
		private function initComplete(...args):void{
			//try{
			//	MMExecute('fl.trace("initComplete");');
			//}catch(e:Error){
			//	trace("initComplete");
			//}
			isInitComplete=true;
			checkComplete();
		}
		private function loadPrevloadClassesComplete(...args):void{
			isLoadPrevloadClassesComplete=true;
			checkComplete();
		}
		private function checkComplete():void{
			if(isInitComplete&&isLoadPrevloadClassesComplete){
				this.dispatchEvent(new Event(Event.COMPLETE));
			}
		}
		
		public function get backgroundAlpha():Number{
			return 0;
		}
		public function set backgroundAlpha(_backgroundAlpha:Number):void{
		}
		public function get backgroundColor():uint{
			return 0x000000;
		}
		public function set backgroundColor(_backgroundColor:uint):void{
		}
		public function get backgroundImage():Object{
			return null;
		}
		public function set backgroundImage(_backgroundImage:Object):void{
		}
		public function get backgroundSize():String{
			return "";
		}
		public function set backgroundSize(_backgroundSize:String):void{
		}
		
		public function get stageWidth():Number{
			return stage.stageWidth;
		}
		public function set stageWidth(_stageWidth:Number):void{
		}
		public function get stageHeight():Number{
			return stage.stageHeight;
		}
		public function set stageHeight(_stageHeight:Number):void{
		}
	}
}