package control
{
	import dragonBones.objects.AnimationData;
	import dragonBones.objects.ArmatureData;
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
	
	import flash.geom.Matrix;
	import flash.geom.Point;
	
	import message.Message;
	import message.MessageDispatcher;
	
	import model.JSFLProxy;
	
	use namespace dragonBones_internal;
	
	public class CopyArmatureCommand
	{
		public static const instance:CopyArmatureCommand = new CopyArmatureCommand();
		
		private var _boneData:BoneData;
		private var _frameNode:Node;
		private var _parentFrameData:FrameData;
		private var _tweenFrameData:FrameData;
		private var _helpMatrix:Matrix;
		private var _helpPoint:Point;
		
		public function CopyArmatureCommand()
		{
			_boneData = new BoneData();
			_frameNode = new Node();
			_parentFrameData = new FrameData();
			_tweenFrameData = new FrameData();
			_helpMatrix = new Matrix();
			_helpPoint = new Point();
		}
		
		public function copyArmatureFrom(targetArmatureXML:XML, sourceArmatureXML:XML, sourceAnimationXML:XML, skeletonData:SkeletonData):void
		{
			targetArmatureXML = targetArmatureXML.copy();
			var targetBoneXMLList:XMLList = targetArmatureXML.elements(ConstValues.BONE);
			var sourceBoneXMLList:XMLList = sourceArmatureXML.elements(ConstValues.BONE);
			//
			var boneNames:Object = {};
			for each(var targetBoneXML:XML in targetBoneXMLList)
			{
				var boneName:String = targetBoneXML.attribute(ConstValues.A_NAME);
				var sourceBoneXML:XML = XMLDataParser.getElementsByAttribute(sourceBoneXMLList, ConstValues.A_NAME, boneName)[0];
				
				if(sourceBoneXML)
				{
					var parentName:String = getBoneParentName(boneName, targetBoneXMLList, sourceBoneXMLList);
					if(parentName)
					{
						targetBoneXML[ConstValues.AT + ConstValues.A_PARENT] = parentName;
						boneNames[boneName] = parentName;
					}
					else
					{
						delete targetBoneXML[ConstValues.AT + ConstValues.A_PARENT];
						boneNames[boneName] = false;
					}
				}
			}
			
			var boneList:Array = [];
			for(boneName in boneNames)
			{
				parentName = boneNames[boneName];
				var depth:int = 0;
				while(parentName)
				{
					depth ++;
					parentName = boneNames[parentName];
				}
				boneList.push({depth:depth, boneName:boneName});
			}
			var length:int = boneList.length;
			if(length > 0)
			{
				boneList.sortOn("depth", Array.NUMERIC);
				var i:int = 0;
				while(i < length)
				{
					boneList[i] = boneList[i].boneName;
					i ++;
				}
			}
			
			var targetArmatureName:String = targetArmatureXML.attribute(ConstValues.A_NAME);
			var sourceArmatureName:String = sourceArmatureXML.attribute(ConstValues.A_NAME);
			//
			sourceAnimationXML = sourceAnimationXML.copy();
			var targetAramtureData:ArmatureData = skeletonData.getArmatureData(targetArmatureName);
			var sourceAnimationData:AnimationData = skeletonData.getAnimationData(sourceArmatureName);
			changeAnimationXMLToRelativeValue(boneList, targetBoneXMLList, sourceAnimationXML, targetAramtureData, sourceAnimationData);
			
			JSFLProxy.getInstance().copyArmatureFrom(targetArmatureName, sourceArmatureName, targetArmatureXML, sourceAnimationXML);
		}
		
		private function changeAnimationXMLToRelativeValue(boneList:Array, targetBoneXMLList:XMLList, sourceAnimationXML:XML, targetAramtureData:ArmatureData, sourceAnimationData:AnimationData):void
		{
			var movementList:Vector.<String> = sourceAnimationData.movementList;
			
			for each(var movementName:String in movementList)
			{
				var movementData:MovementData = sourceAnimationData.getMovementData(movementName);
				var movementXML:XML = XMLDataParser.getElementsByAttribute(sourceAnimationXML.elements(ConstValues.MOVEMENT), ConstValues.A_NAME, movementName)[0];
				
				for each(var boneName:String in boneList)
				{
					var movementBoneData:MovementBoneData = movementData.getMovementBoneData(boneName);
					if(movementBoneData)
					{
						var boneXML:XML = XMLDataParser.getElementsByAttribute(targetBoneXMLList, ConstValues.A_NAME, boneName)[0];
						var parentName:String = boneXML.attribute(ConstValues.A_PARENT);
						var parentXML:XML = XMLDataParser.getElementsByAttribute(targetBoneXMLList, ConstValues.A_NAME, parentName)[0];
						XMLDataParser.parseBoneData(boneXML, parentXML, _boneData);
						
						var movementBoneXMLList:XMLList = movementXML.elements(ConstValues.BONE);
						var movementBoneXML:XML = XMLDataParser.getElementsByAttribute(movementBoneXMLList, ConstValues.A_NAME, boneName)[0];
						var parentMovementBoneXML:XML = XMLDataParser.getElementsByAttribute(movementBoneXMLList, ConstValues.A_NAME, parentName)[0];
						
						if(parentMovementBoneXML)
						{
							var i:uint = 0;
							var parentTotalDuration:uint = 0;
							var totalDuration:uint = 0;
							var currentDuration:uint = 0;
							var parentFrameXMLList:XMLList = parentMovementBoneXML.elements(ConstValues.FRAME);
							var parentFrameCount:uint = parentFrameXMLList.length();
							var parentFrameXML:XML = null;
						}
						
						var frameXMLList:XMLList = movementBoneXML.elements(ConstValues.FRAME);
						var frameCount:uint = frameXMLList.length();
						for(var j:int = 0;j < frameCount;j ++)
						{
							var frameXML:XML = frameXMLList[j];
							var frameData:FrameData = movementBoneData.getFrameDataAt(j);
							
							_frameNode.x = _boneData.x + frameData.x;
							_frameNode.y = _boneData.y + frameData.y;
							_frameNode.skewX = _boneData.skewX + frameData.skewX;
							_frameNode.skewY = _boneData.skewY + frameData.skewY;
							_frameNode.scaleX = _boneData.scaleX + frameData.scaleX;
							_frameNode.scaleY = _boneData.scaleY + frameData.scaleY;
							_frameNode.pivotX = _boneData.pivotX + frameData.pivotX;
							_frameNode.pivotY = _boneData.pivotY + frameData.pivotY;
							
							if(parentMovementBoneXML)
							{
								while(i < parentFrameCount && (parentFrameXML?(totalDuration < parentTotalDuration || totalDuration >= parentTotalDuration + currentDuration):true))
								{
									parentFrameXML = parentFrameXMLList[i];
									parentTotalDuration += currentDuration;
									currentDuration = int(parentFrameXML.attribute(ConstValues.A_DURATION));
									i++;
								}
								
								XMLDataParser.parseFrameData(parentFrameXML, _parentFrameData);
								
								var tweenFrameXML:XML = parentFrameXMLList[i];
								var progress:Number;
								if(tweenFrameXML)
								{
									progress = (totalDuration - parentTotalDuration) / currentDuration;
								}
								else
								{
									tweenFrameXML = parentFrameXML;
									progress = 0;
								}
								XMLDataParser.parseFrameData(tweenFrameXML, _tweenFrameData);
								var parentNode:Node = TransformUtils.getTweenNode(_parentFrameData, _tweenFrameData, progress, _parentFrameData.tweenEasing);
								TransformUtils.nodeToMatrix(parentNode, _helpMatrix);
								
								_helpPoint.x = _frameNode.x;
								_helpPoint.y = _frameNode.y;
								_helpPoint = _helpMatrix.transformPoint(_helpPoint);
								_frameNode.x = _helpPoint.x;
								_frameNode.y = _helpPoint.y;
								_frameNode.skewX += _parentFrameData.skewX;
								_frameNode.skewY += _parentFrameData.skewY;
							}
							totalDuration += int(frameXML.attribute(ConstValues.A_DURATION));
							
							frameXML[ConstValues.AT + ConstValues.A_X] = _frameNode.x;
							frameXML[ConstValues.AT + ConstValues.A_Y] = _frameNode.y;
							frameXML[ConstValues.AT + ConstValues.A_SKEW_X] = _frameNode.skewX * 180 / Math.PI;
							frameXML[ConstValues.AT + ConstValues.A_SKEW_Y] = _frameNode.skewY * 180 / Math.PI;
							frameXML[ConstValues.AT + ConstValues.A_SCALE_X] = _frameNode.scaleX;
							frameXML[ConstValues.AT + ConstValues.A_SCALE_Y] = _frameNode.scaleY;
							frameXML[ConstValues.AT + ConstValues.A_PIVOT_X] = _frameNode.pivotX;
							frameXML[ConstValues.AT + ConstValues.A_PIVOT_Y] = _frameNode.pivotY;
						}
					}
				}
			}
		}
		
		private function getBoneParentName(boneName:String, targetBoneXMLList:XMLList, sourceBoneXMLList:XMLList):String
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
	}
}