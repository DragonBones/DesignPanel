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
		
		public static const JSFLs:Vector.<String> = new <String>[
				"DragonBonesDesignPanel/utils.jsfl",
				"DragonBonesDesignPanel/events.jsfl",
				"DragonBonesDesignPanel/dragonBones.jsfl",
				"DragonBonesDesignPanel/createAnimation.jsfl",
				"DragonBonesDesignPanel/import3DTextures.jsfl"
			];
		
		private static const PORT_JSFL:String = "portJSFL";
		
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
				var str:String = "var xml = <a><![CDATA[" + arg.join(",") + "]]></a>;";
				str += "fl.trace(xml.text());";
				MMExecute(str);
			}
			else
			{
				trace.apply(null, arg);
			}
		}
		
		[Inject]
		public var server:LocalConnectionServerService;
		
		[Inject]
		public var client:LocalConnectionClientService;
		
		private var _requestGroup:RequestGroup;
		private var _timer:Timer;
		
		private var _prevPort:String;
		
		private var _callbackMap:Object;
		
		public function JSFLService()
		{
			init();
		}
		
		private function init():void
		{
			_requestGroup = new RequestGroup();
			_requestGroup.loadingMaxCount = 1;
			_timer = new Timer(2000);
			
			_callbackMap = {};
		}
		
		public function on():void
		{
			if(server)
			{
				server.addPort(PORT_JSFL);
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
			
			for (var type:String in _callbackMap)
			{
				this.removeEventListener(type, _callbackMap[type]);
			}
			_callbackMap = {};
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
		
		public function runJSFLCode(type:String, code:String, callback:Function = null, ...args):void
		{
			if(client)
			{
				_prevPort = PORT_JSFL;
				
				if (callback != null)
				{
					while (!type || _callbackMap[type])
					{
						type = "_type_" + Math.random();
					}
					_callbackMap[type] = {callback:callback, args:args || []};
				}
				client.send(PORT_JSFL, type, code);
			}
		}
		
		public function runJSFLMethod(type:String, method:String, ...args):void
		{
			var code:String = method + "(";
			var callback:Function = null;
			var callbackArgs:Array = [];
			
			for (var i:int = 0, l:int = args.length; i < l; ++i)
			{
				var arg:* = args[i];
				
				if(arg is Function)
				{
					callback = arg;
					if (i < l - 1)
					{
						callbackArgs = args.slice(i + 1);
					}
					break;
				}
				
				if (i != 0)
				{
					code += ",";
				}
				
				if(arg is Number || arg is Boolean || arg is RegExp)
				{
					code += arg;
				}
				else if(arg is XML)
				{
					XML.prettyIndent = -1;
					code += (arg as XML).toXMLString();
					XML.prettyIndent = 1;
				}
				else
				{
					code += '"' + arg + '"';
				}
			}
			
			code += ');';
			
			callbackArgs.unshift(type, code, callback);
			runJSFLCode.apply(this, callbackArgs);
		}
		
		private function jsflLoadHandler(e:Event):void
		{
			switch(e.type)
			{
				case Event.COMPLETE:
					MMExecute(e.target.data);
					break;
				
				default:
					//light.managers.ErrorManager.getInstance().dispatchErrorEvent(this, LOAD_JSFL_FILE_ERROR, "JSFL文件读取失败！");
					break;
			}
		}
		
		private function timerHandler(e:Event):void
		{
			if (client)
			{
				
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
							var serveiceEvent:ServiceEvent = new ServiceEvent(vo.type, vo.data);
							this.dispatchEvent(serveiceEvent);
							
							var callbackData:Object = _callbackMap[vo.type];
							if (callbackData != null)
							{
								callbackData.args.unshift(serveiceEvent);
								callbackData.callback.apply(null, callbackData.args);
								delete _callbackMap[vo.type];
							}
						}
					}
					break;
			}
		}
		
		private function clientErrorHandler(e:Event):void
		{
			light.managers.ErrorManager.getInstance().dispatchErrorEvent(this, JSFL_CONNECTION_ERROR, e.toString());
			
			client.connectToServer();
		}
	}
}