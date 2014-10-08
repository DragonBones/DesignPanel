package core.utils
{
	import dragonBones.core.DragonBones;
	import dragonBones.utils.ConstValues;
		
	public function formatDataToCurrentVersion(xml:XML):XML
	{
		var frameRate:uint = uint(xml.@[A_FRAME_RATE]);
		var newXML:XML = 
			<{ConstValues.DRAGON_BONES}
				{ConstValues.A_VERSION}={DragonBones.DATA_VERSION}
				{ConstValues.A_NAME}={xml.@[A_NAME]}
				{ConstValues.A_FRAME_RATE}={frameRate}
			/>;
		var armatureXMLDic:Object = {};
		var armatureName:String;
		var newArmatureXML:XML; 
		for each(var armatureXML:XML in xml[ARMATURES][ARMATURE])
		{
			armatureName = armatureXML.@[A_NAME];
			newArmatureXML = formatArmature(armatureXML);
			armatureXMLDic[armatureName] = newArmatureXML;
			newXML.appendChild(newArmatureXML);
		}
		
		var newAnimationXML:XML; 
		for each(var animationsXML:XML in xml[ANIMATIONS][ANIMATION])
		{
			armatureName = animationsXML.@[A_NAME];
			newArmatureXML = armatureXMLDic[armatureName];
			if(newArmatureXML)
			{
				for each(var animationXML:XML in animationsXML[MOVEMENT])
				{
					newAnimationXML = formatAnimation(animationXML, newArmatureXML, frameRate);
					newArmatureXML.appendChild(newAnimationXML);
				}
			}
		}
		return newXML;
	}
}

import dragonBones.objects.DisplayData;
import dragonBones.utils.ConstValues;

const ARMATURES:String = "armatures";
const ANIMATIONS:String = "animations";
const ARMATURE:String = "armature";
const BONE:String = "b";
const DISPLAY:String = "d";
const ANIMATION:String = "animation";
const MOVEMENT:String = "mov";
const FRAME:String = "f";
const COLOR_TRANSFORM:String = "colorTransform";

const A_VERSION:String = "version";
const A_FRAME_RATE:String = "frameRate";
const A_NAME:String = "name";
const A_PARENT:String = "parent";
const A_IS_ARMATURE:String = "isArmature";
const A_DURATION:String = "dr";
const A_FADE_IN_TIME:String = "to";
const A_DURATION_TWEEN:String = "drTW";
const A_LOOP:String = "lp";
const A_SCALE:String = "sc";
const A_OFFSET:String = "dl";
const A_EVENT:String = "evt";
const A_SOUND:String = "sd";
const A_TWEEN_EASING:String = "twE";
const A_TWEEN_ROTATE:String = "twR";
const A_ACTION:String = "mov";
const A_VISIBLE:String = "visible";
const A_DISPLAY_INDEX:String = "dI";
const A_Z_ORDER:String = "z";
const A_X:String = "x";
const A_Y:String = "y";
const A_SKEW_X:String = "kX";
const A_SKEW_Y:String = "kY";
const A_SCALE_X:String = "cX";
const A_SCALE_Y:String = "cY";
const A_PIVOT_X:String = "pX";
const A_PIVOT_Y:String = "pY";

const A_ALPHA_OFFSET:String = "a";
const A_RED_OFFSET:String = "r";
const A_GREEN_OFFSET:String = "g";
const A_BLUE_OFFSET:String = "b";
const A_ALPHA_MULTIPLIER:String = "aM";
const A_RED_MULTIPLIER:String = "rM";
const A_GREEN_MULTIPLIER:String = "gM";
const A_BLUE_MULTIPLIER:String = "bM";

function formatArmature(armatureXML:XML):XML
{
	var newArmatureXML:XML = 
		<{ConstValues.ARMATURE}
			{ConstValues.A_NAME}={armatureXML.@[A_NAME]}
		/>;
	var skinXML:XML = <{ConstValues.SKIN} {ConstValues.A_NAME}=""/>;
	newArmatureXML.appendChild(skinXML);
	
	var newBoneXML:XML;
	var slotXML:XML;
	for each(var boneXML:XML in armatureXML[BONE])
	{
		newBoneXML = formatBone(boneXML);
		slotXML = formatSlot(boneXML);
		newArmatureXML.prependChild(newBoneXML);
		skinXML.appendChild(slotXML);
	}
	
	return newArmatureXML;
}

