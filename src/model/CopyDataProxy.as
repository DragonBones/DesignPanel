package model
{
	import dragonBones.Armature;
	import dragonBones.core.dragonBones_internal;
	import dragonBones.factorys.NativeFactory;
	import dragonBones.objects.AnimationData;
	import dragonBones.objects.ArmatureData;
	import dragonBones.objects.BoneData;
	import dragonBones.objects.SkeletonData;
	import dragonBones.objects.XMLDataParser;
	import dragonBones.utils.DBDataUtils;
	
	import flash.events.EventDispatcher;
	import flash.geom.Matrix;
	import flash.geom.Point;
	
	import message.Message;
	import message.MessageDispatcher;
	
	import mx.collections.ArrayCollection;
	
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
		
		public var armaturesAC:ArrayCollection;
		
		public var sourceArmatureProxy:ArmatureProxy;
		public var targetArmatureProxy:ArmatureProxy;
		
		public var boneCopyable:Boolean;
		public var behaviorCopyable:Boolean;
		public var dataChanged:Boolean;
		
		private var _factory:NativeFactory;
		private var _data:SkeletonData;
		private var _xmlDataProxy:XMLDataProxy;
		
		public function CopyDataProxy()
		{
			armaturesAC = new ArrayCollection();
			
			_factory = new NativeFactory();
			_factory.fillBitmapSmooth = true;
			
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
				
				armaturesAC.source = getArmatureList();
				
				_factory.addSkeletonData(_data);
				_factory.addTextureAtlas(ImportDataProxy.getInstance().textureAtlas);
				
				sourceArmatureProxy.armatureData = ImportDataProxy.getInstance().armatureProxy.armatureData;
				targetArmatureProxy.armatureData = null;
				
				boneCopyable = false;
				behaviorCopyable = false;
				dataChanged = false;
			}
		}
		
		public function updateBoneCopyAble():void
		{
			if(
				sourceArmatureProxy.armatureData && 
				targetArmatureProxy.armatureData && 
				sourceArmatureProxy.armatureData.name != targetArmatureProxy.armatureData.name
			)
			{
				for each(var boneData:BoneData in targetArmatureProxy.armatureData.boneDataList)
				{
					var sourBoneData:BoneData = sourceArmatureProxy.armatureData.getBoneData(boneData.name);
					if(sourBoneData)
					{
						boneCopyable = true;
						updateBehaviorCopyAble();
						return;
					}
				}
			}
			
			boneCopyable = false;
			behaviorCopyable = false;
		}
		
		public function updateBehaviorCopyAble():void
		{
			if(boneCopyable)
			{
				behaviorCopyable = !targetArmatureProxy.armatureData.getAnimationData(sourceArmatureProxy.selecteAnimationData.name);
			}
			else
			{
				behaviorCopyable = false;
			}
		}
		
		public function closeCopySession():void
		{
			sourceArmatureProxy.armatureData = null;
			targetArmatureProxy.armatureData = null;
		}
		
		public function executeBoneCopy():void
		{
			targetArmatureProxy.copyBoneTree(sourceArmatureProxy.armatureData);
			_xmlDataProxy.changeBoneTree(targetArmatureProxy.armatureData);
			
			dataChanged = true;
			
			updateBoneCopyAble();
		}
		
		public function executeBehaviorCopy():void
		{
			//拷贝动画前先拷贝骨架
			//executeBoneCopy();
			
			var animationXML:XML = null;
				//_xmlDataProxy.addAnimationToArmature(sourceArmatureProxy.selecteAnimationData, sourceArmatureProxy.armatureData, targetArmatureProxy.armatureData);
			
			var copyAnimationData:AnimationData = XMLDataParser.parseAnimationData(
				animationXML,
				sourceArmatureProxy.armatureData,
				sourceArmatureProxy.selecteAnimationData.frameRate
			);
			
			targetArmatureProxy.addAnimationData(copyAnimationData);
			
			dataChanged = true;
			
			updateBehaviorCopyAble();
		}
		
		public function save():void
		{
			if(dataChanged)
			{
				//jsfl
				
				
				MessageDispatcher.dispatchEvent(
					MessageDispatcher.IMPORT_COMPLETE, 
					_xmlDataProxy, 
					ImportDataProxy.getInstance().textureBytes, 
					ImportDataProxy.getInstance().textureAtlas.movieClip || ImportDataProxy.getInstance().textureAtlas.bitmapData.clone(), 
					ImportDataProxy.getInstance().isExportedSource
				);
			}
			
		}
		
		private function getArmatureList():Array
		{
			var armatureList:Array = [];
			for each(var armatureData:ArmatureData in _data.armatureDataList)
			{
				armatureList.push(armatureData);
			}
			return armatureList;
		}
	}
}
