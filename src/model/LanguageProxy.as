package model{
	import flash.errors.IllegalOperationError;
	
	import message.Message;
	import message.MessageDispatcher;
	
	import mx.collections.ArrayCollection;
	
	[Bindable]
	/**
	 * 管理面板Language
	 */
	public class LanguageProxy{
		[Embed(source="./resources/languages.xml", mimeType="application/octet-stream")]
		private static const XML_DATA:Class;
		
		public static const EXPORT_SWF_WITH_XML:String = "exportSWFwithXML";
		public static const EXPORT_PNG_WITH_XML:String = "exportPNGwithXML";
		public static const EXPORT_ZIP_XML_AND_SWF:String = "exportZIPXMLAndSWF";
		public static const EXPORT_ZIP_XML_AND_PNG:String = "exportZIPXMLAndPNG";
		public static const EXPORT_ZIP_XML_AND_EACH_PNG:String = "exportZIPXMLAndEachPNG";
		
		public static const IMPORT_LABEL:String = "importLabel";
		public static const TEXTURE_SORT:String = "textureSort";
		public static const TEXTURE_WIDTH:String = "textureWidth";
		public static const TEXTURE_PADDING:String = "texturePadding";
		
		public static const EXPORT_LABEL:String = "exportLabel";
		
		public static const OK:String = "ok";
		public static const CANCEL:String = "cancel";
		
		public static const IMPORT_FLA_WAITTING:String = "importFLAWaitting";
		public static const IMPORT_NO_ELEMENT:String = "importNoElement";
		public static const IMPORT_ARMATURE_PROGRESS:String = "importArmatureProgress";
		public static const IMPORT_TEXTURE_PROGRESS:String = "importTextureProgress";
		public static const IMPORT_FILE_WAITTING:String = "importFileWaitting";
		public static const IMPORT_FILE_ERROR:String = "importFileError";
		public static const IMPORT_FILE_PROGRESS:String = "importFileProgress";
		public static const EXPORT_WAITTING:String = "exportWaitting";
		public static const EXPORT_ERROR:String = "exportError";
		
		public static const IMPORT_FLA_ALL_ITEM:String = "importFLAAllItem";
		public static const IMPORT_FLA_SELECTED_ITEM:String = "importFLASelectedItem";
		public static const IMPORT_EXPORTED_DATA:String = "importExportedData";
		
		private static const JSFL_LANGUAGE_CODE:String = "languageCode";
		
		private static var instance:LanguageProxy;
		public static function getInstance():LanguageProxy{
			if(!instance){
				instance = new LanguageProxy();
			}
			return instance;
		}
		
		private var xml:XML;
			
		public var armatureListLabel:String;
		public var movementListLabel:String;
		public var boneTreeLabel:String;
		public var textureListLabel:String;
		
		public var viewScaleLabel:String;
		public var boneHighlightLabel:String;
		
		public var importTitle:String;
		public var exportTitle:String;
		public var frameRateLabel:String;
		
		public var movementPanelTitle:String;
		public var tweenFrameLabel:String;
		public var movementFrameLabel:String;
		public var keyFrameEaseLabel:String;
		public var movementLoopLabel:String;
		
		public var playLabel:String;
		public var stopLabel:String;
		
		public var boneMovementPanelTitle:String;
		public var boneTweenScaleLabel:String;
		public var boneTweenDelayLabel:String;
		
		private var __languageID:int = 0;
		public function get languageID():int{
			return __languageID;
		}
		public function set languageID(value:int):void{
			__languageID = value;
			ShareObjectDataProxy.getInstance().setData("languageID", __languageID);
			update();
			MessageDispatcher.dispatchEvent(MessageDispatcher.LANGUAGE_CHANGE);
		}
		public var languageAC:ArrayCollection = new ArrayCollection();
		
		public function LanguageProxy(){
			if (instance) {
				throw new IllegalOperationError("Singleton already constructed!");
			}
			xml = XML(new XML_DATA());
			
			for each(var _languageXML:XML in xml.language){
				languageAC.addItem(String(_languageXML.@name));
			}
			
			var _languangeID:* = ShareObjectDataProxy.getInstance().getData("languageID");
			if(_languangeID != null){
				__languageID = int(_languangeID);
			}else{
				MessageDispatcher.addEventListener(JSFL_LANGUAGE_CODE, jsflProxyHandler);
				JSFLProxy.getInstance().runJSFLCode(JSFL_LANGUAGE_CODE, "fl.languageCode;");
			}
			
			update();
		}
		
		private function jsflProxyHandler(_e:Message):void{
			switch(_e.type){
				case JSFL_LANGUAGE_CODE:
					MessageDispatcher.removeEventListener(JSFL_LANGUAGE_CODE, jsflProxyHandler);
					try{
						languageID = xml.language.(@id == _e.parameters[0])[0].childIndex();
					}catch(_e:Error){
						languageID = 0;
					}
					break;
			}
		}
		
		
		/**
		 * 从 languages.xml 中获取当前语言的指定 item
		 */
		public function getItem(_id:String, ...args):String{
			var _xml:XML = xml.item.(@id == _id)[0];
			if(_xml){
				var _id:String = xml.language[__languageID].@id;
				var _item:XML = _xml.item.(@id == _id)[0];
				if(!_item){
					_item = _xml.item[0];
				}
				return formatMessage(_item.text(), args);
			}
			return null;
		}
		
		private function formatMessage(_msg:String, _args:Array):String {
			var _i:uint = 0;
			while (_i < _args.length){
				_msg = _msg.replace(new RegExp("\\{" + _i + "\\}", "g"), String(_args[_i]));
				_i++;
			}
			return _msg;
		}
		
		private function update():void{
			armatureListLabel = getItem("armatureList");
			movementListLabel = getItem("movementList");
			boneTreeLabel = getItem("boneTree");
			textureListLabel = getItem("textureList");
			
			viewScaleLabel = getItem("viewScale");
			boneHighlightLabel = getItem("boneHighlight");
			
			importTitle = getItem("importTitle");
			exportTitle = getItem("exportTitle");
			frameRateLabel = getItem("frameRate");
			
			movementPanelTitle = getItem("movementPanelTitle");
			tweenFrameLabel = getItem("tweenFrame");
			movementFrameLabel = getItem("movementFrame");
			keyFrameEaseLabel = getItem("keyFrameEase");
			movementLoopLabel = getItem("movementLoop");
			
			playLabel = getItem("play");
			stopLabel = getItem("stop");
			
			boneMovementPanelTitle = getItem("boneMovementPanelTitle");
			boneTweenScaleLabel = getItem("boneTweenScale");
			boneTweenDelayLabel = getItem("boneTweenDelay");
		}
	}
}