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
	import dragonBones.utils.DBDataUtil;
	
	import flash.events.EventDispatcher;
	import flash.geom.Matrix;
	import flash.geom.Point;
	
	import message.Message;
	import message.MessageDispatcher;
	
	import model.vo.CopyAnimationVO;
	import model.vo.CopyBoneVO;
	
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
		public var animationCopyable:Boolean;
		public var dataChanged:Boolean;
		
		private var _factory:NativeFactory;
		private var _data:SkeletonData;
		private var _xmlDataProxy:XMLDataProxy;
		
		private var _copyBoneVOList:Vector.<CopyBoneVO>;
		private var _copyAnimationVOList:Vector.<CopyAnimationVO>;
		
		public function CopyDataProxy()
		{
			armaturesAC = new ArrayCollection();
			
			_factory = new NativeFactory();
			_factory.fillBitmapSmooth = true;
			
			_copyBoneVOList = new Vector.<CopyBoneVO>;
			_copyAnimationVOList = new Vector.<CopyAnimationVO>;
			
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
				_xmlDataProxy = ImportDataProxy.getInstance().xmlDataProxy.clone();
				_data = XMLDataParser.parseSkeletonData(_xmlDataProxy.xml);
				
				armaturesAC.source = getArmatureList();
				
				_factory.addSkeletonData(_data);
				_factory.addTextureAtlas(ImportDataProxy.getInstance().textureAtlas);
				
				sourceArmatureProxy.armatureData = ImportDataProxy.getInstance().armatureProxy.armatureData;
				targetArmatureProxy.armatureData = null;
				
				boneCopyable = false;
				animationCopyable = false;
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
						updateAnimationCopyAble();
						return;
					}
				}
			}
			
			boneCopyable = false;
			animationCopyable = false;
		}
		
		public function updateAnimationCopyAble():void
		{
			if(boneCopyable)
			{
				animationCopyable = !targetArmatureProxy.armatureData.getAnimationData(sourceArmatureProxy.selectedAnimationName);
			}
			else
			{
				animationCopyable = false;
			}
		}
		
		public function closeCopySession():void
		{
			sourceArmatureProxy.armatureData = null;
			targetArmatureProxy.armatureData = null;
			
			_copyBoneVOList.length = 0;
			_copyAnimationVOList.length = 0;
			
			boneCopyable = false;
			animationCopyable = false;
		}
		
		public function executeBoneCopy():void
		{
			
			targetArmatureProxy.copyBoneTree(sourceArmatureProxy.armatureData);
			_xmlDataProxy.changeBoneTree(targetArmatureProxy.armatureData);
			
			var armatureName:String = targetArmatureProxy.armatureName;
			
			var i:int = _copyBoneVOList.length;
			while(i --)
			{
				if(_copyBoneVOList[i].armatureName == armatureName)
				{
					_copyBoneVOList.length --;
				}
			}
			
			var copyBoneVO:CopyBoneVO = new CopyBoneVO(armatureName, _xmlDataProxy.getArmatureXMLList(armatureName)[0]);
			_copyBoneVOList.push(copyBoneVO);
			
			dataChanged = true;
			
			updateBoneCopyAble();
		}
		
		public function executeAnimationCopy():void
		{
			//拷贝动画前先拷贝骨架
			//executeBoneCopy();
			
			var copyAnimationData:AnimationData = XMLDataParser.parseAnimationData(
				_xmlDataProxy.getAnimationXMLList(sourceArmatureProxy.armatureName, sourceArmatureProxy.selectedAnimationName)[0],
				sourceArmatureProxy.armatureData,
				sourceArmatureProxy.selecteAnimationData.frameRate
			);
			
			var animationXML:XML = _xmlDataProxy.copyAnimationToArmature(copyAnimationData, sourceArmatureProxy.armatureData, targetArmatureProxy.armatureData);
			
			targetArmatureProxy.addAnimationData(copyAnimationData);
			
			var copyAnimationVO:CopyAnimationVO = 
				new CopyAnimationVO(
					targetArmatureProxy.armatureName,
					sourceArmatureProxy.armatureName,
					copyAnimationData.name,
					animationXML
				);
			
			_copyAnimationVOList.push(copyAnimationVO);
			
			dataChanged = true;
			
			updateAnimationCopyAble();
		}
		
		public function save():void
		{
			if(dataChanged)
			{
				
				MessageDispatcher.dispatchEvent(
					MessageDispatcher.COPY_BONE_AND_ANIMATION,
					_copyBoneVOList.concat(),
					_copyAnimationVOList.concat()
				);
				
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