function formatBone(boneXML:XML):XML
{
	var newBoneXML:XML = 
		<{ConstValues.BONE}
			{ConstValues.A_NAME}={boneXML.@[A_NAME]}
		>
			<{ConstValues.TRANSFORM}
				{ConstValues.A_X}={boneXML.@[A_X]}
				{ConstValues.A_Y}={boneXML.@[A_Y]}
				{ConstValues.A_SKEW_X}={boneXML.@[A_SKEW_X]}
				{ConstValues.A_SKEW_Y}={boneXML.@[A_SKEW_Y]}
				{ConstValues.A_SCALE_X}={boneXML.@[A_SCALE_X]}
				{ConstValues.A_SCALE_Y}={boneXML.@[A_SCALE_Y]}
			/>
		</{ConstValues.BONE}>;
	var parent:String = boneXML.@[A_PARENT];
	if(parent)
	{
		newBoneXML.@[ConstValues.A_PARENT] = parent;
	}
	
	return newBoneXML;
}

function formatSlot(boneXML:XML):XML
{
	var slotXML:XML =
		<{ConstValues.SLOT}
			{ConstValues.A_NAME}={boneXML.@[A_NAME]}
			{ConstValues.A_PARENT}={boneXML.@[A_NAME]}
			{ConstValues.A_Z_ORDER}={boneXML.@[A_Z_ORDER]}
		/>;
	
	var newDisplayXML:XML;
	for each(var displayXML:XML in boneXML[DISPLAY])
	{
		newDisplayXML = formatDisplay(displayXML, boneXML);
		slotXML.appendChild(newDisplayXML);
	}
	return slotXML;
}

function formatDisplay(displayXML:XML, boneXML:XML):XML
{
	var displayType:String = uint(displayXML.@[A_IS_ARMATURE]) == 1?DisplayData.ARMATURE:DisplayData.IMAGE;
	var newDisplayXML:XML = 
		<{ConstValues.DISPLAY}
			{ConstValues.A_NAME}={displayXML.@[A_NAME]}
			{ConstValues.A_TYPE}={displayType}
		>
			<{ConstValues.TRANSFORM}
				{ConstValues.A_X}={NaN}
				{ConstValues.A_Y}={NaN}
				{ConstValues.A_SKEW_X}={0}
				{ConstValues.A_SKEW_Y}={0}
				{ConstValues.A_SCALE_X}={1}
				{ConstValues.A_SCALE_Y}={1}
				{ConstValues.A_PIVOT_X}={displayXML.@[A_PIVOT_X]}
				{ConstValues.A_PIVOT_Y}={displayXML.@[A_PIVOT_Y]}
			/>
		</{ConstValues.DISPLAY}>;
	
	return newDisplayXML;
}

function formatAnimation(animationXML:XML, armatureXML:XML, frameRate:uint):XML
{
	var duration:uint = uint(animationXML.@[A_DURATION]);
	var newAnimationXML:XML = 
		<{ConstValues.ANIMATION}
			{ConstValues.A_NAME}={animationXML.@[A_NAME]}
			{ConstValues.A_FADE_IN_TIME}={formatNumber(uint(animationXML.@[A_FADE_IN_TIME]) / frameRate, 1000)}
			{ConstValues.A_DURATION}={duration}
			{ConstValues.A_SCALE}={formatNumber(uint(animationXML.@[A_DURATION_TWEEN]) / duration)}
			{ConstValues.A_LOOP}={uint(animationXML.@[A_LOOP])==1?0:1}
			{ConstValues.A_TWEEN_EASING}={Number(animationXML.@[A_TWEEN_EASING])}
		/>;
	
	var newMainFrameXML:XML;
	for each(var frameXML:XML in animationXML[FRAME])
	{
		newMainFrameXML = formatMainFrame(frameXML, frameRate);
		newAnimationXML.appendChild(newMainFrameXML);
	}
	
	var skinXML:XML = armatureXML[ConstValues.SKIN][0];
	var slotXML:XML;
	var timelineName:String;
	
	var newTimelineXML:XML;
	for each(var timelineXML:XML in animationXML[BONE])
	{
		newTimelineXML = formatTimeline(timelineXML, frameRate);
		newAnimationXML.appendChild(newTimelineXML);
		
		if(skinXML)
		{
			timelineName = newTimelineXML.@[ConstValues.A_NAME];
			slotXML = skinXML[ConstValues.SLOT].(@[ConstValues.A_NAME] == timelineName)[0];
			formatDisplayTransformXYAndTimelinePivot(slotXML, newTimelineXML);
		}
	}
	
	return newAnimationXML;
}

