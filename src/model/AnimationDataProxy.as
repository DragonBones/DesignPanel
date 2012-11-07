package model{
	import dragonBones.objects.AnimationData;
	import dragonBones.objects.MovementBoneData;
	import dragonBones.objects.MovementData;
	import dragonBones.utils.ConstValues;
	import dragonBones.utils.generateAnimationData;
	
	import flash.events.Event;
	
	import message.MessageDispatcher;
	
	import mx.collections.XMLListCollection;
	
	/**
	 * Manage selected animation data
	 */
	public class AnimationDataProxy{
		public var movementsMC:XMLListCollection;
		
		private var xml:XML;
		private var movementsXMLList:XMLList;
		
		private var movementXML:XML;
		private var movementBonesXMLList:XMLList;
		
		private var movementBoneXML:XML;
		
		public function get animationName():String{
			return ImportDataProxy.getElementName(xml);
		}
		
		public function get movementName():String{
			return ImportDataProxy.getElementName(movementXML);
		}
		
		public function get boneName():String{
			return ImportDataProxy.getElementName(movementBoneXML);
		}
		
		public function get durationTo():int{
			if(!movementXML){
				return -1;
			}
			return int(movementXML.attribute(ConstValues.A_DURATION_TO));
		}
		public function set durationTo(_value:int):void{
			if(movementXML){
				movementXML[ConstValues.AT + ConstValues.A_DURATION_TO] = _value;
				updateMovement();
			}
		}
		
		public function get durationTween():int{
			if(movementXML?int(movementXML.attribute(ConstValues.A_DURATION)) == 1:true){
				return -1;
			}
			return int(movementXML.attribute(ConstValues.A_DURATION_TWEEN));
		}
		public function set durationTween(_value:int):void{
			if(movementXML){
				movementXML[ConstValues.AT + ConstValues.A_DURATION_TWEEN] = _value;
				updateMovement();
			}
		}
		
		public function get loop():Boolean{
			return movementXML?Boolean(int(movementXML.attribute(ConstValues.A_LOOP)) == 1):false;
		}
		public function set loop(_value:Boolean):void{
			if(movementXML){
				movementXML[ConstValues.AT + ConstValues.A_LOOP] = _value?1:0;
				updateMovement();
			}
		}
		
		public function get tweenEasing():Number{
			return movementXML?Number(movementXML.attribute(ConstValues.A_TWEEN_EASING)):-1.1;
		}
		public function set tweenEasing(_value:Number):void{
			if(movementXML){
				if(_value<-1){
					movementXML[ConstValues.AT + ConstValues.A_TWEEN_EASING] = NaN;
				}else{
					movementXML[ConstValues.AT + ConstValues.A_TWEEN_EASING] = _value;
				}
				updateMovement();
			}
		}
		
		public function get boneScale():Number{
			if(!movementBoneXML || int(movementXML.attribute(ConstValues.A_DURATION)) < 2){
				return NaN;
			}
			return Number(movementBoneXML.attribute(ConstValues.A_MOVEMENT_SCALE)) * 100;
		}
		public function set boneScale(_value:Number):void{
			if(movementBoneXML){
				movementBoneXML[ConstValues.AT + ConstValues.A_MOVEMENT_SCALE] = _value * 0.01;
				updateMovementBone();
			}
		}
		
		public function get boneDelay():Number{
			if(!movementBoneXML || int(movementXML.attribute(ConstValues.A_DURATION)) < 2){
				return NaN;
			}
			return Number(movementBoneXML.attribute(ConstValues.A_MOVEMENT_DELAY))* 100;
		}
		public function set boneDelay(_value:Number):void{
			if(movementBoneXML){
				movementBoneXML[ConstValues.AT + ConstValues.A_MOVEMENT_DELAY] = _value * 0.01;
				updateMovementBone();
			}
		}
		
		public function AnimationDataProxy(){
			movementsMC = new XMLListCollection();
		}
		
		internal function setData(_xml:XML):void{
			xml = _xml;
			if(xml){
				movementsXMLList = xml.elements(ConstValues.MOVEMENT);
			}else{
				movementsXMLList = null;
			}
			
			movementsMC.source = movementsXMLList;
			
			MessageDispatcher.dispatchEvent(MessageDispatcher.CHANGE_ANIMATION_DATA, animationName);
			
			changeMovement();
		}
		
		public function changeMovement(_movementName:String = null, _isChangedByArmature:Boolean = false):void{
			movementXML = ImportDataProxy.getElementByName(movementsXMLList, _movementName, true);
			if(movementXML){
				movementBonesXMLList = movementXML.elements(ConstValues.BONE);
			}else{
				movementBonesXMLList = null;
			}
			
			MessageDispatcher.dispatchEvent(MessageDispatcher.CHANGE_MOVEMENT_DATA, movementName, _isChangedByArmature);
			
			changeMovementBone(ImportDataProxy.getInstance().armatureDataProxy.boneName);
		}
		
		public function changeMovementBone(_boneName:String = null):void{
			var _movementBoneXML:XML = ImportDataProxy.getElementByName(movementBonesXMLList, _boneName, true);
			if(movementBoneXML == _movementBoneXML){
				return;
			}
			movementBoneXML = _movementBoneXML;
			MessageDispatcher.dispatchEvent(MessageDispatcher.CHANGE_MOVEMENT_BONE_DATA , boneName);
		}
		
		internal function updateBoneParent(_boneName:String):void{
			generateAnimationData(
				animationName, 
				xml, 
				ImportDataProxy.getInstance().skeletonData.getArmatureData(animationName),
				ImportDataProxy.getInstance().skeletonData.getAnimationData(animationName)
			);
		}
		
		private function updateMovement():void{
			var _animationData:AnimationData = ImportDataProxy.getInstance().skeletonData.getAnimationData(animationName);
			var _movementData:MovementData = _animationData.getData(movementName);
			
			_movementData.durationTo = durationTo;
			_movementData.durationTween = durationTween;
			_movementData.loop = loop;
			_movementData.tweenEasing = tweenEasing;
			
			if(!ImportDataProxy.getInstance().isExportedSource){
				JSFLProxy.getInstance().changeMovement(animationName, movementName, movementXML);
			}
			
			MessageDispatcher.dispatchEvent(MessageDispatcher.UPDATE_MOVEMENT_DATA, movementName);
		}
		
		private function updateMovementBone():void{
			var _animationData:AnimationData = ImportDataProxy.getInstance().skeletonData.getAnimationData(animationName);
			var _movementData:MovementData = _animationData.getData(movementName);
			var _movementBoneData:MovementBoneData = _movementData.getData(boneName);
			
			_movementBoneData.scale = boneScale * 0.01;
			_movementBoneData.delay = boneDelay * 0.01;
			if(_movementBoneData.delay > 0){
				_movementBoneData.delay -= 1;
			}
			
			if(!ImportDataProxy.getInstance().isExportedSource){
				var _movementXMLCopy:XML = movementXML.copy();
				delete _movementXMLCopy.elements(ConstValues.BONE).*;
				delete _movementXMLCopy[ConstValues.FRAME];
				JSFLProxy.getInstance().changeMovement(animationName, movementName, _movementXMLCopy);
			}
			
			MessageDispatcher.dispatchEvent(MessageDispatcher.UPDATE_MOVEMENT_BONE_DATA, movementName);
		}
	}
}