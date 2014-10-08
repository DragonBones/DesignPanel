package core.utils
{
	import dragonBones.core.DragonBones;
	import dragonBones.utils.ConstValues;
	
	public function formatSpineData(rawData:Object, textureAtlasXML:XML, dataName:String, frameRate:uint = 60):XML
	{
		var xml:XML = 
			<{ConstValues.DRAGON_BONES}
				{ConstValues.A_VERSION}={DragonBones.DATA_VERSION}
				{ConstValues.A_NAME}={dataName}
				{ConstValues.A_FRAME_RATE}={frameRate}
			/>;
		
		for(var armatureName:String in rawData)
		{
			xml.appendChild(formatArmature(rawData[armatureName], armatureName, textureAtlasXML, frameRate));
		}
		
		return xml;
	}
}

import flash.display.BlendMode;

import dragonBones.objects.DisplayData;
import dragonBones.utils.ConstValues;

const BONE:String = "bones";
const SLOT:String = "slots";
const SKIN:String = "skins";
const ANIMATION:String = "animations";
const ROTATE:String = "rotate";
const TRANSLATE:String = "translate";
const SCALE:String = "scale";
const COMBINE:String = "combine";
const ATTACHMENT:String = "attachment";
const ADDITIVE:String = "additive";
const COLOR:String = "color";

const A_NAME:String = "name";
const A_PARENT:String = "parent";
const A_BONE:String = "bone";
const A_LENGTH:String = "length";

const A_TIME:String = "time";
const A_CURVE:String = "curve";
const A_DURATION:String = "duration";

const A_X:String = "x";
const A_Y:String = "y";
const A_ROTATION:String = "rotation";
const A_ANGLE:String = "angle";
const A_SCALE_X:String = "scaleX";
const A_SCALE_Y:String = "scaleY";
const A_WIDTH:String = "width";
const A_HEIGHT:String = "height";
const A_INHERIT_SCALE:String = "inheritScale";
const A_INHERIT_ROTATION:String = "inheritRotation";

const V_STEPPED:String = "stepped";

const ANGLE_TO_RADIAN:Number = Math.PI / 180;
const BEZIER_SEGMENTS:int = 10;

const _helpArray:Array = [];

function formatArmature(armatureObject:Object, armatureName:String, textureAtlasXML:XML, frameRate:uint):XML
{
	var armatureXML:XML = 
		<{ConstValues.ARMATURE}
			{ConstValues.A_NAME}={armatureName}
		/>;
			
	var boneList:Array = armatureObject[BONE];
	//对动画进行坐标变换时，需要保留bone的local坐标到boneListCopy中
	var boneListCopy:Array = tansformBoneList(boneList);
	
	for each(var boneObject:Object in boneList)
	{
		armatureXML.appendChild(formatBone(boneObject));
	}
	
	var slotList:Array = armatureObject[SLOT];
	
	var skins:Object = armatureObject[SKIN];
	var skinXML:XML;
	for(var skinName:String in skins)
	{
		skinXML = formatSkin(skins[skinName], skinName, slotList, textureAtlasXML);
		armatureXML.appendChild(skinXML);
	}
	
	var animations:Object = armatureObject[ANIMATION];
	var animationObject:Object;
	for(var animationName:String in animations)
	{
		animationObject = animations[animationName];
		//对动画进行坐标变化
		//boneListCopy提供遍历骨骼树由根到叶的顺序
		//slotList提供bone和slot的映射
		//skinXML提供slot和display的映射
		transformAnimation(animationObject, boneListCopy, slotList, frameRate, skinXML);
		armatureXML.appendChild(formatAnimation(animationObject, animationName));
	}
	
	return armatureXML;
}

