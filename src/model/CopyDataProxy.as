package model
{
	import dragonBones.Armature;
	import dragonBones.animation.WorldClock;
	import dragonBones.factorys.BaseFactory;
	import dragonBones.objects.AnimationData;
	import dragonBones.objects.BoneData;
	import dragonBones.objects.FrameData;
	import dragonBones.objects.MovementBoneData;
	import dragonBones.objects.MovementData;
	import dragonBones.objects.Node;
	import dragonBones.objects.SkeletonData;
	import dragonBones.objects.XMLDataParser;
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
		
		
		
		//when change these value,the playing animation will be auto changed
		private var _selectedSourceBehavior:XML;
		private var _selectedDestinationBehavior:XML;
		
		
		public var boneCopyable:Boolean;
		public var behaviorCopyable:Boolean;
		
		
		private var _sharedBoneNames:Vector.<String>;
		
		
		
		public function get selectedDestinationBehavior():*
		{
			return _selectedDestinationBehavior;
		}
		
		
		public function set selectedDestinationBehavior(value:*):void
		{
			_selectedDestinationBehavior = value;
			if (_selectedDestinationBehavior && _destinationDisplayArmature)
			{
				_destinationDisplayArmature.animation.gotoAndPlay(_selectedDestinationBehavior.@[ConstValues.A_NAME]);
			}
		}
		
		
		public function get selectedSourceBehavior():*
		{
			return _selectedSourceBehavior;
		}
		
		public function set selectedSourceBehavior(value:*):void
		{
			_selectedSourceBehavior = value;
			if (_selectedSourceBehavior && _sourceDisplayArmature)
			{
				_sourceDisplayArmature.animation.gotoAndPlay(_selectedSourceBehavior.@[ConstValues.A_NAME]);
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
				var armatureName:String = _selectedDestinationArmature[ConstValues.A_NAME];
				selectedDestinaionBonelist = _selectedDestinationArmature[ConstValues.BONE].copy();
				selectedDestinaionBehaviorList = _selectedDestinationArmature[ConstValues.ANIMATION][ConstValues.MOVEMENT].copy();
				destinationDisplayArmature = _copyFactory.buildArmature(_selectedDestinationArmature.@[ConstValues.A_NAME]);
				if (selectedDestinaionBehaviorList.length() > 0)
					selectedDestinationBehavior = selectedDestinaionBehaviorList[0];
				else
					selectedDestinationBehavior = null;
			}
			else
			{
				selectedDestinaionBonelist = null;
				selectedDestinaionBehaviorList = null;
				destinationDisplayArmature = null;
			}
			checkBonesCopyable();
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
					selectedSourceBehavior = selectedSourceBehaviorList[0];
				else
					selectedSourceBehavior = null;
			}
			else
			{
				selectedSourceBoneList = null;
				selectedSourceBehaviorList = null;
				sourceDisplayArmature = null;
			}
			checkBonesCopyable();
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
			
			var behaviors:XMLList = ImportDataProxy.getInstance().skeletonXML[ConstValues.ANIMATIONS][ConstValues.ANIMATION].copy();
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
			
			_copySkeletonXML = ImportDataProxy.getInstance().skeletonXML.copy();
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
				savingIndex++;
			}
			else
				completeSave();
		}
		
		public function save():void
		{
			waitingForSavingBehaviors = calculateChangedArmatures().children();
			savingIndex = 0;
			MessageDispatcher.addEventListener(JSFLProxy.COPY_MOVEMENT, saveOneBehavior);
			saveOneBehavior(null);
		}
		
		public function calculateChangedArmatures():XML
		{
			var changedBehaviors:XML = <container/>;
			for each (var armatureXML:XML in copyArmaturesData)
			{
				var armatureName:String = armatureXML.@[ConstValues.A_NAME];
				var sourceBones:XML = ImportDataProxy.getInstance().skeletonXML[ConstValues.ARMATURES][ConstValues.ARMATURE].(@[ConstValues.A_NAME] == armatureName)[0];
				var destinationBones:XML = _copySkeletonXML[ConstValues.ARMATURES][ConstValues.ARMATURE].(@[ConstValues.A_NAME] == armatureName)[0];
				if (sourceBones != destinationBones)
				{
					trace(armatureName, " bone changed");
				}
				var sourceBehaviors:XML = ImportDataProxy.getInstance().skeletonXML[ConstValues.ANIMATIONS][ConstValues.ANIMATION].(@[ConstValues.A_NAME] == armatureName)[0];
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
			
			selectedSourceBehavior = null;
			selectedDestinationBehavior = null;
			
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
			var temp1:XML = selectedDestinationBehavior;
			var temp2:XML = selectedDestinationArmature;
			selectedDestinationArmature = null;
			selectedDestinationBehavior = null;
			selectedDestinationArmature = temp2;
			selectedDestinationBehavior = temp1;
		}
		
		
		public function executeBehaviorCopy():void
		{
			var copiedDestinationBehaviors:XMLList = copyBehaviors(_selectedSourceArmatureName, selectedSourceBehaviorList, _sourceAnimationData, selectedDestinaionBehaviorList, _sharedBoneNames, _plattenDestinationBoneList);
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
			var selectedBehaviorName:String = selectedDestinationBehavior ? selectedDestinationBehavior.@[ConstValues.A_NAME] : null;
			selectedDestinationArmature = null;
			selectedDestinationBehavior = null;
			selectedDestinationArmature = temp;
			if (selectedBehaviorName)
				selectedDestinationBehavior = selectedDestinationArmature[ConstValues.ANIMATION][ConstValues.MOVEMENT].(@[ConstValues.A_NAME] == selectedBehaviorName)[0];
			else
				selectedDestinationBehavior = selectedDestinationArmature[ConstValues.ANIMATION][ConstValues.MOVEMENT][0];
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
			return;
		}
		
		public function checkBonesCopyable():void
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
						
						
						//check behaviors
						var copiedDestinationBehaviors:XMLList = copyBehaviors(_selectedSourceArmatureName, selectedSourceBehaviorList, _sourceAnimationData, selectedDestinaionBehaviorList, _sharedBoneNames, _plattenDestinationBoneList);
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
		}
		
		
		
		//return a platten bone list
		private static function copyBones(sourceBones:XMLList, destinationBones:XMLList, sharedBoneNames:Vector.<String>):XMLList
		{
			var plattenBones:XMLList = plattenBones(destinationBones);
			delete plattenBones.@[ConstValues.A_PARENT];
			
			var container:XML = <container/>;
			container.appendChild(sourceBones.copy());
			for each (var boneName:String in sharedBoneNames)
			{
				var parentName:String = container.descendants().(@[ConstValues.A_NAME] == boneName).@[ConstValues.A_PARENT];
				if (parentName)
					plattenBones.(@[ConstValues.A_NAME] == boneName).@[ConstValues.A_PARENT] = parentName;
			}
			return plattenBones;
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
		
		private static function generateSharedBonesInTree2(sourceBones:XMLList, container:XML, reciver:Vector.<String>):void
		{
			for each (var bone:XML in sourceBones)
			{
				var boneName:String = bone.@[ConstValues.A_NAME];
				if (container.descendants().(@[ConstValues.A_NAME] == boneName).length())
				{
					reciver.push(boneName);
					generateSharedBonesInTree2(bone.children(), container, reciver);
				}
			}
		}
		
		
		
		private static function copyBehaviors(sourceArmatureName:String, sourceBehaviors:XMLList, sourceAnimationData:AnimationData, destinationBehaviors:XMLList, sharedBoneNames:Vector.<String>, plattenDestinationBoneList:XMLList):XMLList
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
			var movementBoneXMLList:XMLList = sourceBehavior[ConstValues.BONE];
			for each (var boneName:String in sharedBoneNames)
			{
				var movementBoneData:MovementBoneData = movmentData.getMovementBoneData(boneName);
				if (movementBoneData)
				{
					var boneFramesContainer:XML = sourceBehavior[ConstValues.BONE].(@[ConstValues.A_NAME] == boneName)[0].copy();
					delete boneFramesContainer[ConstValues.FRAME];
					
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
			var _boneData:BoneData = new BoneData;
			XMLDataParser.parseBoneData(boneXML, parentXML, _boneData);
			
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
			var _frameNode:Node = new Node;
			var _parentFrameData:FrameData = new FrameData;
			var _tweenFrameData:FrameData = new FrameData;
			var _helpMatrix:Matrix = new Matrix;
			var _helpPoint:Point = new Point;
			
			for (var j:int = 0; j < frameCount; j++)
			{
				var frameData:FrameData = movementBoneData.getFrameDataAt(j);
				
				//目标的动画坐标为目标骨架坐标 +关键帧相对坐标
				_frameNode.x = _boneData.x + frameData.x;
				_frameNode.y = _boneData.y + frameData.y;
				_frameNode.skewX = _boneData.skewX + frameData.skewX;
				_frameNode.skewY = _boneData.skewY + frameData.skewY;
				_frameNode.scaleX = _boneData.scaleX + frameData.scaleX;
				_frameNode.scaleY = _boneData.scaleY + frameData.scaleY;
				_frameNode.pivotX = _boneData.pivotX + frameData.pivotX;
				_frameNode.pivotY = _boneData.pivotY + frameData.pivotY;
				
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
					XMLDataParser.parseFrameData(parentFrameXML, _parentFrameData);
					
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
					XMLDataParser.parseFrameData(tweenFrameXML, _tweenFrameData);
					
					//将两个XML转成的node计算出补间关键点，再转换为矩阵
					var parentNode:Node = TransformUtils.getTweenNode(_parentFrameData, _tweenFrameData, progress, _parentFrameData.tweenEasing);
					TransformUtils.nodeToMatrix(parentNode, _helpMatrix);
					
					//坐标变换
					_helpPoint.x = _frameNode.x;
					_helpPoint.y = _frameNode.y;
					_helpPoint = _helpMatrix.transformPoint(_helpPoint);
					_frameNode.x = _helpPoint.x;
					_frameNode.y = _helpPoint.y;
					_frameNode.skewX += _parentFrameData.skewX;
					_frameNode.skewY += _parentFrameData.skewY;
				}
				
				//写入关键帧坐标
				var frameXML:XML = frameXMLList[j].copy();
				totalDuration += int(frameXML.attribute(ConstValues.A_DURATION));
				frameXML.@[ConstValues.A_X] = _frameNode.x;
				frameXML.@[ConstValues.A_Y] = _frameNode.y;
				frameXML.@[ConstValues.A_SKEW_X] = _frameNode.skewX * 180 / Math.PI;
				frameXML.@[ConstValues.A_SKEW_Y] = _frameNode.skewY * 180 / Math.PI;
				frameXML.@[ConstValues.A_SCALE_X] = _frameNode.scaleX;
				frameXML.@[ConstValues.A_SCALE_Y] = _frameNode.scaleY;
				frameXML.@[ConstValues.A_PIVOT_X] = _frameNode.pivotX;
				frameXML.@[ConstValues.A_PIVOT_Y] = _frameNode.pivotY;
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
