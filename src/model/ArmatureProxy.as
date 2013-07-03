package model
{
	import dragonBones.Armature;
	import dragonBones.Bone;
	import dragonBones.animation.AnimationState;
	import dragonBones.animation.WorldClock;
	import dragonBones.factorys.NativeFactory;
	import dragonBones.objects.AnimationData;
	import dragonBones.objects.ArmatureData;
	import dragonBones.objects.BoneData;
	import dragonBones.objects.TransformTimeline;
	import dragonBones.utils.DBDataUtils;
	
	import flash.events.Event;
	
	import message.MessageDispatcher;
	
	import mx.collections.ArrayCollection;
	import mx.collections.XMLListCollection;
	
	[Bindable]
	/**
	 * Manage armature data
	 */
	public class ArmatureProxy
	{
		public var bonesMC:XMLListCollection;
		public var animationsAC:ArrayCollection;
		public var factory:NativeFactory;
		
		private var _selectedBoneData:BoneData;
		
		private var _armature:Armature;
		public function get armature():Armature
		{
			return _armature;
		}
		private function set armature(value:Armature):void
		{
			if(_armature)
			{
				WorldClock.clock.remove(_armature);
				_armature.dispose();
			}
			_armature = value;
			if(_armature)
			{
				WorldClock.clock.add(_armature);
			}
		}
		
		public function get armatureName():String
		{
			return _armatureData?_armatureData.name:null;
		}
		private var _armatureData:ArmatureData;
		public function get armatureData():ArmatureData
		{
			return _armatureData;
		}
		public function set armatureData(value:ArmatureData):void
		{
			if(_armatureData == value)
			{
				return;
			}
			_armatureData = value;
			
			bonesMC.source = getBoneList();
			
			animationsAC.source = getAnimationList();
			
			armature = factory.buildArmature(armatureName);
			
			MessageDispatcher.dispatchEvent(MessageDispatcher.SELECT_ARMATURE, this, armatureName);
			
			var selectBoneName:String = this.selectedBoneName;
			var selectAnimationName:String = this.selectedAnimationName;
			
			_selectedBoneData = null;
			_selectAnimationData = null;
			
			if(_armatureData && _armatureData.boneDataList.length > 0)
			{
				selectBone(selectBoneName || _armatureData.boneDataList[0].name);
			}
			else
			{
				selectBone(null);
			}
			
			if(_armatureData && _armatureData.animationDataList.length > 0)
			{
				selecteAnimationData = _armatureData.getAnimationData(selectAnimationName) || _armatureData.animationDataList[0];
			}
			else
			{
				selecteAnimationData = null;
			}
		}
		
		public function get selectedAnimationName():String
		{
			return _selectAnimationData?_selectAnimationData.name:null;
		}
		private var _selectAnimationData:AnimationData;
		public function get selecteAnimationData():AnimationData
		{
			return _selectAnimationData;
		}
		public function set selecteAnimationData(value:AnimationData):void
		{
			if(_selectAnimationData == value)
			{
				return;
			}
			
			_selectAnimationData = value;
			
			if(_armature && _selectAnimationData)
			{
				_armature.animation.gotoAndPlay(_selectAnimationData.name);
				MessageDispatcher.dispatchEvent(MessageDispatcher.SELECT_ANIMATION, this, _selectAnimationData.name);
			}
		}
		
		public function get selectedBoneName():String
		{
			return _selectedBoneData?_selectedBoneData.name:null;
		}
		
		public function get fadeTime():Number
		{
			if(!_selectAnimationData)
			{
				return -1;
			}
			return _selectAnimationData.fadeTime;
		}
		public function set fadeTime(value:Number):void
		{
			if(_selectAnimationData)
			{
				var frame:uint = Math.round(value * _selectAnimationData.frameRate);
				_selectAnimationData.fadeTime =  frame / _selectAnimationData.frameRate;
				updateAnimation();
			}
		}
		
		public function get durationScaled():Number
		{
			if(_selectAnimationData?(_selectAnimationData.duration * _selectAnimationData.frameRate < 2):true)
			{
				return -1;
			}
			return _selectAnimationData.scale * _selectAnimationData.duration;
		}
		public function set durationScaled(value:Number):void
		{
			if(_selectAnimationData)
			{
				var frameScaled:Number = Math.round(value * _selectAnimationData.frameRate);
				_selectAnimationData.scale = frameScaled / _selectAnimationData.frameRate / _selectAnimationData.duration;
				updateAnimation();
			}
		}
		
		public function get loop():Boolean
		{
			return _selectAnimationData?_selectAnimationData.loop != 1:false;
		}
		public function set loop(value:Boolean):void
		{
			if(_selectAnimationData)
			{ 
				_selectAnimationData.loop = value?0:1;
				updateAnimation();
			}
		}
		
		public function get tweenEasing():Number
		{
			return _selectAnimationData?_selectAnimationData.tweenEasing:-1.1;
		}
		public function set tweenEasing(value:Number):void
		{
			if(_selectAnimationData)
			{
				if(value < -1)
				{
					_selectAnimationData.tweenEasing = NaN;
				}
				else
				{
					_selectAnimationData.tweenEasing = value;
				}
				updateAnimation();
			}
		}
		
		public function get timelineScale():Number
		{
			if(_selectAnimationData && _selectedBoneData)
			{
				var timeline:TransformTimeline = _selectAnimationData.getTimeline(_selectedBoneData.name);
				if(timeline && !(timeline.duration * _selectAnimationData.frameRate < 2))
				{
					return timeline.scale * 100;
				}
			}
			return NaN;
		}
		public function set timelineScale(value:Number):void
		{
			if(_selectAnimationData && _selectedBoneData)
			{
				var timeline:TransformTimeline = _selectAnimationData.getTimeline(_selectedBoneData.name);
				if(timeline)
				{
					timeline.scale = value * 0.01;
					updateTransformTimeline();
				}
			}
		}
		
		public function get timelineOffset():Number
		{
			if(_selectAnimationData && _selectedBoneData)
			{
				var timeline:TransformTimeline = _selectAnimationData.getTimeline(_selectedBoneData.name);
				if(timeline && !(timeline.duration * _selectAnimationData.frameRate < 2))
				{
					return timeline.offset * 100;
				}
			}
			return NaN;
		}
		public function set timelineOffset(value:Number):void
		{
			if(_selectAnimationData && _selectedBoneData)
			{
				var timeline:TransformTimeline = _selectAnimationData.getTimeline(_selectedBoneData.name);
				if(timeline)
				{
					timeline.offset = value * 0.01;
					updateTransformTimeline();
				}
			}
		}
		
		public function ArmatureProxy()
		{
			bonesMC = new XMLListCollection();
			animationsAC = new ArrayCollection();
		}
		
		public function selectBone(boneName:String):void
		{
			if(_armatureData)
			{
				var boneData:BoneData = _armatureData.getBoneData(boneName);
			}
			else
			{
				boneData = null;
			}
			
			if(_selectedBoneData == boneData)
			{
				return;
			}
			_selectedBoneData = boneData;
			
			MessageDispatcher.dispatchEvent(MessageDispatcher.SELECT_BONE, this, boneName);
		}
		
		public function changeBoneParent(name:String, parentName:String):void
		{
			var boneData:BoneData = _armatureData.getBoneData(name);
			var parentData:BoneData = _armatureData.getBoneData(parentName);
			
			if(boneData.parent == parentName)
			{
				return;
			}
			
			if(parentData)
			{
				boneData.parent = parentName;
			}
			else
			{
				boneData.parent = null;
			}
			
			DBDataUtils.transformArmatureData(_armatureData);
			DBDataUtils.transformAnimationData(_armatureData);
			_armatureData.sortBoneDataList();
			
			bonesMC.source = getBoneList();
			
			updateArmature();
			
			MessageDispatcher.dispatchEvent(MessageDispatcher.CHANGE_BONE_PARENT, this, name, parentName);
		}
		
		public function copyBoneTree(sourceArmatureData:ArmatureData):void
		{
			for each(var boneData:BoneData in _armatureData.boneDataList)
			{
				var sourceBoneData:BoneData = sourceArmatureData.getBoneData(boneData.name);
				if(sourceBoneData)
				{
					var parentData:BoneData = _armatureData.getBoneData(sourceBoneData.parent);
					if(parentData)
					{
						boneData.parent = parentData.name;
					}
				}
			}
			DBDataUtils.transformArmatureData(_armatureData);
			DBDataUtils.transformAnimationData(_armatureData);
			_armatureData.sortBoneDataList();
			
			bonesMC.source = getBoneList();
			
			updateArmature();
			
			MessageDispatcher.dispatchEvent(MessageDispatcher.CHANGE_BONE_TREE, this);
		}
		
		public function addAnimationData(sourceAnimationData:AnimationData, sourceArmatureData:ArmatureData):void
		{
			
		}
		
		private function getBoneList():XMLList
		{
			var rootXML:XML = <root/>;
			if(_armatureData)
			{
				var boneXMLs:Object = {};
				for each(var boneData:BoneData in _armatureData.boneDataList)
				{
					var boneName:String = boneData.name;
					var boneXML:XML = <bone name={boneName}/>;
					boneXMLs[boneName] = boneXML;
					var parentName:String = boneData.parent;
					if (parentName)
					{
						var parentXML:XML = boneXMLs[parentName];
						if (parentXML)
						{
							parentXML.appendChild(boneXML);
							continue;
						}
					}
					rootXML.appendChild(boneXML);
				}
			}
			return rootXML.children();
		}
		
		private function getAnimationList():Array
		{
			var animationiList:Array = [];
			if(_armatureData)
			{
				for each(var animationData:AnimationData in _armatureData.animationDataList)
				{
					animationiList.push(animationData);
				}
			}
			return animationiList;
		}
		
		private function updateAnimation():void
		{
			if(_armature)
			{
				_armature.animation.play();
			}
			MessageDispatcher.dispatchEvent(MessageDispatcher.CHANGE_ANIMATION_DATA, this, selectedAnimationName);
		}
		
		private function updateTransformTimeline():void
		{
			MessageDispatcher.dispatchEvent(MessageDispatcher.CHANGE_TRANSFORM_TIMELINE_DATA, this, selectedAnimationName, selectedBoneName);
		}
		
		private function updateArmature():void
		{
			var lastAnimationState:AnimationState = _armature.animation.lastAnimationState;
			
			if(lastAnimationState)
			{
				var isPlaying:Boolean = _armature.animation.isPlaying;
				var currentTime:Number = lastAnimationState.currentTime;
				var animationName:String = lastAnimationState.name;
			}
			
			armature = factory.buildArmature(armatureName);
			
			if(lastAnimationState)
			{
				_armature.animation.gotoAndPlay(animationName, 0, -1);
				lastAnimationState = _armature.animation.lastAnimationState;
				lastAnimationState.currentTime = currentTime;
				if(!isPlaying)
				{
					_armature.animation.advanceTime(0);
					_armature.animation.advanceTime(0);
					_armature.animation.stop();
				}
			}
		}
	}
}