function formatBone(boneObject:Object):XML
{
	var boneXML:XML = 
		<{ConstValues.BONE}
			{ConstValues.A_NAME}={boneObject[A_NAME]}
			{ConstValues.A_LENGTH}={formatNumber(boneObject[A_LENGTH])}
		>
			<{ConstValues.TRANSFORM}
				{ConstValues.A_X}={formatNumber(boneObject[A_X])}
				{ConstValues.A_Y}={formatNumber(boneObject[A_Y])}
				{ConstValues.A_SKEW_X}={formatNumber(boneObject[A_ROTATION])}
				{ConstValues.A_SKEW_Y}={formatNumber(boneObject[A_ROTATION])}
				{ConstValues.A_SCALE_X}={formatNumber(boneObject[A_SCALE_X])}
				{ConstValues.A_SCALE_Y}={formatNumber(boneObject[A_SCALE_Y])}
			/>
		</{ConstValues.BONE}>;
		
	var inheritRatation:String = boneObject[A_INHERIT_ROTATION] as String;
	switch (inheritRatation)
	{
		case "0":
		case "false":
		case "no":
			boneXML.@[ConstValues.A_INHERIT_ROTATION] = 0;
			break;
		
		default:
			//boneXML.@[ConstValues.A_INHERIT_ROTATION] = true;
			break;
	}
	
	var inheritScale:String = boneObject[A_INHERIT_SCALE] as String;
	if (inheritScale)
	{
		switch (inheritScale)
		{
			case "1":
			case "true":
			case "yes":
				boneXML.@[ConstValues.A_INHERIT_SCALE] = 1;
				break;
			
			default:
				//boneXML.@[ConstValues.A_INHERIT_SCALE] = false;
				break;
		}
	}
	else
	{
		boneXML.@[ConstValues.A_SCALE_MODE] = 2;
	}
	
	var parent:String = boneObject[A_PARENT];
	if(parent)
	{
		boneXML.@[ConstValues.A_PARENT] = parent;
	}
	
	return boneXML;
}

function formatSkin(skinObject:Object, skinName:String, slotList:Array, textureAtlasXML:XML):XML
{
	var skinXML:XML = 
		<{ConstValues.SKIN}
			{ConstValues.A_NAME}={skinName}
		/>;
	
	var parentName:String;
	var firstAttachment:String;
    var blendMode:String;
	var zOrder:int;
	for(var slotName:String in skinObject)
	{
		parentName = "";
		zOrder = 0;
		for each(var slotObjectInList:Object in slotList)
		{
			if(slotObjectInList[A_NAME] == slotName)
			{
				parentName = slotObjectInList[A_BONE];
				firstAttachment = slotObjectInList[ATTACHMENT];
                var additive:Object = slotObjectInList[ADDITIVE];
                if(additive && additive is Boolean)
                {
                    var isAdditive:Boolean = additive as Boolean;
                    if(isAdditive)
                    {
                        blendMode = BlendMode.ADD;
                    }
                }
				break;
			}
			zOrder ++;
		}
		//默认的display标记出来，以便放到displayList的首位
		skinXML.appendChild(formatSlot(skinObject[slotName], slotName, parentName, firstAttachment, blendMode, zOrder, textureAtlasXML));
	}
			
	return skinXML;
}

function formatSlot(slotObject:Object, slotName:String, slotParent:String, firstAttachment:String, blendMode:String, zOrder:int, textureAtlasXML:XML):XML
{
	var slotXML:XML =
		<{ConstValues.SLOT}
			{ConstValues.A_NAME}={slotName}
			{ConstValues.A_PARENT}={slotParent}
			{ConstValues.A_Z_ORDER}={zOrder}
            {ConstValues.A_BLENDMODE}={blendMode}
		/>;
	
	var displayXML:XML;
	for(var displayName:String in slotObject)
	{
		displayXML = formatDisplay(slotObject[displayName], displayName, textureAtlasXML);
		if(displayName == firstAttachment)
		{
			//默认的display
			slotXML.prependChild(displayXML);
		}
		else
		{
			slotXML.appendChild(displayXML);
		}
	}
	
	return slotXML;
}

