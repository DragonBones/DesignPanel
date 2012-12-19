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
		
		private static const LOCAL_CONNECTION_NAME:String = "_SkeletonDesignPanelLocalConnection";
		private static const CONNECTION_METHOD_NAME:String = "connectionMethodName";
		private static const STATUS:String = "status";
		
		private static const JSFL_URL:String = "SkeletonAnimationDesignPanel/skeleton.jsfl";
		
		private static var instance:JSFLProxy;
		public static function getInstance():JSFLProxy
		{
			if(!instance)
			{
				instance = new JSFLProxy();
			}
			return instance;
		}
		
		private static function xmlToString(_xml:XML):String
		{
			return <a a={_xml.toXMLString()}/>.@a[0].toXMLString();
		}
		
		private static function jsflTrace(...arg):String
		{
			var _str:String = "";
			for(var _i:int = 0;_i < arg.length;_i ++)
			{
				if(_i!=0)
				{
					_str += ", ";
				}
				_str += arg[_i];
			}
			MMExecute("fl.trace(\"" +_str+ "\");");
			return _str;
		}
		
		private var clientID:uint;
		private var urlLoader:URLLoader;
		private var localConnectionSender:LocalConnection;
		private var localConnectionReceiver:LocalConnection;
		
		private var helpByteArray:ByteArray;
		
		/**
		 * Determine if JSFLAPI isAvailable
		 */
		public function get isAvailable():Boolean{
			try{
				MMExecute("fl;");
				return true;
			}catch(_e:Error){}
			return false;
		}
		
		public function JSFLProxy(){
			if (instance) {
				throw new IllegalOperationError("Singleton already constructed!");
			}
			init();
		}
		
		private function init():void{
			clientID = Math.random() * 0xFFFFFFFF;
			
			helpByteArray = new ByteArray();
			
			localConnectionSender = new LocalConnection();
			localConnectionSender.allowDomain("*");
			localConnectionSender.client = {};
			localConnectionSender.client[CONNECTION_METHOD_NAME] = senderConnectMethod;
			localConnectionSender.addEventListener(StatusEvent.STATUS, senderConnectStatusHandler);
			
			try {
				localConnectionSender.connect(LOCAL_CONNECTION_NAME + clientID);
				trace("localConnectionSender connect success!");
			} catch (_e:*){
				throw new Error("localConnectionSender connect error!");
			}
			
			if(isAvailable){
				localConnectionReceiver = new LocalConnection();
				localConnectionReceiver.allowDomain("*");
				localConnectionReceiver.client = {};
				localConnectionReceiver.client[CONNECTION_METHOD_NAME] = receiverConnectMethod;
				localConnectionReceiver.addEventListener(StatusEvent.STATUS, receiverConnectStatusHandler);
				
				try {
					localConnectionReceiver.connect(LOCAL_CONNECTION_NAME);
					JSFLProxy.jsflTrace("localConnectionReceiver connect success!");
				} catch (_e:*){
					throw new Error("localConnectionReceiver connect error!");
				}
				
				urlLoader = new URLLoader();
				urlLoader.addEventListener(Event.COMPLETE, jsflLoadHandler);
				urlLoader.addEventListener(IOErrorEvent.IO_ERROR, jsflLoadHandler);
				urlLoader.load(new URLRequest (JSFL_URL));
			}
		}
		
		private function jsflLoadHandler(_e:Event):void{
			urlLoader.removeEventListener(Event.COMPLETE, jsflLoadHandler);
			urlLoader.removeEventListener(IOErrorEvent.IO_ERROR, jsflLoadHandler);
			switch(_e.type){
				case IOErrorEvent.IO_ERROR:
					throw new Error("JSFL load error!");
					break;
				case Event.COMPLETE:
					if(isAvailable){
						MMExecute(_e.target.data);
					}
					break;
			}
		}
		
		public function runJSFLCode(_type:String, _code:String):void{
			helpByteArray.position = 0;
			helpByteArray.length = 0;
			helpByteArray.writeUTFBytes(_code);
			if(helpByteArray.length > 40 * 1024){
				var _isBytesResult:Boolean = true;
				helpByteArray.compress();
			}
			//trace("clientID:" + clientID, "type:" + _type, "code:" + _code);
			
			localConnectionSender.send(
				LOCAL_CONNECTION_NAME, 
				CONNECTION_METHOD_NAME, 
				clientID, 
				_type, 
				_isBytesResult?helpByteArray:_code
			);
		}
		
		public function runJSFLMethod(_type:String, _method:String, ...args):void{
			var _code:String = _method + "(";
			for each(var _arg:Object in args){
				if(_arg is Number || _arg is Boolean){
					_code += _arg + ",";
				}else if(_arg is XML){
					XML.prettyIndent = -1;
					var _xmlString:String = xmlToString(_arg as XML);
					XML.prettyIndent = 1;
					_code += "'" + _xmlString + "',";
				}else{
					_code += "'" + _arg + "',";
				}
			}
			
			if(args.length > 0){
				_code = _code.substr(0, _code.length -1);
			}
			
			_code += ");";
			
			runJSFLCode(_type, _code);
		}
		
		private function receiverConnectMethod(_clientID:uint, _type:String, _code:*):void {
			if(_code is ByteArray){
				_code.position = 0;
				_code.uncompress();
			}
			
			if(_clientID != clientID){
				//JSFLProxy.jsflTrace("clientID:" + _clientID, "type:" + _type, "code:" + _code);
			}
			
			try {
				var _result:String = MMExecute(_code);
				helpByteArray.position = 0;
				helpByteArray.length = 0;
				helpByteArray.writeUTFBytes(_result);
				if(helpByteArray.length > 40 * 1024){
					var _isBytesResult:Boolean = true;
					helpByteArray.compress();
				}
				
				localConnectionReceiver.send(
					LOCAL_CONNECTION_NAME + _clientID, 
					CONNECTION_METHOD_NAME, 
					_clientID, 
					_type,
					_isBytesResult?helpByteArray:_result
				);
			}catch(_e:Error){
				throw new Error("localConnectionReceiver connect error!");
			}
		}
		
		private function senderConnectMethod(_clientID:uint, _type:String, _result:*):void {
			if(_result is ByteArray){
				_result.position = 0;
				_result.uncompress();
			}
			//trace("clientID:" + _clientID, "type:" + _type, "result:" + _result);
			if(_type){
				MessageDispatcher.dispatchEvent(_type, _result);
			}
		}
		
		private function senderConnectStatusHandler(_e:StatusEvent):void {
			if (_e.level == STATUS) {
			}
		}
		
		private function receiverConnectStatusHandler(_e:StatusEvent):void {
			if (_e.level == STATUS) {
			}
		}
		
		/**
		 * Get armatures from current fla file's library
		 */
		public function getArmatureList(_isSelected:Boolean):void{
			runJSFLMethod(GET_ARMATURE_LIST, "Skeleton.getArmatureList", _isSelected);
		}
		
		/**
		 * Get armature data by name
		 */
		public function generateArmature(_armatureName:String, _scale:Number):void{
			runJSFLMethod(GENERATE_ARMATURE, "Skeleton.generateArmature", _armatureName, _scale, true);
		}
		
		/**
		 * Clear texture container for texture placement 
		 */
		public function clearTextureSWFItem():void{
			runJSFLMethod(CLEAR_TEXTURE_SWFITEM, "Skeleton.clearTextureSWFItem");
		}
		
		/**
		 * Place texture to swfitem by name
		 */
		public function addTextureToSWFItem(_textureName:String, _isLast:Boolean = false):void{
			runJSFLMethod(ADD_TEXTURE_TO_SWFITEM, "Skeleton.addTextureToSWFItem", _textureName, _isLast);
		}
		
		/**
		 * Place texture by textureAtlasXML data
		 */
		public function packTextures(_textureAtlasXML:XML):void{
			runJSFLMethod(PACK_TEXTURES, "Skeleton.packTextures", _textureAtlasXML);
		}
		
		/**
		 * Export textures to swf
		 */
		public function exportSWF():void{
			runJSFLMethod(EXPORT_SWF, "Skeleton.exportSWF");
		}
		
		/**
		 * Update skeleton structure data from XML to fla file
		 */
		public function changeArmatureConnection(_armatureName:String, _armatureXML:XML):void{
			runJSFLMethod(null, "Skeleton.changeArmatureConnection", _armatureName, _armatureXML);
		}
		
		/**
		 * Update movement data from XML data to fla file
		 */
		public function changeMovement(_armatureName:String, _movementName:String, _movementXML:XML):void{
			runJSFLMethod(null, "Skeleton.changeMovement", _armatureName, _movementName, _movementXML);
		}
	}
}