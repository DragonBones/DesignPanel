package model
{
	import dragonBones.core.DragonBones;
	import dragonBones.objects.AnimationData;
	import dragonBones.objects.ArmatureData;
	import dragonBones.objects.BoneData;
	import dragonBones.objects.DBTransform;
	import dragonBones.objects.TransformFrame;
	import dragonBones.objects.TransformTimeline;
	import dragonBones.utils.ConstValues;
	
	import flash.geom.Rectangle;
	
	import utils.TextureUtil;
	
	public class XMLDataProxy
	{
		private static const RADIAN_TO_ANGLE:Number =  180 / Math.PI;
		
		private static const _helpTransform:DBTransform = new DBTransform();
		
		private var _xml:XML
		public function get xml():XML
		{
			return _xml;
		}
		public function set xml(value:XML):void
		{
			_xml = value;
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
			return int(_textureAtlasXML.@[ConstValues.A_WIDTH]);
		}
		
		public function get textureAtlasHeight():uint
		{
			return int(_textureAtlasXML.@[ConstValues.A_HEIGHT]);
		}
		
		public function XMLDataProxy()
		{
		}
		
		public function moveTexturePivotToData():void
		{
			var subTextureXMLList:XMLList = getSubTextureXMLList(_textureAtlasXML);
			var subTextureXML:XML = subTextureXMLList[0];
			if(subTextureXML && subTextureXML.@[ConstValues.A_PIVOT_X].length() > 0)
			{
				var displayXMLList:XMLList = getDisplayXMLList(_xml);
				for each(subTextureXML in subTextureXMLList)
				{
					_xml.@[ConstValues.A_VERSION] = DragonBones.DATA_VERSION;
					var subTextureName:String = subTextureXML.@[ConstValues.A_NAME];
					var pivotX:int = int(subTextureXML.@[ConstValues.A_PIVOT_X]);
					var pivotY:int = int(subTextureXML.@[ConstValues.A_PIVOT_Y]);
					
					delete subTextureXML.@[ConstValues.A_PIVOT_X];
					delete subTextureXML.@[ConstValues.A_PIVOT_Y];
					for each(var displayXML:XML in displayXMLList)
					{
						var displayName:String = displayXML.@[ConstValues.A_NAME];
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
			_xml.@[ConstValues.A_VERSION] = DragonBones.DATA_VERSION;
		}
		
		public function getDisplayList():Vector.<String>
		{
			var displayList:Vector.<String> = new Vector.<String>;
			
			for each(var displayXML:XML in getDisplayXMLList(_xml))
			{
				if(int(displayXML.@[ConstValues.A_IS_ARMATURE]) != 1)
				{
					var displayName:String = displayXML.@[ConstValues.A_NAME];
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
					int(subTextureXML.@[ConstValues.A_X]),
					int(subTextureXML.@[ConstValues.A_Y]),
					int(subTextureXML.@[ConstValues.A_WIDTH]),
					int(subTextureXML.@[ConstValues.A_HEIGHT])
				);
				subTextureRectDic[String(subTextureXML.@[ConstValues.A_NAME])] = rect;
			}
			return subTextureRectDic;
		}
		
		public function scaleData(scale:Number):void
		{
			var boneXMLList:XMLList = _xml[ConstValues.ARMATURES][ConstValues.ARMATURE][ConstValues.BONE];
			scaleXMLList(boneXMLList, scale);
			
			var displayXMLList:XMLList = getDisplayXMLList(_xml);
			scaleXMLList(displayXMLList, scale);
			
			var frameXMLList:XMLList = _xml[ConstValues.ANIMATIONS][ConstValues.ANIMATION][ConstValues.MOVEMENT][ConstValues.BONE][ConstValues.FRAME];
			scaleXMLList(frameXMLList, scale);
			
			var subTextureXMLList:XMLList = getSubTextureXMLList(_textureAtlasXML);
			scaleXMLList(subTextureXMLList, scale);
			
			packTextures(SettingDataProxy.getInstance().textureMaxWidth, SettingDataProxy.getInstance().texturePadding);
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
			return getArmatureXMLList(_xml).(@[ConstValues.A_NAME] == armatureName)[0];
		}
		
		public function getBoneXML(armatureName:String, boneName:String):XML
		{
			var armatureXML:XML = getArmatureXML(armatureName);
			if(armatureXML)
			{
				return armatureXML[ConstValues.BONE].(@[ConstValues.A_NAME] == boneName)[0];
			}
			return null;
		}
		
		public function getAnimationXML(animationName:String, movementName:String):XML
		{
			var animationXML:XML = getAnimationsXML(animationName);
			if(animationXML)
			{
				return animationXML[ConstValues.MOVEMENT].(@[ConstValues.A_NAME] == movementName)[0];
			}
			return null;
		}
		
		public function changePath():void
		{
			for each(var displayXML:XML in getDisplayXMLList(_xml))
			{
				var subTextureName:String = displayXML.@[ConstValues.A_NAME];
				subTextureName = subTextureName.split("/").join("-");
				displayXML.@[ConstValues.A_NAME] = subTextureName;
			}
			
			for each(var subTextureXML:XML in getSubTextureXMLList(_textureAtlasXML))
			{
				subTextureName = subTextureXML.@[ConstValues.A_NAME];
				subTextureName = subTextureName.split("/").join("-");
				subTextureXML.@[ConstValues.A_NAME] = subTextureName;
			}
		}
		
		public function merge(xmlDataProxy:XMLDataProxy):void
		{
			addXML(xmlDataProxy.xml);
			
			for each(var subTextureXML:XML in getSubTextureXMLList(_textureAtlasXML))
			{
				addSubTextureXML(subTextureXML);
			}
			
			packTextures(SettingDataProxy.getInstance().textureMaxWidth, SettingDataProxy.getInstance().texturePadding);
		}
		
		public function packTextures(width:uint, padding:uint):void
		{
			TextureUtil.packTextures(
				width, 
				padding, 
				_textureAtlasXML
			);
		}
		
		public function addXML(xml:XML):void
		{
			var xmlList1:XMLList;
			var xmlList2:XMLList;
			var node1:XML;
			var node2:XML;
			var nodeName:String;
			
			xmlList1 = getDisplayXMLList(_xml);
			xmlList2 = getDisplayXMLList(xml);
			var displayNames:Object = {};
			for each(node2 in xmlList2)
			{
				nodeName = node2.@[ConstValues.A_NAME];
				if(displayNames[nodeName])
				{
					continue;
				}
				displayNames[nodeName] = true;
				var sameDisplayXMLList:XMLList = xmlList1.(@[ConstValues.A_NAME] == nodeName);
				for each(node1 in sameDisplayXMLList)
				{
					//
					node1.parent().children()[node1.childIndex()] = node2.copy();
				}
			}
			
			xmlList1 = getArmatureXMLList(_xml);
			xmlList2 = getArmatureXMLList(xml);
			for each(node2 in xmlList2)
			{
				nodeName = node2.@[ConstValues.A_NAME];
				node1 = xmlList1.(@[ConstValues.A_NAME] == nodeName)[0];
				if(node1)
				{
					delete xmlList1[node1.childIndex()];
				}
				_xml[ConstValues.ARMATURES].appendChild(node2);
			}
			
			xmlList1 = getAnimationsXMLList(_xml);
			xmlList2 = getAnimationsXMLList(xml);
			for each(node2 in xmlList2)
			{
				nodeName = node2.@[ConstValues.A_NAME];
				node1 = xmlList1.(@[ConstValues.A_NAME] == nodeName)[0];
				if(node1)
				{
					delete xmlList1[node1.childIndex()];
				}
				_xml[ConstValues.ANIMATIONS].appendChild(node2);
			}
		}
		
		public function addSubTextureXML(subTextureXML:XML):void
		{
			var subTextureName:String = subTextureXML.@[ConstValues.A_NAME];
			var subTextureXMLList:XMLList = getSubTextureXMLList(_textureAtlasXML);
			var oldSubTextureXML:XML = subTextureXMLList.(@[ConstValues.A_NAME] == subTextureName)[0];
			if(oldSubTextureXML)
			{
				delete subTextureXMLList[oldSubTextureXML.childIndex()];
			}
			
			_textureAtlasXML.appendChild(subTextureXML);
		}
		
		public function removeArmature(armatureName:String):Boolean
		{
			var displayXMLList:XMLList = getDisplayXMLList(_xml);
			if(displayXMLList.(@[ConstValues.A_NAME] == armatureName)[0])
			{
				return false;
			}
			var armatureXMLList:XMLList = getArmatureXMLList(_xml);
			if(armatureXMLList.length() <= 1)
			{
				return false;
			}
			
			var armatureXML:XML = getArmatureXML(armatureName);
			if(armatureXML)
			{
				delete armatureXMLList[armatureXML.childIndex()];
				
				var animationXML:XML = getAnimationsXML(armatureName);
				if(animationXML)
				{
					var animationXMLList:XMLList = getAnimationsXMLList(_xml);
					delete animationXMLList[animationXML.childIndex()];
				}
				
				var deleteDisplayList:XMLList = armatureXML[ConstValues.BONE][ConstValues.DISPLAY];
				
				for each(var displayXML:XML in deleteDisplayList)
				{
					var isArmature:Boolean = displayXML.@[ConstValues.A_IS_ARMATURE] == "1";
					if(isArmature)
					{
						var childArmatureName:String = displayXML.@[ConstValues.A_NAME];
						var remainDisplayList:XMLList = getDisplayXMLList(_xml);
						
						if(!displayXMLList.(@[ConstValues.A_NAME] == childArmatureName)[0])
						{
							removeArmature(childArmatureName);
						}
					}
				}
				
				displayXMLList = getDisplayXMLList(_xml);
				
				var subTextureXMLLisst:XMLList = getSubTextureXMLList(_textureAtlasXML);
				for(var i:int = subTextureXMLLisst.length() - 1;i >= 0;i --)
				{
					var subTextureXML:XML = subTextureXMLLisst[i];
					var subTextureName:String = subTextureXML.@[ConstValues.A_NAME];
					if(!displayXMLList.(@[ConstValues.A_NAME] == subTextureName)[0])
					{
						delete subTextureXMLLisst[i];
					}
				}
				
				packTextures(SettingDataProxy.getInstance().textureMaxWidth, SettingDataProxy.getInstance().texturePadding);
				return true;
			}
			return false;
		}
		
		public function modifySubTextureSize(rectList:Vector.<Rectangle>):XML
		{
			var rectDic:Object = {};
			var subTextureXMLDic:Object = {};
			var subTextureXMLLisst:XMLList = getSubTextureXMLList(_textureAtlasXML);
			for(var i:int = subTextureXMLLisst.length() - 1;i >= 0;i --)
			{
				var subTextureXML:XML = subTextureXMLLisst[i];
				var subTextureName:String = subTextureXML.@[ConstValues.A_NAME];
				subTextureXMLDic[subTextureName] = subTextureXML;
				if(rectList)
				{
					var rect:Rectangle = rectList[i];
					rectDic[subTextureName] = rect;
					subTextureXML.@[ConstValues.A_WIDTH] = Math.ceil(rect.width);
					subTextureXML.@[ConstValues.A_HEIGHT] = Math.ceil(rect.height);
				}
			}
			
			for each(var displayXML:XML in getDisplayXMLList(_xml))
			{
				subTextureName = displayXML.@[ConstValues.A_NAME];
				rect = rectDic[subTextureName];
				if(rect)
				{
					displayXML.@[ConstValues.A_PIVOT_X] = -rect.x;
					displayXML.@[ConstValues.A_PIVOT_Y] = -rect.y;
				}
				subTextureXML = subTextureXMLDic[subTextureName];
				if(subTextureXML)
				{
					subTextureXML.@[ConstValues.A_PIVOT_X] = displayXML.@[ConstValues.A_PIVOT_X];
					subTextureXML.@[ConstValues.A_PIVOT_Y] = displayXML.@[ConstValues.A_PIVOT_Y];
				}
			}
			
			if(rectList)
			{
				packTextures(SettingDataProxy.getInstance().textureMaxWidth, SettingDataProxy.getInstance().texturePadding);
			}
			
			var textureAtlasXMLCopy:XML = _textureAtlasXML.copy();
			delete subTextureXMLLisst.@[ConstValues.A_PIVOT_X];
			delete subTextureXMLLisst.@[ConstValues.A_PIVOT_Y];
			
			return textureAtlasXMLCopy;
		}
		
		public function copy():XMLDataProxy
		{
			var proxy:XMLDataProxy = new XMLDataProxy();
			proxy.xml = _xml.copy();
			proxy.textureAtlasXML = _textureAtlasXML.copy();
			return proxy;
		}
		
		public function changeBoneParent(armatureName:String, boneName:String, parentName:String):void
		{
			var boneXML:XML = getBoneXML(armatureName, boneName);
			if(parentName)
			{
				boneXML.@[ConstValues.A_PARENT] = parentName;
			}
			else
			{
				delete boneXML.@[ConstValues.A_PARENT];
			}
		}
		
		public function changeBoneTree(armatureData:ArmatureData):void
		{
			var armatureXML:XML = getArmatureXML(armatureData.name);
			for each(var boneXML:XML in armatureXML[ConstValues.BONE])
			{
				var boneName:String = boneXML.@[ConstValues.A_NAME];
				var boneData:BoneData = armatureData.getBoneData(boneName);
				if(boneData)
				{
					var parentName:String = boneData.parent;
					if(parentName)
					{
						boneXML.@[ConstValues.A_PARENT] = parentName;
					}
					else
					{
						delete boneXML.@[ConstValues.A_PARENT];
					}
				}
			}
		}
		
		public function addAnimationToArmature(sourceAnimationData:AnimationData, sourceArmatureData:ArmatureData, targetArmatureData:ArmatureData):void
		{
			var animationsXML:XML = getAnimationsXML(sourceArmatureData.name);
			var animationXML:XML = getAnimationXML(sourceArmatureData.name, sourceAnimationData.name).copy();
			
			var timelineXMLList:XMLList = animationXML[ConstValues.BONE];
			var i:int = timelineXMLList.length();
			
			var timelineXML:XML;
			var timelineName:String;
			var targetBoneData:BoneData;
			var transformTimeline:TransformTimeline;
			var frameXMLList:XMLList;
			var j:int;
			var frameXMLListLength:uint;
			var frameXML:XML;
			var frame:TransformFrame;
			while(i --)
			{
				timelineXML = timelineXMLList[i];
				timelineName = timelineXML.@[ConstValues.A_NAME];
				targetBoneData = targetArmatureData.getBoneData(timelineName);
				if(targetBoneData)
				{
					transformTimeline = sourceAnimationData.getTimeline(timelineName);
					frameXMLList = timelineXML[ConstValues.FRAME];
					frameXMLListLength = frameXMLList.length();
					for(j = 0;i < frameXMLListLength;j ++)
					{
						frameXML = frameXMLList[i];
						frame = transformTimeline.frameList[i] as TransformFrame;
						
						_helpTransform.x = targetBoneData.global.x + frame.transform.x;
						_helpTransform.y = targetBoneData.global.y + frame.transform.y;
						_helpTransform.skewX = targetBoneData.global.skewX + frame.transform.skewX;
						_helpTransform.skewY = targetBoneData.global.skewY + frame.transform.skewY;
						_helpTransform.scaleX = targetBoneData.global.scaleX + frame.transform.scaleX;
						_helpTransform.scaleY = targetBoneData.global.scaleY + frame.transform.scaleY;
						
						//frame.pivot
						
						frameXML.@[ConstValues.A_X] = _helpTransform.x;
						frameXML.@[ConstValues.A_Y] = _helpTransform.y;
						frameXML.@[ConstValues.A_SKEW_X] = _helpTransform.skewX * RADIAN_TO_ANGLE;
						frameXML.@[ConstValues.A_SKEW_Y] = _helpTransform.skewY * RADIAN_TO_ANGLE;
						frameXML.@[ConstValues.A_SCALE_X] = _helpTransform.scaleX;
						frameXML.@[ConstValues.A_SCALE_Y] = _helpTransform.scaleY;
						
						//frameXML.@[ConstValues.A_PIVOT_X] = frameNode.pivotX;
						//frameXML.@[ConstValues.A_PIVOT_Y] = frameNode.pivotY;
					}
				}
				else
				{
					delete timelineXMLList[i];
				}
			}
			
			animationsXML.appendChild(animationXML);
		}
		
		public function changeAnimationData(armatureData:ArmatureData, animationName:String):void
		{
			var animationData:AnimationData = armatureData.getAnimationData(animationName);
			var movementXML:XML = getAnimationXML(armatureData.name, animationName);
			movementXML.@[ConstValues.A_DURATION_TO] = Math.round(animationData.fadeTime * animationData.frameRate);
			movementXML.@[ConstValues.A_DURATION_TWEEN] = Math.round(animationData.duration * animationData.scale * animationData.frameRate);
			movementXML.@[ConstValues.A_LOOP] = animationData.loop == 0?1:0;
			movementXML.@[ConstValues.A_TWEEN_EASING] = animationData.tweenEasing;
		}
		
		public function changeTransformTimelineData(armatureData:ArmatureData, animationName:String, boneName:String):void
		{
			var animationData:AnimationData = armatureData.getAnimationData(animationName);
			var transformTimeline:TransformTimeline = animationData.getTimeline(boneName) as TransformTimeline;
			var movementXML:XML = getAnimationXML(armatureData.name, animationName);
			var movementBoneXML:XML = movementXML[ConstValues.BONE].(@[ConstValues.A_NAME] == boneName)[0];
			movementBoneXML.@[ConstValues.A_MOVEMENT_SCALE] = transformTimeline.scale;
			movementBoneXML.@[ConstValues.A_MOVEMENT_DELAY] = transformTimeline.offset;
		}
		
		private function formatNumber(num:Number, retain:uint = 100):Number
		{
			retain = retain || 100;
			return Math.round(num * retain) / retain;
		}
		
		private function getAnimationsXML(animationName:String):XML
		{
			return getAnimationsXMLList(_xml).(@[ConstValues.A_NAME] == animationName)[0];
		}
		
		private static function getArmatureXMLList(xml:XML):XMLList
		{
			return xml[ConstValues.ARMATURES][ConstValues.ARMATURE];
		}
		
		private static function getAnimationsXMLList(xml:XML):XMLList
		{
			return xml[ConstValues.ANIMATIONS][ConstValues.ANIMATION];
		}
		
		private static function getDisplayXMLList(xml:XML):XMLList
		{
			return xml[ConstValues.ARMATURES][ConstValues.ARMATURE][ConstValues.BONE][ConstValues.DISPLAY];
		}
		
		private static function getSubTextureXMLList(textureAtlasXML:XML):XMLList
		{
			return textureAtlasXML[ConstValues.SUB_TEXTURE];
		}
	}
}