function formatDisplay(displayObject:Object, displayName:String, textureAtlasXML:XML):XML
{
	formatTransform(displayObject);
	
	displayName = displayObject[A_NAME] || displayName;
	
	var width:Number = Number(displayObject[A_WIDTH]) || 0;
	var height:Number = Number(displayObject[A_HEIGHT]) || 0;
	
	var scaleX:Number = 1;
	var scaleY:Number = 1;
	
	var subTextureXML:XML = textureAtlasXML[ConstValues.SUB_TEXTURE].(@[ConstValues.A_NAME] == displayName)[0];
	
	if(subTextureXML)
	{
		scaleX = width / Number(subTextureXML.@[ConstValues.A_WIDTH]);
		scaleY = height / Number(subTextureXML.@[ConstValues.A_HEIGHT]);
		
		var spineScaleX:String = displayObject[A_SCALE_X];
		if (spineScaleX)
		{
			scaleX *= Number(spineScaleX);
		}
		var spineScaleY:String = displayObject[A_SCALE_Y];
		if (spineScaleY)
		{
			scaleY *= Number(spineScaleY);
		}
		
		if(isNaN(scaleX))
		{
			scaleX = 1;
		}
		if(isNaN(scaleY))
		{
			scaleY = 1;
		}
	}
	
	var displayXML:XML = 
		<{ConstValues.DISPLAY}
			{ConstValues.A_NAME}={displayName}
			{ConstValues.A_TYPE}={DisplayData.IMAGE}
		>
			<{ConstValues.TRANSFORM}
				{ConstValues.A_X}={formatNumber(displayObject[A_X])}
				{ConstValues.A_Y}={formatNumber(displayObject[A_Y])}
				{ConstValues.A_SKEW_X}={formatNumber(displayObject[A_ROTATION])}
				{ConstValues.A_SKEW_Y}={formatNumber(displayObject[A_ROTATION])}
				{ConstValues.A_SCALE_X}={formatNumber(scaleX)}
				{ConstValues.A_SCALE_Y}={formatNumber(scaleY)}
				{ConstValues.A_PIVOT_X}={formatNumber(width * 0.5 / scaleX)}
				{ConstValues.A_PIVOT_Y}={formatNumber(height * 0.5 / scaleY)}
			/>
		</{ConstValues.DISPLAY}>;
	
	return displayXML;
}

function formatAnimation(animationObject:Object, animationName:String):XML
{
	var animationXML:XML = 
		<{ConstValues.ANIMATION}
			{ConstValues.A_NAME}={animationName}
			{ConstValues.A_FADE_IN_TIME}={-1}
			{ConstValues.A_DURATION}={animationObject[A_DURATION]}
			{ConstValues.A_SCALE}={1}
			{ConstValues.A_LOOP}={1}
		/>;
	
	var timelines:Object = animationObject[BONE];
	for(var timelineName:String in timelines)
	{
		animationXML.appendChild(formatTimeline(timelines[timelineName], timelineName));
	}
	
	return animationXML;
}

function formatTimeline(timelineObject:Object, timelineName:String):XML
{
	var timelineXML:XML =
		<{ConstValues.TIMELINE}
			{ConstValues.A_NAME}={timelineName}
			{ConstValues.A_SCALE}={1}
			{ConstValues.A_OFFSET}={0}
		/>;
	
	for each(var frameObject:Object in timelineObject[COMBINE])
	{
		if(frameObject)
		{
			timelineXML.appendChild(formatFrame(frameObject));
		}
	}
	
	return timelineXML;
}

function formatFrame(frameObject:Object):XML
{
	var frameXML:XML = 
		<{ConstValues.FRAME} 
			{ConstValues.A_DURATION}={formatNumber(frameObject[A_DURATION], 1000)}
		>
			<{ConstValues.TRANSFORM}
				{ConstValues.A_X}={formatNumber(frameObject[A_X])}
				{ConstValues.A_Y}={formatNumber(frameObject[A_Y])}
				{ConstValues.A_SKEW_X}={formatNumber(frameObject[A_ROTATION])}
				{ConstValues.A_SKEW_Y}={formatNumber(frameObject[A_ROTATION])}
				{ConstValues.A_SCALE_X}={formatNumber(frameObject[A_SCALE_X])}
				{ConstValues.A_SCALE_Y}={formatNumber(frameObject[A_SCALE_Y])}
				{ConstValues.A_PIVOT_X}={0}
				{ConstValues.A_PIVOT_Y}={0}
			/>
		</{ConstValues.FRAME}>;
	
	if(frameObject[ConstValues.A_DISPLAY_INDEX] > 0)
	{
		frameXML.@[ConstValues.A_DISPLAY_INDEX] = frameObject[ConstValues.A_DISPLAY_INDEX];
	}
	return frameXML;
}

