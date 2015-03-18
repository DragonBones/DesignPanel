package core.model
{
	import core.SettingManager;
	import core.model.vo.ImportVO;
	import core.suppotClass._BaseModel;
	import core.utils.GlobalConstValues;
	import core.utils.TextureUtil;
	import core.utils.formatDataToCurrentVersion;
	
	import dragonBones.core.DragonBones;
	import dragonBones.objects.AnimationData;
	import dragonBones.objects.ArmatureData;
	import dragonBones.objects.BoneData;
	import dragonBones.objects.DisplayData;
	import dragonBones.objects.TransformTimeline;
	import dragonBones.utils.ConstValues;
	
	import flash.geom.Rectangle;

	public final class ImportModel extends _BaseModel
	{
		private var _textureAtlasWidth:uint;
		public function get textureAtlasWidth():uint
		{
			return _textureAtlasWidth;
		}
		
		private var _textureAtlasHeight:uint;
		public function get textureAtlasHeight():uint
		{
			return _textureAtlasHeight;
		}
		
		private var _vo:ImportVO;
		public function get vo():ImportVO
		{
			return _vo;
		}
		public function set vo(value:ImportVO):void
		{
			if(_vo == value)
			{
				return;
			}
			_vo = value;
		}
		
		public function ImportModel()
		{
			
		}
		
		public function get name():String
		{
			return _vo.skeleton.@[ConstValues.A_NAME];
		}
		public function set name(value:String):void
		{
			_vo.name = value || name;
			_vo.skeleton.@[ConstValues.A_NAME] = _vo.name;
			
			if(_vo.textureAtlasConfig)
			{
				_vo.textureAtlasConfig.@[ConstValues.A_NAME] = _vo.name;
			}
		}
		
		public function get isGlobal():Boolean
		{
			var globalString:String = _vo.skeleton.@[ConstValues.A_IS_GLOBAL];
			return  globalString == "1" || globalString == "";
		}
		public function set isGlobal(value:Boolean):void
		{
			_vo.skeleton.@[ConstValues.A_IS_GLOBAL] = value ? "1" : "0";
		}
		
		public function get textureAtlasPath():String
		{
			return _vo.textureAtlasConfig.@[ConstValues.A_IMAGE_PATH];
		}
		public function set textureAtlasPath(value:String):void
		{
			_vo.textureAtlasConfig.@[ConstValues.A_IMAGE_PATH] = value;
		}
		
		public function getArmatureList(armatureName:String = null):XMLList
		{
			if(armatureName)
			{
				return getArmatureList().(@[ConstValues.A_NAME] == armatureName);
			}
			return _vo.skeleton[ConstValues.ARMATURE];
		}
		
		public function getBoneList(armatureName:String = null, boneName:String = null):XMLList
		{
			if(boneName)
			{
				return getBoneList(armatureName).(@[ConstValues.A_NAME] == boneName);
			}
			return getArmatureList(armatureName)[ConstValues.BONE];
		}
		
		public function getSkinList(armatureName:String = null, skinName:String = null):XMLList
		{
			if(skinName)
			{
				return getSkinList(armatureName).(@[ConstValues.A_NAME] == skinName);
			}
			return getArmatureList(armatureName)[ConstValues.SKIN];
		}
		
		public function getSlotList(armatureName:String = null, skinName:String = null, slotName:String = null):XMLList
		{
			if(slotName)
			{
				return getSlotList(armatureName, skinName).(@[ConstValues.A_NAME] == skinName);
			}
			return getSkinList(armatureName, skinName)[ConstValues.SLOT];
		}
		
		public function getDisplayList(armatureName:String = null, skinName:String = null, slotName:String = null, displayName:String = null):XMLList
		{
			if(displayName)
			{
				return getDisplayList(armatureName, skinName, slotName).(@[ConstValues.A_NAME] == displayName);
			}
			return getSlotList(armatureName, skinName, slotName)[ConstValues.DISPLAY];
		}
		
		public function getAnimationList(armatureName:String = null, animationName:String = null):XMLList
		{
			if(animationName)
			{
				return getAnimationList(armatureName).(@[ConstValues.A_NAME] == animationName);
			}
			return getArmatureList(armatureName)[ConstValues.ANIMATION];
		}
		
		public function getTimelineList(armatureName:String = null, animationName:String = null, timelineName:String = null):XMLList
		{
			if(timelineName)
			{
				return getTimelineList(armatureName, animationName).(@[ConstValues.A_NAME] == timelineName);
			}
			return getAnimationList(armatureName, animationName)[ConstValues.TIMELINE];
		}
		
		public function getSubTextureList(subTextureName:String = null):XMLList
		{
			if(subTextureName)
			{
				return getSubTextureList().(@[ConstValues.A_NAME] == subTextureName);
			}
			return _vo.textureAtlasConfig[ConstValues.SUB_TEXTURE];
		}
		
		public function getSubTextureListFromDisplayList():Vector.<String>
		{
			var displayList:Vector.<String> = new Vector.<String>;
			for each(var display:XML in getDisplayList())
			{
				if(display.@[ConstValues.A_TYPE] == DisplayData.IMAGE)
				{
					var displayName:String = display.@[ConstValues.A_NAME];
					if(displayList.indexOf(displayName) < 0)
					{
						displayList.push(displayName);
					}
				}
			}
			return displayList;
		}
		
		public function getTextureAtlasWithPivot():XML
		{
			var textureAtlasCopy:XML = _vo.textureAtlasConfig.copy();
			var subTextureMap:Object = {};
			var subTextureName:String;
			for each(var subTexture:XML in textureAtlasCopy[ConstValues.SUB_TEXTURE])
			{
				subTextureName = subTexture.@[ConstValues.A_NAME];
				subTextureMap[subTextureName] = subTexture;
			}
			
			for each(var display:XML in getDisplayList())
			{
				subTextureName = display.@[ConstValues.A_NAME];
				subTexture = subTextureMap[subTextureName];
				if(subTexture)
				{
					subTexture.@[ConstValues.A_PIVOT_X] = display[ConstValues.TRANSFORM][0].@[ConstValues.A_PIVOT_X];
					subTexture.@[ConstValues.A_PIVOT_Y] = display[ConstValues.TRANSFORM][0].@[ConstValues.A_PIVOT_Y];
				}
			}
			
			return textureAtlasCopy;
		}
		
		public function getSubTextureRectMap():Object
		{
			var subTextureRectMap:Object = {};
			var subTextureList:XMLList = getSubTextureList();
			for each(var subTexture:XML in subTextureList)
			{
				var rect:Rectangle = new Rectangle(
					int(subTexture.@[ConstValues.A_X]),
					int(subTexture.@[ConstValues.A_Y]),
					int(subTexture.@[ConstValues.A_WIDTH]),
					int(subTexture.@[ConstValues.A_HEIGHT])
				);
				
				var subTextureName:String = subTexture.@[ConstValues.A_NAME];
				subTextureRectMap[subTextureName] = rect;
			}
			return subTextureRectMap;
		}
		
		public function setVersion():void
		{
			_vo.skeleton.@[ConstValues.A_VERSION] = DragonBones.DATA_VERSION;
		}
		
		public function formatXML():void
		{
			_vo.name = name;
			_vo.dataType = isGlobal ? GlobalConstValues.DATA_TYPE_GLOBAL : GlobalConstValues.DATA_TYPE_PARENT;
			SettingManager.getInstance().updateSettingAfterImportData(_vo.dataType);
				
			var version:String = _vo.skeleton.@[ConstValues.A_VERSION];
			switch(version)
			{
				case "1.4":
				case "1.5":
				case "2.0":
				case "2.1":
				case "2.1.1":
				case "2.1.2":
				case "2.2":
					_vo.skeleton = formatDataToCurrentVersion(_vo.skeleton);
					setVersion();
					break;
				default:
					break;
			}
		}
		
		public function addArmature(armature:XML):void
		{
			var armatureName:String = armature.@[ConstValues.A_NAME];
			
			//删除已经存在的armature
			var armatureExisted:XML = getArmatureList(armatureName)[0];
			if(armatureExisted)
			{
				delete getArmatureList()[armatureExisted.childIndex()];
			}
			
			//备份所有display
			var displayList:XMLList = getDisplayList();
			
			//加入新的armature，并找到该armature使用的所有display
			_vo.skeleton.appendChild(armature);
			var armatureDisplayMap:Object = {};
			var displayName:String;
			for each(var display:XML in getDisplayList(armatureName))
			{
				displayName = display.@[ConstValues.A_NAME];
				armatureDisplayMap[displayName] = display;
			}
			
			for each(var displayExisted:XML in displayList)
			{
				displayName = displayExisted.@[ConstValues.A_NAME];
				display = armatureDisplayMap[displayName];
				if(display)
				{
					//更新display的类型和中心点，可能后续会有其他更多的属性更新
					displayExisted.@[ConstValues.A_TYPE] = display.@[ConstValues.A_TYPE];
					displayExisted[ConstValues.TRANSFORM][0].@[ConstValues.A_PIVOT_X] = display[ConstValues.TRANSFORM][0].@[ConstValues.A_PIVOT_X];
					displayExisted[ConstValues.TRANSFORM][0].@[ConstValues.A_PIVOT_Y] = display[ConstValues.TRANSFORM][0].@[ConstValues.A_PIVOT_Y];
				}
			}
		}
		
		public function removeArmatureByName(armatureName:String):Boolean
		{
			var armatureList:XMLList = getArmatureList();
			
			//只有一个armature则不能删除
			if(armatureList.length() <= 1)
			{
				return false;
			}
			
			//如果armature被当作display引用，则不能删除
			if(getDisplayList(null, null, null, armatureName)[0])
			{
				return false;
			}
			
			var armature:XML = getArmatureList(armatureName)[0];
			if(armature)
			{
				delete armatureList[armature.childIndex()];
				
				var displayList:XMLList = getDisplayList(armatureName);
				for each(var display:XML in displayList)
				{
					//找到该armature使用的子armature，一并删除
					if(display.@[ConstValues.A_TYPE] == DisplayData.ARMATURE)
					{
						var childArmatureName:String = display.@[ConstValues.A_NAME];
						//如果子armature没有被其他的armature引用，则删除
						if(!getDisplayList(null, null, null, childArmatureName)[0])
						{
							removeArmatureByName(childArmatureName);
						}
					}
				}
				
				var subTextureList:XMLList = getSubTextureList();
				var i:int = subTextureList.length(); 
				while(i --)
				{
					var subTexture:XML = subTextureList[i];
					var subTextureName:String = subTexture.@[ConstValues.A_NAME];
					//如果subTexture没有被其他display引用，则删除
					if(!getDisplayList(null, null, null, subTextureName)[0])
					{
						delete subTextureList[i];
					}
				}
				
				updateTextureAtlasFromRectMap(getSubTextureRectMap(), true);
				return true;
			}
			return false;
		}
		
		public function addSubTexture(subTexture:XML):void
		{
			var subTextureExisted:XML = getSubTextureList(subTexture.@[ConstValues.A_NAME])[0];
			if(subTextureExisted)
			{
				delete getSubTextureList()[subTextureExisted.childIndex()];
			}
			_vo.textureAtlasConfig.appendChild(subTexture);
		}
		
		public function updateDisplayPivot(rectMap:Object):void
		{
			for each(var display:XML in getDisplayList())
			{
				var displayName:String = display.@[ConstValues.A_NAME];
				var rect:Rectangle = rectMap[displayName];
				if(rect)
				{
					display[ConstValues.TRANSFORM][0].@[ConstValues.A_PIVOT_X] = -rect.x;
					display[ConstValues.TRANSFORM][0].@[ConstValues.A_PIVOT_Y] = -rect.y;
				}
			}
		}
		
		public function merge(importModel:ImportModel):void
		{
			for each(var armature:XML in importModel.getArmatureList())
			{
				addArmature(armature);
			}
			
			for each(var subTexture:XML in importModel.getSubTextureList())
			{
				addSubTexture(subTexture);
			}
			
			updateTextureAtlasFromRectMap(getSubTextureRectMap(), true);
		}
		
		public function createTextureAtlas(rectMap:Object, subTextureList:Vector.<String> = null, name:String = null):void
		{
			_vo.textureAtlasConfig = <{ConstValues.TEXTURE_ATLAS} {ConstValues.A_NAME}={_vo.skeleton?_vo.skeleton.@[ConstValues.A_NAME]:name}/>;
			
			var subTextureName:String;
			var subTexture:XML;
			if(subTextureList)
			{
				for each(subTextureName in subTextureList)
				{
					subTexture = <{ConstValues.SUB_TEXTURE} {ConstValues.A_NAME}={subTextureName}/>;
					_vo.textureAtlasConfig.appendChild(subTexture);
				}
			}
			else
			{
				for(subTextureName in rectMap)
				{
					subTexture = <{ConstValues.SUB_TEXTURE} {ConstValues.A_NAME}={subTextureName}/>;
					_vo.textureAtlasConfig.appendChild(subTexture);
				}
			}
			
			updateTextureAtlasFromRectMap(rectMap);
		}
		
		public function updateTextureAtlasFromRectMap(rectMap:Object, autoSize:Boolean = false):void
		{
			var area:Rectangle = TextureUtil.packTextures(
				autoSize?0:_vo.textureAtlasWidth,
				_vo.textureAtlasPadding,
				rectMap
			);
			
			var subTextureList:XMLList = getSubTextureList();
			var subTexture:XML;
			var subTextureName:String;
			var rect:Rectangle;
			var i:int = subTextureList.length();
			while(i --)
			{
				subTexture = subTextureList[i];
				subTextureName = subTexture.@[ConstValues.A_NAME];
				rect = rectMap[subTextureName];
				if(rect && rect.width * rect.height > 0)
				{
					subTexture.@[ConstValues.A_X] = rect.x;
					subTexture.@[ConstValues.A_Y] = rect.y;
					subTexture.@[ConstValues.A_WIDTH] = Math.ceil(rect.width);
					subTexture.@[ConstValues.A_HEIGHT] = Math.ceil(rect.height);
				}
				else
				{
					delete subTextureList[i];
				}
			}
			
			_textureAtlasWidth = area.width;
			_textureAtlasHeight = area.height;
		}
		
		public function scaleData(scale:Number):void
		{
			var boneTransformList:XMLList = getBoneList()[ConstValues.TRANSFORM];
			scaleList(boneTransformList, scale);
			
			var displayTransformList:XMLList = getDisplayList()[ConstValues.TRANSFORM];
			scaleList(displayTransformList, scale);
			
			var frameTransformList:XMLList = getTimelineList()[ConstValues.FRAME][ConstValues.TRANSFORM];
			scaleList(frameTransformList, scale);
			
			var subTextureTransformList:XMLList = getSubTextureList();
			scaleList(subTextureTransformList, scale);
			
			updateTextureAtlasFromRectMap(getSubTextureRectMap(), true);
		}
		
		public function changeBoneParent(armatureName:String, boneName:String, boneParentName:String):void
		{
			var bone:XML = getBoneList(armatureName, boneName)[0];
			if(!bone)
			{
				return;
			}
			if(boneParentName)
			{
				var parent:XML = getBoneList(armatureName, boneParentName)[0];
				if(parent && String(parent.@[ConstValues.A_PARENT]) == boneName)
				{
					if(bone.@[ConstValues.A_PARENT].length() > 0)
					{
						parent.@[ConstValues.A_PARENT] = bone.@[ConstValues.A_PARENT];
					}
					else
					{
						delete parent.@[ConstValues.A_PARENT];
					}
				}
				bone.@[ConstValues.A_PARENT] = boneParentName;
			}
			else
			{
				delete bone.@[ConstValues.A_PARENT];
			}
		}
		
		public function updateBonesRelationFromData(armatureData:ArmatureData):void
		{
			var armature:XML = getArmatureList(armatureData.name)[0];
			if(!armature)
			{
				return;
			}
			for each(var bone:XML in armature[ConstValues.BONE])
			{
				var boneName:String = bone.@[ConstValues.A_NAME];
				var boneData:BoneData = armatureData.getBoneData(boneName);
				if(boneData)
				{
					var boneParentName:String = boneData.parent;
					if(boneParentName)
					{
						bone.@[ConstValues.A_PARENT] = boneParentName;
					}
					else
					{
						delete bone.@[ConstValues.A_PARENT];
					}
				}
			}
		}
		
		public function updateAnimationFromData(armatureName:String, animationData:AnimationData):void
		{
			var animation:XML = getAnimationList(armatureName, animationData.name)[0];
			animation.@[ConstValues.A_FADE_IN_TIME] = formatNumber(animationData.fadeTime, 1000);
			animation.@[ConstValues.A_SCALE] = formatNumber(animationData.scale);
			animation.@[ConstValues.A_LOOP] = animationData.playTimes;
			animation.@[ConstValues.A_TWEEN_EASING] = formatNumber(animationData.tweenEasing);
			animation.@[ConstValues.A_AUTO_TWEEN] = animationData.autoTween?1:0;
		}
		
		public function updateTransformTimelineFromData(armatureName:String, animationName:String, transformTimeline:TransformTimeline):void
		{
			var timeline:XML = getTimelineList(armatureName, animationName, transformTimeline.name)[0];
			timeline.@[ConstValues.A_SCALE] = formatNumber(transformTimeline.scale);
			timeline.@[ConstValues.A_OFFSET] = formatNumber(transformTimeline.offset);
		}
		
		private function scaleList(list:XMLList, scale:Number):void
		{
			for each(var xml:XML in list)
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
		
		private function formatNumber(num:Number, retain:uint = 100):Number
		{
			retain = retain || 100;
			return Math.round(num * retain) / retain;
		}
	}
}