function formatMainFrame(frameXML:XML, frameRate:uint):XML
{
	var newMainFrameXML:XML =
		<{ConstValues.FRAME}
			{ConstValues.A_DURATION}={frameXML.@[A_DURATION]}
		/>;
	var event:String = frameXML.@[A_EVENT];
	if(event)
	{
		newMainFrameXML.@[ConstValues.A_EVENT] = event;
	}
	var sound:String = frameXML.@[A_SOUND];
	if(sound)
	{
		newMainFrameXML.@[ConstValues.A_SOUND] = sound;
	}
	var action:String = frameXML.@[A_ACTION];
	if(action)
	{
		newMainFrameXML.@[ConstValues.A_ACTION] = action;
	}
	
	return newMainFrameXML;
}

function formatTimeline(timelineXML:XML, frameRate:uint):XML
{
	var offset:Number = (1 - Number(timelineXML.@[A_OFFSET])) % 1;
	var newTimelineXML:XML =
		<{ConstValues.TIMELINE}
			{ConstValues.A_NAME}={timelineXML.@[A_NAME]}
			{ConstValues.A_SCALE}={timelineXML.@[A_SCALE]}
			{ConstValues.A_OFFSET}={offset}
		/>;

	var newFrameXML:XML;
	for each(var frameXML:XML in timelineXML[FRAME])
	{
		newFrameXML = formatFrame(frameXML, frameRate);
		newTimelineXML.appendChild(newFrameXML);
	}
			
	return newTimelineXML;
}