function tansformBoneList(boneList:Array):Array
{
	//sort
	if(boneList.length == 0)
	{
		return null;
	}
	
	var listCopy:Array = [];
	_helpArray.length = 0;
	var i:int = boneList.length;
	while(i --)
	{
		var boneObject:Object = boneList[i];
		var level:int = 0;
		var parentObject:Object = boneObject;
		while(parentObject && parentObject.parent)
		{
			level ++;
			parentObject = getBoneFromList(boneList, parentObject[A_PARENT]);
		}
		_helpArray[i] = {level:level, bone:boneObject};
	}
	
	_helpArray.sortOn("level", Array.NUMERIC);
	
	i = _helpArray.length;
	while(i --)
	{
		boneList[i] = _helpArray[i].bone;
	}
	_helpArray.length = 0;
	
	//transform
	var parentName:String;
	var parentRadian:Number;
	var boneCopy:Object;
	for each(boneObject in boneList)
	{
		formatTransform(boneObject);
		boneCopy = {};
		boneCopy[A_NAME] = boneObject[A_NAME];
		boneCopy[A_PARENT] = boneObject[A_PARENT];
		boneCopy[A_X] = boneObject[A_X];
		boneCopy[A_Y] = boneObject[A_Y];
		boneCopy[A_ROTATION] = boneObject[A_ROTATION];
		boneCopy[A_SCALE_X] = boneObject[A_SCALE_X];
		boneCopy[A_SCALE_Y] = boneObject[A_SCALE_Y];
		listCopy.push(boneCopy);
		parentName = boneObject[A_PARENT];
		if(parentName)
		{
			parentObject = getBoneFromList(boneList, parentName);
			transformToGlobal(boneObject, parentObject);
		}
	}
	
	return listCopy;
}

