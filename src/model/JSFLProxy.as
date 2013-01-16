package model
{
	import adobe.utils.MMExecute;
	
	import flash.errors.IllegalOperationError;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.StatusEvent;
	import flash.net.LocalConnection;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;
	
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
		public static const PACK_TEXTURES:String = "packTextures";
		public static const EXPORT_SWF:String = "exportSWF";
		public static const COPY_MOVEMENT:String = "copyArmatureFrom";
		
		private static const LOCAL_CONNECTION_NAME:String = "_SkeletonDesignPanelLocalConnection";
		private static const CONNECTION_METHOD_NAME:String = "connectionMethodName";
		private static const STATUS:String = "status";
		
		private static const JSFL_URL:String = "SkeletonAnimationDesignPanel/skeleton.jsfl";
		
		private static var _instance:JSFLProxy;
		public static function getInstance():JSFLProxy
		{
			if(!_instance)
			{
				_instance = new JSFLProxy();
			}
			return _instance;
		}
		
		private static function xmlToString(xml:XML):String
		{
			return <a a={xml.toXMLString()}/>.@a[0].toXMLString();
		}
		
		private static function jsflTrace(...arg):String
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
			return str;
		}
		
		private var _clientID:uint;
		private var _exClientID:uint;
		private var _urlLoader:URLLoader;
		private var _localConnectionSender:LocalConnection;
		private var _localConnectionReceiver:LocalConnection;
		private var _helpByteArray:ByteArray;
		
		/**
		 * Determine if JSFLAPI isAvailable
		 */
		public function get isAvailable():Boolean
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
			_clientID = Math.random() * 0xFFFFFFFF;
			
			_helpByteArray = new ByteArray();
			
			_localConnectionSender = new LocalConnection();
			_localConnectionSender.allowDomain("*");
			_localConnectionSender.client = {};
			_localConnectionSender.client[CONNECTION_METHOD_NAME] = senderConnectMethod;
			_localConnectionSender.addEventListener(StatusEvent.STATUS, senderConnectStatusHandler);
			
			try 
			{
				_localConnectionSender.connect(LOCAL_CONNECTION_NAME + _clientID);
				trace("localConnectionSender connect success!");
			}
			catch (e:Error)
			{
				throw new Error("localConnectionSender connect error!");
			}
			
			if(isAvailable)
			{
				_localConnectionReceiver = new LocalConnection();
				_localConnectionReceiver.allowDomain("*");
				_localConnectionReceiver.client = {};
				_localConnectionReceiver.client[CONNECTION_METHOD_NAME] = receiverConnectMethod;
				_localConnectionReceiver.addEventListener(StatusEvent.STATUS, receiverConnectStatusHandler);
				
				try 
				{
					_localConnectionReceiver.connect(LOCAL_CONNECTION_NAME);
					JSFLProxy.jsflTrace("localConnectionReceiver connect success!");
				} 
				catch (e:Error)
				{
					throw new Error("localConnectionReceiver connect error!");
				}
				
				_urlLoader = new URLLoader();
				_urlLoader.addEventListener(Event.COMPLETE, jsflLoadHandler);
				_urlLoader.addEventListener(IOErrorEvent.IO_ERROR, jsflLoadHandler);
				_urlLoader.load(new URLRequest (JSFL_URL));
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
		
		public function runJSFLCode(type:String, code:String):void
		{
			_helpByteArray.position = 0;
			_helpByteArray.length = 0;
			_helpByteArray.writeUTFBytes(code);
			if(_helpByteArray.length > 40 * 1024)
			{
				var isBytesResult:Boolean = true;
				_helpByteArray.compress();
			}
			//trace("clientID:" + clientID, "type:" + _type, "code:" + _code);
			
			_localConnectionSender.send(
				LOCAL_CONNECTION_NAME, 
				CONNECTION_METHOD_NAME, 
				_clientID, 
				type, 
				isBytesResult?_helpByteArray:code
			);
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
		
		private function receiverConnectMethod(clientID:uint, type:String, code:*):void 
		{
			if(code is ByteArray)
			{
				code.position = 0;
				code.uncompress();
			}
			if(clientID != _clientID)
			{
				//JSFLProxy.jsflTrace("clientID:" + clientID, "type:" + type, "code:" + code);
			}
			try 
			{
				_exClientID = clientID;
				var result:String = MMExecute(code);
				_helpByteArray.position = 0;
				_helpByteArray.length = 0;
				_helpByteArray.writeUTFBytes(result);
				if(_helpByteArray.length > 40 * 1024)
				{
					var isBytesResult:Boolean = true;
					_helpByteArray.compress();
				}
				
				_localConnectionReceiver.send(
					LOCAL_CONNECTION_NAME + clientID, 
					CONNECTION_METHOD_NAME, 
					clientID, 
					type,
					isBytesResult?_helpByteArray:result
				);
			}
			catch(_e:Error)
			{
				throw new Error("localConnectionReceiver connect error!");
			}
		}
		
		private function senderConnectMethod(clientID:uint, type:String, result:*):void 
		{
			if(result is ByteArray)
			{
				result.position = 0;
				result.uncompress();
			}
			//trace("clientID:" + clientID, "type:" + type, "result:" + result);
			if(type)
			{
				MessageDispatcher.dispatchEvent(type, result);
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
		public function getArmatureList(isSelected:Boolean):void
		{
			runJSFLMethod(GET_ARMATURE_LIST, "dragonBones.getArmatureList", isSelected);
		}
		
		/**
		 * Get armature data by name
		 */
		public function generateArmature(armatureName:String, scale:Number):void
		{
			runJSFLMethod(GENERATE_ARMATURE, "dragonBones.generateArmature", armatureName, scale, true);
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
		 * Place texture by textureAtlasXML data
		 */
		public function packTextures(textureAtlasXML:XML):void
		{
			runJSFLMethod(PACK_TEXTURES, "dragonBones.packTextures", textureAtlasXML);
		}
		
		/**
		 * Export textures to swf
		 */
		public function exportSWF():void
		{
			runJSFLMethod(EXPORT_SWF, "dragonBones.exportSWF");
		}
		
		/**
		 * Update skeleton structure data from XML to fla file
		 */
		public function changeArmatureConnection(armatureName:String, armatureXML:XML):void
		{
			runJSFLMethod(null, "dragonBones.changeArmatureConnection", armatureName, armatureXML);
		}
		
		/**
		 * Update movement data from XML data to fla file
		 */
		public function changeMovement(armatureName:String, movementName:String, movementXML:XML):void
		{
			runJSFLMethod(null, "dragonBones.changeMovement", armatureName, movementName, movementXML);
		}
		
		/**
		 * Update movement data from XML data to fla file
		 */
		public function copyMovement(targetArmatureName:String, sourceArmatureName:String, sourceMovementName:String, sourceMovementXML:XML):void
		{
			runJSFLMethod(COPY_MOVEMENT, "dragonBones.copyMovement", targetArmatureName, sourceArmatureName, sourceMovementName, sourceMovementXML);
		}
	}
}