function formatFrame(frameXML:XML, frameRate:uint):XML
{
	var newFrameXML:XML =
		<{ConstValues.FRAME}
			{ConstValues.A_DURATION}={frameXML.@[A_DURATION]}
		/>;
	var event:String = frameXML.@[A_EVENT];
	if(event)
	{
		newFrameXML.@[ConstValues.A_EVENT] = event;
	}
	var sound:String = frameXML.@[A_SOUND];
	if(sound)
	{
		newFrameXML.@[ConstValues.A_SOUND] = sound;
	}
	var action:String = frameXML.@[A_ACTION];
	if(action)
	{
		newFrameXML.@[ConstValues.A_ACTION] = action;
	}
	
	if(frameXML.@[A_VISIBLE][0]?uint(frameXML.@[A_VISIBLE]) == 0:false)
	{
		newFrameXML.@[ConstValues.A_HIDE] = 1;
	}
	var tweenEasing:Number = Number(frameXML.@[A_TWEEN_EASING]);
	if(tweenEasing || isNaN(tweenEasing))
	{
		newFrameXML.@[ConstValues.A_TWEEN_EASING] = tweenEasing;
	}
	var tweenRotate:int = int(frameXML.@[A_TWEEN_ROTATE]);
	if(tweenRotate)
	{
		newFrameXML.@[ConstValues.A_TWEEN_ROTATE] = tweenRotate;
	}
	var displayIndex:int = int(frameXML.@[A_DISPLAY_INDEX]);
	if(displayIndex)
	{
		newFrameXML.@[ConstValues.A_DISPLAY_INDEX] = displayIndex;
	}
	
	newFrameXML.@[ConstValues.A_Z_ORDER] = frameXML.@[A_Z_ORDER];
	
	if(displayIndex >= 0)
	{
		var transformXML:XML = 
			<{ConstValues.TRANSFORM}
				{ConstValues.A_X}={frameXML.@[A_X]}
				{ConstValues.A_Y}={frameXML.@[A_Y]}
				{ConstValues.A_SKEW_X}={frameXML.@[A_SKEW_X]}
				{ConstValues.A_SKEW_Y}={frameXML.@[A_SKEW_Y]}
				{ConstValues.A_SCALE_X}={frameXML.@[A_SCALE_X]}
				{ConstValues.A_SCALE_Y}={frameXML.@[A_SCALE_Y]}
				{ConstValues.A_PIVOT_X}={- Number(frameXML.@[A_PIVOT_X])}
				{ConstValues.A_PIVOT_Y}={- Number(frameXML.@[A_PIVOT_Y])}
			/>;
		
		newFrameXML.appendChild(transformXML);
		
		var colorTransformXML:XML = frameXML[COLOR_TRANSFORM][0];
		if(colorTransformXML)
		{
			var newColorTransform:XML = 
				<{COLOR_TRANSFORM}
					{ConstValues.A_ALPHA_OFFSET}={newFrameXML.@[A_ALPHA_OFFSET]}
					{ConstValues.A_RED_OFFSET}={newFrameXML.@[A_RED_OFFSET]}
					{ConstValues.A_GREEN_OFFSET}={newFrameXML.@[A_GREEN_OFFSET]}
					{ConstValues.A_BLUE_OFFSET}={newFrameXML.@[A_BLUE_OFFSET]}
					{ConstValues.A_ALPHA_MULTIPLIER}={newFrameXML.@[A_ALPHA_MULTIPLIER]}
					{ConstValues.A_RED_MULTIPLIER}={newFrameXML.@[A_RED_MULTIPLIER]}
					{ConstValues.A_GREEN_MULTIPLIER}={newFrameXML.@[A_GREEN_MULTIPLIER]}
					{ConstValues.A_BLUE_MULTIPLIER}={newFrameXML.@[A_BLUE_MULTIPLIER]}
				/>;
					
			newFrameXML.appendChild(newColorTransform);
		}
	}
	
	return newFrameXML;
}

function formatDisplayTransformXYAndTimelinePivot(slotXML:XML, timelineXML:XML):void
{
	if(!slotXML)
	{
		return;
	}
	
	var displayIndex:int;
	var displayXML:XML;
	var pivotX:Number;
	var pivotY:Number;
	for each(var frameXML:XML in timelineXML[ConstValues.FRAME])
	{
		displayIndex = frameXML.@[ConstValues.A_DISPLAY_INDEX];
		if(displayIndex >= 0)
		{
			displayXML = slotXML[ConstValues.DISPLAY][displayIndex];
			if(displayXML)
			{
				pivotX = frameXML[ConstValues.TRANSFORM][0].@[ConstValues.A_PIVOT_X];
				pivotY = frameXML[ConstValues.TRANSFORM][0].@[ConstValues.A_PIVOT_Y];
				if(isNaN(displayXML[ConstValues.TRANSFORM][0].@[ConstValues.A_X]))
				{
					displayXML[ConstValues.TRANSFORM][0].@[ConstValues.A_X] = pivotX;
					displayXML[ConstValues.TRANSFORM][0].@[ConstValues.A_Y] = pivotY;
				}
				pivotX -= Number(displayXML[ConstValues.TRANSFORM][0].@[ConstValues.A_X]);
				pivotY -= Number(displayXML[ConstValues.TRANSFORM][0].@[ConstValues.A_Y]);
				frameXML[ConstValues.TRANSFORM][0].@[ConstValues.A_PIVOT_X] = pivotX;
				frameXML[ConstValues.TRANSFORM][0].@[ConstValues.A_PIVOT_Y] = pivotY;
			}
		}
	}
}

function formatNumber(num:Number, retain:uint = 100):Number
{
	retain = retain || 100;
	return Math.round(num * retain) / retain;
}