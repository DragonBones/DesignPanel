package model
{
	import dragonBones.Armature;
	import dragonBones.Bone;
	import dragonBones.animation.WorldClock;
	import dragonBones.events.AnimationEvent;
	import dragonBones.factorys.BaseFactory;
	import dragonBones.objects.BoneData;
	import dragonBones.objects.SkeletonData;
	import dragonBones.objects.XMLDataParser;
	import dragonBones.textures.NativeTextureAtlas;
	import dragonBones.utils.ConstValues;
	import dragonBones.utils.dragonBones_internal;
	
	import flash.errors.IllegalOperationError;
	import flash.utils.ByteArray;
	
	import message.MessageDispatcher;
	
	import mx.collections.XMLListCollection;
	
	import utils.GlobalConstValues;
	import utils.TextureUtil;
	import utils.movePivotToSkeleton;
	
	use namespace dragonBones_internal;
	
	[Bindable]
	/**
	 * Manage imported data
	 */
	public class ImportDataProxy
	{
		private static var _instance:ImportDataProxy
		public static function getInstance():ImportDataProxy
		{
			if(!_instance)
			{
				_instance = new ImportDataProxy();
			}
			return _instance;
		}
		
		public static function getElementByName(xmlList:XMLList, name:String = null, returnFirst:Boolean = false):XML
		{
			if(xmlList)
			{
				if(name)
				{
					return XMLDataParser.getElementsByAttribute(xmlList, ConstValues.A_NAME, name)[0];
				}
				if(returnFirst)
				{
					return xmlList[0];
				}
			}
			return null;
		}
		
		public var armaturesMC:XMLListCollection;
		
		public var isTextureChanged:Boolean;
		public var isExportedSource:Boolean;
		
		private var _armaturesXMLList:XMLList;
		private var _animationsXMLList:XMLList;
		private var _baseFactory:BaseFactory;
		
		public function get skeletonName():String
		{
			return _skeletonXML?_skeletonXML.attribute(ConstValues.A_NAME):"";
		}
		
		public function get frameRate():int
		{
			return int(_skeletonXML.attribute(ConstValues.A_FRAME_RATE));
		}
		
		private var _skeletonXML:XML;
		public function get skeletonXML():XML
		{
			return _skeletonXML;
		}
		
		private var _textureAtlasXML:XML;
		public function get textureAtlasXML():XML
		{
			return _textureAtlasXML;
		}
		
		private var _armatureDataProxy:ArmatureDataProxy;
		public function get armatureDataProxy():ArmatureDataProxy
		{
			return _armatureDataProxy;
		}
		
		private var _animationDataProxy:AnimationDataProxy;
		public function get animationDataProxy():AnimationDataProxy
		{
			return _animationDataProxy;
		}
		
		private var _skeletonData:SkeletonData;
		public function get skeletonData():SkeletonData
		{
			return _skeletonData;
		}
		private function set skeletonData(value:SkeletonData)
		{
			_skeletonData = value;
		}
		
		private var _textureAtlas:NativeTextureAtlas;
		public function get textureAtlas():NativeTextureAtlas
		{
			return _textureAtlas;
		}
		
		public var textureBytes:ByteArray;
		
		private var _armature:Armature;
		public function get armature():Armature
		{
			return _armature;
		}
		
		public function ImportDataProxy()
		{
			if (_instance) 
			{
				throw new IllegalOperationError("Singleton already constructed!");
			}
			armaturesMC = new XMLListCollection();
			
			_armatureDataProxy = new ArmatureDataProxy();
			_animationDataProxy = new AnimationDataProxy();
			_baseFactory = new BaseFactory();
		}
		
		public function setData(skeletonXML:XML, textureAtlasXML:XML, textureData:Object, textureBytes:ByteArray, isExportedSource:Boolean):void
		{
			disposeArmature();
			
			if(_skeletonData)
			{
				_baseFactory.removeSkeletonData(_skeletonData.name);
				_skeletonData.dispose();
			}
			
			if(_textureAtlas)
			{
				_baseFactory.removeTextureAtlas(_textureAtlas.name);
				_textureAtlas.dispose();
			}
			
			isTextureChanged = false;
			
			_skeletonXML = skeletonXML;
			_textureAtlasXML = textureAtlasXML;
			this.textureBytes = textureBytes;
			this.isExportedSource = isExportedSource;
			
			movePivotToSkeleton(_skeletonXML, _textureAtlasXML);
			
			_armaturesXMLList = _skeletonXML.elements(ConstValues.ARMATURES).elements(ConstValues.ARMATURE);
			_animationsXMLList = _skeletonXML.elements(ConstValues.ANIMATIONS).elements(ConstValues.ANIMATION);
			
			armaturesMC.source = _armaturesXMLList;
			
			skeletonData = XMLDataParser.parseSkeletonData(skeletonXML);
			_textureAtlas = new NativeTextureAtlas(textureData, textureAtlasXML)
			_textureAtlas.movieClipToBitmapData();
			_baseFactory.addSkeletonData(_skeletonData);
			_baseFactory.addTextureAtlas(_textureAtlas);
			
			MessageDispatcher.dispatchEvent(MessageDispatcher.CHANGE_IMPORT_DATA, skeletonName);
			
			armatureDataProxy.setData(getArmatureXMLByName());
		}
		
		public function changeRenderArmature(armatureName:String):void
		{
			disposeArmature();
			
			_armature = _baseFactory.buildArmature(armatureName);
			_armature.addEventListener(dragonBones.events.AnimationEvent.MOVEMENT_CHANGE, armatureEventHandler);
			_armature.addEventListener(dragonBones.events.AnimationEvent.START, armatureEventHandler);
			_armature.addEventListener(dragonBones.events.AnimationEvent.COMPLETE, armatureEventHandler);
			WorldClock.clock.add(_armature);
		}
		
		public function render():void
		{
			WorldClock.update();
		}
		
		public function updateTextures():void
		{
			if(isExportedSource || !skeletonName)
			{
				return;
			}
			TextureUtil.packTextures(SettingDataProxy.getInstance().textureMaxWidth, SettingDataProxy.getInstance().texturePadding, textureAtlasXML);
			JSFLProxy.getInstance().packTextures(textureAtlasXML);
			isTextureChanged = true;
		}
		
		public function getArmatureXMLByName(name:String = null):XML
		{
			return getElementByName(_armaturesXMLList, name, true);
		}
		
		public function getAnimationXMLByName(name:String = null):XML
		{
			return getElementByName(_animationsXMLList, name, true);
		}
		
		public function updateArmatureBoneOrigin(boneName:String):void
		{
			var armatureName:String = armatureDataProxy.armatureName;
			updateOrigin(_armature, armatureName, boneName);
		}
		
		private function armatureEventHandler(e:AnimationEvent):void
		{
			switch(e.type)
			{
				case dragonBones.events.AnimationEvent.MOVEMENT_CHANGE:
					MessageDispatcher.dispatchEvent(MessageDispatcher.MOVEMENT_CHANGE, e.movementID);
					break;
				case dragonBones.events.AnimationEvent.START:
					MessageDispatcher.dispatchEvent(MessageDispatcher.MOVEMENT_START, e.movementID);
					break;
				case dragonBones.events.AnimationEvent.COMPLETE:
					MessageDispatcher.dispatchEvent(MessageDispatcher.MOVEMENT_COMPLETE, e.movementID);
					break;
			}
		}
		
		private function updateOrigin(armature:Armature, armatureName:String, boneName:String):void
		{
			if(armature)
			{
				if(armature.name == armatureName)
				{
					var boneData:BoneData = _skeletonData.getArmatureData(armatureName).getBoneData(boneName);
					var bone:Bone = armature.getBone(boneName);
					bone._origin.copy(boneData);
					armature.addBone(bone, boneData.parent);
				}
				for each(bone in armature._boneDepthList)
				{
					updateOrigin(bone.childArmature, armatureName, boneName);
				}
			}
		}
		
		private function disposeArmature():void
		{
			if(_armature)
			{
				WorldClock.clock.remove(_armature);
				_armature.removeEventListener(dragonBones.events.AnimationEvent.MOVEMENT_CHANGE, armatureEventHandler);
				_armature.removeEventListener(dragonBones.events.AnimationEvent.START, armatureEventHandler);
				_armature.removeEventListener(dragonBones.events.AnimationEvent.COMPLETE, armatureEventHandler);
				_armature.dispose();
			}
			_armature = null;
		}
	}
}