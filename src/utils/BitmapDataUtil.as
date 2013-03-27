package utils
{
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.IBitmapDrawable;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	
	public class BitmapDataUtil
	{
		public static function getSubBitmapDataDic(bitmapData:BitmapData, rectDic:Object):Object
		{
			var subBitmapDataDic:Object = {};
			for(var subTextureName:String in rectDic)
			{
				var rect:Rectangle = rectDic[subTextureName];
				var matrix:Matrix = new Matrix();
				matrix.tx = -rect.x;
				matrix.ty = -rect.y;
				var subBitmapData:BitmapData = new BitmapData(rect.width, rect.height, true, 0xFF00FF);
				subBitmapData.draw(bitmapData, matrix);
				subBitmapDataDic[subTextureName] = subBitmapData;
			}
			return subBitmapDataDic;
		}
		
		public static function getMergeBitmapData(subBitmapDataDic:Object, rectDic:Object, width:uint, height:uint, scale:Number = 1):BitmapData
		{
			var bitmapData:BitmapData = new BitmapData(
				width,
				height,
				true,
				0xFF00FF
			);
			
			var smoothing:Boolean = scale != 1;
			
			for(var subTextureName:String in subBitmapDataDic)
			{
				var drawableDisplay:IBitmapDrawable = subBitmapDataDic[subTextureName];
				var rect:Rectangle = rectDic[subTextureName];
				var matrix:Matrix = new Matrix();
				matrix.scale(scale, scale);
				matrix.tx = rect.x;
				matrix.ty = rect.y;
				
				if(!(drawableDisplay is BitmapData))
				{
					var display:DisplayObject = drawableDisplay as DisplayObject;
					var rectOffSet:Rectangle = display.getBounds(display);
					matrix.tx -= rectOffSet.x * scale;
					matrix.ty -= rectOffSet.y * scale;
				}
				
				bitmapData.draw(drawableDisplay, matrix, null, null, rect, smoothing);
				if(drawableDisplay is BitmapData)
				{
					(drawableDisplay as BitmapData).dispose();
				}
			}
			return bitmapData;
		}
	}
}