function transformAnimation(animationObject:Object, boneListCopy:Array, slotList:Array, frameRate:uint, skinXML:XML):void
{
	var boneTimelines:Object = animationObject[BONE];
	var slotTimelines:Object = animationObject[SLOT];
	var maxTime:Number = 0;
	
	var boneTimeline:Object;
	var slotTimeline:Object;
	
	var transform:Object;
	var boneName:String;
	var slotName:String;
	var parentName:String;
	var displayName:String;
	var parentTimeline:Object;
	var frameList:Array;
	var frameListCombined:Array;
	var frameCombined:Object;
	var prevFrameCombined:Object;
	var frameID:uint;
	var time:Number;
	var i:int;
	
	var noTransformFrame:Object;
	var lasfFrames:Array = [];
	
	var slotXML:XML;
	var displayXML:XML;
	
	for each(var boneObject:Object in boneListCopy)
	{
		boneName = boneObject[A_NAME];
		parentName = boneObject[A_PARENT];
		boneTimeline = boneTimelines[boneName];
		parentTimeline = boneTimelines[parentName];
		
		//spine中没有动画的骨骼，默认每个动作添加一个静止帧
		if(!boneTimeline)
		{
			noTransformFrame = {};
			noTransformFrame[A_TIME] = 0;
			boneTimelines[boneName] = boneTimeline = {};
			boneTimeline[TRANSLATE] = [noTransformFrame];
		}
		
		slotTimeline = null;
		slotName = null;
		slotXML = null;
		if(skinXML)
		{
			//将slotTimeline合并到boneTimeline中
			if(slotTimelines)
			{
				for each(var slotObject:Object in slotList)
				{
					if(slotObject[A_BONE] == boneName)
					{
						slotName = slotObject[A_NAME];
						slotTimeline = slotTimelines[slotName];
						if(slotTimeline)
						{
							for(var slotTimelineType:String in slotTimeline)
							{
								boneTimeline[slotTimelineType] = slotTimeline[slotTimelineType];
							}
							break;
						}
					}
				}
			}
			
			if(slotName)
			{
				//找到该boneTimeline对应的slot，暂时只支持一个有效的slot动画
				slotXML = skinXML[ConstValues.SLOT].(@[ConstValues.A_NAME] == slotName)[0];
			}
		}
		
		frameListCombined = [];
		for(var boneTimelineType:String in boneTimeline)
		{
			frameList = boneTimeline[boneTimelineType];
			for each(var frame:Object in frameList)
			{
				time = frame[A_TIME] = Number(frame[A_TIME]) || 0;
				formatTransform(frame, 0);
				setFrameCurve(frame[A_CURVE] as Array);
				frameID = Math.round(time * frameRate);
				frameCombined = frameListCombined[frameID];
				if(!frameCombined)
				{
					frameCombined = frameListCombined[frameID] = {};
					frameCombined[A_TIME] = time;
				}
			}
		}
		
		prevFrameCombined = null;
		i = frameListCombined.length;
		while(i --)
		{
			frameCombined = frameListCombined[i];
			if(frameCombined)
			{
				formatTransform(frameCombined, 0);
				time = frameCombined[A_TIME];
				
				//从原timeline中取得当前时间的合并关键帧
				combineFrameFromTimeline(boneTimeline, time, frameCombined);
				
				//如果合并关键帧中包含A_NAME属性（在combineFrameFromTimeline中设置的），则为该为关键帧设置displayIndex动画
				displayName = frameCombined[A_NAME];
				if(displayName && slotXML)
				{
					displayXML = slotXML[ConstValues.DISPLAY].(@[ConstValues.A_NAME] == displayName)[0];
					if(displayXML)
					{
						frameCombined[ConstValues.A_DISPLAY_INDEX] = displayXML.childIndex();
					}
				}
				
				//动画本地坐标叠加bone本地坐标
				frameCombined[A_X] += boneObject[A_X];
				frameCombined[A_Y] += boneObject[A_Y];
				frameCombined[A_ROTATION] += boneObject[A_ROTATION];
				frameCombined[A_SCALE_X] += boneObject[A_SCALE_X];
				frameCombined[A_SCALE_Y] += boneObject[A_SCALE_Y];
				
				//有父坐标系，则进行坐标变换
				if(parentTimeline)
				{
					transform = {};
					formatTransform(transform, 0);
					getTransformFromFrameList(parentTimeline[COMBINE], time, transform);
					transformToGlobal(frameCombined, transform);
				}
				
				if(prevFrameCombined)
				{
					frameCombined[A_DURATION] = Math.round((prevFrameCombined[A_TIME] - time) * frameRate);
				}
				else
				{
					//最后一帧，添加一个帧长度
					frameCombined[A_DURATION] = 1;
					maxTime = Math.max(maxTime, time);
					
					//将每个timeline的最后一帧收集起来，最后统一处理帧长度
					lasfFrames.push(frameCombined);
				}
				prevFrameCombined = frameCombined;
			}
			else
			{
				//去除无效的空帧
				frameListCombined.splice(i, 1);
			}
		}
		
		boneTimeline[COMBINE] = frameListCombined;
	}
	
	var totalDuration:Number = Math.round(maxTime * frameRate) + 1;
	animationObject[A_DURATION] = totalDuration;
	
	//处理每个timeline的最后一帧的帧长度
	for each(var lastFrame:Object in lasfFrames)
	{
		lastFrame[A_DURATION] = totalDuration - Math.round(lastFrame[A_TIME] * frameRate);
	}
}

function getBoneFromList(boneList:Array, boneName:String):Object
{
	var bone:Object;
	var i:int = boneList.length;
	while(i --)
	{
		bone = boneList[i];
		if(bone[A_NAME] == boneName)
		{
			return bone;
		}
	}
	
	return null;
}

