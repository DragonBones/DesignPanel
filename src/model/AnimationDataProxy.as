package model
{
	import dragonBones.objects.AnimationData;
	import dragonBones.objects.MovementBoneData;
	import dragonBones.objects.MovementData;
	import dragonBones.objects.XMLDataParser;
	import dragonBones.utils.ConstValues;
	import dragonBones.utils.dragonBones_internal;
	
	import flash.events.Event;
	
	import message.MessageDispatcher;
	
	import mx.collections.XMLListCollection;
	
	use namespace dragonBones_internal;
	
	/**
	 * Manage selected animation data
	 */
	public class AnimationDataProxy
	{
		public var movementsMC:XMLListCollection;
		
		private var _xml:XML;
		private var _movementsXMLList:XMLList;
		
		private var _movementXML:XML;
		private var _movementBonesXMLList:XMLList;
		
		private var _movementBoneXML:XML;
		
		public function get animationName():String
		{
			return ImportDataProxy.getElementName(_xml);
		}
		
		public function get movementName():String
		{
			return ImportDataProxy.getElementName(_movementXML);
		}
		
		public function get boneName():String
		{
			return ImportDataProxy.getElementName(_movementBoneXML);
		}
		
		public function get durationTo():Number
		{
			if(!_movementXML)
			{
				return -1;
			}
			return int(_movementXML.attribute(ConstValues.A_DURATION_TO)) / ImportDataProxy.getInstance().frameRate;
		}
		public function set durationTo(value:Number):void
		{
			if(_movementXML)
			{
				_movementXML[ConstValues.AT + ConstValues.A_DURATION_TO] = Math.round(value * ImportDataProxy.getInstance().frameRate);
				updateMovement();
			}
		}
		
		public function get durationTween():Number
		{
			if(_movementXML?int(_movementXML.attribute(ConstValues.A_DURATION)) == 1:true)
			{
				return -1;
			}
			return int(_movementXML.attribute(ConstValues.A_DURATION_TWEEN)) / ImportDataProxy.getInstance().frameRate;
		}
		public function set durationTween(value:Number):void
		{
			if(_movementXML)
			{
				_movementXML[ConstValues.AT + ConstValues.A_DURATION_TWEEN] = Math.round(value * ImportDataProxy.getInstance().frameRate);
				updateMovement();
			}
		}
		
		public function get loop():Boolean
		{
			return _movementXML?Boolean(int(_movementXML.attribute(ConstValues.A_LOOP)) == 1):false;
		}
		public function set loop(value:Boolean):void
		{
			if(_movementXML)
			{
				_movementXML[ConstValues.AT + ConstValues.A_LOOP] = value?1:0;
				updateMovement();
			}
		}
		
		public function get tweenEasing():Number
		{
			return _movementXML?Number(_movementXML.attribute(ConstValues.A_TWEEN_EASING)):-1.1;
		}
		public function set tweenEasing(value:Number):void
		{
			if(_movementXML)
			{
				if(value<-1)
				{
					_movementXML[ConstValues.AT + ConstValues.A_TWEEN_EASING] = NaN;
				}
				else
				{
					_movementXML[ConstValues.AT + ConstValues.A_TWEEN_EASING] = value;
				}
				updateMovement();
			}
		}
		
		public function get boneScale():Number
		{
			if(!_movementBoneXML || int(_movementXML.attribute(ConstValues.A_DURATION)) < 2)
			{
				return NaN;
			}
			return Number(_movementBoneXML.attribute(ConstValues.A_MOVEMENT_SCALE)) * 100;
		}
		public function set boneScale(value:Number):void
		{
			if(_movementBoneXML)
			{
				_movementBoneXML[ConstValues.AT + ConstValues.A_MOVEMENT_SCALE] = value * 0.01;
				updateMovementBone();
			}
		}
		
		public function get boneDelay():Number
		{
			if(!_movementBoneXML || int(_movementXML.attribute(ConstValues.A_DURATION)) < 2)
			{
				return NaN;
			}
			return Number(_movementBoneXML.attribute(ConstValues.A_MOVEMENT_DELAY))* 100;
		}
		public function set boneDelay(value:Number):void
		{
			if(_movementBoneXML)
			{
				_movementBoneXML[ConstValues.AT + ConstValues.A_MOVEMENT_DELAY] = value * 0.01;
				updateMovementBone();
			}
		}
		
		public function AnimationDataProxy()
		{
			movementsMC = new XMLListCollection();
		}
		
		internal function setData(xml:XML):void
		{
			_xml = xml;
			if(_xml)
			{
				_movementsXMLList = _xml.elements(ConstValues.MOVEMENT);
			}
			else
			{
				_movementsXMLList = null;
			}
			
			movementsMC.source = _movementsXMLList;
			
			MessageDispatcher.dispatchEvent(MessageDispatcher.CHANGE_ANIMATION_DATA, animationName);
			
			changeMovement();
		}
		
		public function changeMovement(movementName:String = null, isChangedByArmature:Boolean = false):void
		{
			_movementXML = ImportDataProxy.getElementByName(_movementsXMLList, movementName, true);
			if(_movementXML)
			{
				_movementBonesXMLList = _movementXML.elements(ConstValues.BONE);
			}
			else
			{
				_movementBonesXMLList = null;
			}
			
			MessageDispatcher.dispatchEvent(MessageDispatcher.CHANGE_MOVEMENT_DATA, this.movementName, isChangedByArmature);
			
			changeMovementBone(ImportDataProxy.getInstance().armatureDataProxy.boneName);
		}
		
		public function changeMovementBone(boneName:String = null):void
		{
			var movementBoneXML:XML = ImportDataProxy.getElementByName(_movementBonesXMLList, boneName, true);
			if(movementBoneXML == _movementBoneXML)
			{
				return;
			}
			_movementBoneXML = movementBoneXML;
			MessageDispatcher.dispatchEvent(MessageDispatcher.CHANGE_MOVEMENT_BONE_DATA , this.boneName);
		}
		
		internal function updateBoneParent(boneName:String):void
		{
			XMLDataParser.parseAnimationData(_xml, ImportDataProxy.getInstance().skeletonData);
		}
		
		private function updateMovement():void
		{
			var animationData:AnimationData = ImportDataProxy.getInstance().skeletonData.getAnimationData(animationName);
			var movementData:MovementData = animationData.getMovementData(movementName);
			
			movementData.durationTo = durationTo;
			movementData.durationTween = durationTween;
			movementData.loop = loop;
			movementData.tweenEasing = tweenEasing;
			
			if(!ImportDataProxy.getInstance().isExportedSource)
			{
				JSFLProxy.getInstance().changeMovement(animationName, movementName, _movementXML);
			}
			
			MessageDispatcher.dispatchEvent(MessageDispatcher.UPDATE_MOVEMENT_DATA, movementName);
		}
		
		private function updateMovementBone():void
		{
			var animationData:AnimationData = ImportDataProxy.getInstance().skeletonData.getAnimationData(animationName);
			var movementData:MovementData = animationData.getMovementData(movementName);
			var movementBoneData:MovementBoneData = movementData.getMovementBoneData(boneName);
			
			movementBoneData.scale = boneScale * 0.01;
			movementBoneData.delay = boneDelay * 0.01;
			if(movementBoneData.delay > 0)
			{
				movementBoneData.delay -= 1;
			}
			
			if(!ImportDataProxy.getInstance().isExportedSource)
			{
				var movementXMLCopy:XML = _movementXML.copy();
				delete movementXMLCopy.elements(ConstValues.BONE).*;
				delete movementXMLCopy[ConstValues.FRAME];
				JSFLProxy.getInstance().changeMovement(animationName, movementName, movementXMLCopy);
			}
			
			MessageDispatcher.dispatchEvent(MessageDispatcher.UPDATE_MOVEMENT_BONE_DATA, movementName);
		}
	}
}