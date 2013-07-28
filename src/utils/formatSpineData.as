package utils
{
	import dragonBones.core.DragonBones;
	import dragonBones.utils.ConstValues;
	
	public function formatSpineData(rawData:Object, name:String, frameRate:uint = 60):XML
	{
		var xml:XML = 
			<{ConstValues.DRAGON_BONES}
				{ConstValues.A_VERSION}={DragonBones.DATA_VERSION}
				{ConstValues.A_NAME}={name}
				{ConstValues.A_FRAME_RATE}={frameRate}
			/>;
		
		for(var armatureName:String in rawData)
		{
			xml.appendChild(formatArmature(rawData[armatureName], armatureName, frameRate));
		}
		
		return xml;
	}
}

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

const A_NAME:String = "name";
const A_PARENT:String = "parent";
const A_BONE:String = "bone";
const A_ATTACHMENT:String = "attachment";

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

const V_STEPPED:String = "stepped";

const ANGLE_TO_RADIAN:Number = Math.PI / 180;
const BEZIER_SEGMENTS:int = 10;

const _helpArray:Array = [];

function formatArmature(armatureObject:Object, armatureName:String, frameRate:uint):XML
{
	var armatureXML:XML = 
		<{ConstValues.ARMATURE}
			{ConstValues.A_NAME}={armatureName}
		/>;
			
	var boneList:Array = armatureObject[BONE];
	var boneListCopy:Array = tansformBoneList(boneList);
	
	for each(var boneObject:Object in boneList)
	{
		armatureXML.appendChild(formatBone(boneObject));
	}
	
	var slotList:Array = armatureObject[SLOT];
	
	var skins:Object = armatureObject[SKIN];
	for(var skinName:String in skins)
	{
		armatureXML.appendChild(formatSkin(skins[skinName], skinName, slotList));
	}
	
	var animations:Object = armatureObject[ANIMATION];
	var animationObject:Object;
	for(var animationName:String in animations)
	{
		animationObject = animations[animationName];
		transformAnimation(animationObject, boneListCopy, frameRate);
		armatureXML.appendChild(formatAnimation(animationObject, animationName, slotList));
	}
	
	return armatureXML;
}

function formatBone(boneObject:Object):XML
{
	var boneXML:XML = 
		<{ConstValues.BONE}
			{ConstValues.A_NAME}={boneObject[A_NAME]}
		>
			<{ConstValues.TRANSFORM}
				{ConstValues.A_X}={formatNumber(boneObject[A_X])}
				{ConstValues.A_Y}={formatNumber(boneObject[A_Y])}
				{ConstValues.A_SKEW_X}={formatNumber(boneObject[A_ROTATION])}
				{ConstValues.A_SKEW_Y}={formatNumber(boneObject[A_ROTATION])}
				{ConstValues.A_SCALE_X}={formatNumber(boneObject[A_SCALE_X])}
				{ConstValues.A_SCALE_Y}={formatNumber(boneObject[A_SCALE_Y])}
				{ConstValues.A_PIVOT_X}={0}
				{ConstValues.A_PIVOT_Y}={0}
			/>
		</{ConstValues.BONE}>;
	var parent:String = boneObject[A_PARENT];
	if(parent)
	{
		boneXML.@[ConstValues.A_PARENT] = parent;
	}
	
	return boneXML;
}

function formatSkin(skinObject:Object, skinName:String, slotList:Array):XML
{
	var skinXML:XML = 
		<{ConstValues.SKIN}
			{ConstValues.A_NAME}={skinName}
		/>;
	
	var parentName:String;
	var firstAttachment:String;
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
				firstAttachment = slotObjectInList[A_ATTACHMENT];
				break;
			}
			zOrder ++;
		}
		
		skinXML.appendChild(formatSlot(skinObject[slotName], slotName, parentName, firstAttachment, zOrder));
	}
			
	return skinXML;
}

function formatSlot(slotObject:Object, slotName:String, slotParent:String, firstAttachment:String, zOrder:int):XML
{
	var slotXML:XML =
		<{ConstValues.SLOT}
			{ConstValues.A_NAME}={slotName}
			{ConstValues.A_PARENT}={slotParent}
			{ConstValues.A_Z_ORDER}={zOrder}
		/>;
	
	var displayXML:XML;
	for(var displayName:String in slotObject)
	{
		displayXML = formatDisplay(slotObject[displayName], displayName);
		if(displayName == firstAttachment)
		{
			slotXML.prependChild(displayXML);
		}
		else
		{
			slotXML.appendChild(displayXML);
		}
	}
	
	return slotXML;
}

function formatDisplay(displayObject:Object, displayName:String):XML
{
	formatTransform(displayObject);
	
	var width:Number = Number(displayObject[A_WIDTH]) || 0;
	var height:Number = Number(displayObject[A_HEIGHT]) || 0;
	
	var displayXML:XML = 
		<{ConstValues.DISPLAY}
			{ConstValues.A_NAME}={displayObject[A_NAME] || displayName}
			{ConstValues.A_TYPE}={DisplayData.IMAGE}
		>
			<{ConstValues.TRANSFORM}
				{ConstValues.A_X}={formatNumber(displayObject[A_X])}
				{ConstValues.A_Y}={formatNumber(displayObject[A_Y])}
				{ConstValues.A_SKEW_X}={formatNumber(displayObject[A_ROTATION])}
				{ConstValues.A_SKEW_Y}={formatNumber(displayObject[A_ROTATION])}
				{ConstValues.A_SCALE_X}={1}
				{ConstValues.A_SCALE_Y}={1}
				{ConstValues.A_PIVOT_X}={width * 0.5}
				{ConstValues.A_PIVOT_Y}={height * 0.5}
			/>
		</{ConstValues.DISPLAY}>;
	
	return displayXML;
}

