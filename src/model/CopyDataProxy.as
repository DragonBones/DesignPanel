package model
{
	import dragonBones.Armature;
	import dragonBones.animation.WorldClock;
	import dragonBones.core.dragonBones_internal;
	import dragonBones.factorys.NativeFactory;
	import dragonBones.objects.AnimationData;
	import dragonBones.objects.ArmatureData;
	import dragonBones.objects.BoneData;
	import dragonBones.objects.DBTransform;
	import dragonBones.objects.Frame;
	import dragonBones.objects.SkeletonData;
	import dragonBones.objects.XMLDataParser;
	import dragonBones.textures.NativeTextureAtlas;
	import dragonBones.utils.ConstValues;
	import dragonBones.utils.TransformUtils;
	
	import flash.events.EventDispatcher;
	import flash.geom.Matrix;
	import flash.geom.Point;
	
	import message.Message;
	import message.MessageDispatcher;
	
	use namespace dragonBones_internal;
	
	[Bindable]
	public class CopyDataProxy extends EventDispatcher
	{
		private static var _instance:CopyDataProxy;
		public static function getInstance():CopyDataProxy
		{
			if (!_instance)
			{
				_instance = new CopyDataProxy();
			}
			return _instance;
		}
		
		public var sourceArmatureProxy:ArmatureProxy;
		public var targetArmatureProxy:ArmatureProxy;
		
		public var boneCopyable:Boolean;
		public var behaviorCopyable:Boolean;
		
		private var _factory:NativeFactory;
		private var _data:SkeletonData;
		private var _xmlDataProxy:XMLDataProxy;
		
		public function CopyDataProxy()
		{
			_factory = new NativeFactory();
			
			sourceArmatureProxy = new ArmatureProxy();
			targetArmatureProxy = new ArmatureProxy();
			
			sourceArmatureProxy.factory = ImportDataProxy.getInstance().factory;
			targetArmatureProxy.factory = _factory;
		}
		
		public function openNewCopySession():void
		{
			if(_data)
			{
				_factory.removeSkeletonData(_data.name);
				_data.dispose();
			}
			
			if(ImportDataProxy.getInstance().xmlDataProxy)
			{
				_xmlDataProxy = ImportDataProxy.getInstance().xmlDataProxy.copy();
				_data = XMLDataParser.parseSkeletonData(_xmlDataProxy.xml);
				
				_factory.addSkeletonData(_data);
				_factory.addTextureAtlas(ImportDataProxy.getInstance().textureAtlas);
				
				sourceArmatureProxy.armatureData = ImportDataProxy.getInstance().armatureProxy.armatureData;
			}
		}
		
		public function closeCopySession():void
		{
			
		}
		
		public function executeBoneCopy():void
		{
			/*var sourceBones:XMLList = selectedSourceBoneList;
			var destinationBones:XMLList = selectedDestinaionBonelist.copy();
			var plattenDestinationBones:XMLList = copyBones(sourceBones, destinationBones, _sharedBoneNames);
			var destinationName:String = selectedDestinationArmature.@[ConstValues.A_NAME];
			//update _copySkeletonXML;
			applyCopiedBoneToSkeletonXML(plattenDestinationBones, destinationName);
			//update _selectedDestinationBoneList
			var boneTree:XMLList = generateBoneTree(plattenDestinationBones);
			delete selectedDestinationArmature[ConstValues.BONE];
			selectedDestinationArmature.appendChild(boneTree);
			selectedDestinaionBonelist = boneTree.copy();
			
			resetDestinationSkeletonData();
			//occur to update
			var temp:XML = selectedDestinationArmature;
			selectedDestinationArmature = null;
			selectedDestinationArmature = temp;*/
		}
		
		public function executeBehaviorCopy():void
		{
			
		}
		
		//return a platten bone list
		/*private static function copyBones(sourceArmatureData:ArmatureData, destinationArmatureData:ArmatureData, sharedBoneNames:Vector.<String>):void
		{
			for each (var boneName:String in sharedBoneNames)
			{
				var parentName:String = getBoneParentName(boneName, plattenBoneList, sourceBones);
				//container.descendants().(@[ConstValues.A_NAME] == boneName).@[ConstValues.A_PARENT];
				if (parentName)
					plattenBoneList.(@[ConstValues.A_NAME] == boneName).@[ConstValues.A_PARENT] = parentName;
				else
					delete plattenBoneList.(@[ConstValues.A_NAME] == boneName).@[ConstValues.A_PARENT];
			}
			return plattenBoneList;
		}
		
		private static function generateSharedBonesInTree(sourceBones:XMLList, destinationBones:XMLList):Vector.<String>
		{
			var sharedBones:Vector.<String> = new Vector.<String>;
			var container:XML = <container/>;
			container.appendChild(destinationBones);
			generateSharedBonesInTree2(sourceBones, container, sharedBones);
			return sharedBones;
		}
		
		private static function generateSharedBonesInTree2(sourceBones:XMLList, container:XML, receiver:Vector.<String>):void
		{
			for each (var bone:XML in sourceBones)
			{
				var boneName:String = bone.@[ConstValues.A_NAME];
				if (container.descendants().(@[ConstValues.A_NAME] == boneName).length())
				{
					receiver.push(boneName);
				}
				//即使该骨骼不存在于目标骨架中，仍继续遍历其子骨骼
				generateSharedBonesInTree2(bone.children(), container, receiver);
			}
		}*/
	}
}
