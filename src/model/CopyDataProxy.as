package model
{
	import dragonBones.Armature;
	import dragonBones.animation.Tween;
	import dragonBones.animation.WorldClock;
	import dragonBones.factorys.BaseFactory;
	import dragonBones.objects.AnimationData;
	import dragonBones.objects.BoneData;
	import dragonBones.objects.FrameData;
	import dragonBones.objects.MovementBoneData;
	import dragonBones.objects.MovementData;
	import dragonBones.objects.BoneTransform;
	import dragonBones.objects.SkeletonData;
	import dragonBones.objects.XMLDataParser;
	import dragonBones.textures.NativeTextureAtlas;
	import dragonBones.utils.ConstValues;
	import dragonBones.utils.TransformUtils;
	import dragonBones.utils.dragonBones_internal;
	
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
		
		//the structure data
		public var copyArmaturesData:XMLList;
		
		//the non-structure data for SkeletonData
		private var _copySkeletonXML:XML;
		private var _skeletonData:SkeletonData;
		private var _copyFactory:BaseFactory;
		
		//controlled by view
		private var _selectedSourceArmature:XML;
		private var _selectedDestinationArmature:XML;
		
		//for view displaying
		public var selectedSourceBoneList:XMLList;
		public var selectedDestinaionBonelist:XMLList;
		
		//for view displaying
		public var selectedSourceBehaviorList:XMLList;
		public var selectedDestinaionBehaviorList:XMLList;
		//for view displaying
		private var _sourceDisplayArmature:Armature;
		private var _destinationDisplayArmature:Armature;
		
		private var _selectedMultipleSourceBehaviors:Vector.<Object>;
		private var _selectedMultipleDestinationBehaviors:Vector.<Object>;
		
		public var boneCopyable:Boolean;
		public var behaviorCopyable:Boolean;
		public var behaviorDeletable:Boolean;
		
		private var _sharedBoneNames:Vector.<String>;
		
		public function get selectedMultipleDestinationBehaviors():Vector.<Object>
		{
			return _selectedMultipleDestinationBehaviors;
		}
		
		public function set selectedMultipleDestinationBehaviors(value:Vector.<Object>):void
		{
			_selectedMultipleDestinationBehaviors = value;
			checkBehaviorsDeletable();
		}
		
		public function get selectedMultipleSourceBehaviors():Vector.<Object>
		{
			return _selectedMultipleSourceBehaviors;
		}
		
		public function set selectedMultipleSourceBehaviors(value:Vector.<Object>):void
		{
			_selectedMultipleSourceBehaviors = value;
			checkBehaviorsCopyable();
		}
		
		public function playSourceBehavior(behavior:*):void
		{
			if (behavior && _sourceDisplayArmature)
			{
				_sourceDisplayArmature.animation.gotoAndPlay(behavior.@[ConstValues.A_NAME]);
			}
		}
		
		public function playDestinationBehavior(behavior:*):void
		{
			if (behavior && _destinationDisplayArmature)
			{
				_destinationDisplayArmature.animation.gotoAndPlay(behavior.@[ConstValues.A_NAME]);
			}
		}
		
		
		public function get destinationDisplayArmature():Armature
		{
			return _destinationDisplayArmature;
		}
		
		private function set destinationDisplayArmature(value:Armature):void
		{
			if (_sourceDisplayArmature)
				WorldClock.clock.remove(_destinationDisplayArmature);
			_destinationDisplayArmature = value;
			if (_sourceDisplayArmature)
				WorldClock.clock.add(_destinationDisplayArmature);
		}
		
		public function get sourceDisplayArmature():Armature
		{
			return _sourceDisplayArmature;
		}
		
		private function set sourceDisplayArmature(value:Armature):void
		{
			if (_sourceDisplayArmature)
				WorldClock.clock.remove(_sourceDisplayArmature);
			_sourceDisplayArmature = value;
			if (_sourceDisplayArmature)
				WorldClock.clock.add(_sourceDisplayArmature);
		}
		
		
		
		public function get selectedDestinationArmature():XML
		{
			return _selectedDestinationArmature;
		}
		
		
		public function set selectedDestinationArmature(value:XML):void
		{
			_selectedDestinationArmature = value;
			if (_selectedDestinationArmature)
			{
				selectedDestinaionBonelist = _selectedDestinationArmature[ConstValues.BONE].copy();
				selectedDestinaionBehaviorList = _selectedDestinationArmature[ConstValues.ANIMATION][ConstValues.MOVEMENT].copy();
				destinationDisplayArmature = _copyFactory.buildArmature(_selectedDestinationArmature.@[ConstValues.A_NAME]);
				if (selectedDestinaionBehaviorList.length() > 0)
					playDestinationBehavior(selectedDestinaionBehaviorList[0]);
			}
			else
			{
				selectedDestinaionBonelist = null;
				selectedDestinaionBehaviorList = null;
				destinationDisplayArmature = null;
			}
			checkBonesCopyable();
			checkBehaviorsCopyable();
		}
		
		
		public function get selectedSourceArmature():XML
		{
			return _selectedSourceArmature;
		}
		
		
		public function set selectedSourceArmature(value:XML):void
		{
			_selectedSourceArmature = value;
			if (_selectedSourceArmature)
			{
				selectedSourceBoneList = _selectedSourceArmature[ConstValues.BONE].copy();
				selectedSourceBehaviorList = _selectedSourceArmature[ConstValues.ANIMATION][ConstValues.MOVEMENT].copy();
				sourceDisplayArmature = _copyFactory.buildArmature(_selectedSourceArmature.@[ConstValues.A_NAME]);
				if (selectedSourceBehaviorList.length() > 0)
					playSourceBehavior(selectedSourceBehaviorList[0]);
			}
			else
			{
				selectedSourceBoneList = null;
				selectedSourceBehaviorList = null;
				sourceDisplayArmature = null;
			}
			checkBonesCopyable();
			checkBehaviorsCopyable();
		}
		
		
		
		
		public static function getInstance():CopyDataProxy
		{
			if (!_instance)
			{
				_instance = new CopyDataProxy();
			}
			return _instance;
		}
		
		public function CopyDataProxy()
		{
		}
		
		
		
		public function openNewCopySession():void
		{
			copyArmaturesData = ImportDataProxy.getInstance().armaturesMC.source.copy();
			
			var behaviors:XMLList = SkeletonXMLProxy.getAnimationXMLList(ImportDataProxy.getInstance().skeletonXMLProxy.skeletonXML);
			//add original flag
			for each (var mov:XML in behaviors[ConstValues.MOVEMENT])
				mov.@original = true;
			combineArmatureAndBehaviors(copyArmaturesData, behaviors);
			
			//delete display info
			delete copyArmaturesData[ConstValues.BONE][ConstValues.DISPLAY];
			
			//structuralize bones
			for each (var armature:XML in copyArmaturesData)
			{
				var boneTree:XMLList = generateBoneTree(armature[ConstValues.BONE]);
				delete armature[ConstValues.BONE];
				armature.appendChild(boneTree);
			}
			
			_copySkeletonXML = ImportDataProxy.getInstance().skeletonXMLProxy.skeletonXML.copy();
			_copyFactory = new BaseFactory();
			_copyFactory.addTextureAtlas(ImportDataProxy.getInstance().textureAtlas);
			
			resetDestinationSkeletonData();
			
			var selectedArmatrueName:String = ImportDataProxy.getInstance().armatureDataProxy.armatureName;
			if (selectedArmatrueName)
			{
				selectedSourceArmature = copyArmaturesData.(@[ConstValues.A_NAME] == selectedArmatrueName)[0];
			}
		}
		
		private var waitingForSavingBehaviors:XMLList;
		private var savingIndex:int;
		
		private function completeSave():void
		{
			waitingForSavingBehaviors = null;
			savingIndex = 0;
			MessageDispatcher.removeEventListener(JSFLProxy.COPY_MOVEMENT, saveOneBehavior);
		}
		
		private function saveOneBehavior(e:Message):void
		{
			if (savingIndex < waitingForSavingBehaviors.length())
			{
				var behavior:XML = waitingForSavingBehaviors[savingIndex];
				var armatureName:String = behavior.@armatureName;
				var sourceArmatrueName:String = behavior.@sourceName;
				var behaviorName:String = behavior.@[ConstValues.A_NAME];
				var movementXML:XML = _copySkeletonXML[ConstValues.ANIMATIONS][ConstValues.ANIMATION].(@[ConstValues.A_NAME] == armatureName)[0][ConstValues.MOVEMENT].(@[ConstValues.A_NAME] == behaviorName)[0];
				JSFLProxy.getInstance().copyMovement(armatureName, sourceArmatrueName, behaviorName, movementXML);
				MessageDispatcher.dispatchEvent(MessageDispatcher.SAVE_ANIMATION_PROGRESS, savingIndex, waitingForSavingBehaviors.length());
				savingIndex++;
			}
			else
			{
				MessageDispatcher.dispatchEvent(MessageDispatcher.SAVE_ANIMATION_COMPLETE);
				completeSave();
			}
		}
		
		public function save():void
		{
			
			waitingForSavingBehaviors = calculateChangedArmatures().children();
			savingIndex = 0;
			
			MessageDispatcher.dispatchEvent(MessageDispatcher.SAVE_ANIMATION_START);
			
			var armatureXMLList:XMLList = _copySkeletonXML.descendants(ConstValues.ARMATURE);
			
			for each(var armatureXML:XML in armatureXMLList)
			{
				var armatureName:String = armatureXML.@[ConstValues.A_NAME];
				var originArmatureXML:XML = ImportDataProxy.getInstance().skeletonXMLProxy.getArmatureXML(armatureName);
				if(originArmatureXML != armatureXML)
				{
					var isBoneTreeChange:Boolean = true;
					if(!ImportDataProxy.getInstance().isExportedSource)
					{
						JSFLProxy.getInstance().changeArmatureConnection(armatureName, armatureXML);
					}
				}
			}
			
			if(isBoneTreeChange || waitingForSavingBehaviors.length() > 0)
			{
				ImportDataProxy.getInstance().skeletonXMLProxy.skeletonXML = _copySkeletonXML.copy();
				
				var textureAtlas:NativeTextureAtlas = ImportDataProxy.getInstance().textureAtlas;
				
				ImportDataProxy.getInstance().setData(
					ImportDataProxy.getInstance().skeletonXMLProxy, 
					ImportDataProxy.getInstance().textureBytes,
					textureAtlas.movieClip || textureAtlas.bitmapData.clone(),
					ImportDataProxy.getInstance().isExportedSource
				);
			}
			
			if(!ImportDataProxy.getInstance().isExportedSource)
			{
				MessageDispatcher.addEventListener(JSFLProxy.COPY_MOVEMENT, saveOneBehavior);
				saveOneBehavior(null);
			}
			else
			{
				MessageDispatcher.dispatchEvent(MessageDispatcher.SAVE_ANIMATION_COMPLETE);
			}
		}
		
		public function calculateChangedArmatures():XML
		{
			var changedBehaviors:XML = <container/>;
			for each (var armatureXML:XML in copyArmaturesData)
			{
				var armatureName:String = armatureXML.@[ConstValues.A_NAME];
				var sourceBones:XML = ImportDataProxy.getInstance().skeletonXMLProxy.getArmatureXML(armatureName);
				var destinationBones:XML = _copySkeletonXML[ConstValues.ARMATURES][ConstValues.ARMATURE].(@[ConstValues.A_NAME] == armatureName)[0];
				if (sourceBones != destinationBones)
				{
					trace(armatureName, " bone changed");
				}
				var sourceBehaviors:XML = ImportDataProxy.getInstance().skeletonXMLProxy.getAnimationXML(armatureName);
				var destinationBehaviors:XML = _copySkeletonXML[ConstValues.ANIMATIONS][ConstValues.ANIMATION].(@[ConstValues.A_NAME] == armatureName)[0];
				if (sourceBehaviors != destinationBehaviors)
				{
					trace(armatureName, " behavior changed");
					var behaviors:XMLList = armatureXML[ConstValues.ANIMATION][ConstValues.MOVEMENT].(@original == false).copy();
					for each (var behavior:XML in behaviors)
					{
						behavior.@armatureName = armatureName;
					}
					changedBehaviors.appendChild(behaviors);
				}
			}
			return changedBehaviors;
		}
		
		public function closeCopySession():void
		{
			calculateChangedArmatures();
			
			selectedSourceArmature = null;
			selectedDestinationArmature = null;
			
			_copySkeletonXML = null;
			_copyFactory = null;
			
			sourceDisplayArmature = null;
			destinationDisplayArmature = null;
		}
		
		
		public function executeBoneCopy():void
		{
			var sourceBones:XMLList = selectedSourceBoneList;
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
			selectedDestinationArmature = temp;
		}
		
		
		public function executeBehaviorCopy():void
		{
			var copiedDestinationBehaviors:XMLList = copyBehaviors(_selectedSourceArmatureName, selectedMultipleSourceBehaviors, _sourceAnimationData, selectedDestinaionBehaviorList, _sharedBoneNames, _plattenDestinationBoneList);
			var destinationName:String = selectedDestinationArmature.@[ConstValues.A_NAME];
			
			var container:XML = <{ConstValues.ANIMATION}/>;
			container.@[ConstValues.A_NAME] = destinationName;
			container.appendChild(copiedDestinationBehaviors);
			
			//update selectedDestinationArmature
			delete _selectedDestinationArmature[ConstValues.ANIMATION];
			_selectedDestinationArmature.appendChild(container);
			
			//update _copySkeletonXML;
			delete _copySkeletonXML[ConstValues.ANIMATIONS][ConstValues.ANIMATION].(@[ConstValues.A_NAME] == destinationName)[0];
			container = container.copy();
			delete container[ConstValues.MOVEMENT].@original;
			delete container[ConstValues.MOVEMENT].@sourceName;
			_copySkeletonXML[ConstValues.ANIMATIONS].appendChild(container);
			
			resetDestinationSkeletonData();
			//occur to update
			var temp:XML = selectedDestinationArmature;
			selectedDestinationArmature = null;
			selectedDestinationArmature = temp;
		}
		
		public function executeBehaviorDelete():void
		{
			for each (var behavior:XML in selectedMultipleDestinationBehaviors)
			{
				if (behavior.@original == false)
				{
					var behaviorName:String = behavior.@[ConstValues.A_NAME];
					delete _selectedDestinationArmature[ConstValues.ANIMATION][ConstValues.MOVEMENT].(@[ConstValues.A_NAME] == behaviorName)[0];
					_selectedDestinationArmatureName
					delete _copySkeletonXML[ConstValues.ANIMATIONS][ConstValues.ANIMATION].(@[ConstValues.A_NAME] == _selectedDestinationArmatureName)[ConstValues.MOVEMENT].(@[ConstValues.A_NAME] == behaviorName)[0];
				}
			}
			resetDestinationSkeletonData();
			//occur to update
			selectedDestinaionBehaviorList = _selectedDestinationArmature[ConstValues.ANIMATION][ConstValues.MOVEMENT].copy();
			destinationDisplayArmature = _copyFactory.buildArmature(_selectedDestinationArmature.@[ConstValues.A_NAME]);
			if (selectedDestinaionBehaviorList.length() > 0)
				playDestinationBehavior(selectedDestinaionBehaviorList[0]);
			checkBehaviorsCopyable();
			behaviorDeletable = false;
		}
		
		
		private function applyCopiedBoneToSkeletonXML(plattenDestinationBones:XMLList, destinationName:String):void
		{
			var originalArmature:XML = _copySkeletonXML[ConstValues.ARMATURES][ConstValues.ARMATURE].(@[ConstValues.A_NAME] == destinationName)[0];
			delete originalArmature[ConstValues.BONE].@[ConstValues.A_PARENT];
			for each (var bone:XML in plattenDestinationBones)
			{
				var parentName:String = bone.@[ConstValues.A_PARENT];
				if (parentName)
				{
					var boneName:String = bone.@[ConstValues.A_NAME];
					originalArmature[ConstValues.BONE].(@[ConstValues.A_NAME] == boneName).@[ConstValues.A_PARENT] = parentName;
				}
			}
		}
		
		
		private function resetDestinationSkeletonData():void
		{
			_skeletonData = XMLDataParser.parseSkeletonData(_copySkeletonXML);
			_copyFactory.addSkeletonData(_skeletonData);
		}
		
		private function checkBonesCopyable():void
		{
			if (selectedDestinationArmature == null || _selectedSourceArmature == null)
			{
				boneCopyable = false;
				behaviorCopyable = false;
			}
			else
			{
				if (_selectedSourceArmatureName == _selectedDestinationArmatureName)
				{
					//selected the same armature
					boneCopyable = false;
					behaviorCopyable = false;
				}
				else
				{
					_sharedBoneNames = generateSharedBonesInTree(selectedSourceBoneList, selectedDestinaionBonelist);
					
					if (_sharedBoneNames.length == 0)
					{
						trace("no shared bones");
						boneCopyable = false;
						behaviorCopyable = false;
					}
					else
					{
						//check bones
						var destinationBones:XMLList = selectedDestinaionBonelist.copy();
						var copiedDestinationBones:XMLList = copyBones(selectedSourceBoneList, destinationBones, _sharedBoneNames);
						copiedDestinationBones = generateBoneTree(copiedDestinationBones);
						if (destinationBones == copiedDestinationBones)
						{
							trace("it's the same after copied!");
							boneCopyable = false;
						}
						else
						{
							trace("boneCopyable");
							boneCopyable = true;
						}
						
					}
					
				}
			}
		}
		
		private function checkBehaviorsCopyable():void
		{
			if (selectedDestinationArmature == null || _selectedSourceArmature == null)
			{
				boneCopyable = false;
				behaviorCopyable = false;
			}
			else
			{
				if (_selectedSourceArmatureName == _selectedDestinationArmatureName)
				{
					//selected the same armature
					boneCopyable = false;
					behaviorCopyable = false;
				}
				else
				{
					var copiedDestinationBehaviors:XMLList = copyBehaviors(_selectedSourceArmatureName, selectedMultipleSourceBehaviors, _sourceAnimationData, selectedDestinaionBehaviorList, _sharedBoneNames, _plattenDestinationBoneList);
					if (selectedDestinaionBehaviorList == copiedDestinationBehaviors)
					{
						trace("Behavior is the same after copied!");
						behaviorCopyable = false;
					}
					else
					{
						behaviorCopyable = true;
					}
				}
			}
		}
		
		private function checkBehaviorsDeletable():void
		{
			if (selectedDestinationArmature == null)
			{
				behaviorDeletable = false;
			}
			else
			{
				var flag:Boolean = false;
				for each (var behavior:XML in selectedMultipleDestinationBehaviors)
				{
					if (behavior.@original == false)
					{
						flag = true;
						break;
					}
				}
				behaviorDeletable = flag;
			}
		}
		
		//return a platten bone list
		private static function copyBones(sourceBones:XMLList, destinationBones:XMLList, sharedBoneNames:Vector.<String>):XMLList
		{
			var plattenBoneList:XMLList = plattenBones(destinationBones);
			sourceBones = plattenBones(sourceBones);
			
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
		
		private static function getBoneParentName(boneName:String, targetBoneXMLList:XMLList, sourceBoneXMLList:XMLList):String
		{
			while(true)
			{
				var boneXML:XML = XMLDataParser.getElementsByAttribute(sourceBoneXMLList, ConstValues.A_NAME, boneName)[0];
				boneName = boneXML.attribute(ConstValues.A_PARENT);
				if(boneName)
				{
					boneXML = XMLDataParser.getElementsByAttribute(targetBoneXMLList, ConstValues.A_NAME, boneName)[0];
					if(boneXML)
					{
						break;
					}
				}
				else
				{
					break;
				}
			}
			return boneName;
		}
		
		private static function plattenBones(treeBones:XMLList):XMLList
		{
			var container:XML = <container/>;
			container.appendChild(treeBones.copy());
			var plattenBones:XMLList = container.descendants();
			delete plattenBones[ConstValues.BONE];
			return plattenBones;
		}
		
		private static function combineArmatureAndBehaviors(armatures:XMLList, behaviors:XMLList):void
		{
			for each (var behavior:XML in behaviors)
			{
				var behaviorName:String = behavior.@[ConstValues.A_NAME];
				var armature:XMLList = armatures.(@[ConstValues.A_NAME] == behaviorName);
				if (armature.length() == 1)
				{
					armature[0].appendChild(behavior);
				}
			}
		}
		
		private static function generateBoneTree(plattenBones:XMLList):XMLList
		{
			plattenBones = plattenBones.copy();
			var container:XML = <container/>;
			for each (var bone:XML in plattenBones)
			{
				var parentName:String = bone.@[ConstValues.A_PARENT];
				if (parentName)
				{
					var parentBone:XML = plattenBones.(@[ConstValues.A_NAME] == parentName)[0];
					if (parentBone)
					{
						if (parentBone != bone)
							parentBone.appendChild(bone);
						else
							throw(new Error("bone data error"));
					}
					else
					{
						delete bone.@[ConstValues.A_PARENT];
						container.appendChild(bone);
					}
				}
				else
					container.appendChild(bone);
			}
			return container.children();
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
		}
		
		private static function copyBehaviors(sourceArmatureName:String, sourceBehaviors:Vector.<Object>, sourceAnimationData:AnimationData, destinationBehaviors:XMLList, sharedBoneNames:Vector.<String>, plattenDestinationBoneList:XMLList):XMLList
		{
			var copyContainer:XML = <container/>
			//save the existing behaviors
			copyContainer.appendChild(destinationBehaviors.copy());
			
			for each (var sourceBehavior:XML in sourceBehaviors)
			{
				var sourceBehaviorName:String = sourceBehavior.@[ConstValues.A_NAME];
				if (destinationBehaviors.(@[ConstValues.A_NAME] == sourceBehaviorName).length() == 0)
				{
					copyContainer.appendChild(copyBehavior(sourceArmatureName, sourceBehaviorName, sourceBehavior, sourceAnimationData, sharedBoneNames, plattenDestinationBoneList));
				}
				else
				{
					//todo: Duplication of name, how to do in this case?
				}
			}
			
			return copyContainer.children();
		}
		
		private static function copyBehavior(sourceArmatureName:String, behaviorName:String, sourceBehavior:XML, sourceAnimationData:AnimationData, sharedBoneNames:Vector.<String>, plattenDestinationBoneList:XMLList):XML
		{
			var copiedBehavior:XML = sourceBehavior.copy();
			copiedBehavior.@[ConstValues.A_NAME] = behaviorName;
			copiedBehavior.@original = false;
			copiedBehavior.@sourceName = sourceArmatureName;
			//remove all children
			copiedBehavior.setChildren(new XMLList());
			
			var movmentData:MovementData = sourceAnimationData.getMovementData(behaviorName);
			var movementBoneXMLList:XMLList = sourceBehavior[ConstValues.BONE].copy();
			for each (var boneName:String in sharedBoneNames)
			{
				var movementBoneData:MovementBoneData = movmentData.getMovementBoneData(boneName);
				if (movementBoneData)
				{
					var boneFramesContainer:XML = sourceBehavior[ConstValues.BONE].(@[ConstValues.A_NAME] == boneName)[0].copy();
					delete boneFramesContainer[ConstValues.FRAME];
					
					//movementBoneXMLList will be changed in this function
					copyBoneFrameData(movementBoneData, plattenDestinationBoneList, boneName, movementBoneXMLList, boneFramesContainer);
					
					copiedBehavior.appendChild(boneFramesContainer);
				}
			}
			return copiedBehavior;
		}
		
		private static function copyBoneFrameData(movementBoneData:MovementBoneData, plattenDestinationBoneList:XMLList, boneName:String, movementBoneXMLList:XMLList, boneFramesContainer:XML):void
		{
			//找到目标骨骼和其父骨骼，重新计算相对新的父骨骼（可能骨骼从属关系在复制骨架的时候被改变了）坐标，并存储在_boneData中
			var boneXML:XML = XMLDataParser.getElementsByAttribute(plattenDestinationBoneList, ConstValues.A_NAME, boneName)[0];
			var parentName:String = boneXML.@[ConstValues.A_PARENT];
			var parentXML:XML = XMLDataParser.getElementsByAttribute(plattenDestinationBoneList, ConstValues.A_NAME, parentName)[0];
			var boneData:BoneData = new BoneData();
			XMLDataParser.parseBoneData(boneXML, parentXML, boneData);
			
			//找到当前源骨架同名骨骼以及其父骨骼的动画数据
			var movementBoneXML:XML = XMLDataParser.getElementsByAttribute(movementBoneXMLList, ConstValues.A_NAME, boneName)[0];
			var parentMovementBoneXML:XML = XMLDataParser.getElementsByAttribute(movementBoneXMLList, ConstValues.A_NAME, parentName)[0];
			
			//有父骨骼，则需要做准备工作，需要坐标变换
			if (parentMovementBoneXML)
			{
				var i:uint = 0;
				var parentTotalDuration:uint = 0;
				var totalDuration:uint = 0;
				var currentDuration:uint = 0;
				var parentFrameXMLList:XMLList = parentMovementBoneXML.elements(ConstValues.FRAME);
				var parentFrameCount:uint = parentFrameXMLList.length();
				var parentFrameXML:XML = null;
			}
			
			//遍历每个骨骼关键帧
			var frameXMLList:XMLList = movementBoneXML.elements(ConstValues.FRAME);
			var frameCount:uint = frameXMLList.length();
			var frameNode:BoneTransform = new BoneTransform;
			var parentFrameData:FrameData = new FrameData;
			var tweenFrameData:FrameData = new FrameData;
			var helpMatrix:Matrix = new Matrix;
			var helpPoint:Point = new Point;
			
			for (var j:int = 0; j < frameCount; j++)
			{
				var frameData:FrameData = movementBoneData._frameList[j];
				
				//目标的动画坐标为目标骨架坐标 +关键帧相对坐标
				frameNode.x = boneData.node.x + frameData.node.x;
				frameNode.y = boneData.node.y + frameData.node.y;
				frameNode.skewX = boneData.node.skewX + frameData.node.skewX;
				frameNode.skewY = boneData.node.skewY + frameData.node.skewY;
				frameNode.scaleX = boneData.node.scaleX + frameData.node.scaleX;
				frameNode.scaleY = boneData.node.scaleY + frameData.node.scaleY;
				frameNode.pivotX = boneData.node.pivotX + frameData.node.pivotX;
				frameNode.pivotY = boneData.node.pivotY + frameData.node.pivotY;
				
				//如果有从属关系
				if (parentMovementBoneXML)
				{
					//找到父级动画的当前关键帧
					while (i < parentFrameCount && (parentFrameXML ? (totalDuration < parentTotalDuration || totalDuration >= parentTotalDuration + currentDuration) : true))
					{
						parentFrameXML = parentFrameXMLList[i];
						parentTotalDuration += currentDuration;
						currentDuration = int(parentFrameXML.attribute(ConstValues.A_DURATION));
						i++;
					}
					XMLDataParser.parseFrameData(parentFrameXML, parentFrameData);
					
					//找到父级动画的下一个关键帧，并计算补间进度，因为动画的关键帧可能不是一一对应的
					var tweenFrameXML:XML = parentFrameXMLList[i];
					var progress:Number;
					if (tweenFrameXML)
					{
						progress = (totalDuration - parentTotalDuration) / currentDuration;
					}
					else
					{
						tweenFrameXML = parentFrameXML;
						progress = 0;
					}
					XMLDataParser.parseFrameData(tweenFrameXML, tweenFrameData);
					
					progress = Tween.getEaseValue(progress, parentFrameData.tweenEasing);
					
					//将两个XML转成的node计算出补间关键点，再转换为矩阵
					
					var parentNode:BoneTransform = new BoneTransform();
					TransformUtils.setOffSetNode(parentFrameData.node, tweenFrameData.node, parentNode, tweenFrameData.tweenRotate);
					TransformUtils.setTweenNode(parentFrameData.node, parentNode, parentNode, progress);
					
					TransformUtils.nodeToMatrix(parentNode, helpMatrix);
					
					//坐标变换
					helpPoint.x = frameNode.x;
					helpPoint.y = frameNode.y;
					helpPoint = helpMatrix.transformPoint(helpPoint);
					frameNode.x = helpPoint.x;
					frameNode.y = helpPoint.y;
					frameNode.skewX += parentFrameData.node.skewX;
					frameNode.skewY += parentFrameData.node.skewY;
				}
				
				//写入关键帧坐标
				var frameXML:XML = frameXMLList[j];
				totalDuration += int(frameXML.attribute(ConstValues.A_DURATION));
				frameXML.@[ConstValues.A_X] = frameNode.x;
				frameXML.@[ConstValues.A_Y] = frameNode.y;
				frameXML.@[ConstValues.A_SKEW_X] = frameNode.skewX * 180 / Math.PI;
				frameXML.@[ConstValues.A_SKEW_Y] = frameNode.skewY * 180 / Math.PI;
				frameXML.@[ConstValues.A_SCALE_X] = frameNode.scaleX;
				frameXML.@[ConstValues.A_SCALE_Y] = frameNode.scaleY;
				frameXML.@[ConstValues.A_PIVOT_X] = frameNode.pivotX;
				frameXML.@[ConstValues.A_PIVOT_Y] = frameNode.pivotY;
				boneFramesContainer.appendChild(frameXML);
			}
			
		}
		
		
		//for internal use
		
		private function get _selectedSourceArmatureName():String
		{
			return _selectedSourceArmature.@[ConstValues.A_NAME];
		}
		
		private function get _sourceAnimationData():AnimationData
		{
			return _skeletonData.getAnimationData(_selectedSourceArmatureName);
		}
		
		private function get _selectedDestinationArmatureName():String
		{
			return _selectedDestinationArmature.@[ConstValues.A_NAME];
		}
		
		private function get _plattenDestinationBoneList():XMLList
		{
			return _copySkeletonXML[ConstValues.ARMATURES][ConstValues.ARMATURE].(@[ConstValues.A_NAME] == _selectedDestinationArmatureName)[ConstValues.BONE];
		}
	}
}