function combineFrameFromTimeline(timeline:Object, time:Number, resultTransform:Object):void
{
	var frameList:Array;
	var currentFrame:Object;
	var nextFrame:Object;
	var frameObject:Object;
	var length:uint;
	var percent:Number;
	for(var type:String in timeline)
	{
		frameList = timeline[type];
		length = frameList.length;
		
		currentFrame = null;
		nextFrame = null;
		for(var i:int = 0;i < length;i ++)
		{
			frameObject = frameList[i];
			if(frameObject[A_TIME] > time)
			{
				nextFrame = frameObject;
				break;
			}
			currentFrame = frameObject;
		}
		
		if(nextFrame && currentFrame)
		{
			percent = (time - currentFrame[A_TIME]) / (nextFrame[A_TIME] - currentFrame[A_TIME]);
			percent = getFrameCurvePercent(currentFrame, percent);
		}
		else
		{
			nextFrame = frameObject;
			currentFrame = frameObject;
			percent = 0;
		}
		
		switch(type)
		{
			case TRANSLATE:
				resultTransform[A_X] = currentFrame[A_X] + percent * (nextFrame[A_X] - currentFrame[A_X]);
				resultTransform[A_Y] = currentFrame[A_Y] + percent * (nextFrame[A_Y] - currentFrame[A_Y]);
				break;
			case ROTATE:
				resultTransform[A_ROTATION] = formatRotation(currentFrame[A_ROTATION] + percent * (nextFrame[A_ROTATION] - currentFrame[A_ROTATION]));
				break;
			case SCALE:
				resultTransform[A_SCALE_X] = currentFrame[A_SCALE_X] + percent * (nextFrame[A_SCALE_X] - currentFrame[A_SCALE_X]);
				resultTransform[A_SCALE_Y] = currentFrame[A_SCALE_Y] + percent * (nextFrame[A_SCALE_Y] - currentFrame[A_SCALE_Y]);
				break;
			case ATTACHMENT:
				resultTransform[A_NAME] = currentFrame[A_NAME];
				break;
		}
	}
}

function getTransformFromFrameList(frameList:Array, time:Number, resultTransform:Object):void
{
	var currentFrame:Object;
	var nextFrame:Object;
	var frameObject:Object;
	var percent:Number;
	var length:uint = frameList.length;
	
	for(var i:int = 0;i < length;i ++)
	{
		frameObject = frameList[i];
		if(frameObject[A_TIME] > time)
		{
			nextFrame = frameObject;
			break;
		}
		currentFrame = frameObject;
	}
	
	if(nextFrame && currentFrame)
	{
		percent = (time - currentFrame[A_TIME]) / (nextFrame[A_TIME] - currentFrame[A_TIME]);
	}
	else
	{
		nextFrame = frameObject;
		currentFrame = frameObject;
		percent = 0;
	}
	
	resultTransform[A_X] = currentFrame[A_X] + percent * (nextFrame[A_X] - currentFrame[A_X]);
	resultTransform[A_Y] = currentFrame[A_Y] + percent * (nextFrame[A_Y] - currentFrame[A_Y]);
	resultTransform[A_ROTATION] = formatRotation(currentFrame[A_ROTATION] + percent * (nextFrame[A_ROTATION] - currentFrame[A_ROTATION]));
	resultTransform[A_SCALE_X] = currentFrame[A_SCALE_X] + percent * (nextFrame[A_SCALE_X] - currentFrame[A_SCALE_X]);
	resultTransform[A_SCALE_Y] = currentFrame[A_SCALE_Y] + percent * (nextFrame[A_SCALE_Y] - currentFrame[A_SCALE_Y]);
}

function formatTransform(transformObject:Object, defaultScale:Number = 1):void
{
	transformObject[A_X] = Number(transformObject[A_X]) || 0;
	transformObject[A_Y] = -Number(transformObject[A_Y]) || 0;
	transformObject[A_ROTATION] = formatRotation(-Number(transformObject[A_ROTATION]) || -Number(transformObject[A_ANGLE])) || 0;
	transformObject[A_SCALE_X] = Number(transformObject[A_SCALE_X]) || defaultScale;
	transformObject[A_SCALE_Y] = Number(transformObject[A_SCALE_Y]) || defaultScale;
}

