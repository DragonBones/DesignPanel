package utils
{
	import flash.display.BitmapData;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	
	import model.SkeletonXMLProxy;
	
	
	public function mergeBitmapData(rawBitmapData:BitmapData, addBitmapData:BitmapData, rawSkeletonXMLProxy:SkeletonXMLProxy, addSkeletonXMLProxy:SkeletonXMLProxy):BitmapData
	{
		
		var rawSubBitmapDataDic:Object = rawSkeletonXMLProxy.getSubBitmapDataDic(rawBitmapData);
		var addSubBitmapDataDic:Object = addSkeletonXMLProxy.getSubBitmapDataDic(addBitmapData);
		
		for(var subTextureName:String in addSubBitmapDataDic)
		{
			var subBitmapData:BitmapData = rawSubBitmapDataDic[subTextureName];
			if(subBitmapData)
			{
				subBitmapData.dispose();
			}
			rawSubBitmapDataDic[subTextureName] = addSubBitmapDataDic[subTextureName];
		}
		
		rawSkeletonXMLProxy.merge(addSkeletonXMLProxy);
		
		var bitmapData:BitmapData = new BitmapData(
			rawSkeletonXMLProxy.textureAtlasWidth,
			rawSkeletonXMLProxy.textureAtlasHeight,
			true,
			0xFF00FF
		);
		
		for(subTextureName in rawSubBitmapDataDic)
		{
			subBitmapData = rawSubBitmapDataDic[subTextureName];
			var rect:Rectangle = rawSkeletonXMLProxy.getSubTextureRect(subTextureName);
			var matrix:Matrix = new Matrix();
			matrix.tx = rect.x;
			matrix.ty = rect.y;
			bitmapData.draw(subBitmapData, matrix, null, null, rect);
			subBitmapData.dispose();
		}
		
		return bitmapData;
	}
}