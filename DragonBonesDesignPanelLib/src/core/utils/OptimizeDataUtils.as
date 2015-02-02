package core.utils
{
	import dragonBones.utils.ConstValues;

	public class OptimizeDataUtils
	{
		private static var animationPropertyArray:Array = [ConstValues.A_FADE_IN_TIME, ConstValues.A_SCALE, ConstValues.A_LOOP];
		private static var animationValueArray:Array = [0,1,1];
		
		private static var timelinePropertyArray:Array = [ConstValues.A_SCALE, ConstValues.A_OFFSET, ConstValues.A_PIVOT_X, ConstValues.A_PIVOT_Y];
		private static var timelineValueArray:Array = [1,0,0,0];
		
		private static var framePropertyArray:Array = [ConstValues.A_TWEEN_SCALE, ConstValues.A_TWEEN_ROTATE, ConstValues.A_HIDE, ConstValues.A_DISPLAY_INDEX, ConstValues.A_SCALE_X_OFFSET, ConstValues.A_SCALE_Y_OFFSET];
		private static var frameValueArray:Array = [1,0,0,0,0,0];
		
		private static var transformPropertyArray:Array = [ConstValues.A_X, ConstValues.A_Y, ConstValues.A_SKEW_X, ConstValues.A_SKEW_Y, ConstValues.A_SCALE_X, ConstValues.A_SCALE_Y, ConstValues.A_PIVOT_X, ConstValues.A_PIVOT_Y];
		private static var transformValueArray:Array = [0,0,0,0,1,1,0,0];
		
		private static var colorTransformPropertyArray:Array = [ConstValues.A_ALPHA_OFFSET, ConstValues.A_RED_OFFSET, ConstValues.A_GREEN_OFFSET, ConstValues.A_BLUE_OFFSET, ConstValues.A_ALPHA_MULTIPLIER,  ConstValues.A_RED_MULTIPLIER,  ConstValues.A_GREEN_MULTIPLIER,  ConstValues.A_BLUE_MULTIPLIER];
		private static var colorTransformValueArray:Array = [0,0,0,0,100,100,100,100];
		
		public static function optimizeData(dragonBonesData:Object):void
		{
			for each(var armatureData:Object in dragonBonesData.armature)
			{
				var boneDataList:Array = armatureData.bone;
				
				for each(var boneData:Object in boneDataList)
				{
					optimizeTransform(boneData.transform);
				}
				
				var skinList:Array = armatureData.skin;
				var slotList:Array;
				var displayList:Array;
				for each(var skinData:Object in skinList)
				{
					slotList = skinData.slot;
					for each(var slotData:Object in slotList)
					{
						displayList = slotData.display;
						for each(var displayData:Object in displayList)
						{
							optimizeTransform(displayData.transform);
						}
					}
				}
				
				var animationList:Array = armatureData.animation;
				var timelineList:Array;
				var frameList:Array;
				for each(var animationData:Object in animationList)
				{
					optimizeAnimation(animationData);
					
					timelineList = animationData.timeline;
					for each(var timelineData:Object in timelineList)
					{
						optimizeTimeline(timelineData);
						
						frameList = timelineData.frame;
						for each(var frameData:Object in frameList)
						{
							optimizeFrame(frameData);
							optimizeTransform(frameData.transform);
							optimizeColorTransform(frameData.colorTransform);
						}
					}
				}
			}
		}
		
		private static function optimizeAnimation(animationData:Object):void
		{
			optimizeItem(animationData, animationPropertyArray, animationValueArray, 4);
		}
		
		private static function optimizeTimeline(timelineData:Object):void
		{
			optimizeItem(timelineData, timelinePropertyArray, timelineValueArray, 4);
		}
		
		private static function optimizeFrame(frameData:Object):void
		{
			optimizeItem(frameData, framePropertyArray, frameValueArray, 4);
		}
		
		private static function optimizeTransform(transform:Object):void
		{
			optimizeItem(transform, transformPropertyArray, transformValueArray, 4);
		}
		
		private static function optimizeColorTransform(colorTransform:Object):void
		{
			optimizeItem(colorTransform, transformPropertyArray, transformValueArray, 4);
		}
		
		private static function optimizeItem(item:Object, propertyArray:Array, valueArray:Array, prec:uint = 4):void
		{
			if(!item)
			{
				return;
			}
			
			var i:int = propertyArray.length;
			var property:String;
			var value:Number;
			while(i--)
			{
				property = propertyArray[i];
				value = valueArray[i];
				if(!item.hasOwnProperty(property))
				{
					continue;
				}
				if(compareWith(item[property], value, prec))
				{
					delete item[property];
				}
				else
				{
					item[property] = Number(Number(item[property]).toFixed(prec));
				}
			}
		}
		
		private static function compareWith(source:Number, target:Number, prec:uint):Boolean
		{
			var delta:Number = 1 / Math.pow(10, prec);
			if(source >= target - delta && source <= target + delta)
			{
				return true;
			}
			return false;
		}
	}
}