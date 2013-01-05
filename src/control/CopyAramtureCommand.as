package control
{
	import dragonBones.objects.AnimationData;
	import dragonBones.objects.FrameData;
	import dragonBones.objects.MovementBoneData;
	import dragonBones.objects.MovementData;
	import dragonBones.objects.XMLDataParser;
	import dragonBones.utils.ConstValues;
	
	import message.Message;
	import message.MessageDispatcher;
	
	import model.JSFLProxy;
	
	public class CopyAramtureCommand
	{
		public static const instance:CopyAramtureCommand = new CopyAramtureCommand();
		
		public function CopyAramtureCommand()
		{
			
		}
		
		public function copyArmatureFrom(copyAramtureXML:XML, rawArmatureXML:XML, copyAnimationXML:XML, copyAnimationData:AnimationData):void
		{
			rawArmatureXML = rawArmatureXML.copy();
			var copyBoneXMLList:XMLList = copyAramtureXML.elements(ConstValues.BONE);
			var rawBoneXMLList:XMLList = rawArmatureXML.elements(ConstValues.BONE);
			//
			for each(var rawBoneXML:XML in rawBoneXMLList)
			{
				var boneName:String = rawBoneXML.attribute(ConstValues.A_NAME);
				var copyBoneXML:XML = XMLDataParser.getElementsByAttribute(copyBoneXMLList, ConstValues.A_NAME, boneName)[0];
				
				if(copyBoneXML)
				{
					var parentName:String = getBoneParentName(boneName, copyBoneXMLList, rawBoneXMLList);
					if(parentName)
					{
						rawBoneXML[ConstValues.AT + ConstValues.A_PARENT] = parentName;
					}
					else
					{
						delete rawBoneXML[ConstValues.AT + ConstValues.A_PARENT];
					}
				}
			}
			//
			copyAnimationXML = copyAnimationXML.copy();
			changeAnimationXMLToRelativeValue(rawBoneXMLList, copyAnimationXML, copyAnimationData);
			
			var copyArmatureName:String = copyAramtureXML.attribute(ConstValues.A_NAME);
			var rawArmatureName:String = rawArmatureXML.attribute(ConstValues.A_NAME);
			JSFLProxy.getInstance().copyArmatureFrom(copyArmatureName, rawArmatureName, rawArmatureXML, copyAnimationXML);
		}
		
		private function changeAnimationXMLToRelativeValue(rawBoneXMLList:XMLList, copyAnimationXML:XML, copyAnimationData:AnimationData):void
		{
			var movementList:Vector.<String> = copyAnimationData.movementList;
			
			for each(var boneXML:XML in rawBoneXMLList)
			{
				var boneName:String = boneXML.attribute(ConstValues.A_NAME);
				var x:Number = Number(boneXML.attribute(ConstValues.A_X));
				var y:Number = Number(boneXML.attribute(ConstValues.A_Y));
				var scaleX:Number = Number(boneXML.attribute(ConstValues.A_SCALE_X));
				var scaleY:Number = Number(boneXML.attribute(ConstValues.A_SCALE_Y));
				var skewX:Number = Number(boneXML.attribute(ConstValues.A_SKEW_X));
				var skewY:Number = Number(boneXML.attribute(ConstValues.A_SKEW_Y));
				var pivotX:Number = Number(boneXML.attribute(ConstValues.A_PIVOT_X));
				var pivotY:Number = Number(boneXML.attribute(ConstValues.A_PIVOT_Y));
				
				for each(var movement:String in movementList)
				{
					var movementData:MovementData = copyAnimationData.getMovementData(movement);
					var movementBoneData:MovementBoneData = movementData.getMovementBoneData(boneName);
					if(movementBoneData)
					{
						var movementXML:XML = XMLDataParser.getElementsByAttribute(copyAnimationXML.elements(ConstValues.MOVEMENT), ConstValues.A_NAME, movement)[0];
						var movementBoneXML:XML = XMLDataParser.getElementsByAttribute(movementXML.elements(ConstValues.BONE), ConstValues.A_NAME, boneName)[0];
						var frameXMLList:XMLList = movementBoneXML.elements(ConstValues.FRAME);
						for each(var frameXML:XML in frameXMLList)
						{
							var index:int = frameXML.childIndex();
							var frameData:FrameData = movementBoneData.getFrameDataAt(index);
							frameXML[ConstValues.AT + ConstValues.A_X] = x + frameData.x;
							frameXML[ConstValues.AT + ConstValues.A_Y] = y + frameData.y;
							frameXML[ConstValues.AT + ConstValues.A_SCALE_X] = scaleX + frameData.scaleX;
							frameXML[ConstValues.AT + ConstValues.A_SCALE_Y] = scaleY + frameData.scaleY;
							frameXML[ConstValues.AT + ConstValues.A_SKEW_X] = skewX + frameData.skewX * 180 / Math.PI;
							frameXML[ConstValues.AT + ConstValues.A_SKEW_Y] = skewY + frameData.skewY * 180 / Math.PI;
							frameXML[ConstValues.AT + ConstValues.A_PIVOT_X] = pivotX + frameData.pivotX;
							frameXML[ConstValues.AT + ConstValues.A_PIVOT_Y] = pivotY + frameData.pivotY;
						}
					}
				}
			}
		}
		
		private function getBoneParentName(boneName:String, copyBoneXMLList:XMLList, rawBoneXMLList:XMLList):String
		{
			while(true)
			{
				var boneXML:XML = XMLDataParser.getElementsByAttribute(copyBoneXMLList, ConstValues.A_NAME, boneName)[0];
				boneName = boneXML.attribute(ConstValues.A_PARENT);
				if(boneName)
				{
					boneXML = XMLDataParser.getElementsByAttribute(rawBoneXMLList, ConstValues.A_NAME, boneName)[0];
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