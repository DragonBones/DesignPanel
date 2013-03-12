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
				var xml:XML = XMLDataParser.getElementsByAttribute(xmlList, ConstValues.A_NAME, name)[0];
				if(returnFirst && !xml)
				{
					xml = xmlList[0];
				}
			}
			return xml;
		}
		
		public var armaturesMC:XMLListCollection;
		
		public var isExportedSource:Boolean;
		
		private var _armaturesXMLList:XMLList;
		private var _animationsXMLList:XMLList;
		private var _baseFactory:BaseFactory;
		
		public function get skeletonName():String
		{
			return _skeletonData?_skeletonData.name:"";
		}
		
		private var _skeletonXMLProxy:SkeletonXMLProxy;
		public function get skeletonXMLProxy():SkeletonXMLProxy
		{
			return _skeletonXMLProxy;
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
		private function set skeletonData(value:SkeletonData):void
		{
			_skeletonData = value;
		}
		
		private var _textureAtlas:NativeTextureAtlas;
		public function get textureAtlas():NativeTextureAtlas
		{
			return _textureAtlas;
		}
		
		private var _textureBytes:ByteArray;
		public function get textureBytes():ByteArray
		{
			return _textureBytes;
		}
		
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
		
		public function setData(skeletonXMLProxy:SkeletonXMLProxy, textureBytes:ByteArray, textureData:Object, isExportedSource:Boolean):void
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
			
			_skeletonXMLProxy = skeletonXMLProxy;
			_textureBytes = textureBytes;
			this.isExportedSource = isExportedSource;
			
			_skeletonXMLProxy.movePivotToSkeleton();
			
			_armaturesXMLList = SkeletonXMLProxy.getArmatureXMLList(_skeletonXMLProxy.skeletonXML);
			_animationsXMLList = SkeletonXMLProxy.getAnimationXMLList(_skeletonXMLProxy.skeletonXML);
			
			armaturesMC.source = _armaturesXMLList;
			
			skeletonData = XMLDataParser.parseSkeletonData(_skeletonXMLProxy.skeletonXML);
			_textureAtlas = new NativeTextureAtlas(textureData, _skeletonXMLProxy.textureAtlasXML)
			_textureAtlas.movieClipToBitmapData();
			_baseFactory.addSkeletonData(_skeletonData);
			_baseFactory.addTextureAtlas(_textureAtlas);
			
			MessageDispatcher.dispatchEvent(MessageDispatcher.CHANGE_IMPORT_DATA, skeletonName);
			
			
			armatureDataProxy.setData(getArmatureXMLByName(armatureDataProxy.armatureName));
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
			WorldClock.clock.advanceTime(-1);
		}
		
		public function getArmatureXMLByName(name:String):XML
		{
			return getElementByName(_armaturesXMLList, name, true);
		}
		
		public function getAnimationXMLByName(name:String):XML
		{
			return getElementByName(_animationsXMLList, name);
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
					bone.origin.copy(boneData.node);
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