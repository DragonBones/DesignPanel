package model
{
	import dragonBones.core.DBObject;
	import dragonBones.core.DragonBones;
	import dragonBones.objects.AnimationData;
	import dragonBones.objects.ArmatureData;
	import dragonBones.objects.BoneData;
	import dragonBones.objects.DBTransform;
	import dragonBones.objects.DisplayData;
	import dragonBones.objects.TransformFrame;
	import dragonBones.objects.TransformTimeline;
	import dragonBones.utils.ConstValues;
	import dragonBones.utils.DBDataUtil;
	import dragonBones.utils.TransformUtil;
	
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	
	import utils.TextureUtil;
	import utils.formatDataToCurrentVersion;
	
	public class XMLDataProxy
	{
		private static const RADIAN_TO_ANGLE:Number =  180 / Math.PI;
		
		private static const _helpTransform:DBTransform = new DBTransform();
		
		private static const _helpMatrix:Matrix = new Matrix();
		
		private var _xml:XML
		public function get xml():XML
		{
			return _xml;
		}
		public function set xml(value:XML):void
		{
			_xml = formatXML(value);
		}
		
		private var _textureAtlasXML:XML;
		public function get textureAtlasXML():XML
		{
			return _textureAtlasXML;
		}
		public function set textureAtlasXML(value:XML):void
		{
			_textureAtlasXML = value;
			//
			delete _textureAtlasXML.@[ConstValues.A_WIDTH];
			delete _textureAtlasXML.@[ConstValues.A_HEIGHT];
		}
		private var _width:uint;
		public function get textureAtlasWidth():uint
		{
			return _width;
		}
		
		private var _height:uint;
		public function get textureAtlasHeight():uint
		{
			return _height;
		}
		
		public function XMLDataProxy()
		{
			
		}
		
		/*
		public function moveTexturePivotToData():void
		{
			var subTextureXMLList:XMLList = getSubTextureXMLList();
			var subTextureXML:XML = subTextureXMLList[0];
			var displayXMLList:XMLList;
			var subTextureName:String;
			var pivotX:int;
			var pivotY:int;
			if(subTextureXML && subTextureXML.@[ConstValues.A_PIVOT_X].length() > 0)
			{
				displayXMLList = getDisplayXMLList(_xml);
				for each(subTextureXML in subTextureXMLList)
				{
					subTextureName = subTextureXML.@[ConstValues.A_NAME];
					pivotX = int(subTextureXML.@[ConstValues.A_PIVOT_X]);
					pivotY = int(subTextureXML.@[ConstValues.A_PIVOT_Y]);
					
					delete subTextureXML.@[ConstValues.A_PIVOT_X];
					delete subTextureXML.@[ConstValues.A_PIVOT_Y];
					for each(var displayXML:XML in displayXMLList)
					{
						var displayName:String = displayXML.@[ConstValues.A_NAME];
						if(displayName == subTextureName)
						{
							displayXML[ConstValues.TRANSFORM].@[ConstValues.A_PIVOT_X] = pivotX;
							displayXML[ConstValues.TRANSFORM].@[ConstValues.A_PIVOT_Y] = pivotY;
						}
					}
				}
				setVersion();
			}
		}
		*/
		
		public function setVersion():void
		{
			_xml.@[ConstValues.A_VERSION] = DragonBones.DATA_VERSION;
		}
		
		public function getArmatureXMLList(armatureName:String = null):XMLList
		{
			if(armatureName)
			{
				return getArmatureXMLList().(@[ConstValues.A_NAME] == armatureName);
			}
			return _xml[ConstValues.ARMATURE];
		}
		
		public function getBoneXMLList(armatureName:String = null, boneName:String = null):XMLList
		{
			if(boneName)
			{
				return getBoneXMLList(armatureName).(@[ConstValues.A_NAME] == boneName);
			}
			return getArmatureXMLList(armatureName)[ConstValues.BONE];
		}
		
		public function getSkinXMLList(armatureName:String = null, skinName:String = null):XMLList
		{
			if(skinName)
			{
				return getSkinXMLList(armatureName).(@[ConstValues.A_NAME] == skinName);
			}
			return getArmatureXMLList(armatureName)[ConstValues.SKIN];
		}
		
		public function getSlotXMLList(armatureName:String = null, skinName:String = null, slotName:String = null):XMLList
		{
			if(slotName)
			{
				return getSlotXMLList(armatureName, skinName).(@[ConstValues.A_NAME] == skinName);
			}
			return getSkinXMLList(armatureName, skinName)[ConstValues.SLOT];
		}
		
		public function getDisplayXMLList(armatureName:String = null, skinName:String = null, slotName:String = null, displayName:String = null):XMLList
		{
			if(displayName)
			{
				return getDisplayXMLList(armatureName, skinName, slotName).(@[ConstValues.A_NAME] == displayName);
			}
			return getSlotXMLList(armatureName, skinName, slotName)[ConstValues.DISPLAY];
		}
		
		public function getAnimationXMLList(armatureName:String = null, animationName:String = null):XMLList
		{
			if(animationName)
			{
				return getAnimationXMLList(armatureName).(@[ConstValues.A_NAME] == animationName);
			}
			return getArmatureXMLList(armatureName)[ConstValues.ANIMATION];
		}
		
		public function getTimelineXMLList(armatureName:String = null, animationName:String = null, timelineName:String = null):XMLList
		{
			if(timelineName)
			{
				return getTimelineXMLList(armatureName, animationName).(@[ConstValues.A_NAME] == timelineName);
			}
			return getAnimationXMLList(armatureName, animationName)[ConstValues.TIMELINE];
		}
		
		public function getSubTextureXMLList(subTextureName:String = null):XMLList
		{
			if(subTextureName)
			{
				return getSubTextureXMLList().(@[ConstValues.A_NAME] == subTextureName);
			}
			return _textureAtlasXML[ConstValues.SUB_TEXTURE];
		}
		
		public function getSubTextureListFromDisplayList():Vector.<String>
		{
			var displayList:Vector.<String> = new Vector.<String>;
			
			for each(var displayXML:XML in getDisplayXMLList())
			{
				if(displayXML.@[ConstValues.A_TYPE] == DisplayData.IMAGE)
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
		
		public function scaleData(scale:Number):void
		{
			var boneTransformXMLList:XMLList = getBoneXMLList()[ConstValues.TRANSFORM];
			scaleXMLList(boneTransformXMLList, scale);
			
			var displayTransformXMLList:XMLList = getDisplayXMLList()[ConstValues.TRANSFORM];
			scaleXMLList(displayTransformXMLList, scale);
			
			var frameTransformXMLList:XMLList = getTimelineXMLList()[ConstValues.FRAME][ConstValues.TRANSFORM];
			scaleXMLList(frameTransformXMLList, scale);
			
			var subTextureTransformXMLList:XMLList = getSubTextureXMLList();
			scaleXMLList(subTextureTransformXMLList, scale);
			
			updateTextureAtlas(getSubTextureRectMap());
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
		
		public function changePath():void
		{
			for each(var displayXML:XML in getDisplayXMLList())
			{
				var subTextureName:String = displayXML.@[ConstValues.A_NAME];
				subTextureName = subTextureName.split("/").join("-");
				displayXML.@[ConstValues.A_NAME] = subTextureName;
			}
			
			for each(var subTextureXML:XML in getSubTextureXMLList())
			{
				subTextureName = subTextureXML.@[ConstValues.A_NAME];
				subTextureName = subTextureName.split("/").join("-");
				subTextureXML.@[ConstValues.A_NAME] = subTextureName;
			}
		}
		
		public function addArmatureXML(armatureXML:XML):void
		{
			var armatureName:String = armatureXML.@[ConstValues.A_NAME];
			var oldArmatureXML:XML = getArmatureXMLList(armatureName)[0];
			if(oldArmatureXML)
			{
				delete getArmatureXMLList()[oldArmatureXML.childIndex()];
			}
			
			var displayXMLList:XMLList = getDisplayXMLList();
			
			_xml.appendChild(armatureXML);
			
			var armatureDisplayMap:Object = {};
			var displayName:String;
			for each(var displayXML:XML in getDisplayXMLList(armatureName))
			{
				displayName = displayXML.@[ConstValues.A_NAME];
				armatureDisplayMap[displayName] = displayXML;
			}
			
			for each(var exDisplayXML:XML in displayXMLList)
			{
				displayName = exDisplayXML.@[ConstValues.A_NAME];
				displayXML = armatureDisplayMap[displayName];
				if(displayXML)
				{
					exDisplayXML.@[ConstValues.A_TYPE] = displayXML.@[ConstValues.A_TYPE];
					exDisplayXML[ConstValues.TRANSFORM][0].@[ConstValues.A_PIVOT_X] = displayXML[ConstValues.TRANSFORM][0].@[ConstValues.A_PIVOT_X];
					exDisplayXML[ConstValues.TRANSFORM][0].@[ConstValues.A_PIVOT_Y] = displayXML[ConstValues.TRANSFORM][0].@[ConstValues.A_PIVOT_Y];
				}
			}
		}
		
		public function addSubTextureXML(subTextureXML:XML):void
		{
			var oldSubTextureXML:XML = getSubTextureXMLList(subTextureXML.@[ConstValues.A_NAME])[0];
			if(oldSubTextureXML)
			{
				delete getSubTextureXMLList()[oldSubTextureXML.childIndex()];
			}
			
			_textureAtlasXML.appendChild(subTextureXML);
		}
		
		public function removeArmature(armatureName:String):Boolean
		{
			var armatureXMLList:XMLList = getArmatureXMLList();
			if(armatureXMLList.length() <= 1)
			{
				return false;
			}
			if(getDisplayXMLList(null, null, null, armatureName)[0])
			{
				return false;
			}
			
			var armatureXML:XML = getArmatureXMLList(armatureName)[0];
			if(armatureXML)
			{
				delete armatureXMLList[armatureXML.childIndex()];
				
				var deleteDisplayList:XMLList = getDisplayXMLList(armatureName);
				for each(var displayXML:XML in deleteDisplayList)
				{
					if(displayXML.@[ConstValues.A_TYPE] == DisplayData.ARMATURE)
					{
						var childArmatureName:String = displayXML.@[ConstValues.A_NAME];
						//
						if(!getDisplayXMLList(null, null, null, childArmatureName)[0])
						{
							removeArmature(childArmatureName);
						}
					}
				}
				
				var subTextureXMLLisst:XMLList = getSubTextureXMLList();
				var i:int = subTextureXMLLisst.length(); 
				while(i --)
				{
					var subTextureXML:XML = subTextureXMLLisst[i];
					var subTextureName:String = subTextureXML.@[ConstValues.A_NAME];
					if(!getDisplayXMLList(null, null, null, subTextureName)[0])
					{
						delete subTextureXMLLisst[i];
					}
				}
				
				updateTextureAtlas(getSubTextureRectMap());
				return true;
			}
			return false;
		}
		
		public function merge(xmlDataProxy:XMLDataProxy):void
		{
			for each(var armatureXML:XML in xmlDataProxy.getArmatureXMLList())
			{
				addArmatureXML(armatureXML);
			}
			
			for each(var subTextureXML:XML in xmlDataProxy.getSubTextureXMLList())
			{
				addSubTextureXML(subTextureXML);
			}
			
			updateTextureAtlas(getSubTextureRectMap());
		}
		
		public function clone():XMLDataProxy
		{
			var proxy:XMLDataProxy = new XMLDataProxy();
			proxy.xml = _xml.copy();
			proxy.textureAtlasXML = _textureAtlasXML.copy();
			return proxy;
		}
		
		public function createTextureAtlas(rectMap:Object, subTextureList:Vector.<String> = null):void
		{
			_textureAtlasXML = <{ConstValues.TEXTURE_ATLAS} {ConstValues.A_NAME}={_xml.@[ConstValues.A_NAME]}/>;
			
			var subTextureName:String;
			var subTextureXML:XML;
			if(subTextureList)
			{
				for each(subTextureName in subTextureList)
				{
					subTextureXML = <{ConstValues.SUB_TEXTURE} {ConstValues.A_NAME}={subTextureName}/>;
					_textureAtlasXML.appendChild(subTextureXML);
				}
			}
			else
			{
				for(subTextureName in rectMap)
				{
					subTextureXML = <{ConstValues.SUB_TEXTURE} {ConstValues.A_NAME}={subTextureName}/>;
					_textureAtlasXML.appendChild(subTextureXML);
				}
			}
			
			updateTextureAtlas(rectMap);
		}
		
		public function updateDisplayPivot(rectMap:Object):void
		{
			for each(var displayXML:XML in getDisplayXMLList())
			{
				var displayName:String = displayXML.@[ConstValues.A_NAME];
				var rect:Rectangle = rectMap[displayName];
				if(rect)
				{
					displayXML[ConstValues.TRANSFORM][0].@[ConstValues.A_PIVOT_X] = -rect.x;
					displayXML[ConstValues.TRANSFORM][0].@[ConstValues.A_PIVOT_Y] = -rect.y;
				}
			}
		}
		
		public function updateTextureAtlas(rectMap:Object):void
		{
			var area:Rectangle = TextureUtil.packTextures(
				SettingDataProxy.getInstance().textureMaxWidth,
				SettingDataProxy.getInstance().texturePadding,
				rectMap
			);
			
			var subTextureXMLList:XMLList = getSubTextureXMLList();
			var subTextureXML:XML;
			var subTextureName:String;
			var rect:Rectangle;
			var i:int = subTextureXMLList.length();
			while(i --)
			{
				subTextureXML = subTextureXMLList[i];
				subTextureName = subTextureXML.@[ConstValues.A_NAME];
				rect = rectMap[subTextureName];
				if(rect)
				{
					subTextureXML.@[ConstValues.A_X] = rect.x;
					subTextureXML.@[ConstValues.A_Y] = rect.y;
					subTextureXML.@[ConstValues.A_WIDTH] = Math.ceil(rect.width);
					subTextureXML.@[ConstValues.A_HEIGHT] = Math.ceil(rect.height);
				}
				else
				{
					delete subTextureXMLList[i];
				}
			}
			
			_width = area.width;
			_height = area.height;
		}
		
		public function getTextureAtlasXMLWithPivot():XML
		{
			var textureAtlasXMLCopy:XML = _textureAtlasXML.copy();
			var subTextureXMLDic:Object = {};
			for each(var subTextureXML:XML in textureAtlasXMLCopy[ConstValues.SUB_TEXTURE])
			{
				var subTextureName:String = subTextureXML.@[ConstValues.A_NAME];
				subTextureXMLDic[subTextureName] = subTextureXML;
			}
			
			for each(var displayXML:XML in getDisplayXMLList())
			{
				subTextureName = displayXML.@[ConstValues.A_NAME];
				subTextureXML = subTextureXMLDic[subTextureName];
				if(subTextureXML)
				{
					subTextureXML.@[ConstValues.A_PIVOT_X] = displayXML[ConstValues.TRANSFORM][0].@[ConstValues.A_PIVOT_X];
					subTextureXML.@[ConstValues.A_PIVOT_Y] = displayXML[ConstValues.TRANSFORM][0].@[ConstValues.A_PIVOT_Y];
				}
			}
			
			return textureAtlasXMLCopy;
		}
		
		public function getSubTextureRectMap():Object
		{
			var subTextureRectDic:Object = {};
			var subTextureXMLList:XMLList = getSubTextureXMLList();
			for each(var subTextureXML:XML in subTextureXMLList)
			{
				var rect:Rectangle = new Rectangle(
					int(subTextureXML.@[ConstValues.A_X]),
					int(subTextureXML.@[ConstValues.A_Y]),
					int(subTextureXML.@[ConstValues.A_WIDTH]),
					int(subTextureXML.@[ConstValues.A_HEIGHT])
				);
				var subTextureName:String = subTextureXML.@[ConstValues.A_NAME];
				subTextureRectDic[subTextureName] = rect;
			}
			return subTextureRectDic;
		}
		
		public function changeBoneParent(armatureName:String, boneName:String, parentName:String):void
		{
			var boneXML:XML = getBoneXMLList(armatureName, boneName)[0];
			if(!boneXML)
			{
				return;
			}
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
			var armatureXML:XML = getArmatureXMLList(armatureData.name)[0];
			if(!armatureXML)
			{
				return;
			}
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
		
		public function copyAnimationToArmature(sourceAnimationData:AnimationData, sourceArmatureData:ArmatureData, targetArmatureData:ArmatureData):XML
		{
			var animationXML:XML = getAnimationXMLList(sourceArmatureData.name, sourceAnimationData.name)[0].copy();
			var timelineXMLList:XMLList = animationXML[ConstValues.TIMELINE];
			var boneDataList:Vector.<BoneData> = sourceArmatureData.boneDataList;
			
			var boneName:String;
			var timelineXML:XML;
			var sourceBoneData:BoneData;
			var targetBoneData:BoneData;
			var transformTimeline:TransformTimeline;
			var parentTimeline:TransformTimeline;
			var frameXMLList:XMLList;
			var j:int;
			var frameXMLListLength:uint;
			var frameXML:XML;
			var frame:TransformFrame;
			
			var pivotX:Number;
			var pivotY:Number;
			
			for(var i:int = 0;i < boneDataList.length;i ++)
			{
				sourceBoneData = boneDataList[i];
				boneName = sourceBoneData.name;
				timelineXML = timelineXMLList.(@[ConstValues.A_NAME] == boneName)[0];
				targetBoneData = targetArmatureData.getBoneData(boneName);
				if(targetBoneData)
				{
					transformTimeline = sourceAnimationData.getTimeline(boneName);
					frameXMLList = timelineXML[ConstValues.FRAME];
					frameXMLListLength = frameXMLList.length();
					
					if(sourceBoneData.parent)
					{
						parentTimeline = sourceAnimationData.getTimeline(sourceBoneData.parent);
					}
					else
					{
						parentTimeline = null;
					}
					
					for(j = 0;j < frameXMLListLength;j ++)
					{
						frameXML = frameXMLList[j];
						frame = transformTimeline.frameList[j] as TransformFrame;
						
						frame.global.x = targetBoneData.transform.x + transformTimeline.originTransform.x + frame.transform.x;
						frame.global.y = targetBoneData.transform.y + transformTimeline.originTransform.y + frame.transform.y;
						frame.global.skewX = targetBoneData.transform.skewX + transformTimeline.originTransform.skewX + frame.transform.skewX;
						frame.global.skewY = targetBoneData.transform.skewY + transformTimeline.originTransform.skewY + frame.transform.skewY;
						frame.global.scaleX = targetBoneData.transform.scaleX + transformTimeline.originTransform.scaleX + frame.transform.scaleX;
						frame.global.scaleY = targetBoneData.transform.scaleY + transformTimeline.originTransform.scaleY + frame.transform.scaleY;
						pivotX = targetBoneData.pivot.x + transformTimeline.originPivot.x + frame.pivot.x;
						pivotY = targetBoneData.pivot.y + transformTimeline.originPivot.y + frame.pivot.y;
						
						if(parentTimeline)
						{
							DBDataUtil.getTimelineTransform(parentTimeline, frame.position, _helpTransform);
							
							var x:Number = frame.global.x;
							var y:Number = frame.global.y;
							
							TransformUtil.transformToMatrix(_helpTransform, _helpMatrix);
							
							frame.global.x = _helpMatrix.a * x + _helpMatrix.c * y + _helpMatrix.tx;
							frame.global.y = _helpMatrix.d * y + _helpMatrix.b * x + _helpMatrix.ty;
							
							frame.global.skewX += _helpTransform.skewX;
							frame.global.skewY += _helpTransform.skewY;
						}
						
						frameXML.@[ConstValues.A_X] = frame.global.x;
						frameXML.@[ConstValues.A_Y] = frame.global.y;
						frameXML.@[ConstValues.A_SKEW_X] = frame.global.skewX * RADIAN_TO_ANGLE;
						frameXML.@[ConstValues.A_SKEW_Y] = frame.global.skewY * RADIAN_TO_ANGLE;
						frameXML.@[ConstValues.A_SCALE_X] = frame.global.scaleX;
						frameXML.@[ConstValues.A_SCALE_Y] = frame.global.scaleY;
						frameXML.@[ConstValues.A_PIVOT_X] = pivotX;
						frameXML.@[ConstValues.A_PIVOT_Y] = pivotY;
					}
				}
				else
				{
					delete timelineXMLList[timelineXML.childIndex()];
				}
			}
			
			var armatureXML:XML = getArmatureXMLList(targetArmatureData.name)[0];
			armatureXML.appendChild(animationXML);
			
			return animationXML;
		}
		
		public function changeAnimationData(armatureData:ArmatureData, animationName:String):void
		{
			var animationData:AnimationData = armatureData.getAnimationData(animationName);
			var animationXML:XML = getAnimationXMLList(armatureData.name, animationName)[0];
			animationXML.@[ConstValues.A_FADE_IN_TIME] = formatNumber(animationData.fadeInTime, 1000);
			animationXML.@[ConstValues.A_SCALE] = formatNumber(animationData.scale);
			animationXML.@[ConstValues.A_LOOP] = animationData.loop;
			animationXML.@[ConstValues.A_TWEEN_EASING] = formatNumber(animationData.tweenEasing);
		}
		
		public function changeTransformTimelineData(armatureData:ArmatureData, animationName:String, timelineName:String):void
		{
			var animationData:AnimationData = armatureData.getAnimationData(animationName);
			var transformTimeline:TransformTimeline = animationData.getTimeline(timelineName) as TransformTimeline;
			var timelineXML:XML = getTimelineXMLList(armatureData.name, animationName, timelineName)[0];
			timelineXML.@[ConstValues.A_SCALE] = formatNumber(transformTimeline.scale);
			timelineXML.@[ConstValues.A_OFFSET] = formatNumber(transformTimeline.offset);
		}
		
		private function formatNumber(num:Number, retain:uint = 100):Number
		{
			retain = retain || 100;
			return Math.round(num * retain) / retain;
		}
		
		private static function formatXML(xml:XML):XML
		{
			var version:String = xml.@[ConstValues.A_VERSION];
			switch(version)
			{
				case "1.4":
				case "1.5":
				case "2.0":
				case "2.1":
				case "2.1.1":
				case "2.1.2":
				case "2.2":
					return formatDataToCurrentVersion(xml);
				default:
					break;
			}
			
			return xml;
		}
	}
}