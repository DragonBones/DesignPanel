package model{
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
	 * 面板与JSFL通信代理
	 */
	public class JSFLProxy{
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
		public static function getInstance():JSFLProxy{
			if(!instance){
				instance = new JSFLProxy();
			}
			return instance;
		}
		
		private static function xmlToString(_xml:XML):String{
			return <a a={_xml.toXMLString()}/>.@a[0].toXMLString();
		}
		
		private static function jsflTrace(...arg):String{
			var _str:String = "";
			for(var _i:uint = 0;_i < arg.length;_i ++){
				if(_i!=0){
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
		 * JSFLAPI 是否可用
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
		 * 获取 Flash pro 当前活动的 fla 档案中符合骨骼结构的库元件（选中的或是全部的）的列表
		 */
		public function getArmatureList(_isSelected:Boolean):void{
			runJSFLMethod(GET_ARMATURE_LIST, "Skeleton.getArmatureList", _isSelected);
		}
		
		/**
		 * 解析 fla 库中指定元件的骨骼数据
		 */
		public function generateArmature(_armatureName:String):void{
			runJSFLMethod(GENERATE_ARMATURE, "Skeleton.generateArmature", _armatureName, true);
		}
		
		/**
		 * 初始化 fla 库中用于放置贴图的库元件
		 */
		public function clearTextureSWFItem():void{
			runJSFLMethod(CLEAR_TEXTURE_SWFITEM, "Skeleton.clearTextureSWFItem");
		}
		
		/**
		 * 添加 fla 库中指定的贴图元件到场景
		 */
		public function addTextureToSWFItem(_textureName:String, _isLast:Boolean = false):void{
			runJSFLMethod(ADD_TEXTURE_TO_SWFITEM, "Skeleton.addTextureToSWFItem", _textureName, _isLast);
		}
		
		/**
		 * 根据 textureAtlasXML 为 fla 场景上放置的贴图排序
		 */
		public function packTextures(_textureAtlasXML:XML):void{
			runJSFLMethod(PACK_TEXTURES, "Skeleton.packTextures", _textureAtlasXML);
		}
		
		/**
		 * 导出 fla 所有用到的贴图元件为 SWF
		 */
		public function exportSWF():void{
			runJSFLMethod(EXPORT_SWF, "Skeleton.exportSWF");
		}
		
		/**
		 * 将骨骼从属关系的变更同步到 fla 档案中
		 */
		public function changeArmatureConnection(_armatureName:String, _armatureXML:XML):void{
			runJSFLMethod(null, "Skeleton.changeArmatureConnection", _armatureName, _armatureXML);
		}
		
		/**
		 * 将动作、骨骼动画的数据变更同步到 fla 档案中
		 */
		public function changeMovement(_armatureName:String, _movementName:String, _movementXML:XML):void{
			runJSFLMethod(null, "Skeleton.changeMovement", _armatureName, _movementName, _movementXML);
		}
	}
}