package model{
	import dragonBones.Armature;
	import dragonBones.Bone;
	import dragonBones.events.Event;
	import dragonBones.factorys.BaseFactory;
	import dragonBones.objects.BoneData;
	import dragonBones.objects.SkeletonData;
	import dragonBones.objects.TextureData;
	import dragonBones.objects.XMLDataParser;
	import dragonBones.utils.ConstValues;
	import dragonBones.utils.dragonBones_internal;
	
	import flash.errors.IllegalOperationError;
	import flash.utils.ByteArray;
	
	import message.MessageDispatcher;
	
	import mx.collections.ArrayCollection;
	import mx.collections.XMLListCollection;
	
	import utils.GlobalConstValues;
	import utils.TextureUtil;
	
	use namespace dragonBones_internal;
	
	[Bindable]
	/**
	 * 管理导入的数据
	 */
	public class ImportDataProxy{
		private static var instance:ImportDataProxy
		public static function getInstance():ImportDataProxy{
			if(!instance){
				instance = new ImportDataProxy();
			}
			return instance;
		}
		
		public static function getElementByName(_xmlList:XMLList, _name:String = null, _returnFirst:Boolean = false):XML{
			if(_xmlList){
				if(_name){
					return _xmlList.(attribute(ConstValues.A_NAME) == _name)[0];
				}
				if(_returnFirst){
					return _xmlList[0];
				}
			}
			return null;
		}
		
		public static function getElementName(_xml:XML, _key:String = null):String{
			return _xml?String(_xml.attribute(ConstValues.A_NAME)):"";
		}
		
		public var armaturesMC:XMLListCollection;
		
		public var isExportedSource:Boolean;
		public var isTextureChanged:Boolean;
		
		private var rawSkeletonXML:XML;
		
		private var armaturesXMLList:XMLList;
		private var animationsXMLList:XMLList;
		private var armatures:Object;
		private var baseFactory:BaseFactory;
		
		private var __dataImportID:int = 0;
		public function get dataImportID():int{
			return __dataImportID;
		}
		public function set dataImportID(value:int):void{
			__dataImportID = value;
			ShareObjectDataProxy.getInstance().setData("dataImportID", __dataImportID);
		}
		
		public var textureMaxWidthID:int = 0;
		public var textureMaxWidthAC:ArrayCollection = new ArrayCollection(["Auto size", 128, 256, 512, 1024, 2048, 4096]);
		public function get textureMaxWidth():int{
			if(textureMaxWidthID == 0){
				return 0;
			}
			return int(textureMaxWidthAC.getItemAt(textureMaxWidthID));
		}
		
		public var texturePadding:int = 2;
		
		public var textureSortID:int = 0;
		public var textureSortAC:ArrayCollection = new ArrayCollection(["MaxRects"]);
		
		public function get skeletonName():String{
			return getElementName(__skeletonXML);
		}
		
		public function get frameRate():int{
			return int(__skeletonXML.attribute(ConstValues.A_FRAME_RATE));
		}
		
		private var __skeletonXML:XML;
		public function get skeletonXML():XML{
			return __skeletonXML;
		}
		
		private var __textureAtlasXML:XML;
		public function get textureAtlasXML():XML{
			return __textureAtlasXML;
		}
		
		private var __armatureDataProxy:ArmatureDataProxy;
		public function get armatureDataProxy():ArmatureDataProxy{
			return __armatureDataProxy;
		}
		
		private var __animationDataProxy:AnimationDataProxy;
		public function get animationDataProxy():AnimationDataProxy{
			return __animationDataProxy;
		}
		
		private var __skeletonData:SkeletonData;
		public function get skeletonData():SkeletonData{
			return __skeletonData;
		}
		
		private var __textureData:TextureData;
		public function get textureData():TextureData{
			return __textureData;
		}
		
		private var __armature:Armature;
		public function get armature():Armature{
			return __armature;
		}
		
		public function ImportDataProxy(){
			if (instance) {
				throw new IllegalOperationError("Singleton already constructed!");
			}
			armaturesMC = new XMLListCollection();
			
			__armatureDataProxy = new ArmatureDataProxy();
			__animationDataProxy = new AnimationDataProxy();
			baseFactory = new BaseFactory();
			
			__dataImportID = ShareObjectDataProxy.getInstance().getOrSetData("dataImportID", 0);
		}
		
		public function setData(_skeletonXML:XML, _textureAtlasXML:XML, _textureData:ByteArray, _isSWFSource:Boolean):void{
			for each(__armature in armatures){
				__armature.dispose();
			}
			__armature = null;
			armatures = {};
			
			isTextureChanged = false;
			isExportedSource = _isSWFSource;
			
			rawSkeletonXML = _skeletonXML;
			__skeletonXML = rawSkeletonXML.copy();
			__textureAtlasXML = _textureAtlasXML;
			
			armaturesXMLList = __skeletonXML.elements(ConstValues.ARMATURES).elements(ConstValues.ARMATURE);
			animationsXMLList = __skeletonXML.elements(ConstValues.ANIMATIONS).elements(ConstValues.ANIMATION);
			
			armaturesMC.source = armaturesXMLList;
			
			if(__skeletonData){
				__skeletonData.dispose();
			}
			
			if(__textureData){
				__textureData.dispose();
			}
			
			__textureData = new TextureData(__textureAtlasXML, _textureData, onUpdateHandler);
		}
		
		public function changeRenderArmature(_armatureName:String):void{
			__armature = armatures[_armatureName];
			if(!__armature){
				armatures[_armatureName] = __armature = baseFactory.buildArmature(_armatureName);
			}
			
			__armature.addEventListener(dragonBones.events.Event.MOVEMENT_CHANGE, aramtureEventHandler);
			__armature.addEventListener(dragonBones.events.Event.START, aramtureEventHandler);
			__armature.addEventListener(dragonBones.events.Event.COMPLETE, aramtureEventHandler);
		}
		
		public function render():void{
			if(__armature){
				__armature.update();
			}
		}
		
		public function updateTextures():void{
			if(isExportedSource || !skeletonName){
				return;
			}
			/*switch(textureSortID){
			case 0:
			break;
			}*/
			TextureUtil.packTextures(textureMaxWidth, texturePadding, textureAtlasXML);
			JSFLProxy.getInstance().packTextures(textureAtlasXML);
			isTextureChanged = true;
		}
		
		public function getArmatureXMLByName(_name:String = null):XML{
			return getElementByName(armaturesXMLList, _name, true);
		}
		
		public function getAnimationXMLByName(_name:String = null):XML{
			return getElementByName(animationsXMLList, _name, true);
		}
		
		public function updateArmatureBoneOrigin(_boneName:String):void{
			var _armatureName:String = armatureDataProxy.armatureName;
			for each(var _armature:Armature in armatures){
				updateOrigin(_armature, _armatureName, _boneName);
			}
		}
		
		private function onUpdateHandler():void{
			__skeletonData = XMLDataParser.parseSkeletonData(__skeletonXML);
			baseFactory.skeletonData = __skeletonData;
			baseFactory.textureData = __textureData;
			MessageDispatcher.dispatchEvent(MessageDispatcher.CHANGE_IMPORT_DATA, skeletonName);
			
			armatureDataProxy.setData(getArmatureXMLByName());
		}
		
		private function aramtureEventHandler(_e:dragonBones.events.Event):void{
			switch(_e.type){
				case dragonBones.events.Event.MOVEMENT_CHANGE:
					MessageDispatcher.dispatchEvent(MessageDispatcher.MOVEMENT_CHANGE, _e.data);
					break;
				case dragonBones.events.Event.START:
					MessageDispatcher.dispatchEvent(MessageDispatcher.MOVEMENT_START, _e.data);
					break;
				case dragonBones.events.Event.COMPLETE:
					MessageDispatcher.dispatchEvent(MessageDispatcher.MOVEMENT_COMPLETE, _e.data);
					break;
			}
		}
		
		private function updateOrigin(_armature:Armature, _armatureName:String, _boneName:String):void{
			if(_armature){
				if(_armature.name == _armatureName){
					var _boneData:BoneData = __skeletonData.getArmatureData(_armatureName).getBoneData(_boneName);
					var _bone:Bone = _armature.getBone(_boneName);
					_bone.origin.copy(_boneData);
					_armature.addBone(_bone, _boneData.parent);
				}
				for each(_bone in _armature._boneDepthList){
					updateOrigin(_bone.childArmature, _armatureName, _boneName);
				}
			}
		}
	}
}