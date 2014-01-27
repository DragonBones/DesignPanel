var dragonBones = {};
(function(){

var OLD_BONE = "b";
var OLD_ANIMATION = "mov";
var OLD_TIMELINE = "b";
var OLD_DURATION_TO = "to";
var OLD_LOOP = "lp";
var OLD_DURATION_TWEEN = "drTW";
var OLD_TWEEN_EASING = "twE";
var OLD_SCALE = "sc";
var OLD_OFFSET = "dl";

var DRAGON_BONES = "dragonBones";
var ARMATURE = "armature";
var BONE = "bone";
var SKIN = "skin";
var SLOT = "slot";
var DISPLAY = "display";
var ANIMATION = "animation";
var TIMELINE = "timeline";
var FRAME = "frame";
var TRANSFORM = "transform";
var COLOR_TRANSFORM = "colorTransform";

var A_FRAME_RATE = "frameRate";
var A_NAME = "name";
var A_START = "start";
var A_DURATION = "duration";
var A_FADE_IN_TIME = "fadeInTime";
var A_LOOP = "loop";
var A_SCALE = "scale";
var A_OFFSET = "offset";

var A_PARENT = "parent";
var A_TYPE = "type";
var A_X = "x";
var A_Y = "y";
var A_SKEW_X = "skX";
var A_SKEW_Y = "skY";
var A_SCALE_X = "scX";
var A_SCALE_Y = "scY";
var A_PIVOT_X = "pX";
var A_PIVOT_Y = "pY";
var A_Z_ORDER = "z";
var A_BLEND_MODE = "blendMode";
var A_DISPLAY_INDEX = "displayIndex";
var A_EVENT = "event";
var A_SOUND = "sound";
var A_TWEEN_EASING ="tweenEasing";
var A_TWEEN_ROTATE ="tweenRotate";
var A_ACTION = "action";
var A_HIDE = "hide";

var A_WIDTH = "width";
var A_HEIGHT = "height";

var A_ALPHA_OFFSET = "aO";
var A_RED_OFFSET = "rO";
var A_GREEN_OFFSET = "gO";
var A_BLUE_OFFSET = "bO";
var A_ALPHA_MULTIPLIER = "aM";
var A_RED_MULTIPLIER = "rM";
var A_GREEN_MULTIPLIER = "gM";
var A_BLUE_MULTIPLIER = "bM";

var V_IMAGE = "image";
var V_ARMATURE = "armature";

var SYMBOL = "symbol";
var MOVIE_CLIP = "movie clip";
var GRAPHIC = "graphic";
var BITMAP = "bitmap";
var TWEEN_TYPE_IK = "IK pose";
var TWEEN_TYPE_NONE = "none";
var TWEEN_TYPE_SHAPE = "shape";
var TWEEN_TYPE_MOTION = "motion";
var TWEEN_TYPE_MOTION_OBJECT = "motion object";
var STRING = "string";
var LABEL_TYPE_NAME = "name";
var EVENT_PREFIX = "@";
var ACTION_PREFIX = "#";
var NO_EASING = "^";
var DELIM_CHAR = "|";
var UNDERLINE_CHAR = "_";

var PANEL_FOLDER = "DragonBonesDesignPanel";
var ARMATURE_DATA = "armatureData";
var ANIMATION_DATA = "animationData";

var TEXTURE_SWF_ITEM = "textureSWFItem";
var TEXTURE_SWF = "armatureTextureSWF.swf";
var TEXTURE_AUTO_CREATE = "dbTextures";

var _helpTransform = {x:0, y:0};

var _currentDom;
var _currentDomName;
var _currentItemBackup;
var _currentFrameBackup;
var _librarySelectItemsBackup;
var _isMergeLayersInFolder;

var _defaultFadeInTime;

var _xml;

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
function isBoneLayer(layer)
{
	var frames = filterKeyFrames(layer.frames);
	var i = frames.length;
	while(i --)
	{
		if(frames[i].elements.length > 0)
		{
			return true;
		}
	}
	return false;
}

//filter key frames from a frame array
function filterKeyFrames(frames)
{
	var framesCopy = [];
	var length = frames.length;
	var frame;
	for(var i = 0;i < length;i ++)
	{
		frame = frames[i];
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
		obj.name = "unnamed_" + Math.round(Math.random() * 10000);
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
	var result = 
		frame.labelType == LABEL_TYPE_NAME && 
		frame.name.indexOf(framePrefix) >= 0 && 
		frame.name.length > 1;
	
	if(result && returnName)
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
	return result;
}

//To determine whether the frame is a main frame
function isMainFrame(frame)
{
	if(frame.labelType == LABEL_TYPE_NAME)
	{
		if(
			isSpecialFrame(frame, EVENT_PREFIX) || 
			isSpecialFrame(frame, ACTION_PREFIX)
		)
		{
			return false;
		}
		//
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
	if(
		item.symbolType != MOVIE_CLIP && 
		item.symbolType != GRAPHIC
	)
	{
		return null;
	}
	var layersFiltered = [];
	var layers = item.timeline.layers;
	var i = layers.length;
	var layer;
	var mainLayer;
	while(i --)
	{
		layer = layers[i];
		switch(layer.layerType)
		{
			case "folder":
			case "guide":
			case "mask":
				break;
			default:
				if(layer.name && layer.name.indexOf("^") == 0)
				{
					break;
				}
				else if(isMainLayer(layer))
				{
					mainLayer = layer;
				}
				else if(isBoneLayer(layer))
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
			//检测未加标签的子动画时，虽然frameCount大于1，但应更深入的检查是否各个图层只有一帧
			
			mainLayer = {};
			mainLayer.frameCount = item.timeline.frameCount;
			mainLayer.frames = [];
			mainLayer.noLabelChildArmature = true;
			
			var frame = {};
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
	var frame;
	var mainFrame;
	var isEndFrame;
	for(var i = 0;i < length;i ++)
	{
		frame = frames[i];
		if(isMainFrame(frame))
		{
			//new main frame
			mainFrame = {};
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
		isEndFrame = i + 1 == length || isMainFrame(frames[i + 1]);
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
	var element;
	while(i --)
	{
		element = elements[i];
		if(
			element.symbolType == MOVIE_CLIP || 
			element.symbolType == GRAPHIC || 
			element.instanceType == BITMAP
		)
		{
			return element;
		}
	}
	return null;
}

function appendXML(parentXML, childXML)
{
	var xmlList = parentXML[childXML.localName()];
	var lastXML = (xmlList && xmlList.length() > 0)?xmlList[xmlList.length() - 1]:null;
	if(lastXML)
	{
		parentXML.insertChildAfter(lastXML, childXML);
	}
	else
	{
		parentXML.appendChild(childXML);
	}
}

function getAnimationXML(armatureXML, name, item, duration, noLabelChildArmature)
{
	var xml = armatureXML[ANIMATION].(@name == name)[0];
	if(!xml)
	{
		var fadeInTime;

		if(noLabelChildArmature)
		{
			fadeInTime = 0;
		}
		else if(!isNaN(_defaultFadeInTime))
		{
			fadeInTime = _defaultFadeInTime;
		}
		else
		{
			fadeInTime = 0.3;
		}
		
		var loop = 1;
		var scale = 1;
		var tweenEasing = NaN;
		
		if(item.hasData(ANIMATION_DATA))
		{
			var animationsXML = XML(item.getData(ANIMATION_DATA));
			var animationXMLInItem;
			if(animationsXML[ANIMATION].length() > 0)
			{
				animationXMLInItem = animationsXML[ANIMATION].(@name == name)[0];
				if(animationXMLInItem)
				{
					fadeInTime = Number(animationXMLInItem.@[A_FADE_IN_TIME]);
					loop = Number(animationXMLInItem.@[A_LOOP]);
					scale = Number(animationXMLInItem.@[A_SCALE]);
					tweenEasing = Number(animationXMLInItem.@[A_TWEEN_EASING]);
				}
			}
			
			if(!animationXMLInItem && animationsXML[OLD_ANIMATION].length() > 0)
			{
				animationXMLInItem = animationsXML[OLD_ANIMATION].(@name == name)[0];
				if(animationXMLInItem)
				{
					fadeInTime = Number(animationXMLInItem.@[OLD_DURATION_TO]) / _currentDom.frameRate;
					loop = Number(animationXMLInItem.@[OLD_LOOP]);
					if(loop == 1)
					{
						loop = 0;
					}
					else
					{
						loop = 1;
					}
					scale = Number(animationXMLInItem.@[OLD_DURATION_TWEEN]) / duration;
					tweenEasing = Number(animationXMLInItem.@[OLD_TWEEN_EASING][0]);
				}
				//delete old data
			}
		}
		else if(duration == 2)
		{
			scale = 5;
			loop = 0;
			tweenEasing = 2;
		}
		
		xml = 
			<{ANIMATION} 
				{A_NAME}={name}
				{A_FADE_IN_TIME}={formatNumber(fadeInTime, 1000)}
				{A_DURATION}={duration}
				{A_SCALE}={formatNumber(scale)}
				{A_LOOP}={loop}
				{A_TWEEN_EASING}={formatNumber(tweenEasing)}
			/>;
		armatureXML.appendChild(xml);
	}
	
	return xml;
}

function getTimelineXML(animationXML, name, item)
{
	var xml = animationXML[TIMELINE].(@name == name)[0];
	if(!xml)
	{
		var scale = 1;
		var offset = 0;
		if(item.hasData(ANIMATION_DATA))
		{
			var animationName = animationXML.@[A_NAME];
			
			var animationsXML = XML(item.getData(ANIMATION_DATA));
			var animationXMLInItem;
			if(animationsXML[ANIMATION].length() > 0)
			{
				animationXMLInItem = animationsXML[ANIMATION].(@name == animationName)[0];
				if(animationXMLInItem)
				{
					var timelineXML = animationXMLInItem[TIMELINE].(@name == name)[0];
					if(timelineXML)
					{
						scale = Number(timelineXML.@[A_SCALE]);
						offset = Number(timelineXML.@[A_OFFSET]);
					}
				}
			}
			
			if(!animationXMLInItem && animationsXML[OLD_ANIMATION].length() > 0)
			{
				animationXMLInItem = animationsXML[OLD_ANIMATION].(@name == animationName)[0];
				if(animationXMLInItem)
				{
					var timelineXML = animationXMLInItem[OLD_TIMELINE].(@name == name)[0];
					if(timelineXML)
					{
						scale = Number(timelineXML.@[OLD_SCALE]);
						offset = 1 - Number(timelineXML.@[OLD_OFFSET]);
						offset %= 1;
					}
				}
			}
		}
		
		xml = 
			<{TIMELINE}
				{A_NAME}={name}
				{A_SCALE}={formatNumber(scale)}
				{A_OFFSET}={formatNumber(offset)}
			/>;
		
		animationXML.appendChild(xml);
	}
	return xml;
}

function getBoneXML(armatureXML, name, item, frameXML)
{
	var xml = armatureXML[BONE].(@name == name)[0];
	if(!xml)
	{
		var transformXML = frameXML[TRANSFORM][0];
		xml = 
			<{BONE}
				{A_NAME}={name}
			>
				<{TRANSFORM}
					{A_X}={transformXML.@[A_X]}
					{A_Y}={transformXML.@[A_Y]}
					{A_SKEW_X}={transformXML.@[A_SKEW_X]}
					{A_SKEW_Y}={transformXML.@[A_SKEW_Y]}
					{A_SCALE_X}={transformXML.@[A_SCALE_X]}
					{A_SCALE_Y}={transformXML.@[A_SCALE_Y]}
				/>
			</{BONE}>;
		
		if(item.hasData(ARMATURE_DATA))
		{
			var armatureXMLInItem = XML(item.getData(ARMATURE_DATA));
			var connectionXML;
			if(armatureXMLInItem[BONE].length() > 0)
			{
				connectionXML = armatureXMLInItem[BONE].(@name == name)[0];
			}
			else if(armatureXMLInItem[OLD_BONE].length() > 0)
			{
				connectionXML = armatureXMLInItem[OLD_BONE].(@name == name)[0];
			}
			
			if(connectionXML && connectionXML.@[A_PARENT][0])
			{
				xml.@[A_PARENT] = connectionXML.@[A_PARENT];
			}
		}
		armatureXML.prependChild(xml);
	}
	return xml;
}

function getSlotXML(armatureXML, name, item, frameXML)
{
	var skinXML = armatureXML[SKIN][0];
	var xml = skinXML[SLOT].(@name == name)[0];
	if(!xml)
	{
		xml = 
			<{SLOT}
				{A_NAME}={name}
				{A_PARENT}={name}
				{A_Z_ORDER}={frameXML.@[A_Z_ORDER]}
			/>;
			
		appendXML(skinXML, xml);
	}
	return xml;
}

function getDisplayXML(slotXML, name, item, frameXML, isArmature)
{
	var xml = slotXML[DISPLAY].(@name == name)[0];
	if(!xml)
	{
		var transformXML = frameXML[TRANSFORM][0];
		xml = 
			<{DISPLAY} 
				{A_NAME}={name}
				{A_TYPE}={isArmature?V_ARMATURE:V_IMAGE}
			>
				<{TRANSFORM}
					{A_X}={Number(transformXML.@[A_PIVOT_X])}
					{A_Y}={Number(transformXML.@[A_PIVOT_Y])}
					{A_SKEW_X}={0}
					{A_SKEW_Y}={0}
					{A_SCALE_X}={1}
					{A_SCALE_Y}={1}
				/>
			</{DISPLAY}>;
			
		appendXML(slotXML, xml);
	}
	return xml;
}

function generateAnimation(item, mainFrame, layers, armatureXML, result, noLabelChildArmature)
{
	var start = mainFrame.frame.startFrame;
	var duration = mainFrame.duration;
	var animationName = mainFrame.frame.name;
	var noAutoEasing = false;
	if(isNoEasingFrame(mainFrame.frame))
	{
		noAutoEasing = true;
		animationName = animationName.substr(1);
	}
	
	var animationXML = getAnimationXML(armatureXML, animationName, item, duration, noLabelChildArmature);

	var boneNameDic = {};
	var boneZDic = {};
	var zList = [];
	
	var changeFrames = [];
	var timeline;
	var layersLength = layers.length;
	var layer;
	var boneName;
	var timelineXML;
	var frames;
	var framesLength;
	var frameStart
	var frameDuration;
	var elements;
	var symbol;
	var boneList;
	var zOrder;
	var itemFolderName;
	var noAutoEasingFrame;
	for(var i = 0;i < layersLength;i ++)
	{
		layer = layers[i];
		layer.locked = false;
		boneName = formatName(layer);
		boneZDic[boneName] = boneZDic[boneName] || [];
		timelineXML = null;
		frames = filterKeyFrames(layer.frames.slice(start, start + duration));
		framesLength = frames.length;
		for(var j = 0;j < framesLength;j ++)
		{
			frame = frames[j];
			//
			if(frame.duration > 1 && frame.tweenType == TWEEN_TYPE_SHAPE)
			{
				changeFrames.push({layer:layer, start:frame.startFrame + 1, end:frame.startFrame + frame.duration});
				_currentDom.library.editItem(item.name);
				timeline = _currentDom.getTimeline();
				timeline.setSelectedLayers(timeline.layers.indexOf(layer));
				timeline.convertToKeyframes(frame.startFrame, frame.startFrame + frame.duration);
				//
				frames = filterKeyFrames(layer.frames.slice(start, start + duration));
				framesLength = frames.length;
			}
			
			if(frame.startFrame < start)
			{
				frameStart = 0;
				frameDuration = frame.duration - start + frame.startFrame;
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
			elements = frame.elements;
			symbol = getBoneSymbol(elements);
			itemFolderName = null;
			noAutoEasingFrame = false;
			if(!symbol)
			{
				if(elements.length > 0)
				{
					_currentDom.library.editItem(item.name);
					timeline = _currentDom.getTimeline();
					timeline.currentFrame = frame.startFrame;
					
					_currentDom.selectNone();
					_currentDom.selection = elements.concat();
					
					if(_currentDom.selection && _currentDom.selection.length > 0)
					{
						itemFolderName = TEXTURE_AUTO_CREATE + "/" + item.name;
						_currentDom.library.addNewItem("folder", itemFolderName);
						var newMCName = boneName + "_" + frame.startFrame;
						_currentDom.convertToSymbol(MOVIE_CLIP, newMCName, "top left");
						_currentDom.library.moveToFolder(itemFolderName, newMCName, true);
						
						symbol = _currentDom.selection[0];
					}
				}
				
				if(!symbol)
				{
					continue;
				}
				noAutoEasingFrame = true;
			}
			else
			{
			
			}
			if(!timelineXML)
			{
				timelineXML = getTimelineXML(animationXML, boneName, item);
			}
			for(var k = frameStart ;k < frameStart + frameDuration;k ++)
			{
				var zOrder = zList[k];
				if(isNaN(zOrder))
				{
					zList[k] = zOrder = 0;
				}
				else
				{
					zList[k] = ++ zOrder;
				}
			}
			zOrder = zList[frameStart];
			boneList = boneZDic[boneName];
			for(k = frameStart;k < frameStart + frameDuration;k ++)
			{
				if(!isNaN(boneList[k]))
				{
					boneNameDic[boneName] = true;
					boneName = formatSameName(layer, boneNameDic);
					boneList = boneZDic[boneName] = [];
					timelineXML = getTimelineXML(animationXML, boneName, item);
				}
				boneList[k] = zOrder;
			}
			
			if(frame.tweenType == TWEEN_TYPE_MOTION_OBJECT)
			{
				break;
			}
			//zOrder
			addFrameToTimeline(
				generateFrame(item, frame, boneName, symbol, i, noAutoEasing || noAutoEasingFrame, armatureXML),
				frameStart,
				frameDuration, 
				timelineXML
			);
			
			if(itemFolderName)
			{
				_currentDom.breakApart();
				_currentDom.exitEditMode();
			}
		}
	}
	
	if(changeFrames.length > 0)
	{
		_currentDom.library.editItem(item.name);
		timeline = _currentDom.getTimeline();
		for each(var object in changeFrames)
		{
			timeline.setSelectedLayers(timeline.layers.indexOf(object.layer));
			timeline.clearKeyframes(object.start, object.end);
		}
	}
	
	
	var timelineXMLList = animationXML[TIMELINE];
	var prevFrameXML;
	var frameXMLList;
	var frameXML;
	var prevStart;
	var prevDuration;
	var frameDutation;
	for each(timelineXML in timelineXMLList)
	{
		//boneName = timelineXML.@[A_NAME];
		prevFrameXML = null;
		frameXMLList = timelineXML[FRAME];
		for each(frameXML in frameXMLList)
		{
			frameStart = Number(frameXML.@[A_START]);
			if(frameXML.childIndex() == 0)
			{
				if(frameStart > 0)
				{
					timelineXML.prependChild(<{FRAME} {A_DURATION}={frameStart} {A_DISPLAY_INDEX}="-1"/>);
				}
			}
			else 
			{
				prevStart = Number(prevFrameXML.@[A_START]);
				prevDuration = Number(prevFrameXML.@[A_DURATION]);
				if(frameStart > prevStart + prevDuration)
				{
					frameDutation = frameStart - prevStart - prevDuration;
					timelineXML.insertChildBefore(frameXML, <{FRAME} {A_DURATION}={frameDutation} {A_DISPLAY_INDEX}="-1"/>);
				}
			}
			if(frameXML.childIndex() == timelineXML[FRAME].length() - 1)
			{
				frameStart = Number(frameXML.@[A_START]);
				prevDuration = Number(frameXML.@[A_DURATION]);
				if(frameStart + prevDuration < duration)
				{
					frameDutation = duration - frameStart - prevDuration;
					timelineXML.appendChild(<{FRAME} {A_DURATION}={frameDutation} {A_DISPLAY_INDEX}="-1"/>);
				}
			}
			
			prevFrameXML = frameXML;
		}
	}
	delete animationXML[TIMELINE][FRAME].@[A_START];
	
	generateAnimationEventFrames(animationXML, mainFrame);
}

function generateFrame(item, frame, boneName, symbol, zOrder, noAutoEasing, armatureXML)
{
	_helpTransform = symbol.getTransformationPoint();
	
	if(
		symbol.instanceType == BITMAP && 
		_helpTransform.x == 0 && 
		_helpTransform.y == 0
	)
	{
		_helpTransform.x = symbol.hPixels * 0.5;
		_helpTransform.y = symbol.vPixels * 0.5;
	}

	var frameXML = 
		<{FRAME}
			{A_Z_ORDER}={zOrder}
		>
			<{TRANSFORM}
				{A_X}={formatNumber(symbol.transformX)}
				{A_Y}={formatNumber(symbol.transformY)}
				{A_SKEW_X}={formatNumber(symbol.skewX)}
				{A_SKEW_Y}={formatNumber(symbol.skewY)}
				{A_SCALE_X}={formatNumber(symbol.scaleX)}
				{A_SCALE_Y}={formatNumber(symbol.scaleY)}
				{A_PIVOT_X}={- _helpTransform.x}
				{A_PIVOT_Y}={- _helpTransform.y}
			/>
		</{FRAME}>;
	
	if(symbol.instanceType != BITMAP)
	{
		var aO = symbol.colorAlphaAmount;
		var rO = symbol.colorRedAmount;
		var gO = symbol.colorGreenAmount;
		var bO = symbol.colorBlueAmount;
		var aM = symbol.colorAlphaPercent;
		var rM = symbol.colorRedPercent;
		var gM = symbol.colorGreenPercent;
		var bM = symbol.colorBluePercent;
		if(
			aO != 0 ||
			rO != 0 || 
			gO != 0 || 
			bO != 0 || 
			aM != 100 || 
			rM != 100 || 
			gM != 100 || 
			bM != 100
		)
		{
			var colorTransformXML = 
				<{COLOR_TRANSFORM}
					{A_ALPHA_OFFSET}={aO}
					{A_RED_OFFSET}={rO}
					{A_GREEN_OFFSET}={gO}
					{A_BLUE_OFFSET}={bO}
					{A_ALPHA_MULTIPLIER}={aM}
					{A_RED_MULTIPLIER}={rM}
					{A_GREEN_MULTIPLIER}={gM}
					{A_BLUE_MULTIPLIER}={bM}
				/>;
			frameXML.appendChild(colorTransformXML);
		}
	}
	
	var boneXML = getBoneXML(armatureXML, boneName, item, frameXML);
	var slotXML = getSlotXML(armatureXML, boneName, item, frameXML);
	if(symbol.blendMode)
	{
		slotXML.@[A_BLEND_MODE] = symbol.blendMode;
	}
	
	var imageItem = symbol.libraryItem;
	var imageName = formatName(imageItem);
	var isChildArmature = symbol.symbolType == MOVIE_CLIP;
	var isArmature = Boolean(isArmatureItem(imageItem, isChildArmature));
	var displayXML = getDisplayXML(slotXML, imageName, item, frameXML, isArmature);
	
	var transformXML = frameXML[TRANSFORM][0];
	transformXML.@[A_PIVOT_X] = formatNumber(Number(transformXML.@[A_PIVOT_X]) - Number(displayXML[TRANSFORM][0].@[A_X]));
	transformXML.@[A_PIVOT_Y] = formatNumber(Number(transformXML.@[A_PIVOT_Y]) - Number(displayXML[TRANSFORM][0].@[A_Y]));
	
	if(symbol.visible === false)
	{
		frameXML.@[A_HIDE] = 1;
	}
	var displayIndex = displayXML.childIndex();
	if(displayIndex != 0)
	{
		frameXML.@[A_DISPLAY_INDEX] = displayIndex;
	}
	
	if(isArmature)
	{
		dragonBones.generateArmature(imageName, isChildArmature, false, _isMergeLayersInFolder);
	}
	
	var str = isSpecialFrame(frame, ACTION_PREFIX, true);
	if(str)
	{
		frameXML.@[A_ACTION] = str;
	}
	
	//ease
	if(noAutoEasing?frame.tweenType != TWEEN_TYPE_MOTION:isNoEasingFrame(frame))
	{
		frameXML.@[A_TWEEN_EASING] = NaN;
	}
	else if(frame.tweenType == TWEEN_TYPE_MOTION)
	{
		frameXML.@[A_TWEEN_EASING] = formatNumber(frame.tweenEasing * 0.01);
		var tweenRotate = 0;
		switch(frame.motionTweenRotate)
		{
			case "clockwise":
				tweenRotate = frame.motionTweenRotateTimes + 1;
				break;
			case "counter-clockwise":
				tweenRotate = - frame.motionTweenRotateTimes - 1;
				break;
		}
		if(tweenRotate)
		{
			frameXML.@[A_TWEEN_ROTATE] = tweenRotate;
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

function generateAnimationEventFrames(animationXML, mainFrame)
{
	//
	if(mainFrame.frames.length == 1)
	{
		return;
	}
	var start = mainFrame.frame.startFrame;
	var length = mainFrame.frames.length;
	for(var i = 0;i < length;i ++)
	{
		var frame = mainFrame.frames[i];
		var frameXML = <{FRAME} {A_DURATION}={frame.duration}/>;
		var event = isSpecialFrame(frame, EVENT_PREFIX, true);
		var action = isSpecialFrame(frame, ACTION_PREFIX, true);
		var sound = frame.soundName && (frame.soundLibraryItem.linkageClassName || frame.soundName);
		if(event)
		{
			frameXML.@[A_EVENT] = event;
		}
		if(action)
		{
			frameXML.@[A_ACTION] = action;
		}
		if(sound)
		{
			frameXML.@[A_SOUND] = sound;
		}
		animationXML.appendChild(frameXML);
	}
}

function addFrameToTimeline(frameXML, start, duration, timelineXML)
{
	frameXML.@[A_START] = start;
	frameXML.@[A_DURATION] = duration;
	var frameXMLList = timelineXML[FRAME];
	for each(var eachFrameXML in frameXMLList)
	{
		if(Number(eachFrameXML.@[A_START]) > start)
		{
			timelineXML.insertChildBefore(eachFrameXML, frameXML);
			return;
		}
	}
	timelineXML.appendChild(frameXML);
}

function canMergeLayersInFolder(item)
{
	if(item)
	{
		var timeline = item.timeline;
		var folderMap = {};
		var hasFolder = false;
		for each(var layer in timeline.layers)
		{
			if(layer.layerType == "folder")
			{
				folderMap[layer.name] = 0;
				hasFolder = true;
			}
		}
		if(hasFolder)
		{
			for each(var layer in timeline.layers)
			{
				if(layer.layerType != "folder" && layer.parentLayer)
				{
					var count = folderMap[layer.parentLayer.name] || 0;
					count ++;
					if(count > 1)
					{
						return true;
					}
					folderMap[layer.parentLayer.name] = count;
				}
			}
		}
	}
	return false;
}

function mergeLayersInFolder(item)
{
	var _currentDom = fl.getDocumentDOM();
	var library = _currentDom.library;
	
	library.selectNone();
	library.duplicateItem(item.name);
	
	var itemCopy = library.getSelectedItems()[0];
	
	library.addNewItem("folder", TEXTURE_AUTO_CREATE);
	library.moveToFolder(TEXTURE_AUTO_CREATE, itemCopy.name, true);
	
	library.editItem(itemCopy.name);
	var timeline = itemCopy.timeline;
	
	//搜索所有图层，把补间转换为关键帧，去掉嵌套的文件夹，标记需要删除的图层
	var folderObjArr = [];
	var currFolderLayer = null;
	var junkLayerMark = [];
	var junkLayerCount = 0;
	var layerID = -1;
	for each(var layer in timeline.layers)
	{
		layerID++;
		if(currFolderLayer)
		{
			if(folderObj)
			{
			}
			else
			{
				var folderObj = {folderLayerID:layerID - 1 - junkLayerCount, layerIdArr:[]};
			}
		}
		else
		{
			if(layer.layerType=="folder")
			{
				//找到一个文件夹
				currFolderLayer = layer;
			}
			continue;
		}
		
		if(layer.parentLayer)
		{
			if(layer.parentLayer == currFolderLayer)
			{
				if(layer.layerType == "folder")
				{
					//嵌套的文件夹
					layer.layerType = "normal";
					junkLayerCount ++;
					junkLayerMark[layerID] = true;
					continue;
				}
			}
		}
		else
		{
			folderObjArr.push(folderObj);
			folderObj = null;
			currFolderLayer = null;
			if(layer.layerType == "folder")
			{
				//找到一个文件夹
				currFolderLayer = layer;
			}
			continue;
		}
		
		switch(layer.layerType)
		{
			case "guide":
			case "mask":
				junkLayerCount ++;
				junkLayerMark[layerID] = true;
				continue;
			break;
		}
		
		folderObj.layerIdArr.push(layerID - junkLayerCount);
		timeline.currentLayer = layerID;
		if(layer.animationType == "none")
		{
			//无补间，或传统补间，或形状补间
			var frameID = layer.frames.length;
			while(frameID --)
			{
				var startFrameId = layer.frames[frameID].startFrame;
				var frame = layer.frames[frameID];
				
				var hasPlayOnceOrLoopGraphic = false;
				for each(var element in frame.elements)
				{
					if(
						element.libraryItem
						&&
						element.libraryItem.timeline
						&&
						element.libraryItem.timeline.frameCount>1
						&&
						element.symbolType=="graphic"
						&&
						(
							element.loop=="play once"
							||
							element.loop=="loop"
						)
					)
					{
						hasPlayOnceOrLoopGraphic=true;
						break;
					}
				}
				if(hasPlayOnceOrLoopGraphic)
				{
					timeline.convertToKeyframes(startFrameId + 1,frameID + 1);
				}
				else
				{
					switch(frame.tweenType)
					{
						case TWEEN_TYPE_MOTION:
						case TWEEN_TYPE_SHAPE:
							if(startFrameId != frameID)
							{
								timeline.convertToKeyframes(startFrameId + 1,frameID + 1);
							}
						break;
						case TWEEN_TYPE_NONE:
							//
						break;
					}
				}
				frameID = startFrameId;
			}
		}
		else
		{
			//TWEEN_TYPE_MOTION_OBJECT或IK pose全部转成关键帧
			
			//timeline.convertToKeyframes(0, layer.frames.length);//失败
			var frameID = layer.frames.length;
			while(frameID --)
			{
				timeline.convertToKeyframes(frameID);
			}
		}
	}
	if(folderObj)
	{
		folderObjArr.push(folderObj);
		folderObj = null;
	}
	
	var layerID = junkLayerMark.length;
	while(-- layerID >= 0)
	{
		if(junkLayerMark[layerID])
		{
			timeline.deleteLayer(layerID);
		}
	}
	junkLayerMark = null;
	
	var folderObjID = folderObjArr.length;
	while(folderObjID --)
	{
		
		for each(var layer in timeline.layers)
		{
			layer.locked = true;
			layer.visible = true;
		}
		
		
		var folderObj = folderObjArr[folderObjID];
		//trace(folderObj.folderLayerID + "," + folderObj.layerIdArr);
		
		//获取最大帧数
		var maxFrameCount = -1;
		for each(var layerID in folderObj.layerIdArr)
		{
			var layer = timeline.layers[layerID];
			layer.locked = false;
			if(maxFrameCount < layer.frames.length)
			{
				maxFrameCount = layer.frames.length;
			}
		}
		
		//根据最大帧数补齐不足最大帧数的图层
		for each(var layerID in folderObj.layerIdArr)
		{
			var layer = timeline.layers[layerID];
			if(layer.frames.length < maxFrameCount)
			{
				timeline.currentLayer = layerID;
				timeline.convertToBlankKeyframes(layer.frames.length);
				timeline.currentLayer = layerID;//没这句有时候不行很奇怪
				timeline.insertFrames(maxFrameCount - layer.frames.length, false, layer.frames.length);
			}
		}
		
		//标记公共关键帧
		var keyFrameIdMark = new Array();
		for each(var layerID in folderObj.layerIdArr)
		{
			var layer = timeline.layers[layerID];
			var frameID = maxFrameCount;
			while(frameID --)
			{
				frameID = layer.frames[frameID].startFrame;
				keyFrameIdMark[frameID] = true;
			}
		}
		
		//同步关键帧
		for each(var layerID in folderObj.layerIdArr)
		{
			var layer = timeline.layers[layerID];
			timeline.currentLayer = layerID;
			var frameID = keyFrameIdMark.length;
			while(frameID--)
			{
				if(keyFrameIdMark[frameID])
				{
					var frame = layer.frames[frameID];
					if(frame.startFrame == frameID)
					{
					}
					else
					{
						timeline.convertToKeyframes(frameID);
					}
				}
			}
		}
		
		var folderLayer = timeline.layers[folderObj.folderLayerID];
		folderLayer.locked = false;
		folderLayer.layerType = "normal";
		timeline.currentLayer = folderObj.folderLayerID;
		if(folderLayer.length < maxFrameCount)
		{
			timeline.insertFrames(maxFrameCount - folderLayer.length, false, folderLayer.length);
		}
		
		var frameID = keyFrameIdMark.length;
		while(frameID --)
		{
			if(keyFrameIdMark[frameID])
			{
				timeline.currentLayer = folderObj.folderLayerID;
				timeline.convertToKeyframes(frameID);
				timeline.currentFrame = frameID;
				_currentDom.selectAll();
				if(_currentDom.selection.length)
				{
					_currentDom.group();
					var itemName = item.name + "_" + folderLayer.name + "_" + (frameID + 1);
					if(library.itemExists(itemName))
					{
						var itemID = 1;
						while(library.itemExists(itemName + "(" + (++ itemID) + ")"))
						{
						}
						itemName += "(" + itemID + ")";
					}
					_currentDom.convertToSymbol(MOVIE_CLIP, itemName, "top left");
					
					var element = _currentDom.selection[0];
					itemName = element.libraryItem.name;
					timeline.currentLayer = folderObj.folderLayerID;
					var frame = timeline.layers[folderObj.folderLayerID].frames[frameID];
					frame.labelType = LABEL_TYPE_NAME;
					frame.name = NO_EASING;
					library.addItemToDocument({x:0,y:0}, itemName);
					_currentDom.selection[0].matrix = element.matrix;
					
					_currentDom.library.moveToFolder(TEXTURE_AUTO_CREATE, itemName, true);
				}
			}
		}
		
		var i = folderObj.layerIdArr.length;
		while(i --)
		{
			var layerID = folderObj.layerIdArr[i];
			timeline.deleteLayer(layerID);
		}
	}
	return itemCopy;
}

function putItemToTimeline(dom, textureName)
{
	_helpTransform.x = _helpTransform.y = 0;
	var timeline = dom.getTimeline();
	timeline.currentFrame = 0;
	var tryTimes = 0;
	var putSuccess = false;
	var symbol;
	dom.selectNone();
	do
	{
		putSuccess = dom.library.addItemToDocument(_helpTransform, textureName);
		symbol = dom.selection[0]
		tryTimes ++;
	}
	while((!putSuccess || !symbol) && tryTimes < 5);
	if(symbol)
	{
		return symbol;
	}
	
	trace("内存不足导致放置贴图失败！请尝试重新导入。");
	return false;
}

dragonBones.getArmatureList = function(isSelected, armatureNames, defaultFadeInTime)
{
	fl.outputPanel.clear();
	
	//if frame count > 1, the skeleton have animation.
	/*if(mainLayer.frameCount > 1)
	{
		
	}*/
	_currentDom = fl.getDocumentDOM();
	if(errorDOM())
	{
		return false;
	}
	_currentDomName = _currentDom.name.split(".")[0];
	
	var timeline = _currentDom.getTimeline();
	_currentItemBackup = timeline.libraryItem;
	if(_currentItemBackup)
	{
		_currentFrameBackup = timeline.currentFrame;
	}
	_librarySelectItemsBackup = _currentDom.library.getSelectedItems().concat();
	_currentDom.exitEditMode();
	
	if(armatureNames)
	{
		armatureNames = armatureNames.split(",");
	}
	
	var items;
	var item;
	if(armatureNames && armatureNames.length > 0)
	{
		items = [];
		for each(var armatureName in armatureNames)
		{
			item = _currentDom.library.items[_currentDom.library.findItemIndex(armatureName)];
			if(item)
			{
				items.push(item);
			}
		}
	}
	else
	{
		items = isSelected?_librarySelectItemsBackup:_currentDom.library.items;
	}
	
	_defaultFadeInTime = defaultFadeInTime;
	
	var xml = 
		<{DRAGON_BONES}
			{A_NAME}={_currentDomName}
		/>;
	for each(item in items)
	{
		if(isArmatureItem(item))
		{
			formatName(item);
			xml.appendChild(
				<{ARMATURE} 
					{A_NAME}={item.name} 
					{A_SCALE} ={1}
				/>
			);
		}
	}
	return xml.toXMLString();
}

dragonBones.generateArmature = function(armatureName, isChildArmature, newGenerate, isMergeLayersInFolder)
{
	var item = _currentDom.library.items[_currentDom.library.findItemIndex(armatureName)];
	if(!item)
	{
		return false;
	}
	if(!_xml || newGenerate)
	{
		_xml = 
			<{DRAGON_BONES}
				{A_NAME}={_currentDomName} 
				{A_FRAME_RATE}={_currentDom.frameRate}
			/>;
	}
	else if(_xml[ARMATURE].(@name == armatureName)[0])
	{
		return false;
	}
	_isMergeLayersInFolder = isMergeLayersInFolder;
	var armatureXML = 
		<{ARMATURE} {A_NAME}={armatureName}>
			<{SKIN} {A_NAME}=""/>
		</{ARMATURE}>;
	appendXML(_xml, armatureXML);
	
	//
	if(_isMergeLayersInFolder && canMergeLayersInFolder(item))
	{
		item = mergeLayersInFolder(item);
	}
	
	
	var result = {};
	var layersFiltered = isArmatureItem(item, isChildArmature);
	if(!layersFiltered)
	{
		return false;
	}
	var mainLayer = layersFiltered.shift();
	var mainFrameList = getMainFrameList(mainLayer.frames);
	var noLabelChildArmature = mainLayer.noLabelChildArmature
	for each(var mainFrame in mainFrameList)
	{
		generateAnimation(item, mainFrame, layersFiltered, armatureXML, result, noLabelChildArmature);
	}
	
	return _xml.toXMLString();
}

dragonBones.clearTextureSWFItem = function()
{
	if(!_currentDom.library.itemExists(TEXTURE_SWF_ITEM))
	{
		_currentDom.library.addNewItem(MOVIE_CLIP, TEXTURE_SWF_ITEM);
	}
	_currentDom.library.editItem(TEXTURE_SWF_ITEM);
	
	_xml = null;
	
	var timeline = _currentDom.getTimeline();
	timeline.currentLayer = 0;
	timeline.removeFrames(0, timeline.frameCount);
	timeline.insertBlankKeyframe(0);
	timeline.insertBlankKeyframe(1);
	
	return true;
}

dragonBones.addTextureToSWFItem = function(textureName)
{
	var item = _currentDom.library.items[_currentDom.library.findItemIndex(textureName)];
	if(!item)
	{
		return false;
	}
	
	var symbol = putItemToTimeline(_currentDom, textureName);
	if(symbol)
	{
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
		
		_currentDom.getTimeline().currentFrame = 1;
		
		return textureName;
	}
	
	return false;
}

dragonBones.exportSWF = function()
{
	if(errorDOM())
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
	
	if(!_currentDom.library.itemExists(TEXTURE_SWF_ITEM))
	{
		return "";
	}
	
	//
	_currentDom.getTimeline().removeFrames(1, 1);
	if(_currentItemBackup)
	{
		_currentDom.library.editItem(_currentItemBackup.name);
		_currentDom.getTimeline().currentFrame = _currentFrameBackup;
		//select backup library items
	}
	
	folderURL = folderURL + "WindowSWF" + pathDelimiter + PANEL_FOLDER;
	if(!FLfile.exists(folderURL))
	{
		FLfile.createFolder(folderURL);
	}
	var swfURL = folderURL + pathDelimiter + TEXTURE_SWF;
	
	_currentDom.library.items[_currentDom.library.findItemIndex(TEXTURE_SWF_ITEM)].exportSWF(swfURL);
	
	_currentDom.library.deleteItem(TEXTURE_AUTO_CREATE);
	
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
	
	item.addData(ARMATURE_DATA, STRING, data);
	//Jsfl api Or Flash pro bug
	item.symbolType = GRAPHIC;
	item.symbolType = MOVIE_CLIP;
	
	return true;
}

dragonBones.changeAnimation = function(armatureName, animationName, data)
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
	delete data[TIMELINE].*;
	delete data[FRAME];
	
	var animationsXML;
	if(item.hasData(ANIMATION_DATA))
	{
		animationsXML = XML(item.getData(ANIMATION_DATA));
	}
	else
	{
		animationsXML = <{ANIMATION_DATA}/>;
	}
	var animationXML = animationsXML[ANIMATION].(@name == animationName)[0];
	if(animationXML)
	{
		var childIndex = animationXML.childIndex();
		delete animationsXML.elements()[childIndex];
	}
	animationsXML.appendChild(data);
	
	item.addData(ANIMATION_DATA, STRING, animationsXML.toXMLString());
	//Jsfl api Or Flash pro bug
	item.symbolType = GRAPHIC;
	item.symbolType = MOVIE_CLIP;
	return true;
}

dragonBones.copyAnimation = function(targetArmatureName, sourceArmatureName, sourceAnimationName, sourceAnimationXML)
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
		if(mainFrame.frame.name == sourceAnimationName)
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
		if(mainFrame.frame.name == sourceAnimationName)
		{
			break;
		}
	}
	
	sourceAnimationXML = XML(sourceAnimationXML).toXMLString();
	sourceAnimationXML = replaceString(sourceAnimationXML, "&lt;", "<");
	sourceAnimationXML = replaceString(sourceAnimationXML, "&gt;", ">");
	sourceAnimationXML = XML(sourceAnimationXML);
	
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
			var timelineXML = sourceAnimationXML[TIMELINE].(@name == boneName)[0];
			if(!timelineXML)
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
			var frameXMLList = timelineXML[FRAME];
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
				//
				_helpTransform.pivotX = - Number(frameXML.@[A_PIVOT_X]);
				_helpTransform.pivotY = - Number(frameXML.@[A_PIVOT_Y]);
				
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