package utils{
	import dragonBones.utils.ConstValues;
	
	import flash.geom.Rectangle;
	
	/**
	 * 贴图排序工具
	 */
	public final class TextureUtil{
		
		/**
		 * 整理排序 textureAtlasXML
		 */
		public static function packTextures(_widthDefault:uint, _padding:uint, _textureAtlasXML:XML, _verticalSide:Boolean = false):void{
			var _subTextureXMLList:XMLList = _textureAtlasXML.elements(ConstValues.SUB_TEXTURE);
			if (_subTextureXMLList.length() == 0) {
				return;
			}
			var _dimensions:uint = 0;
			var _subTextureList:Array = [];
			for each(var _subTextureXML:XML in _subTextureXMLList){
				_dimensions += int(_subTextureXML.attribute(ConstValues.A_WIDTH)) * int(_subTextureXML.attribute(ConstValues.A_HEIGHT));
				_subTextureList.push(_subTextureXML);
			}
			//贴图按照大小排序
			_subTextureList.sort(sortTextureList);
			
			if(_widthDefault == 0){
				//计算 Auto size 的 width
				_widthDefault = Math.sqrt(_dimensions);
			}
			
			_widthDefault = getNearest2N(Math.max(int(_subTextureList[0].attribute(ConstValues.A_WIDTH)) + _padding, _widthDefault));
			
			//预置一个较高的高度
			var _heightMax:uint = 40960;
			var _remainRectList:Vector.<Rectangle> = new Vector.<Rectangle>;
			_remainRectList.push(new Rectangle(0, 0, _widthDefault, _heightMax));
			
			var _isFit:Boolean;
			var _width:uint;
			var _height:uint;
			var _pivotX:Number;
			var _pivotY:Number;
			
			var _rect:Rectangle;
			var _rectPrev:Rectangle;
			var _rectNext:Rectangle;
			var _rectID:int;
			
			do {
				//寻找最高的空白区域
				_rect = getHighestRect(_remainRectList);
				_rectID = _remainRectList.indexOf(_rect);
				_isFit = false;
				for(var _iT:String in _subTextureList) {
					//逐个比较贴图对象是否适合该区域
					_subTextureXML = _subTextureList[_iT];
					_width = int(_subTextureXML.attribute(ConstValues.A_WIDTH)) + _padding;
					_height = int(_subTextureXML.attribute(ConstValues.A_HEIGHT)) + _padding;
					if (_rect.width >= _width && _rect.height >= _height) {
						//考虑竖直贴图的合理摆放
						if (_verticalSide?(_height > _width * 4?(_rectID > 0?(_rect.height - _height >= _remainRectList[_rectID - 1].height):true):true):true){
							_isFit = true;
							break;
						}
					}
				}
				if(_isFit){
					//如果合适，放置贴图，并将矩形区域再次分区
					_subTextureXML[ConstValues.AT + ConstValues.A_X] = _rect.x;
					_subTextureXML[ConstValues.AT + ConstValues.A_Y] = _rect.y;
					_subTextureList.splice(int(_iT), 1);
					_remainRectList.splice(_rectID + 1, 0, new Rectangle(_rect.x + _width, _rect.y, _rect.width - _width, _rect.height));
					_rect.y += _height;
					_rect.width = _width;
					_rect.height -= _height;
				}else{
					//不合适，则放弃这个矩形区域，把这个区域将与他相邻的矩形区域合并（与较高的一边合并）
					if(_rectID == 0){
						_rectNext = _remainRectList[_rectID + 1];
					}else if(_rectID == _remainRectList.length - 1){
						_rectNext = _remainRectList[_rectID - 1];
					}else{
						_rectPrev = _remainRectList[_rectID - 1];
						_rectNext = _remainRectList[_rectID + 1];
						_rectNext = _rectPrev.height <= _rectNext.height?_rectNext:_rectPrev;
					}
					if(_rect.x < _rectNext.x){
						_rectNext.x = _rect.x;
					}
					_rectNext.width = _rect.width + _rectNext.width;
					_remainRectList.splice(_rectID, 1);
				}
			}while (_subTextureList.length > 0);
			
			//计算_heightMax
			_heightMax = getNearest2N(_heightMax - getLowestRect(_remainRectList).height);
			_textureAtlasXML[ConstValues.AT + ConstValues.A_WIDTH] = _widthDefault;
			_textureAtlasXML[ConstValues.AT + ConstValues.A_HEIGHT] = _heightMax;
		}
		
		private static function sortTextureList(_subTextureXML1:XML, _subTextureXML2:XML):int{
			var _v1:uint = int(_subTextureXML1.attribute(ConstValues.A_WIDTH)) + int(_subTextureXML1.attribute(ConstValues.A_HEIGHT));
			var _v2:uint = int(_subTextureXML2.attribute(ConstValues.A_WIDTH)) + int(_subTextureXML2.attribute(ConstValues.A_HEIGHT));
			if (_v1 == _v2) {
				return int(_subTextureXML1.attribute(ConstValues.A_WIDTH)) > int(_subTextureXML2.attribute(ConstValues.A_WIDTH))?-1:1;
			}
			return _v1 > _v2?-1:1;
		}
		
		private static function getNearest2N(_n:uint):uint{
			return _n & _n - 1?1 << _n.toString(2).length:_n;
		}
		
		private static function getHighestRect(_rectList:Vector.<Rectangle>):Rectangle{
			var _height:uint = 0;
			var _rectHighest:Rectangle;
			for each(var _rect:Rectangle in _rectList) {
				if (_rect.height > _height) {
					_height = _rect.height;
					_rectHighest = _rect;
				}
			}
			return _rectHighest;
		}
		
		private static function getLowestRect(_rectList:Vector.<Rectangle>):Rectangle{
			var _height:uint = 40960;
			var _rectLowest:Rectangle;
			for each(var _rect:Rectangle in _rectList) {
				if (_rect.height < _height) {
					_height = _rect.height;
					_rectLowest = _rect;
				}
			}
			return _rectLowest;
		}
	}
}