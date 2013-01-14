package model
{
	import dragonBones.Armature;
	import dragonBones.Bone;
	import dragonBones.animation.WorldClock;
	import dragonBones.factorys.BaseFactory;
	import dragonBones.objects.SkeletonData;
	import dragonBones.objects.XMLDataParser;
	import dragonBones.utils.ConstValues;
	
	import flash.events.EventDispatcher;
	
	[Bindable]
	public class CopyDataProxy extends EventDispatcher
	{
		private static var _instance:CopyDataProxy;
		
		//the structure data
		public var copyArmaturesData:XMLList;
		
		//the non-structure data for SkeletonData
		private var _copySkeletonXML:XML;
		
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
		private var _destinationBoneNames:XMLList;
		
		
		
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
				selectedDestinaionBonelist = _selectedDestinationArmature[ConstValues.BONE].copy();
				selectedDestinaionBehaviorList = _selectedDestinationArmature[ConstValues.ANIMATION][ConstValues.MOVEMENT].copy();
				destinationDisplayArmature = _copyFactory.buildArmature(_selectedDestinationArmature.@[ConstValues.A_NAME]);
				var behavious:XMLList = _selectedDestinationArmature[ConstValues.ANIMATION][ConstValues.MOVEMENT];
				if (behavious.length() > 0)
					selectedDestinationBehavior = behavious[0];
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
				var behaviors:XMLList = _selectedSourceArmature[ConstValues.ANIMATION][ConstValues.MOVEMENT];
				if (behaviors.length() > 0)
					selectedSourceBehavior = behaviors[0];
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
		
		//todo: complete this interface
		public function calculateChangedArmatures():Array
		{
			for each(var armatureName:String in copyArmaturesData.@[ConstValues.A_NAME])
			{
				var sourceBones:XML=ImportDataProxy.getInstance().skeletonXML[ConstValues.ARMATURES][ConstValues.ARMATURE].(@[ConstValues.A_NAME]==armatureName)[0];
				var destinationBones:XML=_copySkeletonXML[ConstValues.ARMATURES][ConstValues.ARMATURE].(@[ConstValues.A_NAME]==armatureName)[0];
				if(sourceBones!=destinationBones)
				{
					trace(armatureName," bone changed");
				}
				var sourceBehaviors:XML=ImportDataProxy.getInstance().skeletonXML[ConstValues.ANIMATIONS][ConstValues.ANIMATION].(@[ConstValues.A_NAME]==armatureName)[0];
				var destinationBehaviors:XML=_copySkeletonXML[ConstValues.ANIMATIONS][ConstValues.ANIMATION].(@[ConstValues.A_NAME]==armatureName)[0];
				if(sourceBehaviors!=destinationBehaviors)
				{
					trace(armatureName," behavior changed");
				}
			}
			return null;
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
			selectedDestinaionBonelist = boneTree;
			
			
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
			var copiedDestinationBehaviors:XMLList = copyBehaviors(selectedSourceBehaviorList, selectedDestinaionBehaviorList, _sharedBoneNames, _destinationBoneNames);
			var destinationName:String = selectedDestinationArmature.@[ConstValues.A_NAME];
			
			var temp:XMLList = copiedDestinationBehaviors.copy();
			delete temp.@original;
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
			_copySkeletonXML[ConstValues.ANIMATIONS].appendChild(container);
			
			resetDestinationSkeletonData();
			//occur to update
			var temp1:XML = selectedDestinationBehavior;
			var temp2:XML = selectedDestinationArmature;
			selectedDestinationArmature = null;
			selectedDestinationBehavior = null;
			selectedDestinationArmature = temp2;
			selectedDestinationBehavior = temp1;
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
			_copyFactory.addSkeletonData(XMLDataParser.parseSkeletonData(_copySkeletonXML));
			return;
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
				var sourceArmatureName:String = _selectedSourceArmature.@[ConstValues.A_NAME];
				var destinationArmatureName:String = _selectedDestinationArmature.@[ConstValues.A_NAME];
				if (sourceArmatureName == destinationArmatureName)
				{
					//selected the same armature
					boneCopyable = false;
					behaviorCopyable = false;
				}
				else
				{
					//var sourceBoneNames:XMLList=_copySkeletonXML[ConstValues.ARMATURES][ConstValues.ARMATURE].(@[ConstValues.A_NAME] == sourceArmatureName)[ConstValues.BONE].@[ConstValues.A_NAME];
					_destinationBoneNames = _copySkeletonXML[ConstValues.ARMATURES][ConstValues.ARMATURE].(@[ConstValues.A_NAME] == destinationArmatureName)[ConstValues.BONE].@[ConstValues.A_NAME];
					
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
						
						var copiedDestinationBehaviors:XMLList = copyBehaviors(selectedSourceBehaviorList, selectedDestinaionBehaviorList, _sharedBoneNames, _destinationBoneNames);
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
		private function copyBones(sourceBones:XMLList, destinationBones:XMLList, sharedBoneNames:Vector.<String>):XMLList
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
		
		
		private function plattenBones(treeBones:XMLList):XMLList
		{
			var container:XML = <container/>;
			container.appendChild(treeBones.copy());
			var plattenBones:XMLList = container.descendants();
			delete plattenBones[ConstValues.BONE];
			return plattenBones;
		}
		
		private function combineArmatureAndBehaviors(armatures:XMLList, behaviors:XMLList):void
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
		
		private function generateBoneTree(plattenBones:XMLList):XMLList
		{
			plattenBones = plattenBones.copy();
			var container:XML = <container/>;
			for each (var bone:XML in plattenBones)
			{
				var parentName:String = bone.@[ConstValues.A_PARENT];
				if (parentName)
				{
					var parentBone:XML = plattenBones.(@[ConstValues.A_NAME] == parentName)[0];
					if(parentBone)
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
		
		private function generateSharedBonesInTree(sourceBones:XMLList, destinationBones:XMLList):Vector.<String>
		{
			var sharedBones:Vector.<String> = new Vector.<String>;
			var container:XML = <container/>;
			container.appendChild(destinationBones);
			generateSharedBonesInTree2(sourceBones, container, sharedBones);
			return sharedBones;
		}
		
		private function generateSharedBonesInTree2(sourceBones:XMLList, container:XML, reciver:Vector.<String>):void
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
		
		
		
		private function copyBehaviors(sourceBehaviors:XMLList, destinationBehaviors:XMLList, sharedBoneNames:Vector.<String>, destinationBoneNames:XMLList):XMLList
		{
			var copyContainer:XML = <container/>
			copyContainer.appendChild(destinationBehaviors.copy());
			for each (var sourceBehavior:XML in sourceBehaviors)
			{
				var sourceBehaviorName:String = sourceBehavior.@[ConstValues.A_NAME];
				if (destinationBehaviors.(@[ConstValues.A_NAME] == sourceBehaviorName).length() == 0)
				{
					copyContainer.appendChild(copyBehavior(sourceBehaviorName, sourceBehavior, sharedBoneNames, destinationBoneNames));
				}
				else
				{
					//todo: how to do in this case?
				}
			}
			
			return copyContainer.children();
		}
		
		private function copyBehavior(behaviorName:String, sourceBehavior:XML, sharedBoneNames:Vector.<String>, destinationBoneNames:XMLList):XML
		{
			var copiedBehavior:XML = sourceBehavior.copy();
			copiedBehavior.@[ConstValues.A_NAME] = behaviorName;
			copiedBehavior.@original = false;
			//remove all children
			copiedBehavior.setChildren(new XMLList());
			
			for each (var boneName:String in destinationBoneNames)
			{
				if (sharedBoneNames.indexOf(boneName) != -1)
					copiedBehavior.appendChild(sourceBehavior[ConstValues.BONE].(@[ConstValues.A_NAME] == boneName));
				else
				{
					//todo: how to do in this case?
				}
			}
			return copiedBehavior;
		}
	
	}
}
