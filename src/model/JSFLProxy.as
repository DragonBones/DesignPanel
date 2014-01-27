package model
{
	import flash.errors.IllegalOperationError;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.StatusEvent;
	import flash.net.LocalConnection;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;
	
	import adobe.utils.MMExecute;
	
	import message.MessageDispatcher;
	
	/**
	 * Delegate of communicate between UI panel and JSFL
	 */
	public class JSFLProxy
	{
		public static const GET_ARMATURE_LIST:String = "getArmatureList";
		public static const GENERATE_ARMATURE:String = "generateArmature";
		public static const CLEAR_TEXTURE_SWFITEM:String = "clearTextureSWFItem";
		public static const ADD_TEXTURE_TO_SWFITEM:String = "addTextureToSWFItem";
		public static const EXPORT_SWF:String = "exportSWF";
		public static const COPY_ANIMATION:String = "copyArmatureFrom";
		
		private static const LOCAL_CONNECTION_NAME:String = "_DragonBonesDesignPanelLocalConnection";
		private static const CONNECTION_METHOD_NAME:String = "connectionMethodName";
		private static const STATUS:String = "status";
		
		private static const JSFL_URL:String = "DragonBonesDesignPanel/skeleton.jsfl";
		
		private static const MAX_SIZE:uint = 1024 * 35;
		
		private static var _sendByteArray:ByteArray = new ByteArray();
		private static var _receiveByteArray:ByteArray = new ByteArray();
		
		private static var _instance:JSFLProxy;
		public static function getInstance():JSFLProxy
		{
			if(!_instance)
			{
				_instance = new JSFLProxy();
			}
			return _instance;
		}
		
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
				var str:String = "";
				var length:uint = arg.length;
				for(var i:int = 0;i < length;i ++)
				{
					if(i != 0)
					{
						str += ", ";
					}
					str += arg[i];
				}
				MMExecute("fl.trace(\"" +str+ "\");");
			}
			else
			{
				trace.apply(JSFLProxy, arg);
			}
		}
		
		private static function xmlToString(xml:XML):String
		{
			return <a a={xml.toXMLString()}/>.@a[0].toXMLString();
		}
		
		private static function formatSendData(data:String):Array
		{
			var isBytes:Boolean = false;
			_sendByteArray.position = 0;
			_sendByteArray.length = 0;
			_sendByteArray.writeObject(data);
			if(_sendByteArray.length > MAX_SIZE)
			{
				isBytes = true;
				_sendByteArray.compress();
			}
			
			var list:Array = [];
			var length:uint = _sendByteArray.length;
			if(length > MAX_SIZE)
			{
				for(var i:uint = 0;i < length;i += MAX_SIZE)
				{
					var byteArray:ByteArray = new ByteArray();
					byteArray.writeBytes(_sendByteArray, i, (i + MAX_SIZE < length)?MAX_SIZE:(length - i));
					list.push(byteArray);
				}
			}
			else
			{
				list.push(isBytes?_sendByteArray:data);
			}
			return list;
		}
		
		private static function formatReceiveData(data:Object, index:int):String
		{
			var dataString:String;
			if(data is String)
			{
				dataString = data as String;
			}
			else
			{
				_receiveByteArray.position = _receiveByteArray.length;
				_receiveByteArray.writeBytes(data as ByteArray);
				if(index < 0)
				{
					_receiveByteArray.uncompress();
					dataString = _receiveByteArray.readObject() as String;
					_receiveByteArray.length = 0;
				}
			}
			return dataString;
		}
		
		private var _clientID:uint;
		private var _localConnectionName:String;
		private var _urlLoader:URLLoader;
		private var _localConnectionSender:LocalConnection;
		private var _localConnectionReceiver:LocalConnection;
		
		public function JSFLProxy()
		{
			if (_instance) 
			{
				throw new IllegalOperationError("Singleton already constructed!");
			}
			init();
		}
		
		private function init():void
		{
			_localConnectionName = LOCAL_CONNECTION_NAME;
			
			if(isAvailable)
			{
				_localConnectionReceiver = new LocalConnection();
				_localConnectionReceiver.allowDomain("*");
				_localConnectionReceiver.client = {};
				_localConnectionReceiver.client[CONNECTION_METHOD_NAME] = receiverConnectMethod;
				_localConnectionReceiver.addEventListener(StatusEvent.STATUS, receiverConnectStatusHandler);
				
				try 
				{
					_localConnectionReceiver.connect(_localConnectionName);
					jsflTrace("localConnectionReceiver connect success!");
				} 
				catch (e:Error)
				{
					while(true)
					{
						var localConnectionName:String = _localConnectionName + int(Math.random() * 0xFFFFFFFF) + 1;
						try 
						{
							_localConnectionReceiver.connect(localConnectionName);
							_localConnectionName = localConnectionName;
							jsflTrace("localConnectionReceiver connect success!(undebug)");
							break;
						}
						catch (e:Error)
						{
						}
					}
				}
				
				loadJSFLFile();
			}
			
			
			_localConnectionSender = new LocalConnection();
			_localConnectionSender.allowDomain("*");
			_localConnectionSender.client = {};
			_localConnectionSender.client[CONNECTION_METHOD_NAME] = senderConnectMethod;
			_localConnectionSender.addEventListener(StatusEvent.STATUS, senderConnectStatusHandler);
			
			while(true)
			{
				_clientID = Math.random() * 0xFFFFFFFF;
				try 
				{
					_localConnectionSender.connect(_localConnectionName + _clientID);
					trace("localConnectionSender connect success!");
					break;
				}
				catch (e:Error)
				{
				}
			}

		}
		
		private function jsflLoadHandler(e:Event):void
		{
			_urlLoader.removeEventListener(Event.COMPLETE, jsflLoadHandler);
			_urlLoader.removeEventListener(IOErrorEvent.IO_ERROR, jsflLoadHandler);
			switch(e.type)
			{
				case IOErrorEvent.IO_ERROR:
					throw new Error("JSFL load error!");
					break;
				case Event.COMPLETE:
					if(isAvailable)
					{
						MMExecute(e.target.data);
					}
					break;
			}
		}
		
		public function loadJSFLFile():void
		{
			if(_urlLoader)
			{
				_urlLoader.removeEventListener(Event.COMPLETE, jsflLoadHandler);
				_urlLoader.removeEventListener(IOErrorEvent.IO_ERROR, jsflLoadHandler);
				try 
				{
					_urlLoader.close();
				}
				catch (e:Error)
				{
				}
			}
			_urlLoader = new URLLoader();
			_urlLoader.addEventListener(Event.COMPLETE, jsflLoadHandler);
			_urlLoader.addEventListener(IOErrorEvent.IO_ERROR, jsflLoadHandler);
			_urlLoader.load(new URLRequest (JSFL_URL));
		}
		
		public function runJSFLCode(type:String, code:String):void
		{
			var list:Array = formatSendData(code);
			var length:uint = list.length;
			for(var i:int = 0;i < length;i ++)
			{
				_localConnectionSender.send(
					_localConnectionName, 
					CONNECTION_METHOD_NAME, 
					_clientID, 
					type, 
					list[i],
					(i < length - 1)?i:-1
				);
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
					code += "'" + xmlString + "',";
				}
				else
				{
					code += "'" + arg + "',";
				}
			}
			
			if(args.length > 0)
			{
				code = code.substr(0, code.length -1);
			}
			
			code += ");";
			
			runJSFLCode(type, code);
		}
		
		private function receiverConnectMethod(clientID:uint, type:String, code:Object, index:int):void 
		{
			var dataString:String = formatReceiveData(code, index);
			if(!dataString)
			{
				return;
			}
			
			try 
			{
				var result:String = MMExecute(dataString);
				var list:Array = formatSendData(result);
				var length:uint = list.length;
				for(var i:int = 0;i < length;i ++)
				{
					_localConnectionReceiver.send(
						_localConnectionName + clientID, 
						CONNECTION_METHOD_NAME, 
						clientID, 
						type,
						list[i],
						(i < length - 1)?i:-1
					);
				}
			}
			catch(_e:Error)
			{
				throw new Error("localConnectionReceiver connect error!");
			}
		}
		
		private function senderConnectMethod(clientID:uint, type:String, result:Object, index:int):void 
		{
			var dataString:String = formatReceiveData(result, index);
			if(!dataString)
			{
				return;
			}
			
			if(type)
			{
				MessageDispatcher.dispatchEvent(type, dataString);
			}
		}
		
		private function senderConnectStatusHandler(e:StatusEvent):void 
		{
			if (e.level == STATUS) 
			{
			}
		}
		
		private function receiverConnectStatusHandler(e:StatusEvent):void 
		{
			if (e.level == STATUS) 
			{
			}
		}
		
		/**
		 * Get armatures from current fla file's library
		 */
		public function getArmatureList(isSelected:Boolean, armatureNames:Vector.<String> = null):void
		{
			if(!armatureNames)
			{
				armatureNames = new Vector.<String>;
			}
			runJSFLMethod(GET_ARMATURE_LIST, "dragonBones.getArmatureList", isSelected, armatureNames);
		}
		
		/**
		 * Get armature data by name
		 */
		public function generateArmature(armatureName:String, mergeLayersInFolder:Boolean):void
		{
			runJSFLMethod(GENERATE_ARMATURE, "dragonBones.generateArmature", armatureName, false, true, mergeLayersInFolder);
		}
		
		/**
		 * Clear texture container for texture placement 
		 */
		public function clearTextureSWFItem():void
		{
			runJSFLMethod(CLEAR_TEXTURE_SWFITEM, "dragonBones.clearTextureSWFItem");
		}
		
		/**
		 * Place texture to swfitem by name
		 */
		public function addTextureToSWFItem(textureName:String, isLast:Boolean = false):void
		{
			runJSFLMethod(ADD_TEXTURE_TO_SWFITEM, "dragonBones.addTextureToSWFItem", textureName, isLast);
		}
		
		/**
		 * Export textures to swf
		 */
		public function exportSWF():void
		{
			runJSFLMethod(EXPORT_SWF, "dragonBones.exportSWF");
		}
		
		/**
		 * Update armature structure data from XML to fla file
		 */
		public function changeArmatureConnection(armatureName:String, armatureXML:XML):void
		{
			runJSFLMethod(null, "dragonBones.changeArmatureConnection", armatureName, armatureXML);
		}
		
		/**
		 * Update animation data from XML data to fla file
		 */
		public function changeAnimation(armatureName:String, animationName:String, animationXML:XML):void
		{
			runJSFLMethod(null, "dragonBones.changeAnimation", armatureName, animationName, animationXML);
		}
		
		/**
		 * Update animation data from XML data to fla file
		 */
		public function copyAnimation(targetArmatureName:String, sourceArmatureName:String, sourceAnimationName:String, sourceAnimationXML:XML):void
		{
			runJSFLMethod(COPY_ANIMATION, "dragonBones.copyAnimation", targetArmatureName, sourceArmatureName, sourceAnimationName, sourceAnimationXML);
		}
	}
}