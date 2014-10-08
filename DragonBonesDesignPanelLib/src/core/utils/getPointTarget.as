package core.utils{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.Sprite;
	import flash.geom.Matrix;
	import flash.geom.Point;
	
	/**
	 * @param _container container
	 * @param _point point
	 * @param _size size
	 * @param _maxAlpha alpha data(0~1)
	 */
	
	public function getPointTarget(container:DisplayObjectContainer, point:Point, size:int = 1, maxAlpha:Number = 0):DisplayObject 
	{
		var filtersBackup:Array = [];
		var numChildren:uint = container.numChildren;
		
		for(var i:int = 0;i < numChildren;i ++)
		{
			var childDisplay:DisplayObject = container.getChildAt(i);
			if(childDisplay.filters && childDisplay.filters.length > 0)
			{
				filtersBackup[i] = childDisplay.filters;
				childDisplay.filters = null;
			}
		}
		
		var bmd:BitmapData = bmdArr[size];
		if(bmd)
		{
			
		}
		else
		{
			
			bmdArr[size] = bmd =new BitmapData(size * 2 - 1, size * 2 - 1, true, 0x00000000);
		}
		
		i = numChildren;
		var alpha:int = int(maxAlpha * 0xff);
		while (--i >= 0) 
		{
			bmd.fillRect(bmd.rect, 0x00000000);
			var child:DisplayObject = container.getChildAt(i);
			var m:Matrix = child.transform.matrix;
			m.tx -= point.x - (size * 2 - 1)/2;
			m.ty -= point.y - (size * 2 - 1)/2;
			bmd.draw(child, m);
			var y:int = bmd.height;
			var ok:Boolean = true;
			loop:while (--y >= 0) 
			{
				var x:int = y + 1 > size?(y + 1) - size:size-(y + 1);
				var xMax:int = bmd.width - 1 - x;
				while (x <= xMax) 
				{
					if ((bmd.getPixel32(x, y) >>> 24) > alpha) 
					{
						//bmd.setPixel32(x,y,0xffff0000);
					}
					else
					{
						ok = false;
						break loop;
					}
					x++;
				}
			}
			if(ok) 
			{
				break;
			}
			child = null;
		}
		
		for(i = 0;i < numChildren;i ++)
		{
			childDisplay = container.getChildAt(i);
			if(filtersBackup[i])
			{
				childDisplay.filters = filtersBackup[i];
			}
		}
		
		return child;
	}
}
const bmdArr:Array=new Array();