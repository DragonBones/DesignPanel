package core.utils
{
	import dragonBones.animation.TimelineState;
	import dragonBones.objects.DBTransform;
	import dragonBones.utils.TransformUtil;
	
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;

	public class DataUtils
	{
		private static const HALF_PI:Number = Math.PI * 0.5;
		private static const DOUBLE_PI:Number = Math.PI * 2;
		
		private static const _helpMatrix:Matrix = new Matrix();
		
		public static function xmlToObject(xml:XML, listNames:Vector.<String> = null):Object
		{
			if (xml == null)
			{
				return null;
			}
			
			var result:Object;
			var isSimpleType:Boolean = false;
			
			if (xml.children().length() > 0 && xml.hasSimpleContent())
			{
				isSimpleType = true;
				result = ComplexString.simpleType(xml.toString());
			} 
			else if (xml.hasComplexContent())
			{
				result = {};
				for each(var childXML:XML in xml.elements())
				{
					var objectName:String = childXML.localName();
					var object:Object = xmlToObject(childXML, listNames);
					var existing:Object = result[objectName];
					if (existing != null)
					{
						if (existing is Array)
						{
							existing.push(object);
						} 
						else 
						{
							existing = [existing];
							existing.push(object);
							result[objectName] = existing;
						}
					}
					else if(listNames && listNames.indexOf(objectName) >= 0)
					{
						result[objectName] = [object];
					}
					else
					{
						result[objectName] = object;
					}
				}
			}
			
			for each(var attributeXML:XML in xml.attributes())
			{
				/*if (attribute == "xmlns" || attribute.indexOf("xmlns:") != -1)
				{
				continue;
				}*/
				if (result == null)
				{
					result = {};
				}
				if (isSimpleType && !(result is ComplexString))
				{
					result = new ComplexString(result.toString());
					isSimpleType = false;
				}
				var attributeName:String = attributeXML.localName();
				result[attributeName] = ComplexString.simpleType(attributeXML.toString());
			}
			return result;
		}
		
		public static function convertDragonBonesDataToRelativeObject(dragonBonesData:Object):void
		{
			
			for each(var armatureData:Object in dragonBonesData.armature)
			{
				sortArmatureBoneList(armatureData);
				transformArmatureData(armatureData);
			}
			
			for each(armatureData in dragonBonesData.armature)
			{
				transformArmatureDataAnimations(armatureData);
			}
		}
		
		private static function transformArmatureData(armatureData:Object):void
		{
		//处理骨架数据
			var boneDataList:Array = armatureData.bone;
			var newBoneDataList:Array = new Array();
			
			var length:int = boneDataList.length;
			var newBoneData:Object;
			var parentBoneData:Object;
			for(var i:int = 0; i < length; i++)
			{
				newBoneData = cloneObject(boneDataList[i])
				if(newBoneData.parent)
				{
					parentBoneData = findBoneData(armatureData, newBoneData.parent);
					if(parentBoneData)
					{
						globalToLocal(newBoneData.transform, parentBoneData.transform);
					}
				}
				newBoneDataList.push(newBoneData);
			}
			
			boneDataList.length = 0;
			for each(newBoneData in newBoneDataList)
			{
				boneDataList.push(newBoneData);
			}
		}
		
		public static function transformArmatureDataAnimations(armatureData:Object):void
		{
			var animationDataList:Array = armatureData.animation;
			var i:int = animationDataList.length;
			
			while(i --)
			{
				transformAnimationData(animationDataList[i], armatureData);
			}
		}
		
		public static function transformAnimationData(animationData:Object, armatureData:Object):void
		{
			var skinDataList:Array = armatureData.skin;
			var skinData:Object;
			if(skinDataList)
			{
				skinData = armatureData.skin[0];
			}
			
			var boneDataList:Array = armatureData.bone;
			var boneData:Object;
			for each(boneData in boneDataList)
			{
				var timelineData:Object = findTimelineData(animationData, boneData.name);
				if(!timelineData)
				{
					continue;
				}
				
				var frameData:Object;
				var position:Number = 0;
				var frameDataList:Array = timelineData.frame;
				//为Timeline中的每个frame计算position.
				for each(frameData in frameDataList)
				{
					frameData.global = cloneObject(frameData.transform);
					frameData.position = position;
					position += frameData.duration;
				}
				
				var slotData:Object = findSlotData(skinData, boneData.name);
				
				
				var originPivot:Point = null;
				var prevFrameData:Object = null;
				
				for each(frameData in frameDataList)
				{
					calculateFrameTransform(animationData, armatureData, boneData, frameData);
					
					frameData.transform.x -= boneData.transform.x;
					frameData.transform.y -= boneData.transform.y;
					frameData.transform.skX = formatAngle(frameData.transform.skX - boneData.transform.skX);
					frameData.transform.skY = formatAngle(frameData.transform.skY - boneData.transform.skY);
					frameData.transform.scX -= boneData.transform.scX;
					frameData.transform.scY -= boneData.transform.scY;
					
					if(originPivot == null)
					{
						originPivot = new Point(frameData.transform.pX, frameData.transform.pY);
					}
					frameData.transform.pX -= originPivot.x;
					frameData.transform.pY -= originPivot.y;
					if(slotData)
					{
						frameData.z -= slotData.z;
					}
					
					if(prevFrameData)
					{
						var dLX:Number = frameData.transform.skX - prevFrameData.transform.skX;
						
						if(prevFrameData.tweenRotate)
						{
							
							if(prevFrameData.tweenRotate > 0)
							{
								if(dLX < 0)
								{
									frameData.transform.skX += Math.PI * 2;
									frameData.transform.skY += Math.PI * 2;
								}
								
								if(prevFrameData.tweenRotate > 1)
								{
									frameData.transform.skX += Math.PI * 2 * (prevFrameData.tweenRotate - 1);
									frameData.transform.skY += Math.PI * 2 * (prevFrameData.tweenRotate - 1);
								}
							}
							else
							{
								if(dLX > 0)
								{
									frameData.transform.skX -= Math.PI * 2;
									frameData.transform.skY -= Math.PI * 2;
								}
								
								if(prevFrameData.tweenRotate < 1)
								{
									frameData.transform.skX += Math.PI * 2 * (prevFrameData.tweenRotate + 1);
									frameData.transform.skY += Math.PI * 2 * (prevFrameData.tweenRotate + 1);
								}
							}
						}
						else
						{
							frameData.transform.skX = prevFrameData.transform.skX + formatAngle(frameData.transform.skX - prevFrameData.transform.skX);
							frameData.transform.skY = prevFrameData.transform.skY + formatAngle(frameData.transform.skY - prevFrameData.transform.skY);
						}
					}
					prevFrameData = frameData;
				}
			}
		}
		
		private static function calculateFrameTransform(animationData:Object, armatureData:Object, boneData:Object, frameData:Object):void
		{
			var parentBoneData:Object = findBoneData(armatureData, boneData.parent);
			if(parentBoneData)
			{
				var parentTimelineData:Object = findTimelineData(animationData, parentBoneData.name);
				if(parentTimelineData)
				{	
					var parentTimelineDataList:Array = new Array();
					var parentBoneDataList:Array = new Array();
					//构建父骨头列表以及对应的etimeline列表
					while(parentTimelineData)
					{
						parentTimelineDataList.push(parentTimelineData);
						parentBoneDataList.push(parentBoneData);
						parentBoneData = findBoneData(armatureData, parentBoneData.parent);
						if(parentBoneData)
						{
							findTimelineData(animationData, parentBoneData.name);
						}
						else
						{
							parentTimelineData = null;
						}
					}
					
					var i:int = parentTimelineDataList.length;
					
					var helpMatrix:Matrix = new Matrix();
					var globalTransform:Object;
					var currentTransform:Object = new Object();
					//从根开始遍历
					while(i --)
					{
						parentTimelineData = parentTimelineDataList[i];
						parentBoneData = parentBoneDataList[i];
						//一级一级找到当前帧对应的每个父节点的transform(相对transform) 保存到currentTransform，globalTransform保存根节点的transform
						calculateTimelineTransform(parentTimelineData, frameData.position, currentTransform, !globalTransform);
						
						if(globalTransform)
						{
							globalTransform.skX += currentTransform.skX + parentBoneData.transform.skX;
							globalTransform.skY += currentTransform.skY + parentBoneData.transform.skY;
							globalTransform.scX = currentTransform.scX + parentBoneData.transform.scX;
							globalTransform.scY = currentTransform.scY + parentBoneData.transform.scY;
							
							var x:Number = currentTransform.x + parentBoneData.transform.x;
							var y:Number = currentTransform.y + parentBoneData.transform.y;
							
							globalTransform.x = helpMatrix.a * x + helpMatrix.c * y + helpMatrix.tx;
							globalTransform.y = helpMatrix.d * y + helpMatrix.b * x + helpMatrix.ty;
						}
						else
						{
							globalTransform = new Object();
							copyTransform(currentTransform, globalTransform);
						}
						transformToMatrix(globalTransform, helpMatrix, true);
					}
					globalToLocal(frameData.transform, globalTransform);
				}
			}
		}
		
		private static function calculateTimelineTransform(timelineData:Object, position:int, outputTransform:Object, isRoot:Boolean):void
		{
			var frameDataList:Array = timelineData.frame;
			var i:int = frameDataList.length;
			
			while(i --)
			{
				var currentFrameData:Object = frameDataList[i];
				//找到穿越当前帧的关键帧
				if(currentFrameData.position <= position && currentFrameData.position + currentFrameData.duration > position)
				{
					//是最后一帧或者就是当前帧
					if(i == frameDataList.length - 1 || position == currentFrameData.position)
					{
						var targetTransform:Object = isRoot?currentFrameData.global:currentFrameData.transform;
						copyTransform(targetTransform, outputTransform);
					}
					else
					{
						var tweenEasing:Number = currentFrameData.tweenEasing;
						var progress:Number = (position - currentFrameData.position) / currentFrameData.duration;
						if(tweenEasing && tweenEasing != 10)
						{
							progress = TimelineState.getEaseValue(progress, tweenEasing);
						}
						var nextFrameData:Object = frameDataList[i + 1];
						
						var currentTransform:Object = isRoot?currentFrameData.global:currentFrameData.transform;
						var nextTransform:Object = isRoot?nextFrameData.global:nextFrameData.transform;
						
						outputTransform.x = currentTransform.x + (nextTransform.x - currentTransform.x) * progress;
						outputTransform.y = currentTransform.y + (nextTransform.y - currentTransform.y) * progress;
						outputTransform.skX = formatAngle(currentTransform.skX + (nextTransform.skX - currentTransform.skX) * progress);
						outputTransform.skY = formatAngle(currentTransform.skY + (nextTransform.skY - currentTransform.skY) * progress);
						outputTransform.scX = currentTransform.scX + (nextTransform.scX - currentTransform.scX) * progress;
						outputTransform.scY = currentTransform.scY + (nextTransform.scY - currentTransform.scY) * progress;
					}
					break;
				}
			}
		}
		
		private static function sortArmatureBoneList(armatureData:Object):void
		{
			var helpArray:Array = [];
			var boneList:Array = armatureData.bone;
			
			for each(var boneData:Object in boneList)
			{
				var level:int = 0;
				var parentData:Object = boneData;
				while(parentData)
				{
					level++;
					parentData = findBoneData(armatureData, parentData.parent);
				}
				helpArray.push([level, boneData]);
			}
			helpArray.sortOn("0", Array.NUMERIC);
			boneList.length = 0;
			for each(boneData in helpArray)
			{
				boneList.push(boneData[1]);
			}
		}
		
		private static function cloneObject(obj:Object):*
		{
			var copier:ByteArray = new ByteArray();
			copier.writeObject(obj);
			copier.position = 0;
			return copier.readObject();
		}
		
		private static function copyTransform(sourceTransform:Object, targetTransform:Object):void
		{
			targetTransform.x = sourceTransform.x;
			targetTransform.y = sourceTransform.y;
			targetTransform.skX = sourceTransform.skX;
			targetTransform.skY = sourceTransform.skY;
			targetTransform.scX = sourceTransform.scX;
			targetTransform.scY = sourceTransform.scY;
		}
		
		private static function findBoneData(armatureData:Object, boneName:String):Object
		{
			if(boneName)
			{
				var boneDataList:Array = armatureData.bone;
				for each(var bone:Object in boneDataList)
				{
					if(bone.name == boneName)
					{
						return bone;
					}
				}
			}
			return null;
		}
		private static function findTimelineData(animationData:Object, boneName:String):Object
		{
			if(boneName)
			{
				var timelineList:Array = animationData.timeline;
				for each(var timeline:Object in timelineList)
				{
					if(timeline.name == boneName)
					{
						return timeline;
					}
				}
			}
			return null;
		}
		private static function findSlotData(skinData:Object, boneName:String):Object
		{
			if(boneName)
			{
				var slotList:Array = skinData.slot;
				for each(var slot:Object in slotList)
				{
					if(slot.name == boneName)
					{
						return slot;
					}
				}
			}
			return null;
		}
		
		private static function globalToLocal(transform:Object, parentTransform:Object):void
		{
			transformToMatrix(parentTransform, _helpMatrix, true);
			_helpMatrix.invert();
			
			var x:Number = transform.x;
			var y:Number = transform.y;
			
			transform.x = _helpMatrix.a * x + _helpMatrix.c * y + _helpMatrix.tx;
			transform.y = _helpMatrix.d * y + _helpMatrix.b * x + _helpMatrix.ty;
			
			transform.skX = formatAngle(transform.skX - parentTransform.skX);
			transform.skY = formatAngle(transform.skY - parentTransform.skY);
		}
		
		private static function transformToMatrix(transform:Object, matrix:Matrix, keepScale:Boolean = false):void
		{
			if(keepScale)
			{
				matrix.a = transform.scX * Math.cos(transform.skY)
				matrix.b = transform.scX * Math.sin(transform.skY)
				matrix.c = -transform.scY * Math.sin(transform.skX);
				matrix.d = transform.scY * Math.cos(transform.skX);
				matrix.tx = transform.x;
				matrix.ty = transform.y;
			}
			else
			{
				matrix.a = Math.cos(transform.skY)
				matrix.b = Math.sin(transform.skY)
				matrix.c = -Math.sin(transform.skX);
				matrix.d = Math.cos(transform.skX);
				matrix.tx = transform.x;
				matrix.ty = transform.y;
			}
		}
		
		private static function formatAngle(angle:Number):Number
		{
			angle %= 360
			if (angle > 180)
			{
				angle -= 360;
			}
			else if (angle < -180)
			{
				angle += 360;
			}
			return angle;
		}
	}
}

dynamic class ComplexString
{
	public var value:String;
	
	public function ComplexString(val:String)
	{
		value = val;
	}
	
	public function toString():String 
	{
		return value;
	}
	
	public function valueOf():Object 
	{
		return simpleType(value);
	}
	
	public static function simpleType(value:Object):Object 
	{
		switch(value) 
		{
			case "NaN":
				return NaN;
			case "true":
				return true;
			case "false":
				return false;
			case "null":
				return null;
			case "undefined":
				return undefined;
		}
		if (isNaN(Number(value))) 
		{
			return value;
		}
		return Number(value);
	}
}