function transformToGlobal(boneObject:Object, parentObject:Object):void
{
	if(parentObject)
	{
		var x:Number = boneObject[A_X];
		var y:Number = boneObject[A_Y];
		var scaleX:Number = parentObject[A_SCALE_X];
		var scaleY:Number = parentObject[A_SCALE_Y];
		var parentRadian:Number = parentObject[A_ROTATION] * ANGLE_TO_RADIAN;
		boneObject[A_X] = x * Math.cos(parentRadian) * scaleX - y * Math.sin(parentRadian) * scaleY + parentObject[A_X];
		boneObject[A_Y] = x * Math.sin(parentRadian) * scaleX + y * Math.cos(parentRadian) * scaleY + parentObject[A_Y];
		boneObject[A_ROTATION] = formatRotation(boneObject[A_ROTATION] + parentObject[A_ROTATION]);
	}
}

function setFrameCurve(curve:Array):void
{
	if(!curve)
	{
		return;
	}
	var cx1:Number = curve[0];
	var cy1:Number = curve[1];
	var cx2:Number = curve[2];
	var cy2:Number = curve[3];
	
	var subdiv_step:Number = 1 / BEZIER_SEGMENTS;
	var subdiv_step2:Number = subdiv_step * subdiv_step;
	var subdiv_step3:Number = subdiv_step2 * subdiv_step;
	var pre1:Number = 3 * subdiv_step;
	var pre2:Number = 3 * subdiv_step2;
	var pre4:Number = 6 * subdiv_step2;
	var pre5:Number = 6 * subdiv_step3;
	var tmp1x:Number = -cx1 * 2 + cx2;
	var tmp1y:Number = -cy1 * 2 + cy2;
	var tmp2x:Number = (cx1 - cx2) * 3 + 1;
	var tmp2y:Number = (cy1 - cy2) * 3 + 1;
	
	curve[0] = cx1 * pre1 + tmp1x * pre2 + tmp2x * subdiv_step3;
	curve[1] = cy1 * pre1 + tmp1y * pre2 + tmp2y * subdiv_step3;
	curve[2] = tmp1x * pre4 + tmp2x * pre5;
	curve[3] = tmp1y * pre4 + tmp2y * pre5;
	curve[4] = tmp2x * pre5;
	curve[5] = tmp2y * pre5;
}

function getFrameCurvePercent(frameObject:Object, percent:Number):Number
{
	var curve:* = frameObject[A_CURVE];
	if(!curve)	
	{
		return percent;
	}
	else if(curve == V_STEPPED)
	{
		return 0;
	}
	else if(curve is Array)
	{
		
	}
	else
	{
		return percent;
	}
	
	var dfx:Number = curve[0];
	var dfy:Number = curve[1];
	var ddfx:Number = curve[2];
	var ddfy:Number = curve[3];
	var dddfx:Number = curve[4];
	var dddfy:Number = curve[5];
	var x:Number = dfx;
	var y:Number = dfy;
	var lastX:Number;
	var lastY:Number;
	
	var i:int = BEZIER_SEGMENTS - 2;
	while(true) 
	{
		if(x >= percent) 
		{
			lastX = x - dfx;
			lastY = y - dfy;
			return lastY + (y - lastY) * (percent - lastX) / (x - lastX);
		}
		if (i == 0)
		{
			break;
		}
		i --;
		dfx += ddfx;
		dfy += ddfy;
		ddfx += dddfx;
		ddfy += dddfy;
		x += dfx;
		y += dfy;
	}
	
	return y + (1 - y) * (percent - x) / (1 - x);
}

function formatRotation(rotation:Number):Number
{
	rotation %= 360;
	if (rotation > 180)
	{
		rotation -= 360;
	}
	if (rotation < -180)
	{
		rotation += 360;
	}
	return rotation;
}

function formatNumber(num:Number, retain:Number = 100):Number
{
	retain = retain || 100;
	return Math.round(num * retain) / retain;
}