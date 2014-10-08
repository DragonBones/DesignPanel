package core.model
{
	import core.events.ModelEvent;
	import core.model.vo.ImportVO;
	import core.model.vo.ParsedVO;
	import core.suppotClass._BaseModel;
	
	import dragonBones.factorys.NativeFactory;
	import dragonBones.objects.AnimationData;
	import dragonBones.objects.ArmatureData;
	import dragonBones.objects.BoneData;
	import dragonBones.objects.SkinData;
	import dragonBones.objects.Timeline;
	import dragonBones.objects.TransformTimeline;
	import dragonBones.objects.XMLDataParser;
	import dragonBones.textures.NativeTextureAtlas;
	import dragonBones.utils.DBDataUtil;
	
	import mx.collections.ArrayCollection;
	import mx.collections.XMLListCollection;
	
	[Bindable]
	public final class ParsedModel extends _BaseModel
	{
		private static const DATA_NAME:String = "importName";
		
		public var armaturesAC:ArrayCollection;
		public var skinsAC:ArrayCollection;
		public var animationsAC:ArrayCollection;
		public var bonesMC:XMLListCollection
		
		private var _factory:NativeFactory;
		public function get factory():NativeFactory
		{
			return _factory;
		}
		
		private var _vo:ParsedVO;
		public function get vo():ParsedVO
		{
			return _vo;
		}
		
		public function setDataFromImport(importVO:ImportVO):void
		{
			removeOldData();
			_vo.importVO = importVO;
			_vo.skeleton = XMLDataParser.parseSkeletonData(importVO.skeleton);
			if(importVO.textureAtlas && importVO.textureAtlasConfig)
			{
				_vo.textureAtlas = new NativeTextureAtlas(importVO.textureAtlas, importVO.textureAtlasConfig);
			}
			
			_factory.useBitmapDataTexture = true;
			_factory.fillBitmapSmooth = true;
			_factory.addSkeletonData(_vo.skeleton, DATA_NAME);
			if(_vo.textureAtlas)
			{
				_factory.addTextureAtlas(_vo.textureAtlas, DATA_NAME);
			}
			
			armaturesAC.source = getArmatureList();
			//
			this.dispatcher.dispatchEvent(new ModelEvent(ModelEvent.PARSED_MODEL_DATA_CHANGE, this, _vo));
			
			armatureSelected = _armatureSelected?(_vo.skeleton.getArmatureData(_armatureSelected.name)||_vo.skeleton.armatureDataList[0]):_vo.skeleton.armatureDataList[0];
		}
		
		public function clearData():void
		{	
			removeOldData();
			createNewData();
			_armatureSelected = null;
			_boneSelected = null;
			this.dispatcher.dispatchEvent(new ModelEvent(ModelEvent.PARSED_MODEL_ARMATURE_CHANGE, this, _armatureSelected));
		}
		
		private function removeOldData():void
		{
			_vo.importVO = null;
			if(_vo.skeleton)
			{
				_factory.removeSkeletonData(DATA_NAME);
				_vo.skeleton.dispose();
				_vo.skeleton = null;
			}
			
			if(_vo.textureAtlas)
			{
				_factory.removeTextureAtlas(DATA_NAME);
				_vo.textureAtlas.dispose();
				_vo.textureAtlas = null;
			}
		}
		
		private function createNewData():void
		{
			_vo = new ParsedVO();
			_armatureSelected = null;
			_animationSelected = null;
			_skinSelected = null;
			
			armaturesAC = new ArrayCollection();
			skinsAC = new ArrayCollection();
			animationsAC = new ArrayCollection();
			bonesMC = new XMLListCollection();
			
			_factory = new NativeFactory();
			_factory.useBitmapDataTexture = true;
			_factory.fillBitmapSmooth = true;
		}
		
		private var _armatureSelected:ArmatureData;
		public function get armatureSelected():ArmatureData
		{
			return _armatureSelected;
		}
		public function set armatureSelected(value:ArmatureData):void
		{
			if(_armatureSelected == value)
			{
				return;
			}
			if(value && _vo.skeleton.armatureDataList.indexOf(value) < 0)
			{
				return;
			}
			_armatureSelected = value;
			
			skinsAC.source = getSkinList();
			animationsAC.source = getAnimationList();
			bonesMC.source = getBoneList();
			
			this.dispatcher.dispatchEvent(new ModelEvent(ModelEvent.PARSED_MODEL_ARMATURE_CHANGE, this, _armatureSelected));
			
			
			if(_armatureSelected.skinDataList.length > 0)
			{
				skinSelected = _skinSelected?(_armatureSelected.getSkinData(_skinSelected.name)||_armatureSelected.skinDataList[0]):_armatureSelected.skinDataList[0];
			}
			else
			{
				_skinSelected = null;
				this.dispatcher.dispatchEvent(new ModelEvent(ModelEvent.PARSED_MODEL_SKIN_CHANGE, this));
			}
			
			if(_armatureSelected.animationDataList.length > 0)
			{
				animationSelected = _animationSelected?(_armatureSelected.getAnimationData(_animationSelected.name)||_armatureSelected.animationDataList[0]):_armatureSelected.animationDataList[0];
			}
			else
			{
				_animationSelected = null;
				this.dispatcher.dispatchEvent(new ModelEvent(ModelEvent.PARSED_MODEL_ANIMATION_CHANGE, this));
			}
			
			
			boneSelected = _boneSelected?_armatureSelected.getBoneData(_boneSelected.name):null;
		}
		
		private var _skinSelected:SkinData;
		public function get skinSelected():SkinData
		{
			return _skinSelected;
		}
		public function set skinSelected(value:SkinData):void
		{
			if(_skinSelected == value)
			{
				return;
			}
			if(value && _armatureSelected.skinDataList.indexOf(value) < 0)
			{
				return;
			}
			_skinSelected = value;
			
			this.dispatcher.dispatchEvent(new ModelEvent(ModelEvent.PARSED_MODEL_SKIN_CHANGE, this, _skinSelected));
		}
		
		private var _animationSelected:AnimationData;
		public function get animationSelected():AnimationData
		{
			return _animationSelected;
		}
		public function set animationSelected(value:AnimationData):void
		{
			if(_animationSelected == value)
			{
				return;
			}
			if(value && _armatureSelected.animationDataList.indexOf(value) < 0)
			{
				return;
			}
			_animationSelected = value;
			
			this.dispatcher.dispatchEvent(new ModelEvent(ModelEvent.PARSED_MODEL_ANIMATION_CHANGE, this, _animationSelected));
		}
		
		private var _boneSelected:BoneData;
		public function get boneSelected():BoneData
		{
			return _boneSelected;
		}
		public function set boneSelected(value:BoneData):void
		{
			if(_boneSelected == value)
			{
				return;
			}
			if(value && _armatureSelected.boneDataList.indexOf(value) < 0)
			{
				return;
			}
			_boneSelected = value;
			
			this.dispatcher.dispatchEvent(new ModelEvent(ModelEvent.PARSED_MODEL_BONE_CHANGE, this, _boneSelected));
		}
		
		public function get isMultipleFrameAnimation():Boolean
		{
			if(_animationSelected)
			{
				if(_animationSelected.frameList.length > 1)
				{
					return true;
				}
				else
				{
					for each(var timeline:Timeline in _animationSelected.timelineList)
					{
						if(timeline.frameList.length > 1)
						{
							return true;
						}
					}
				}
			}
			return false;
		}
		
		public function get fadeInTime():Number
		{
			return _animationSelected?_animationSelected.fadeTime:0;
		}
		public function set fadeInTime(value:Number):void
		{
			if(_animationSelected)
			{
				_animationSelected.fadeTime =  value;
				updateAnimation();
			}
		}
		
		public function get durationScaled():Number
		{
			if(_animationSelected && isMultipleFrameAnimation)
			{
				return Math.round(_animationSelected.scale * _animationSelected.duration * 0.001 * 100) / 100;
			}
			return 0;
		}
		public function set durationScaled(value:Number):void
		{
			//
		}
		
		public function get animationScale():Number
		{
			return _animationSelected?_animationSelected.scale:0;
		}
		public function set animationScale(value:Number):void
		{
			if(_animationSelected)
			{
				_animationSelected.scale = value;
				updateAnimation();
				//
				durationScaled = 0;
			}
		}
		
		public function get playTimes():int
		{
			return _animationSelected?_animationSelected.playTimes:0;
		}
		public function set playTimes(value:int):void
		{
			if(_animationSelected)
			{ 
				_animationSelected.playTimes = value;
				updateAnimation();
			}
		}
		
		public function get autoTween():Boolean
		{
			return _animationSelected?_animationSelected.autoTween:false;
		}
		public function set autoTween(value:Boolean):void
		{
			if(_animationSelected)
			{
				_animationSelected.autoTween = value;
				updateAnimation();
			}
		}
		
		public function get tweenEasing():Number
		{
			return _animationSelected?_animationSelected.tweenEasing:NaN;
		}
		public function set tweenEasing(value:Number):void
		{
			if(_animationSelected)
			{
				if(value < -1)
				{
					_animationSelected.tweenEasing = NaN;
				}
				else
				{
					_animationSelected.tweenEasing = value;
				}
				updateAnimation();
			}
		}
		
		public function get timelineScale():Number
		{
			if(_animationSelected && _boneSelected)
			{
				var timeline:TransformTimeline = _animationSelected.getTimeline(_boneSelected.name);
				if(timeline)
				{
					return timeline.scale * 100;
				}
			}
			return NaN;
		}
		public function set timelineScale(value:Number):void
		{
			if(_animationSelected && _boneSelected)
			{
				var timeline:TransformTimeline = _animationSelected.getTimeline(_boneSelected.name);
				if(timeline)
				{
					timeline.scale = value * 0.01;
					updateTransformTimeline();
				}
			}
		}
		
		public function get timelineOffset():Number
		{
			if(_animationSelected && _boneSelected)
			{
				var timeline:TransformTimeline = _animationSelected.getTimeline(_boneSelected.name);
				if(timeline)
				{
					return timeline.offset * 100;
				}
			}
			return NaN;
		}
		public function set timelineOffset(value:Number):void
		{
			if(_animationSelected && _boneSelected)
			{
				var timeline:TransformTimeline = _animationSelected.getTimeline(_boneSelected.name);
				if(timeline)
				{
					timeline.offset = value * 0.01;
					updateTransformTimeline();
				}
			}
		}
		
		public function ParsedModel()
		{
			createNewData();
		}
		
		public function addAnimationData(animationData:AnimationData):void
		{
			_armatureSelected.addAnimationData(animationData);
			animationsAC.source = getAnimationList();
			animationSelected = animationData;
		}
		
		public function changeBoneParent(boneName:String, boneParentName:String):void
		{
			var boneData:BoneData = _armatureSelected.getBoneData(boneName);
			if(boneData.parent == boneParentName)
			{
				return;
			}
			
			var parentData:BoneData = _armatureSelected.getBoneData(boneParentName);
			if(parentData)
			{
				if(parentData.parent == boneName)
				{
					parentData.parent = boneData.parent;
				}
				boneData.parent = boneParentName;
			}
			else
			{
				boneData.parent = null;
			}
			
			DBDataUtil.transformArmatureData(_armatureSelected);
			DBDataUtil.transformArmatureDataAnimations(_armatureSelected);
			_armatureSelected.sortBoneDataList();
			
			bonesMC.source = getBoneList();
			
			this.dispatcher.dispatchEvent(new ModelEvent(ModelEvent.PARSED_MODEL_BONE_PARENT_CHANGE, this, [boneName, boneParentName]));
		}
		
		private function getArmatureList():Array
		{
			var armatureList:Array = [];
			for each(var armatureData:ArmatureData in _vo.skeleton.armatureDataList)
			{
				armatureList.push(armatureData);
			}
			return armatureList;
		}
		
		private function getSkinList():Array
		{
			var skinList:Array = [];
			for each(var skinData:SkinData in _armatureSelected.skinDataList)
			{
				skinList.push(skinData);
			}
			return skinList;
		}
		
		private function getAnimationList():Array
		{
			var animationiList:Array = [];
			for each(var animationData:AnimationData in _armatureSelected.animationDataList)
			{
				animationiList.push(animationData);
			}
			return animationiList;
		}
		
		private function getBoneList():XMLList
		{
			var rootXML:XML = <root/>;
			var boneMap:Object = {};
			var boneName:String;
			var parentName:String;
			var bone:XML;
			var parent:XML;
			for each(var boneData:BoneData in _armatureSelected.boneDataList)
			{
				boneName = boneData.name;
				parentName = boneData.parent;
				bone = <bone name={boneName}/>;
				boneMap[boneName] = bone;
				if (parentName)
				{
					parent = boneMap[parentName];
					if (parent)
					{
						parent.appendChild(bone);
						continue;
					}
				}
				rootXML.appendChild(bone);
			}
			return rootXML.children();
		}
		
		private function updateAnimation():void
		{
			this.dispatcher.dispatchEvent(new ModelEvent(ModelEvent.PARSED_MODEL_ANIMATION_DATA_CHANGE, this));
		}
		
		private function updateTransformTimeline():void
		{
			this.dispatcher.dispatchEvent(new ModelEvent(ModelEvent.PARSED_MODEL_TIMELINE_DATA_CHANGE, this));
		}
	}
}