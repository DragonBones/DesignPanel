package core.utils
{
	import dragonBones.animation.TimelineState;
	import dragonBones.objects.DBTransform;
	import dragonBones.utils.ConstValues;
	
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;

	public class DataUtils
	{
		private static const _helpMatrix:Matrix = new Matrix();
		
		private static const _helpTransformMatrix:Matrix = new Matrix();
		private static const _helpParentTransformMatrix:Matrix = new Matrix();
		
		
		
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
			
			var timelineData:Object;
			var frameDataList:Array;
			var frameData:Object;
			for each(boneData in boneDataList)
			{
				timelineData = findTimelineData(animationData, boneData.name);
				if(!timelineData)
				{
					continue;
				}
				
				var position:Number = 0;
				frameDataList = timelineData.frame;
				//为Timeline中的每个frame计算position.
				for each(frameData in frameDataList)
				{
					frameData.global = cloneObject(frameData.transform);
					frameData.position = position;
					position += frameData.duration;
				}
				
				var slotData:Object = findSlotData(skinData, boneData.name);
				
				var prevFrameData:Object = null;
				
				for each(frameData in frameDataList)
				{
					//空帧的情况
					if(frameData.transform == null)
					{
						if(timelineData.originPivotX == null)
						{
							timelineData.originPivotX = 0;
							timelineData.originPivotY = 0;
						}

						continue;
					}
					calculateFrameTransform(animationData, armatureData, boneData, frameData);
					
					frameData.transform.x -= boneData.transform.x;
					frameData.transform.y -= boneData.transform.y;
					frameData.transform.skX = formatAngle(frameData.transform.skX - boneData.transform.skX);
					frameData.transform.skY = formatAngle(frameData.transform.skY - boneData.transform.skY);
					frameData.transform.scX /= boneData.transform.scX;
					frameData.transform.scY /= boneData.transform.scY;
					
					if(timelineData.originPivotX == null)
					{
						timelineData.originPivotX = frameData.transform.pX;
						timelineData.originPivotY = frameData.transform.pY;
					}
					
					frameData.transform.pX -= timelineData.originPivotX;
					frameData.transform.pY -= timelineData.originPivotY;
					
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
									frameData.transform.skX += 360;
									frameData.transform.skY += 360;
								}
								
								if(prevFrameData.tweenRotate > 1)
								{
									frameData.transform.skX += 360 * (prevFrameData.tweenRotate - 1);
									frameData.transform.skY += 360 * (prevFrameData.tweenRotate - 1);
								}
							}
							else
							{
								if(dLX > 0)
								{
									frameData.transform.skX -= 360;
									frameData.transform.skY -= 360;
								}
								
								if(prevFrameData.tweenRotate < 1)
								{
									frameData.transform.skX += 360 * (prevFrameData.tweenRotate + 1);
									frameData.transform.skY += 360 * (prevFrameData.tweenRotate + 1);
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
			
		//移除没用的数据 frame.global, frame.position
			var timelineDataList:Array = animationData.timeline;
			for each(timelineData in timelineDataList)
			{
				frameDataList = timelineData.frame;
				for each(frameData in frameDataList)
				{
					delete frameData.position;
					delete frameData.global;
				}
			}
		}
		
		// 计算相对父节点的相对Transform
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
							parentTimelineData = findTimelineData(animationData, parentBoneData.name);
						}
						else
						{
							parentTimelineData = null;
						}
					}
					
					var i:int = parentTimelineDataList.length;
					
					var globalTransform:Object;
					var globalTransformMatrix:Matrix = new Matrix();
					
					var currentTransform:Object = new Object();
					var currentTransformMatrix:Matrix = new Matrix();
					
					//从根开始遍历
					while(i --)
					{
						parentTimelineData = parentTimelineDataList[i];
						parentBoneData = parentBoneDataList[i];
						//一级一级找到当前帧对应的每个父节点的transform(相对transform) 保存到currentTransform，globalTransform保存根节点的transform
						calculateTimelineTransform(parentTimelineData, frameData.position, currentTransform, !globalTransform);
						
						if(!globalTransform)
						{
							globalTransform = new Object();
							copyTransform(currentTransform, globalTransform);
						}
						else
						{
							currentTransform.x += parentBoneData.transform.x;
							currentTransform.y += parentBoneData.transform.y;
							
							currentTransform.skX += parentBoneData.transform.skX;
							currentTransform.skY += parentBoneData.transform.skY;
							
							currentTransform.scX *= parentBoneData.transform.scX;
							currentTransform.scY *= parentBoneData.transform.scY;
							
							transformToMatrix(currentTransform, currentTransformMatrix, true);
							currentTransformMatrix.concat(globalTransformMatrix);
							matrixToTransform(currentTransformMatrix, globalTransform, currentTransform.scX * globalTransform.scX >= 0, currentTransform.scY * globalTransform.scY >= 0);
						}
						transformToMatrix(globalTransform, globalTransformMatrix, true);
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
			transformToMatrix(transform, _helpTransformMatrix, true);
			transformToMatrix(parentTransform, _helpParentTransformMatrix, true);
			
			_helpParentTransformMatrix.invert();
			_helpTransformMatrix.concat(_helpParentTransformMatrix);
			
			matrixToTransform(_helpTransformMatrix, transform, transform.scX * parentTransform.scX >= 0, transform.scY * parentTransform.scY >= 0);
		}
		
		private static function transformToMatrix(transform:Object, matrix:Matrix, keepScale:Boolean = false):void
		{
			if(keepScale)
			{
				matrix.a = transform.scX * Math.cos(transform.skY*ConstValues.ANGLE_TO_RADIAN)
				matrix.b = transform.scX * Math.sin(transform.skY*ConstValues.ANGLE_TO_RADIAN)
				matrix.c = -transform.scY * Math.sin(transform.skX*ConstValues.ANGLE_TO_RADIAN);
				matrix.d = transform.scY * Math.cos(transform.skX*ConstValues.ANGLE_TO_RADIAN);
				matrix.tx = transform.x;
				matrix.ty = transform.y;
			}
			else
			{
				matrix.a = Math.cos(transform.skY*ConstValues.ANGLE_TO_RADIAN)
				matrix.b = Math.sin(transform.skY*ConstValues.ANGLE_TO_RADIAN)
				matrix.c = -Math.sin(transform.skX*ConstValues.ANGLE_TO_RADIAN);
				matrix.d = Math.cos(transform.skX*ConstValues.ANGLE_TO_RADIAN);
				matrix.tx = transform.x;
				matrix.ty = transform.y;
			}
		}
		
		public static function matrixToTransform(matrix:Matrix, transform:Object, scaleXF:Boolean, scaleYF:Boolean):void
		{
			transform.x = matrix.tx;
			transform.y = matrix.ty;
			transform.scX = Math.sqrt(matrix.a * matrix.a + matrix.b * matrix.b) * (scaleXF ? 1 : -1);
			transform.scY = Math.sqrt(matrix.d * matrix.d + matrix.c * matrix.c) * (scaleYF ? 1 : -1);
			
			var skewXArray:Array = [];
			skewXArray[0] = Math.acos(matrix.d / transform.scY);
			skewXArray[1] = -skewXArray[0];
			skewXArray[2] = Math.asin(-matrix.c / transform.scY);
			skewXArray[3] = skewXArray[2] >= 0 ? Math.PI - skewXArray[2] : skewXArray[2] - Math.PI;
			
			if(Number(skewXArray[0]).toFixed(4) == Number(skewXArray[2]).toFixed(4) || Number(skewXArray[0]).toFixed(4) == Number(skewXArray[3]).toFixed(4))
			{
				transform.skX = skewXArray[0];
			}
			else 
			{
				transform.skX = skewXArray[1];
			}
			
			var skewYArray:Array = [];
			skewYArray[0] = Math.acos(matrix.a / transform.scX);
			skewYArray[1] = -skewYArray[0];
			skewYArray[2] = Math.asin(matrix.b / transform.scX);
			skewYArray[3] = skewYArray[2] >= 0 ? Math.PI - skewYArray[2] : skewYArray[2] - Math.PI;
			
			if(Number(skewYArray[0]).toFixed(4) == Number(skewYArray[2]).toFixed(4) || Number(skewYArray[0]).toFixed(4) == Number(skewYArray[3]).toFixed(4))
			{
				transform.skY = skewYArray[0];
			}
			else 
			{
				transform.skY = skewYArray[1];
			}
			
			transform.skX *= ConstValues.RADIAN_TO_ANGLE;
			transform.skY *= ConstValues.RADIAN_TO_ANGLE;
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
