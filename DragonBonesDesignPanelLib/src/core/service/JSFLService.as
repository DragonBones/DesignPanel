package core.service
{
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	
	import adobe.utils.MMExecute;
	
	import core.events.ServiceEvent;
	import core.suppotClass._BaseService;
	
	import light.events.LDataEvent;
	import light.managers.ErrorManager;
	import light.net.LocalConnectionClientService;
	import light.net.LocalConnectionServerService;
	import light.net.RequestGroup;
	import light.net.vo.LCVO;
	
	/**
	 * Delegate of communicate between UI panel and JSFL
	 */
	public class JSFLService extends _BaseService
	{
		public static const LOAD_JSFL_FILE_ERROR:String = "LOAD_JSFL_FILE_ERROR";
		public static const JSFL_CONNECTION_ERROR:String = "JSFL_CONNECTION_ERROR";
		
		private static const JSFLs:Vector.<String> = new <String>[
				"DragonBonesDesignPanel/utils.jsfl",
				"DragonBonesDesignPanel/events.jsfl",
				"DragonBonesDesignPanel/dragonBones.jsfl",
				"DragonBonesDesignPanel/createAnimation.jsfl",
				"DragonBonesDesignPanel/import3DTextures.jsfl"
			];
		
		private static const PORT_JSFL:String = "portJSFL";
		private static const PORT_CHECK_CONNECT:String = "portCheckConnect";
		
		/**
		 * Determine if JSFLAPI isAvailable
		 */
		public static function get isAvailable():Boolean
		{
			try
			{
				MMExecute("fl;");
				return true;
			}
			catch(e:Error)
			{
			}
			return false;
		}
		
		public static function jsflTrace(...arg):void
		{
			if(isAvailable)
			{
				MMExecute("fl.trace('" + arg.join(", ") + "');");
			}
			else
			{
				trace.apply(null, arg);
			}
		}
		
		private static function xmlToString(xml:XML):String
		{
			return <a a={xml.toXMLString()}/>.@a[0].toXMLString();
		}
		
		[Inject]
		public var server:LocalConnectionServerService;
		
		[Inject]
		public var client:LocalConnectionClientService;
		
		public var isServerConnected:Boolean;
		
		private var _requestGroup:RequestGroup;
		private var _timer:Timer;
		
		private var _prevPort:String;
		
		public function JSFLService()
		{
			init();
		}
		
		private function init():void
		{
			_requestGroup = new RequestGroup();
			_requestGroup.loadingMaxCount = 1;
			_timer = new Timer(2000);
		}
		
		public function on():void
		{
			if(server)
			{
				server.addPort(PORT_JSFL);
				server.addPort(PORT_CHECK_CONNECT);
				server.addEventListener(LocalConnectionServerService.SERVER_RECEIIVED, serverHandler);
			}
			else
			{
				_timer.addEventListener(TimerEvent.TIMER, timerHandler);
				_timer.start();
			}
			
			if(client)
			{
				client.addEventListener(LocalConnectionClientService.CLIENT_RECEIIVED, clientHandler);
				client.addEventListener(LocalConnectionClientService.SEND_ERROR, clientErrorHandler);
			}
			
			loadJSFLFile();
		}
		
		public function off():void
		{
			if(server)
			{
				server.removePort(PORT_JSFL);
				server.removePort(PORT_CHECK_CONNECT);
				server.removeEventListener(LocalConnectionServerService.SERVER_RECEIIVED, serverHandler);
			}
			else
			{
				_timer.removeEventListener(TimerEvent.TIMER, timerHandler);
				_timer.stop();
			}
			
			if(client)
			{
				client.removeEventListener(LocalConnectionClientService.CLIENT_RECEIIVED, clientHandler);
				client.removeEventListener(LocalConnectionClientService.SEND_ERROR, clientErrorHandler);
			}
		}
		
		public function loadJSFLFile():void
		{
			if(isAvailable)
			{
				for each(var jsflURL:String in JSFLs)
				{
					_requestGroup.load(jsflURL, jsflLoadHandler);
				}
			}
		}
		
		public function runJSFLCode(type:String, code:String):void
		{
			if(client)
			{
				_prevPort = PORT_JSFL;
				client.send(PORT_JSFL, type, code);
			}
		}
		
		public function runJSFLMethod(type:String, method:String, ...args):void
		{
			var code:String = method + "(";
			for each(var arg:Object in args)
			{
				if(arg is Number || arg is Boolean)
				{
					code += arg + ",";
				}
				else if(arg is XML)
				{
					XML.prettyIndent = -1;
					var xmlString:String = xmlToString(arg as XML);
					XML.prettyIndent = 1;
					code += '"' + xmlString + '",';
				}
				else
				{
					code += '"' + arg + '",';
				}
			}
			
			if(args.length > 0)
			{
				code = code.substr(0, code.length -1);
			}
			
			code += ');';
			
			runJSFLCode(type, code);
		}
		
		private function jsflLoadHandler(e:Event):void
		{
			switch(e.type)
			{
				case Event.COMPLETE:
					MMExecute(e.target.data);
					break;
				
				default:
					light.managers.ErrorManager.getInstance().dispatchErrorEvent(this, LOAD_JSFL_FILE_ERROR, "JSFL文件读取失败！");
					break;
			}
		}
		
		private function timerHandler(e:Event):void
		{
			if (client)
			{
				_prevPort = PORT_CHECK_CONNECT;
				client.send(PORT_CHECK_CONNECT, null, "handshake");
			}
		}
		
		private function serverHandler(e:LDataEvent):void
		{
			switch(e.type)
			{
				case LocalConnectionServerService.SERVER_RECEIIVED:
					var vo:LCVO = e.data as LCVO;
					var sendVO:LCVO;
					if(vo.port == PORT_JSFL)
					{
						sendVO = vo.clone();
						sendVO.data = MMExecute(vo.data.toString());
						server.send(sendVO);
					}
					else if(vo.port == PORT_CHECK_CONNECT)
					{
						sendVO = vo.clone();
						sendVO.data = "handshake";
						server.send(sendVO);
					}
					break;
			}
		}
		
		private function clientHandler(e:LDataEvent):void
		{
			switch(e.type)
			{
				case LocalConnectionClientService.CLIENT_RECEIIVED:
					var vo:LCVO = e.data as LCVO;
					if(vo.port == PORT_JSFL)
					{
						if (vo.type)
						{
							this.dispatchEvent(new ServiceEvent(vo.type, vo.data));
						}
					}
					else if(vo.port == PORT_CHECK_CONNECT)
					{
						// handshake
						isServerConnected = true;
					}
					break;
			}
		}
		
		private function clientErrorHandler(e:Event):void
		{
			if (_prevPort == PORT_JSFL)
			{
				light.managers.ErrorManager.getInstance().dispatchErrorEvent(this, JSFL_CONNECTION_ERROR, e.toString());
			}
			else if (_prevPort == PORT_CHECK_CONNECT)
			{
				isServerConnected = false;
				client.connectToServer(-1);
			}
		}
	}
}