package utils{
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
	
	public function getPointTarget(_container:DisplayObjectContainer, _point:Point, _size:int = 1, _maxAlpha:Number = 0):DisplayObject {
		
		var bmd:BitmapData=bmdArr[_size];
		if(bmd){
		}else{
			bmdArr[_size]=bmd=new BitmapData(_size * 2 - 1, _size * 2 - 1, true, 0x00000000);
		}
		
		var i:int = _container.numChildren;
		var alpha:int = int(_maxAlpha * 0xff);
		while (--i >= 0) {
			bmd.fillRect(bmd.rect, 0x00000000);
			var child:DisplayObject = _container.getChildAt(i);
			var m:Matrix = child.transform.matrix;
			m.tx -= _point.x - (_size * 2 - 1)/2;
			m.ty -= _point.y - (_size * 2 - 1)/2;
			bmd.draw(child, m);
			var y:int = bmd.height;
			var ok:Boolean = true;
			loop:while (--y >= 0) {
				var x:int = y + 1 > _size?(y + 1) - _size:_size-(y + 1);
				var xMax:int = bmd.width - 1 - x;
				while (x <= xMax) {
					if ((bmd.getPixel32(x, y) >>> 24) > alpha) {
						//bmd.setPixel32(x,y,0xffff0000);
					}else{
						ok = false;
						break loop;
					}
					x++;
				}
			}
			if (ok) {
				return child;
			}
		}
		
		return null;
	}
}
const bmdArr:Array=new Array();