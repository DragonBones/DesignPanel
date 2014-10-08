package core.utils
{
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.IBitmapDrawable;
	import flash.display.Sprite;
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
				if(rect.width && rect.height)
				{
					var matrix:Matrix = new Matrix();
					matrix.tx = -rect.x;
					matrix.ty = -rect.y;
					var subBitmapData:BitmapData = new BitmapData(rect.width, rect.height, true, 0xFF00FF);
					subBitmapData.draw(bitmapData, matrix);
					subBitmapDataDic[subTextureName] = subBitmapData;
				}
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
				
				if(drawableDisplay is Sprite)
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
		
		public static function byteArrayMapToBitmapDataMap(byteArrayMap:Object, callBack:Function):void
		{
			new ByteArrayMapToBitmapDataMap(byteArrayMap, callBack);
		}
	}
}



import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.DisplayObject;
import flash.display.IBitmapDrawable;
import flash.display.Loader;
import flash.display.LoaderInfo;
import flash.events.Event;
import flash.geom.Matrix;
import flash.geom.Rectangle;
import flash.system.LoaderContext;
import flash.utils.ByteArray;

class ByteArrayMapToBitmapDataMap
{
	private static var _loaderContext:LoaderContext = new LoaderContext(false);
	private static var _holdPool:Vector.<ByteArrayMapToBitmapDataMap> = new Vector.<ByteArrayMapToBitmapDataMap>;
	
	_loaderContext.allowCodeImport = true;
	
	private var _bitmapDataMap:Object;
	private var _callback:Function;
	
	public function ByteArrayMapToBitmapDataMap(byteArrayMap:Object, callBack:Function)
	{
		_bitmapDataMap = {};
		_callback = callBack;
		
		for(var name:String in byteArrayMap)
		{
			var byteArray:ByteArray = byteArrayMap[name] as ByteArray;
			if(byteArray)
			{
				var loader:Loader = new Loader();
				loader.contentLoaderInfo.addEventListener(Event.COMPLETE, loadBitmapDataHandler);
				loader.loadBytes(byteArray, _loaderContext);
				_bitmapDataMap[name] = loader;
			}
		}
		
		_holdPool.push(this);
	}
	
	private function loadBitmapDataHandler(e:Event):void
	{
		var loaderInfo:LoaderInfo = e.target as LoaderInfo;
		loaderInfo.removeEventListener(Event.COMPLETE, loadBitmapDataHandler);
		
		var notComplete:Boolean;
		var loader:Loader = loaderInfo.loader;
		for(var name:String in _bitmapDataMap)
		{
			var content:Object = _bitmapDataMap[name];
			if(content == loader)
			{
				_bitmapDataMap[name] = (loaderInfo.content as Bitmap).bitmapData;
			}
			else if(content is Loader)
			{
				notComplete = true;
			}
		}
		
		if(!notComplete)
		{
			if(_callback != null)
			{
				_callback(_bitmapDataMap);
			}
			
			_bitmapDataMap = null;
			_callback = null;
			
			_holdPool.splice(_holdPool.indexOf(this), 1);
		}
	}
}