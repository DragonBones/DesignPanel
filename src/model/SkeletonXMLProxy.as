package model
{
	import dragonBones.objects.XMLDataParser;
	import dragonBones.utils.ConstValues;
	
	import flash.geom.Rectangle;
	
	import utils.TextureUtil;
	
	public class SkeletonXMLProxy
	{
		private var _skeletonXML:XML
		public function get skeletonXML():XML
		{
			return _skeletonXML;
		}
		public function set skeletonXML(value:XML):void
		{
			_skeletonXML = value;
		}
		
		private var _textureAtlasXML:XML;
		public function get textureAtlasXML():XML
		{
			return _textureAtlasXML;
		}
		public function set textureAtlasXML(value:XML):void
		{
			_textureAtlasXML = value;
		}
		
		public function get textureAtlasWidth():uint
		{
			return int(_textureAtlasXML.attribute(ConstValues.A_WIDTH));
		}
		
		public function get textureAtlasHeight():uint
		{
			return int(_textureAtlasXML.attribute(ConstValues.A_HEIGHT));
		}
		
		public function SkeletonXMLProxy()
		{
		}
		
		public function movePivotToSkeleton():void
		{
			var subTextureXMLList:XMLList = getSubTextureXMLList(_textureAtlasXML);
			var subTextureXML:XML = subTextureXMLList[0];
			if(subTextureXML && subTextureXML.attribute(ConstValues.A_PIVOT_X).length() > 0)
			{
				var displayXMLList:XMLList = getDisplayXMLList(_skeletonXML);
				for each(subTextureXML in subTextureXMLList)
				{
					var subTextureName:String = subTextureXML.attribute(ConstValues.A_NAME);
					var pivotX:int = int(subTextureXML.attribute(ConstValues.A_PIVOT_X));
					var pivotY:int = int(subTextureXML.attribute(ConstValues.A_PIVOT_Y));
					
					delete subTextureXML.@[ConstValues.A_PIVOT_X];
					delete subTextureXML.@[ConstValues.A_PIVOT_Y];
					for each(var displayXML:XML in displayXMLList)
					{
						var displayName:String = displayXML.attribute(ConstValues.A_NAME);
						if(displayName == subTextureName)
						{
							displayXML.@[ConstValues.A_PIVOT_X] = pivotX;
							displayXML.@[ConstValues.A_PIVOT_Y] = pivotY;
						}
					}
				}
			}
		}
		
		public function setVersion():void
		{
			_skeletonXML.@[ConstValues.A_VERSION] = ConstValues.VERSION;
		}
		
		public function getDisplayList():Vector.<String>
		{
			var displayList:Vector.<String> = new Vector.<String>;
			
			for each(var displayXML:XML in getDisplayXMLList(_skeletonXML))
			{
				if(int(displayXML.attribute(ConstValues.A_IS_ARMATURE)) != 1)
				{
					var displayName:String = displayXML.attribute(ConstValues.A_NAME);
					if(displayList.indexOf(displayName) < 0)
					{
						displayList.push(displayName);
					}
				}
			}
			return displayList;
		}
		
		public function getSubTextureRectDic():Object
		{
			var subTextureRectDic:Object = {};
			var subTextureXMLList:XMLList = getSubTextureXMLList(_textureAtlasXML);
			for each(var subTextureXML:XML in  subTextureXMLList)
			{
				var rect:Rectangle = new Rectangle(
					int(subTextureXML.attribute(ConstValues.A_X)),
					int(subTextureXML.attribute(ConstValues.A_Y)),
					int(subTextureXML.attribute(ConstValues.A_WIDTH)),
					int(subTextureXML.attribute(ConstValues.A_HEIGHT))
				);
				subTextureRectDic[String(subTextureXML.attribute(ConstValues.A_NAME))] = rect;
			}
			return subTextureRectDic;
		}
		
		public function scaleData(scale:Number):void
		{
			var boneXMLList:XMLList = _skeletonXML.elements(ConstValues.ARMATURES).elements(ConstValues.ARMATURE).elements(ConstValues.BONE);
			scaleXMLList(boneXMLList, scale);
			
			var displayXMLList:XMLList = getDisplayXMLList(_skeletonXML);
			scaleXMLList(displayXMLList, scale);
			
			var frameXMLList:XMLList = _skeletonXML.elements(ConstValues.ANIMATIONS).elements(ConstValues.ANIMATION).elements(ConstValues.MOVEMENT).elements(ConstValues.BONE).elements(ConstValues.FRAME);
			scaleXMLList(frameXMLList, scale);
			
			var subTextureXMLList:XMLList = getSubTextureXMLList(_textureAtlasXML);
			scaleXMLList(subTextureXMLList, scale);
			
			packTextures(0, 2);
		}
		
		private function scaleXMLList(xmlList:XMLList, scale:Number):void
		{
			for each(var xml:XML in xmlList)
			{
				if(xml.@[ConstValues.A_X].length() > 0)
				{
					xml.@[ConstValues.A_X] = formatNumber(Number(xml.@[ConstValues.A_X]) * scale);
				}
				if(xml.@[ConstValues.A_Y].length() > 0)
				{
					xml.@[ConstValues.A_Y] = formatNumber(Number(xml.@[ConstValues.A_Y]) * scale);
				}
				if(xml.@[ConstValues.A_PIVOT_X].length() > 0)
				{
					xml.@[ConstValues.A_PIVOT_X] = formatNumber(Number(xml.@[ConstValues.A_PIVOT_X]) * scale);
				}
				if(xml.@[ConstValues.A_PIVOT_Y].length() > 0)
				{
					xml.@[ConstValues.A_PIVOT_Y] = formatNumber(Number(xml.@[ConstValues.A_PIVOT_Y]) * scale);
				}
				if(xml.@[ConstValues.A_WIDTH].length() > 0)
				{
					xml.@[ConstValues.A_WIDTH] = Math.ceil(Number(xml.@[ConstValues.A_WIDTH]) * scale);
				}
				if(xml.@[ConstValues.A_HEIGHT].length() > 0)
				{
					xml.@[ConstValues.A_HEIGHT] = Math.ceil(Number(xml.@[ConstValues.A_HEIGHT]) * scale);
				}
			}
		}
		
		public function getArmatureXML(armatureName:String):XML
		{
			return XMLDataParser.getElementsByAttribute(getArmatureXMLList(_skeletonXML), ConstValues.A_NAME, armatureName)[0];
		}
		
		public function getAnimationXML(animationName:String):XML
		{
			return XMLDataParser.getElementsByAttribute(getAnimationXMLList(_skeletonXML), ConstValues.A_NAME, animationName)[0];
		}
		
		public function getBoneXML(armatureName:String, boneName:String):XML
		{
			var armatureXML:XML = getArmatureXML(armatureName);
			if(armatureXML)
			{
				return XMLDataParser.getElementsByAttribute(armatureXML.elements(ConstValues.BONE), ConstValues.A_NAME, boneName)[0];
			}
			return null;
		}
		
		public function getMovementXML(animationName:String, movementName:String):XML
		{
			var animationXML:XML = getAnimationXML(animationName);
			if(animationXML)
			{
				return XMLDataParser.getElementsByAttribute(animationXML.elements(ConstValues.MOVEMENT), ConstValues.A_NAME, movementName)[0];
			}
			return null;
		}
		
		public function changePath():void
		{
			for each(var displayXML:XML in getDisplayXMLList(_skeletonXML))
			{
				var subTextureName:String = displayXML.attribute(ConstValues.A_NAME);
				subTextureName = subTextureName.split("/").join("-");
				displayXML.@[ConstValues.A_NAME] = subTextureName;
			}
			
			for each(var subTextureXML:XML in getSubTextureXMLList(_textureAtlasXML))
			{
				subTextureName = subTextureXML.attribute(ConstValues.A_NAME);
				subTextureName = subTextureName.split("/").join("-");
				subTextureXML.@[ConstValues.A_NAME] = subTextureName;
			}
		}
		
		public function merge(skeletonXMLProxy:SkeletonXMLProxy):void
		{
			addSkeletonXML(skeletonXMLProxy.skeletonXML);
			
			for each(var subTextureXML:XML in getSubTextureXMLList(_textureAtlasXML))
			{
				addSubTextureXML(subTextureXML);
			}
			
			packTextures(0, 2);
		}
		
		public function packTextures(width:uint, padding:uint):void
		{
			TextureUtil.packTextures(
				width, 
				padding, 
				_textureAtlasXML
			);
		}
		
		public function addSkeletonXML(skeletonXML:XML):void
		{
			var xmlList1:XMLList;
			var xmlList2:XMLList;
			var node1:XML;
			var node2:XML;
			var nodeName:String;
			
			xmlList1 = getDisplayXMLList(_skeletonXML);
			xmlList2 = getDisplayXMLList(skeletonXML);
			var displayNames:Object = {};
			for each(node2 in xmlList2)
			{
				nodeName = node2.attribute(ConstValues.A_NAME);
				if(displayNames[nodeName])
				{
					continue;
				}
				displayNames[nodeName] = true;
				var sameDisplayXMLList:XMLList = XMLDataParser.getElementsByAttribute(xmlList1, ConstValues.A_NAME, nodeName);
				for each(node1 in sameDisplayXMLList)
				{
					//
					node1.parent().children()[node1.childIndex()] = node2.copy();
				}
			}
			
			xmlList1 = getArmatureXMLList(_skeletonXML);
			xmlList2 = getArmatureXMLList(skeletonXML);
			for each(node2 in xmlList2)
			{
				nodeName = node2.attribute(ConstValues.A_NAME);
				node1 = XMLDataParser.getElementsByAttribute(xmlList1, ConstValues.A_NAME, nodeName)[0];
				if(node1)
				{
					delete xmlList1[node1.childIndex()];
				}
				_skeletonXML.elements(ConstValues.ARMATURES).appendChild(node2);
			}
			
			xmlList1 = getAnimationXMLList(_skeletonXML);
			xmlList2 = getAnimationXMLList(skeletonXML);
			for each(node2 in xmlList2)
			{
				nodeName = node2.attribute(ConstValues.A_NAME);
				node1 = XMLDataParser.getElementsByAttribute(xmlList1, ConstValues.A_NAME, nodeName)[0];
				if(node1)
				{
					delete xmlList1[node1.childIndex()];
				}
				_skeletonXML.elements(ConstValues.ANIMATIONS).appendChild(node2);
			}
		}
		
		public function addSubTextureXML(subTextureXML:XML):void
		{
			var subTextureName:String = subTextureXML.attribute(ConstValues.A_NAME);
			var subTextureXMLList:XMLList = getSubTextureXMLList(_textureAtlasXML);
			var oldSubTextureXML:XML = XMLDataParser.getElementsByAttribute(subTextureXMLList, ConstValues.A_NAME, subTextureName)[0];
			if(oldSubTextureXML)
			{
				delete subTextureXMLList[oldSubTextureXML.childIndex()];
			}
			
			_textureAtlasXML.appendChild(subTextureXML);
		}
		
		public function removeArmature(armatureName:String):Boolean
		{
			var displayXMLList:XMLList = getDisplayXMLList(_skeletonXML);
			if(XMLDataParser.getElementsByAttribute(displayXMLList, ConstValues.A_NAME, armatureName)[0])
			{
				return false;
			}
			var armatureXMLList:XMLList = getArmatureXMLList(_skeletonXML);
			if(armatureXMLList.length() <= 1)
			{
				return false;
			}
			
			var armatureXML:XML = getArmatureXML(armatureName);
			if(armatureXML)
			{
				delete armatureXMLList[armatureXML.childIndex()];
				
				var animationXML:XML = getAnimationXML(armatureName);
				if(animationXML)
				{
					var animationXMLList:XMLList = getAnimationXMLList(_skeletonXML);
					delete animationXMLList[animationXML.childIndex()];
				}
				
				var deleteDisplayList:XMLList = armatureXML.elements(ConstValues.BONE).elements(ConstValues.DISPLAY);
				
				for each(var displayXML:XML in deleteDisplayList)
				{
					var isArmature:Boolean = displayXML.attribute(ConstValues.A_IS_ARMATURE) == "1";
					if(isArmature)
					{
						var childArmatureName:String = displayXML.attribute(ConstValues.A_NAME);
						var remainDisplayList:XMLList = getDisplayXMLList(_skeletonXML);
						
						if(!XMLDataParser.getElementsByAttribute(displayXMLList, ConstValues.A_NAME, childArmatureName)[0])
						{
							removeArmature(childArmatureName);
						}
					}
				}
				
				displayXMLList = getDisplayXMLList(_skeletonXML);
				
				var subTextureXMLLisst:XMLList = getSubTextureXMLList(_textureAtlasXML);
				for(var i:int = subTextureXMLLisst.length() - 1;i >= 0;i --)
				{
					var subTextureXML:XML = subTextureXMLLisst[i];
					var subTextureName:String = subTextureXML.attribute(ConstValues.A_NAME);
					if(!XMLDataParser.getElementsByAttribute(displayXMLList, ConstValues.A_NAME, subTextureName)[0])
					{
						delete subTextureXMLLisst[i];
					}
				}
				
				packTextures(0, 2);
				return true;
			}
			return false;
		}
		
		public function copy():SkeletonXMLProxy
		{
			var skeletonXMLProxy:SkeletonXMLProxy = new SkeletonXMLProxy();
			skeletonXMLProxy.skeletonXML = _skeletonXML.copy();
			skeletonXMLProxy.textureAtlasXML = _textureAtlasXML.copy();
			return skeletonXMLProxy;
		}
		
		
		private function formatNumber(num:Number, retain:uint = 100):Number
		{
			retain = retain || 100;
			return Math.round(num * retain) / retain;
		}
		
		public static function getArmatureXMLList(skeletonXML:XML):XMLList
		{
			return skeletonXML.elements(ConstValues.ARMATURES).elements(ConstValues.ARMATURE);
		}
		
		public static function getAnimationXMLList(skeletonXML:XML):XMLList
		{
			return skeletonXML.elements(ConstValues.ANIMATIONS).elements(ConstValues.ANIMATION);
		}
		
		public static function getDisplayXMLList(skeletonXML:XML):XMLList
		{
			return skeletonXML.elements(ConstValues.ARMATURES).elements(ConstValues.ARMATURE).elements(ConstValues.BONE).elements(ConstValues.DISPLAY);
		}
		
		public static function getSubTextureXMLList(textureAtlasXML:XML):XMLList
		{
			return textureAtlasXML.elements(ConstValues.SUB_TEXTURE)
		}
	}
}