function formatAnimation(animationObject:Object, animationName:String, slotList:Array):XML
{
	var animationXML:XML = 
		<{ConstValues.ANIMATION}
			{ConstValues.A_NAME}={animationName}
			{ConstValues.A_FADE_IN_TIME}={-1}
			{ConstValues.A_DURATION}={animationObject[A_DURATION]}
			{ConstValues.A_SCALE}={1}
			{ConstValues.A_LOOP}={1}
			{ConstValues.A_TWEEN_EASING}={NaN}
		/>;
	
	var timelines:Object = animationObject[BONE];
	var zOrder:int;
	for(var timelineName:String in timelines)
	{
		zOrder = 0;
		for each(var slotObject:Object in slotList)
		{
			if(slotObject[A_BONE] == timelineName)
			{
				break;
			}
			zOrder ++;
		}
		animationXML.appendChild(formatTimeline(timelines[timelineName], timelineName, zOrder));
	}
	
	return animationXML;
}

function formatTimeline(timelineObject:Object, timelineName:String, zOrder:int):XML
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
			timelineXML.appendChild(formatFrame(frameObject, zOrder));
		}
	}
	
	return timelineXML;
}

function formatFrame(frameObject:Object, zOrder:int):XML
{
	var frameXML:XML = 
		<{ConstValues.FRAME} 
			{ConstValues.A_DURATION}={frameObject[A_DURATION]}
			{ConstValues.A_Z_ORDER}={zOrder}
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

function transformAnimation(animationObject:Object, boneListCopy:Array, frameRate:uint):void
{
	var boneTimelines:Object = animationObject[BONE];
	
	var maxTime:Number = 0;
	var transform:Object;
	var boneName:String;
	var parentName:String;
	var boneTimeline:Object;
	var parentTimeline:Object;
	var frameList:Array;
	var frameListCombined:Array;
	var frameCombined:Object;
	var prevFrameCombined:Object;
	var frameID:uint;
	var time:Number;
	var i:int;
	for each(var boneObject:Object in boneListCopy)
	{
		boneName = boneObject[A_NAME];
		parentName = boneObject[A_PARENT];
		boneTimeline = boneTimelines[boneName];
		parentTimeline = boneTimelines[parentName];
		if(boneTimeline)
		{
			frameListCombined = [];
			for(var type:String in boneTimeline)
			{
				frameList = boneTimeline[type];
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
					combineFrameFromTimeline(boneTimeline, time, frameCombined);
					
					frameCombined[A_X] += boneObject[A_X];
					frameCombined[A_Y] += boneObject[A_Y];
					frameCombined[A_ROTATION] += boneObject[A_ROTATION];
					frameCombined[A_SCALE_X] += boneObject[A_SCALE_X];
					frameCombined[A_SCALE_Y] += boneObject[A_SCALE_Y];
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
						//
						frameCombined[A_DURATION] = 1;
						maxTime = Math.max(maxTime, time);
					}
					prevFrameCombined = frameCombined;
				}
				else
				{
					frameListCombined.splice(i, 1);
				}
			}
			
			boneTimeline[COMBINE] = frameListCombined;
		}
	}
	//
	animationObject[A_DURATION] = Math.round(maxTime * frameRate) + 1;
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
	var percent:Number;
	var i:int;
	for(var type:String in timeline)
	{
		frameList = timeline[type];
		currentFrame = null;
		i = 0;
		for each(var nextFrame:Object in frameList)
		{
			if(nextFrame[A_TIME] > time)
			{
				break;
			}
			if(i != frameList.length - 1)
			{
				currentFrame = nextFrame;
			}
			i ++;
		}
		
		if(currentFrame)
		{
			percent = (time - currentFrame[A_TIME]) / (nextFrame[A_TIME] - currentFrame[A_TIME]);
			percent = getFrameCurvePercent(currentFrame, percent);
		}
		else
		{
			currentFrame = nextFrame;
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
		}
	}
}

function getTransformFromFrameList(frameList:Array, time:Number, resultTransform:Object):void
{
	var currentFrame:Object;
	
	var i:int = 0;
	for each(var nextFrame:Object in frameList)
	{
		if(nextFrame[A_TIME] > time)
		{
			break;
		}
		if(i != frameList.length - 1)
		{
			currentFrame = nextFrame;
		}
		i ++;
	}
	
	var percent:Number;
	if(currentFrame)
	{
		percent = (time - currentFrame[A_TIME]) / (nextFrame[A_TIME] - currentFrame[A_TIME]);
	}
	else
	{
		percent = 0;
		currentFrame = nextFrame;
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

function formatNumber(num:Number, retain:uint = 100):Number
{
	retain = retain || 100;
	return Math.round(num * retain) / retain;
}