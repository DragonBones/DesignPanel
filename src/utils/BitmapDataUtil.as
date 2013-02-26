package utils
{
	import flash.display.BitmapData;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	
	public class BitmapDataUtil
	{
		public static function getSubBitmapDataDic(bitmapData:BitmapData, rectDic:Object, scale:Number = 1):Object
		{
			var subBitmapDataDic:Object = {};
			for(var subTextureName:String in rectDic)
			{
				var rect:Rectangle = rectDic[subTextureName];
				var matrix:Matrix = new Matrix();
				matrix.tx = -rect.x;
				matrix.ty = -rect.y;
				matrix.scale(scale, scale);
				var subBitmapData:BitmapData = new BitmapData(Math.ceil(rect.width * scale), Math.ceil(rect.height * scale), true, 0xFF00FF);
				subBitmapData.draw(bitmapData, matrix);
				subBitmapDataDic[subTextureName] = subBitmapData;
			}
			return subBitmapDataDic;
		}
		
		public static function getMergeBitmapData(subBitmapDataDic:Object, rectDic:Object, width:uint, height:uint):BitmapData
		{
			var bitmapData:BitmapData = new BitmapData(
				width,
				height,
				true,
				0xFF00FF
			);
			
			for(var subTextureName:String in subBitmapDataDic)
			{
				var subBitmapData:BitmapData = subBitmapDataDic[subTextureName];
				var rect:Rectangle = rectDic[subTextureName];
				var matrix:Matrix = new Matrix();
				matrix.tx = rect.x;
				matrix.ty = rect.y;
				bitmapData.draw(subBitmapData, matrix, null, null, rect);
				subBitmapData.dispose();
			}
			return bitmapData;
		}
	}
}