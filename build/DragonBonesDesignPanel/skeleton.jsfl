var dragonBones = {};
(function(){

var SKELETON = "skeleton";

var ARMATURES = "armatures";
var ARMATURE = "armature";
var BONE = "b";
var DISPLAY = "d";

var ANIMATIONS = "animations";
var ANIMATION = "animation";
var MOVEMENT = "mov";
var FRAME = "f";
var COLOR_TRANSFORM = "colorTransform";

var TEXTURE_ATLAS = "TextureAtlas";
var SUB_TEXTURE = "SubTexture";

var A_FRAME_RATE = "frameRate";
var A_NAME = "name";
var A_START = "st";
var A_DURATION = "dr";
var A_DURATION_TO = "to";
var A_DURATION_TWEEN = "drTW";
var A_LOOP = "lp";
var A_MOVEMENT_SCALE = "sc";
var A_MOVEMENT_DELAY = "dl";

var A_PARENT = "parent";
var A_X = "x";
var A_Y = "y";
var A_SCALE_X = "cX";
var A_SCALE_Y = "cY";
var A_SKEW_X = "kX";
var A_SKEW_Y = "kY";
var A_Z = "z";
var A_DISPLAY_INDEX = "dI";
var A_EVENT = "evt";
var A_SOUND = "sd";
var A_SOUND_EFFECT = "sdE";
var A_TWEEN_EASING ="twE";
var A_TWEEN_ROTATE_ ="twR_";
var A_TWEEN_ROTATE ="twR";
var A_IS_ARMATURE = "isArmature";
var A_MOVEMENT = "mov";
var A_VISIBLE = "visible";

var A_WIDTH = "width";
var A_HEIGHT = "height";
var A_PIVOT_X = "pX";
var A_PIVOT_Y = "pY";

var A_ALPHA = "a";
var A_RED = "r";
var A_GREEN = "g";
var A_BLUE = "b";

var A_ALPHA_MULTIPLIER = "aM";
var A_RED_MULTIPLIER = "rM";
var A_GREEN_MULTIPLIER = "gM";
var A_BLUE_MULTIPLIER = "bM";

var V_SOUND_LEFT = "l";
var V_SOUND_RIGHT = "r";
var V_SOUND_LEFT_TO_RIGHT = "lr";
var V_SOUND_RIGHT_TO_LEFT = "rl";
var V_SOUND_FADE_IN = "in";
var V_SOUND_FADE_OUT = "out";

var SYMBOL = "symbol";
var MOVIE_CLIP = "movie clip";
var GRAPHIC = "graphic";
var BITMAP = "bitmap";
var STRING = "string";
var LABEL_TYPE_NAME = "name";
var EVENT_PREFIX = "@";
var MOVEMENT_PREFIX = "#";
var NO_EASING = "^";
var DELIM_CHAR = "|";
var UNDERLINE_CHAR = "_";

var PANEL_FOLDER = "DragonBonesDesignPanel";
var ARMATURE_DATA = "armatureData";
var ANIMATION_DATA = "animationData";

var TEXTURE_SWF_ITEM = "textureSWFItem";
var TEXTURE_SWF = "armatureTextureSWF.swf";

var _helpTransform = {x:0, y:0};

var _currentDom;
var _currentDomName;
var _currentItemBackup;
var _currentFrameBackup;

var _skeletonXML;
var _armaturesXML;
var _animationsXML;

var _armatureXML;
var _animationXML;
var _armatureConnectionXML;

function trace()
{
	var str = "";
	for(var i = 0;i < arguments.length;i ++)
	{
		if(i)
		{
			str += ",";
		}
		str += arguments[i];
	}
	fl.trace(str);
}

function formatNumber(num, retain)
{
	retain = retain || 100;
	return Math.round(num * retain) / retain;
}

function replaceString(strOld, str, rep)
{
	if(strOld)
	{
		return strOld.split(str).join(rep);
	}
	return "";
}

//to determine whether the layer is blank layer
function isBlankLayer(layer)
{
	var frames = filterKeyFrames(layer.frames);
	var i = frames.length;
	while(i --)
	{
		if(frames[i].elements.length)
		{
			return false;
		}
	}
	return true;
}

//filter key frames from a frame array
function filterKeyFrames(frames)
{
	var framesCopy = [];
	var length = frames.length;
	for(var i = 0;i < length;i ++)
	{
		var frame = frames[i];
		if(framesCopy.indexOf(frame) >= 0)
		{
			continue;
		}
		framesCopy.push(frame);
	}
	return framesCopy;
}

function errorDOM()
{
	if(!_currentDom)
	{
		alert("Cannot open FLA file!");
		return true;
	}
	return false;
}

//change object name if its name is invalid.
function formatName(obj)
{
	if(!obj.name)
	{
		obj.name = "unnamed" + Math.round(Math.random() * 10000);
	}
	return obj.name;
}

//handle conflict object name
function formatSameName(obj, dic)
{
	var name = formatName(obj);
	var i = 0;
	while(dic[name])
	{
		name = obj.name + i;
		i ++;
	}
	if(i > 0)
	{
		obj.name = name;
	}
	dic[name] = true;
	return name;
}

//to determine whether the frame is not a easing frame.
function isNoEasingFrame(frame)
{
	return frame.labelType == LABEL_TYPE_NAME && frame.name.indexOf(NO_EASING) == 0;
}

//To determine whether the frame is special frame
function isSpecialFrame(frame, framePrefix, returnName)
{
	var b = frame.labelType == LABEL_TYPE_NAME && frame.name.indexOf(framePrefix) >= 0 && frame.name.length > 1;
	if(b && returnName)
	{
		var arr = frame.name.split(DELIM_CHAR);
		for each(var str in arr)
		{
			if(str.indexOf(framePrefix) == 0)
			{
				return str.substr(1);
			}
		}
		//frame.name is incorrect special frame name
		return false;
	}
	return b;
}

//To determine whether the frame is a main frame
function isMainFrame(frame)
{
	if(frame.labelType == LABEL_TYPE_NAME)
	{
		if(isSpecialFrame(frame, EVENT_PREFIX) || isSpecialFrame(frame, MOVEMENT_PREFIX))
		{
			return false;
		}
		if(frame.name.indexOf(NO_EASING) == 0 && frame.name.length == 1)
		{
			return false;
		}
		return true;
	}
	return false;
}

//To determine whether the layer is main label layer
function isMainLayer(layer)
{
	var frames = filterKeyFrames(layer.frames);
	var i = frames.length;
	while(i --)
	{
		if(isMainFrame(frames[i]))
		{
			return true;
		}
	}
	return false;
}

//To determine whether the item is valide armature.
//If yes, return mainLayer and boneLayers
function isArmatureItem(item, isChildArmature)
{
	if(item.symbolType != MOVIE_CLIP && item.symbolType != GRAPHIC)
	{
		return null;
	}
	var layersFiltered = [];
	var layers = item.timeline.layers;
	var i = layers.length;
	while(i --)
	{
		var layer = layers[i];
		switch(layer.layerType)
		{
			case "folder":
			case "guide":
			case "mask":
				break;
			default:
				if(isMainLayer(layer))
				{
					var mainLayer = layer;
				}
				else if(!isBlankLayer(layer))
				{
					layersFiltered.push(layer);
				}
				break;
		}
	}
	
	if(layersFiltered.length > 0)
	{
		if(mainLayer)
		{
			layersFiltered.unshift(mainLayer);
			return layersFiltered;
		}
		else if(isChildArmature && item.timeline.frameCount > 1)
		{
			mainLayer = {};
			mainLayer.frameCount = item.timeline.frameCount;
			mainLayer.frames = [];
			
			var frame = { };
			frame.labelType = LABEL_TYPE_NAME;
			frame.name = "unnamed";
			frame.startFrame = 0;
			frame.duration = mainLayer.frameCount;
			
			mainLayer.frames.push(frame);
			layersFiltered.unshift(mainLayer);
			return layersFiltered;
		}
	}
	return null;
}

function getMainFrameList(frames)
{
	frames = filterKeyFrames(frames);
	var nameDic = {};
	var mainFrameList = [];
	var length = frames.length;
	for(var i = 0;i < length;i ++)
	{
		var frame = frames[i];
		if(isMainFrame(frame))
		{
			//new main frame
			var mainFrame = {};
			mainFrame.frame = frame;
			mainFrame.duration = frame.duration;
			mainFrame.frames = [frame];
			formatSameName(frame, nameDic);
		}
		else if(mainFrame)
		{
			//continue
			mainFrame.duration += frame.duration;
			mainFrame.frames.push(frame);
		}
		else
		{
			//ignore
			continue;
		}
		var isEndFrame = i + 1 == length || isMainFrame(frames[i + 1]);
		if(mainFrame && isEndFrame)
		{
			//end
			mainFrameList.push(mainFrame);
		}
	}
	return mainFrameList;
}

//filter bone symbol from all elements in a frame.
function getBoneSymbol(elements)
{
	var i = elements.length;
	while(i --)
	{
		var element = elements[i];
		if(element.symbolType == MOVIE_CLIP || element.symbolType == GRAPHIC || element.instanceType == BITMAP)
		{
			return element;
		}
	}
	return null;
}

//get bone by name from a frame 
function getBoneFromLayers(layers, boneName, frameIndex)
{
	var i = layers.length;
	while(i --)
	{
		var layer = layers[i];
		if(layer.name == boneName)
		{
			var frame = layer.frames[frameIndex];
			if(frame)
			{
				return getBoneSymbol(frame.elements);
			}
			break;
		}
	}
	return null;
}

//write armature connection data
function setArmatureConnection(item, data)
{
	item.addData(ARMATURE_DATA, STRING, data);
	//Jsfl api Or Flash pro bug
	item.symbolType = GRAPHIC;
	item.symbolType = MOVIE_CLIP;
}

function getMovementXML(movementName, duration, item)
{
	var xml = <{MOVEMENT} {A_NAME}={movementName}/>;
	if(item.hasData(ANIMATION_DATA))
	{
		var animationXML = XML(item.getData(ANIMATION_DATA));
		var movementXML = animationXML[MOVEMENT].(@name == movementName)[0];
	}
	xml.@[A_DURATION] = duration;
	if(movementXML)
	{
		xml.@[A_DURATION_TO] = movementXML.@[A_DURATION_TO];
	}
	else
	{
		xml.@[A_DURATION_TO] = 6;
	}
	if(duration > 1)
	{
		if(movementXML)
		{
			if(duration == movementXML.@[A_DURATION])
			{
				xml.@[A_DURATION_TWEEN] = movementXML.@[A_DURATION_TWEEN];
			}
			else
			{
				xml.@[A_DURATION_TWEEN] = duration;
				movementXML.@[A_DURATION] = duration;
				movementXML.@[A_DURATION_TWEEN] = duration;
			}
			xml.@[A_LOOP] = movementXML.@[A_LOOP];
			xml.@[A_TWEEN_EASING] = movementXML.@[A_TWEEN_EASING].length()?movementXML.@[A_TWEEN_EASING]:NaN;
		}
		else
		{
			xml.@[A_DURATION_TWEEN] = duration > 2?duration:10;
			if(duration == 2)
			{
				xml.@[A_LOOP] = 1;
				xml.@[A_TWEEN_EASING] = 2;
			}
			else
			{
				xml.@[A_LOOP] = 0;
				xml.@[A_TWEEN_EASING] = NaN;
			}
		}
	}
	return xml;
}

function getMovementBoneXML(movementXML, boneName, item)
{
	var xml = movementXML[BONE].(@name == boneName)[0];
	if(!xml)
	{
		xml = 
		<{BONE}
			{A_NAME}={boneName}
			{A_MOVEMENT_SCALE}="1"
			{A_MOVEMENT_DELAY}="0"
		/>;
		if(item.hasData(ANIMATION_DATA))
		{
			var animationXML = XML(item.getData(ANIMATION_DATA));
			movementName = movementXML.@[A_NAME];
			var movementXMLBackup = animationXML[MOVEMENT].(@name == movementName)[0];
			if(movementXMLBackup)
			{
				var boneXML = movementXMLBackup[BONE].(@name == boneName)[0];
				if(boneXML)
				{
					xml.@[A_MOVEMENT_SCALE] = boneXML.@[A_MOVEMENT_SCALE];
					xml.@[A_MOVEMENT_DELAY] = boneXML.@[A_MOVEMENT_DELAY];
				}
			}
		}
		movementXML.appendChild(xml);
	}
	return xml;
}

function getBoneXML(name, frameXML)
{
	var xml = _armatureXML[BONE].(@name == name)[0];
	if(!xml)
	{
		xml = 
		<{BONE}
			{A_NAME}={name}
			{A_X}={frameXML.@[A_X]}
			{A_Y}={frameXML.@[A_Y]}
			{A_SKEW_X}={frameXML.@[A_SKEW_X]}
			{A_SKEW_Y}={frameXML.@[A_SKEW_Y]}
			{A_SCALE_X}={frameXML.@[A_SCALE_X]}
			{A_SCALE_Y}={frameXML.@[A_SCALE_Y]}
			{A_PIVOT_X}={frameXML.@[A_PIVOT_X]}
			{A_PIVOT_Y}={frameXML.@[A_PIVOT_Y]}
			{A_Z}={frameXML.@[A_Z]}
		/>;
		var connectionXML = _armatureConnectionXML[BONE].(@name == name)[0];
		if(connectionXML && connectionXML.@[A_PARENT][0])
		{
			xml.@[A_PARENT] = connectionXML.@[A_PARENT];
		}
		_armatureXML.appendChild(xml);
	}
	return xml;
}

function getDisplayXML(boneXML, imageName, isArmature)
{
	var xml = boneXML[DISPLAY].(@name == imageName)[0];
	if(!xml)
	{
		xml = <{DISPLAY} {A_NAME}={imageName}/>;
		if(isArmature)
		{
			xml.@[A_IS_ARMATURE] = 1;
		}
		boneXML.appendChild(xml);
	}
	return xml;
}

function generateMovement(item, mainFrame, layers)
{
	var start = mainFrame.frame.startFrame;
	var duration = mainFrame.duration;
	var movementName = mainFrame.frame.name;
	if(isNoEasingFrame(mainFrame.frame))
	{
		var noAutoEasing = true;
		movementName = movementName.substr(1);
	}
	
	var movementXML = getMovementXML(movementName, duration, item);
	
	var boneNameDic = {};
	var boneZDic = {};
	var zList = [];
	
	var layersLength = layers.length;
	for(var i = 0;i < layersLength;i ++)
	{
		var layer = layers[i];
		var boneName = formatName(layer);
		boneZDic[boneName] = boneZDic[boneName] || [];
		var movementBoneXML = null;
		var frames = filterKeyFrames(layer.frames.slice(start, start + duration));
		var framesLength = frames.length;
		for(var j = 0;j < framesLength;j ++)
		{
			frame = frames[j];
			if(frame.startFrame < start)
			{
				var frameStart = 0;
				var frameDuration = frame.duration - start + frame.startFrame;
			}
			else if(frame.startFrame + frame.duration > start + duration)
			{
				frameStart = frame.startFrame - start;
				frameDuration = duration - frame.startFrame + start;
			}
			else
			{
				frameStart = frame.startFrame - start;
				frameDuration= frame.duration;
			}
			var symbol = getBoneSymbol(frame.elements);
			if(!symbol)
			{
				continue;
			}
			if(!movementBoneXML)
			{
				movementBoneXML = getMovementBoneXML(movementXML, boneName, item);
			}
			for(var k = frameStart ;k < frameStart + frameDuration;k ++)
			{
				var z = zList[k];
				if(isNaN(z))
				{
					zList[k] = z = 0;
				}
				else
				{
					zList[k] = ++ z;
				}
			}
			z = zList[frameStart];
			var boneList = boneZDic[boneName];
			for(k = frameStart;k < frameStart + frameDuration;k ++)
			{
				if(!isNaN(boneList[k]))
				{
					boneNameDic[boneName] = true;
					boneName = formatSameName(layer, boneNameDic);
					boneList = boneZDic[boneName] = [];
					movementBoneXML = getMovementBoneXML(movementXML, boneName, item);
				}
				boneList[k] = z;
			}
			
			if(frame.tweenType == "motion object")
			{
				break;
			}
			addFrameToMovementBone(
				generateFrame(frame, boneName, symbol, z, noAutoEasing),
				frameStart,
				frameDuration, 
				movementBoneXML
			);
		}
	}
	var timelineXMLList = movementXML[BONE];
	for each(var movementBoneXML in timelineXMLList)
	{
		boneName = movementBoneXML.@[A_NAME];
		var prevFrameXML = null;
		var frameXMLList = movementBoneXML[FRAME];
		for each(var frameXML in frameXMLList)
		{
			frameStart = Number(frameXML.@[A_START]);
			if(frameXML.childIndex() == 0)
			{
				if(frameStart > 0)
				{
					movementBoneXML.prependChild(<{FRAME} {A_DURATION}={frameStart} {A_DISPLAY_INDEX}="-1"/>);
				}
			}
			else 
			{
				var prevStart = Number(prevFrameXML.@[A_START]);
				var prevDuration = Number(prevFrameXML.@[A_DURATION]);
				if(frameStart > prevStart + prevDuration)
				{
					movementBoneXML.insertChildBefore(frameXML, <{FRAME} {A_DURATION}={frameStart - prevStart - prevDuration} {A_DISPLAY_INDEX}="-1"/>);
				}
			}
			if(frameXML.childIndex() == movementBoneXML[FRAME].length() - 1)
			{
				frameStart = Number(frameXML.@[A_START]);
				prevDuration = Number(frameXML.@[A_DURATION]);
				if(frameStart + prevDuration < duration)
				{
					movementBoneXML.appendChild(<{FRAME} {A_DURATION}={duration - frameStart - prevDuration} {A_DISPLAY_INDEX}="-1"/>);
				}
			}
			//tweenRotate property is for the end point of tween instead of start point
			//sometimes, x0 need to be ingored
			if(prevFrameXML && prevFrameXML.@[A_TWEEN_ROTATE_][0])
			{
				var dSkY = Number(frameXML.@[A_SKEW_Y]) - Number(prevFrameXML.@[A_SKEW_Y]);
				if(dSkY < -180)
				{
					dSkY += 360;
				}
				if(dSkY > 180)
				{
					dSkY -= 360;
				}
				tweenRotate = Number(prevFrameXML.@[A_TWEEN_ROTATE_]);
				if(dSkY !=0)
				{
					if(dSkY < 0)
					{
						if(tweenRotate >= 0)
						{
							tweenRotate ++;
						}
					}
					else
					{
						if(tweenRotate < 0)
						{
							tweenRotate --;
						}
					}
				}
				frameXML.@[A_TWEEN_ROTATE] = tweenRotate;
				delete prevFrameXML.@[A_TWEEN_ROTATE_];
			}
			
			prevFrameXML = frameXML;
		}
	}
	delete movementXML[BONE][FRAME].@[A_START];
	
	generateMovementEventFrames(movementXML, mainFrame);
	
	_animationXML.appendChild(movementXML);
}

function generateFrame(frame, boneName, symbol, z, noAutoEasing)
{
	_helpTransform = symbol.getTransformationPoint();
	if(symbol.instanceType == BITMAP && _helpTransform.x == 0 && _helpTransform.y == 0)
	{
		_helpTransform.x = symbol.hPixels * 0.5;
		_helpTransform.y = symbol.vPixels * 0.5;
	}

	var frameXML = 
	<{FRAME}
		{A_X}={formatNumber(symbol.transformX)}
		{A_Y}={formatNumber(symbol.transformY)}
		{A_SKEW_X}={formatNumber(symbol.skewX)}
		{A_SKEW_Y}={formatNumber(symbol.skewY)}
		{A_SCALE_X}={formatNumber(symbol.scaleX)}
		{A_SCALE_Y}={formatNumber(symbol.scaleY)}
		{A_PIVOT_X}={_helpTransform.x}
		{A_PIVOT_Y}={_helpTransform.y}
		{A_Z}={z}
	/>;
	
	if(symbol.instanceType != BITMAP)
	{
		var a = symbol.colorAlphaAmount;
		var r = symbol.colorRedAmount;
		var g = symbol.colorGreenAmount;
		var b = symbol.colorBlueAmount;
		var aM = symbol.colorAlphaPercent;
		var rM = symbol.colorRedPercent;
		var gM = symbol.colorGreenPercent;
		var bM = symbol.colorBluePercent;
		if(
			a != 0 ||
			r != 0 || 
			g != 0 || 
			b != 0 || 
			aM != 100 || 
			rM != 100 || 
			gM != 100 || 
			bM != 100
		)
		{
			var colorTransformXML = 
			<{COLOR_TRANSFORM}
				{A_ALPHA}={a}
				{A_RED}={r}
				{A_GREEN}={g}
				{A_BLUE}={b}
				{A_ALPHA_MULTIPLIER}={aM}
				{A_RED_MULTIPLIER}={rM}
				{A_GREEN_MULTIPLIER}={gM}
				{A_BLUE_MULTIPLIER}={bM}
			/>;
			frameXML.appendChild(colorTransformXML);
		}
	}
	
	var boneXML = getBoneXML(boneName, frameXML);
	
	var imageItem = symbol.libraryItem;
	var imageName = formatName(imageItem);
	var isChildArmature = symbol.symbolType == MOVIE_CLIP;
	var isArmature = isArmatureItem(imageItem, isChildArmature);
	
	var displayXML = getDisplayXML(boneXML, imageName, isArmature);
	
	if(symbol.visible === false)
	{
		frameXML.@[A_VISIBLE] = 0;
	}
	
	frameXML.@[A_DISPLAY_INDEX] = displayXML.childIndex();
	
	if(isArmature)
	{
		var backupArmatureXML = _armatureXML;
		var backupAnimationXML = _animationXML;
		var backupArmatureConnectionXML = _armatureConnectionXML;
		
		dragonBones.generateArmature(imageName,1, false, isChildArmature);
		
		_armatureXML = backupArmatureXML;
		_animationXML = backupAnimationXML;
		_armatureConnectionXML = backupArmatureConnectionXML;
	}
	
	var str = isSpecialFrame(frame, MOVEMENT_PREFIX, true);
	if(str)
	{
		frameXML.@[A_MOVEMENT] = str;
	}
	
	//ease
	if(noAutoEasing)
	{
		if(frame.tweenType != "motion")
		{
			frameXML.@[A_TWEEN_EASING] = NaN;
		}
		else
		{
			frameXML.@[A_TWEEN_EASING] = formatNumber(frame.tweenEasing * 0.01);
			var tweenRotate = NaN;
			switch(frame.motionTweenRotate)
			{
				case "clockwise":
					tweenRotate = frame.motionTweenRotateTimes + 1;
					break;
				case "counter-clockwise":
					tweenRotate = - frame.motionTweenRotateTimes - 1;
					break;
			}
			if(!isNaN(tweenRotate))
			{
				frameXML.@[A_TWEEN_ROTATE_] = tweenRotate;
			}
		}
	}
	else
	{
		if(isNoEasingFrame(frame))
		{
			frameXML.@[A_TWEEN_EASING] = NaN;
		}
		else if(frame.tweenType == "motion")
		{
			frameXML.@[A_TWEEN_EASING] = formatNumber(frame.tweenEasing * 0.01);
			var tweenRotate = NaN;
			switch(frame.motionTweenRotate)
			{
				case "clockwise":
					tweenRotate = frame.motionTweenRotateTimes;
					break;
				case "counter-clockwise":
					tweenRotate = - frame.motionTweenRotateTimes;
					break;
			}
			if(!isNaN(tweenRotate))
			{
				frameXML.@[A_TWEEN_ROTATE_] = tweenRotate;
			}
		}
	}
	
	//event
	str = isSpecialFrame(frame, EVENT_PREFIX, true);
	if(str)
	{
		frameXML.@[A_EVENT] = str;
	}

	//sound
	if(frame.soundName)
	{
		frameXML.@[A_SOUND] = frame.soundLibraryItem.linkageClassName || frame.soundName;
	}
	
	return frameXML;
}

function generateMovementEventFrames(movementXML, mainFrame)
{
	if(mainFrame.frames.length > 1)
	{
		var start = mainFrame.frame.startFrame;
		var length = mainFrame.frames.length;
		for(var i = 0;i < length;i ++)
		{
			var frame = mainFrame.frames[i];
			var eventXML = <{FRAME} {A_START}={frame.startFrame - start} {A_DURATION}={frame.duration}/>;
			var event = isSpecialFrame(frame, EVENT_PREFIX, true);
			var movement = isSpecialFrame(frame, MOVEMENT_PREFIX, true);
			var sound = frame.soundName && (frame.soundLibraryItem.linkageClassName || frame.soundName);
			if(event)
			{
				eventXML.@[A_EVENT] = event;
			}
			if(movement)
			{
				eventXML.@[A_MOVEMENT] = movement;
			}
			if(sound)
			{
				frameXML.@[A_SOUND] = sound;
			}
			movementXML.appendChild(eventXML);
		}
	}
}

function addFrameToMovementBone(frameXML, start, duration, movementBoneXML)
{
	frameXML.@[A_START] = start;
	frameXML.@[A_DURATION] = duration;
	var frameXMLList = movementBoneXML[FRAME];
	for each(var eachFrameXML in frameXMLList)
	{
		if(Number(eachFrameXML.@[A_START]) > start)
		{
			movementBoneXML.insertChildBefore(eachFrameXML, frameXML);
			return;
		}
	}
	movementBoneXML.appendChild(frameXML);
}

dragonBones.getArmatureList = function(isSelected, armatureNames)
{
	fl.outputPanel.clear();
	_currentDom = fl.getDocumentDOM();
	if(errorDOM())
	{
		return false;
	}
	
	var timeline = _currentDom.getTimeline();
	_currentItemBackup = timeline.libraryItem;
	if(_currentItemBackup)
	{
		_currentFrameBackup = timeline.currentFrame;
	}
	_currentDom.exitEditMode();
	_currentDomName = _currentDom.name.split(".")[0];
	
	if(armatureNames)
	{
		armatureNames = armatureNames.split(",");
		var armatureLength = armatureNames.length;
	}
	
	if(armatureLength > 0)
	{
		var items = [];
		for each(var armatureName in armatureNames)
		{
			var item = _currentDom.library.items[_currentDom.library.findItemIndex(armatureName)];
			if(item)
			{
				items.push(item);
			}
		}
	}
	else
	{
		var items = isSelected?_currentDom.library.getSelectedItems():_currentDom.library.items;
	}
	
	var xml = <{ARMATURES} {A_NAME}={_currentDomName}/>;
	for each(var item in items)
	{
		if(isArmatureItem(item))
		{
			formatName(item);
			xml.appendChild(<{ARMATURE} {A_NAME}={item.name} scale ={1}/>);
		}
	}
	return xml.toXMLString();
}

dragonBones.generateArmature = function(armatureName, scale, isNewXML, isChildArmature)
{
	var item = _currentDom.library.items[_currentDom.library.findItemIndex(armatureName)];
	if(!item)
	{
		return false;
	}
	if(isNewXML)
	{
		_skeletonXML = <{SKELETON} {A_NAME}={_currentDomName} {A_FRAME_RATE}={_currentDom.frameRate}/>;
		_armaturesXML = <{ARMATURES}/>;
		_animationsXML = <{ANIMATIONS}/>;
		_skeletonXML.appendChild(_armaturesXML);
		_skeletonXML.appendChild(_animationsXML);
	}
	if(_armaturesXML[ARMATURE].(@name == armatureName)[0])
	{
		return false;
	}
	
	_armatureXML = <{ARMATURE} {A_NAME}={armatureName}/>;
	_armaturesXML.appendChild(_armatureXML);
	_animationXML = <{ANIMATION} {A_NAME}={armatureName}/>;
	_armatureConnectionXML = item.hasData(ARMATURE_DATA)?XML(item.getData(ARMATURE_DATA)):_armatureXML;
	
	var layersFiltered = isArmatureItem(item, isChildArmature);
	var mainLayer = layersFiltered.shift();
	var mainFrameList = getMainFrameList(mainLayer.frames);
	for each(var mainFrame in mainFrameList)
	{
		generateMovement(item, mainFrame, layersFiltered);
	}
	
	//setArmatureConnection(item, _armatureXML.toXMLString());
	
	//if frame count > 1, the skeleton have animation.
	if(mainLayer.frameCount > 1)
	{
		_animationsXML.appendChild(_animationXML);
	}
	
	return _skeletonXML.toXMLString();
}

dragonBones.clearTextureSWFItem = function()
{
	if(!_currentDom.library.itemExists(TEXTURE_SWF_ITEM))
	{
		_currentDom.library.addNewItem(MOVIE_CLIP, TEXTURE_SWF_ITEM);
	}
	_currentDom.library.editItem(TEXTURE_SWF_ITEM);
	_skeletonXML = null;
	_armaturesXML = null;
	_animationsXML = null;

	_armatureXML = null;
	_animationXML = null;
	_armatureConnectionXML = null;
	
	var timeline = _currentDom.getTimeline();
	timeline.currentLayer = 0;
	timeline.removeFrames(0, timeline.frameCount);
	timeline.insertBlankKeyframe(0);
	timeline.insertBlankKeyframe(1);
	return <{TEXTURE_ATLAS} {A_NAME}={_currentDomName}/>.toXMLString();
}

dragonBones.addTextureToSWFItem = function(_textureName, isLast)
{
	var item = _currentDom.library.items[_currentDom.library.findItemIndex(_textureName)];
	if(!item)
	{
		return false;
	}
	
	var timeline = _currentDom.getTimeline();
	timeline.currentFrame = 0;
	_helpTransform.x = _helpTransform.y = 0;
	var tryTimes = 0;
	var putSuccess = false;
	var symbol;
	_currentDom.selectNone();
	do
	{
		putSuccess = _currentDom.library.addItemToDocument(_helpTransform, _textureName);
		symbol = _currentDom.selection[0]
		tryTimes ++;
	}
	while((!putSuccess || !symbol) && tryTimes < 5);
	if(!symbol)
	{
		trace("内存不足导致放置贴图失败！请尝试重新导入。");
		return false;
	}
	switch(symbol.instanceType)
	{
		case SYMBOL:
			if(symbol.symbolType != MOVIE_CLIP)
			{
				symbol.symbolType = MOVIE_CLIP
			}
			break;
		case BITMAP:
			var bitmapItem = symbol.libraryItem;
			bitmapItem.linkageExportForAS = true;
			bitmapItem.linkageClassName = bitmapItem.name;
			break;
	}
	
	var subTextureXML = <{SUB_TEXTURE} {A_NAME}={_textureName}/>;
	
	if(isLast)
	{
		timeline.removeFrames(1, 1);
		if(_currentItemBackup)
		{
			_currentDom.library.editItem(_currentItemBackup.name);
			_currentDom.getTimeline().currentFrame = _currentFrameBackup;
		}
	}
	else
	{
		timeline.currentFrame = 1;
	}
	return subTextureXML.toXMLString();
}

dragonBones.exportSWF = function()
{
	if(errorDOM())
	{
		return "";
	}
	
	if(!_currentDom.library.itemExists(TEXTURE_SWF_ITEM))
	{
		return "";
	}
	var folderURL = fl.configURI;
	if(folderURL.indexOf("/")>=0)
	{
		var pathDelimiter = "/";
	}
	else if(folderURL.indexOf("\\")>=0)
	{
		pathDelimiter = "\\";
	}
	else
	{
		return "";
	}
	folderURL = folderURL + "WindowSWF" + pathDelimiter + PANEL_FOLDER;
	if(!FLfile.exists(folderURL))
	{
		FLfile.createFolder(folderURL);
	}
	var swfURL = folderURL + pathDelimiter + TEXTURE_SWF;
	_currentDom.library.items[_currentDom.library.findItemIndex(TEXTURE_SWF_ITEM)].exportSWF(swfURL);
	return swfURL;
}

//Write armatureConnection data by armatureName
dragonBones.changeArmatureConnection = function(armatureName, data)
{
	if(errorDOM())
	{
		return false;
	}
	var item = _currentDom.library.items[_currentDom.library.findItemIndex(armatureName)];
	if(!item)
	{
		trace("cannot find " + armatureName + " element，please make sure your fla file is synchronized！");
		return false;
	}
	data = XML(data).toXMLString();
	data = replaceString(data, "&lt;", "<");
	data = replaceString(data, "&gt;", ">");
	setArmatureConnection(item, data);
	return true;
}

dragonBones.changeMovement = function(armatureName, movementName, data)
{
	if(errorDOM())
	{
		return false;
	}
	var item = _currentDom.library.items[_currentDom.library.findItemIndex(armatureName)];
	if(!item)
	{
		trace("cannot find " + armatureName + " element，please make sure your fla file is synchronized！");
		return false;
	}
	
	data = XML(data).toXMLString();
	data = replaceString(data, "&lt;", "<");
	data = replaceString(data, "&gt;", ">");
	data = XML(data);
	delete data[BONE].*;
	
	var animationXML;
	if(item.hasData(ANIMATION_DATA))
	{
		animationXML = XML(item.getData(ANIMATION_DATA));
	}
	else
	{
		animationXML = <{ANIMATION}/>;
	}
	var movementXML = animationXML[MOVEMENT].(@name == movementName)[0];
	if(movementXML)
	{
		animationXML[MOVEMENT][movementXML.childIndex()] = data;
	}
	else
	{
		animationXML.appendChild(data);
	}
	item.addData(ANIMATION_DATA, STRING, animationXML.toXMLString());
	//Jsfl api Or Flash pro bug
	item.symbolType = GRAPHIC;
	item.symbolType = MOVIE_CLIP;
	return true;
}

dragonBones.copyMovement = function(targetArmatureName, sourceArmatureName, sourceMovementName, sourceMovementXML)
{
	if(errorDOM())
	{
		return false;
	}
	
	var targetArmature = _currentDom.library.items[_currentDom.library.findItemIndex(targetArmatureName)];
	var sourceArmature = _currentDom.library.items[_currentDom.library.findItemIndex(sourceArmatureName)];
	var unfoundName = !targetArmature?targetArmatureName:(!sourceArmature?sourceArmatureName:null);
	if(unfoundName)
	{
		trace("cannot find " + unfoundName + " element，please make sure your fla file is synchronized！");
		return false;
	}
	
	//获取 targetArmature 中的元件列表
	var targetLayers = isArmatureItem(targetArmature);
	var targetMainLayer = targetLayers.shift();
	var targetMainFrameList = getMainFrameList(targetMainLayer.frames);
	for each(var mainFrame in targetMainFrameList)
	{
		if(mainFrame.frame.name == sourceMovementName)
		{
			//拥有同名动画
			return false;
		}
	}
	
	var targetTimeline = targetArmature.timeline;
	var targetStartFrame = targetTimeline.frameCount;
	var targetMark = {};
	var targetLayerIndexs = {};
	for each(var layer in targetLayers)
	{
		var layerIndex = targetTimeline.layers.indexOf(layer);
		var boneName = layer.name;
		targetLayerIndexs[boneName] = layerIndex;
		
		var targetTextureList = [];
		targetMark[boneName] = targetTextureList;
		for each(var frame in filterKeyFrames(layer.frames))
		{
			var boneSymbol = getBoneSymbol(frame.elements);
			if(boneSymbol)
			{
				var textureName = boneSymbol.libraryItem.name;
				if(targetTextureList.indexOf(textureName) == -1)
				{
					targetTextureList.push(textureName);
				}
			}
		}
	}
	
	var sourceLayers = isArmatureItem(sourceArmature);
	var sourceMainLayer = sourceLayers[0];
	var sourceMainFrameList = getMainFrameList(sourceMainLayer.frames);
	
	for each(var mainFrame in sourceMainFrameList)
	{
		if(mainFrame.frame.name == sourceMovementName)
		{
			break;
		}
	}
	
	sourceMovementXML = XML(sourceMovementXML).toXMLString();
	sourceMovementXML = replaceString(sourceMovementXML, "&lt;", "<");
	sourceMovementXML = replaceString(sourceMovementXML, "&gt;", ">");
	sourceMovementXML = XML(sourceMovementXML);
	
	var sourceStartFrame = mainFrame.frame.startFrame;
	var sourceDuration = mainFrame.duration;
	var sourceTimeline = sourceArmature.timeline;
	
	var targetLayerIndex;
	var boneName = layer.name;
	for each(var layer in sourceLayers)
	{
		if(sourceMainLayer == layer)
		{
			boneName = null;
			targetLayerIndex = targetTimeline.layers.indexOf(targetMainLayer);
		}
		else
		{
			boneName = layer.name;
			targetLayerIndex = targetLayerIndexs[boneName];
			if(!targetLayerIndex && targetLayerIndex != 0)
			{
				continue;
			}
		}
		
		_currentDom.library.editItem(sourceArmatureName);
		sourceTimeline.currentLayer = sourceTimeline.layers.indexOf(layer);
		sourceTimeline.copyFrames(sourceStartFrame, sourceStartFrame + sourceDuration);
		
		_currentDom.library.editItem(targetArmatureName);
		targetTimeline.currentLayer = targetLayerIndex;
		targetTimeline.pasteFrames(targetStartFrame, targetStartFrame + sourceDuration);
		
		if(boneName)
		{
			var movementBoneXML = sourceMovementXML[BONE].(@name == boneName)[0];
			if(!movementBoneXML)
			{
				continue;
			}
			layer = targetTimeline.layers[targetLayerIndex];
			layer.locked = false;
			layer.visible = true;
			var targetTextureList = targetMark[boneName];
			var copyTextureList = [];
			var currentFrame = 0;
			var frames = layer.frames;
			var frameXMLList = movementBoneXML[FRAME];
			for each(var frameXML in frameXMLList)
			{
				var frame = frames[targetStartFrame + currentFrame];
				currentFrame += Number(frameXML.@[A_DURATION]);
				var boneSymbol = getBoneSymbol(frame.elements);
				if(!boneSymbol)
				{
					continue;
				}
				var textureName = boneSymbol.libraryItem.name;
				var subListID = copyTextureList.indexOf(textureName);
				if(subListID == -1)
				{
					subListID = copyTextureList.length;
					copyTextureList.push(textureName);
				}
				if(subListID >= targetTextureList.length)
				{
					subListID = targetTextureList.length - 1;
				}
				textureName = targetTextureList[subListID];
				targetTimeline.currentFrame = frame.startFrame;
				_currentDom.selectNone();
				boneSymbol.selected = true;
				_currentDom.swapElement(textureName);
				boneSymbol = _currentDom.selection[0];
				
				_helpTransform.x = Number(frameXML.@[A_X]);
				_helpTransform.y = Number(frameXML.@[A_Y]);
				_helpTransform.scaleX = Number(frameXML.@[A_SCALE_X]);
				_helpTransform.scaleY = Number(frameXML.@[A_SCALE_Y]);
				_helpTransform.skewX = Number(frameXML.@[A_SKEW_X]) / 180 * Math.PI;
				_helpTransform.skewY = Number(frameXML.@[A_SKEW_Y]) / 180 * Math.PI;
				_helpTransform.pivotX = Number(frameXML.@[A_PIVOT_X]);
				_helpTransform.pivotY = Number(frameXML.@[A_PIVOT_Y]);
				
				var matrix = boneSymbol.matrix;
				matrix.a = _helpTransform.scaleX * Math.cos(_helpTransform.skewY)
				matrix.b = _helpTransform.scaleX * Math.sin(_helpTransform.skewY)
				matrix.c = -_helpTransform.scaleY * Math.sin(_helpTransform.skewX);
				matrix.d = _helpTransform.scaleY * Math.cos(_helpTransform.skewX);
				matrix.tx = _helpTransform.x - (matrix.a * _helpTransform.pivotX + matrix.c * _helpTransform.pivotY);
				matrix.ty = _helpTransform.y - (matrix.b * _helpTransform.pivotX + matrix.d * _helpTransform.pivotY);
				
				_helpTransform.x = _helpTransform.pivotX;
				_helpTransform.y = _helpTransform.pivotY;
				boneSymbol.matrix = matrix;
				boneSymbol.setTransformationPoint(_helpTransform);
			}
		}
	}
}

})();