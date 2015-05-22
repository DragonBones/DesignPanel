var dragonBones;
(function (dragonBones)
{


    var Utils = utils.Utils;


    var DragonBones = (function (_super) 
    {
        __extends(DragonBones, _super);
        function DragonBones() 
        {
            _super.call(this);

            this._currentItemBackup = null;
            this._currentFrameBackup = null;
            this._librarySelectItemsBackup = null;
            this._isMergeLayersInFolder = false;
            this._defaultFadeInTime = 0;

            this._xml = null;
            this._armatureList = null;
            this._currentArmatureItem = null;
            this._currentArmatureXML = null;
            this._displayRegistPositionMap = null;
            this._textHasAnimationMap = null;
            this._fontItemMap = null;
        }

        DragonBones.DRAGON_BONES = "dragonBones";
        DragonBones.ARMATURE = "armature";
        DragonBones.BONE = "bone";
        DragonBones.SKIN = "skin";
        DragonBones.SLOT = "slot";
        DragonBones.DISPLAY = "display";
        DragonBones.ANIMATION = "animation";
        DragonBones.TIMELINE = "timeline";
        DragonBones.FRAME = "frame";
        DragonBones.TRANSFORM = "transform";
        DragonBones.COLOR_TRANSFORM = "colorTransform";
        DragonBones.RECTANGLE = "rectangle";
        DragonBones.ELLIPSE = "ellipse";
        DragonBones.TEXT = "text";
        DragonBones.COLOR = "color";
        DragonBones.SCALING_GRID = "scalingGrid";

        DragonBones.A_NAME = "name";
        DragonBones.A_PARENT = "parent";
        DragonBones.A_TYPE = "type";
        DragonBones.A_CUSTOM = "custom";

        DragonBones.A_FRAME_RATE = "frameRate";
        DragonBones.A_DURATION = "duration";
        DragonBones.A_FADE_IN_TIME = "fadeInTime";
        DragonBones.A_LOOP = "loop";
        DragonBones.A_SCALE = "scale";
        DragonBones.A_OFFSET = "offset";

        DragonBones.A_X = "x";
        DragonBones.A_Y = "y";
        DragonBones.A_SKEW_X = "skX";
        DragonBones.A_SKEW_Y = "skY";
        DragonBones.A_SCALE_X = "scX";
        DragonBones.A_SCALE_Y = "scY";
        DragonBones.A_PIVOT_X = "pX";
        DragonBones.A_PIVOT_Y = "pY";
        DragonBones.A_Z_ORDER = "z";
        DragonBones.A_BLEND_MODE = "blendMode";

        DragonBones.A_DISPLAY_INDEX = "displayIndex";
        DragonBones.A_EVENT = "event";
        DragonBones.A_EVENT_PARAMETERS = "eventParameters";
        DragonBones.A_SOUND = "sound";
        DragonBones.A_AUTO_TWEEN ="autoTween";
        DragonBones.A_TWEEN_EASING ="tweenEasing";
        DragonBones.A_TWEEN_ROTATE ="tweenRotate";
        DragonBones.A_TWEEN_SCALE = "tweenScale";
        DragonBones.A_ACTION = "action";
        DragonBones.A_HIDE = "hide";

        DragonBones.A_WIDTH = "width";
        DragonBones.A_HEIGHT = "height";

        DragonBones.A_SCALE_X_OFFSET = "scXOffset";
        DragonBones.A_SCALE_Y_OFFSET = "scYOffset";

        DragonBones.A_ALPHA_OFFSET = "aO";
        DragonBones.A_RED_OFFSET = "rO";
        DragonBones.A_GREEN_OFFSET = "gO";
        DragonBones.A_BLUE_OFFSET = "bO";
        DragonBones.A_ALPHA_MULTIPLIER = "aM";
        DragonBones.A_RED_MULTIPLIER = "rM";
        DragonBones.A_GREEN_MULTIPLIER = "gM";
        DragonBones.A_BLUE_MULTIPLIER = "bM";

        DragonBones.A_ALPHA = "a";
        DragonBones.A_RED = "r";
        DragonBones.A_GREEN = "g";
        DragonBones.A_BLUE = "b";

        DragonBones.A_LEFT = "left";
        DragonBones.A_RIGHT = "right";
        DragonBones.A_TOP = "top";
        DragonBones.A_BOTTOM = "bottom";

        DragonBones.A_BOLD = "bold";
        DragonBones.A_ITALIC = "italic";
        DragonBones.A_SIZE = "size";
        DragonBones.A_FACE = "face";
        DragonBones.A_ALIGN_H = "alignH";
        DragonBones.A_ALIGN_V = "alignV";
        DragonBones.A_LINE_TYPE = "lineType";
        DragonBones.A_TEXT_TYPE = "textType";
        DragonBones.A_TEXT = "text";
        DragonBones.A_HTML_TEXT = "htmlText";
        DragonBones.A_LETTER_SPACING = "letterSpacing";
        DragonBones.A_LINE_SPACING = "lineSpacing";
        DragonBones.A_MAX_CHARACTERS = "maxCharacters";

        DragonBones.A_Z = "z";
        DragonBones.A_ROTATION_X = "rotationX";
        DragonBones.A_ROTATION_Y = "rotationY";
        DragonBones.A_ROTATION_Z = "rotationZ";
        DragonBones.A_OFFSET_ROTATION_X = "offsetRotationX";
        DragonBones.A_OFFSET_ROTATION_Y = "offsetRotationY";
        DragonBones.A_OFFSET_ROTATION_Z = "offsetRotationZ";
        DragonBones.A_MATRIX3D = "matrix3D";

        DragonBones.A_ID = "id";
        DragonBones.A_URL = "url";

        DragonBones.A_START = "start";

        DragonBones.V_IMAGE = "image";
        DragonBones.V_ARMATURE = "armature";
        DragonBones.V_TEXT = "text";

        DragonBones.DELIM_CHAR = "|";
        DragonBones.EVENT_PREFIX = "@";
        DragonBones.SET_PREFIX = "$";
        DragonBones.ACTION_PREFIX = "#";
        DragonBones.NO_EASING = "^";

        DragonBones.CONFIG_FOLDER = "DragonBonesDesignPanel";

        DragonBones.ARMATURE_DATA = "armatureData";
        DragonBones.ANIMATION_DATA = "animationData";
        DragonBones.FRAME_DATA = "frameData";
        DragonBones.SCALE_OFFSET_DATA = "scaleOffsetData";

        DragonBones.DRAGON_BONES_XML = "dragonBones.xml";
        DragonBones.TEXTURE_SWF = "textureAtlas.swf";
        DragonBones.TEXTURE_SWF_ITEM = "__dbTextureAtlas";
        DragonBones.TEXTURE_AUTO_CREATE = "__dbTextures";

        DragonBones.ERROR_NO_ACTIVE_DOM = "noActiveDom";
        DragonBones.ERROR_NO_ARMATURE_IN_DOM = "noArmatureInDom";

        DragonBones.NOT_EXPORT = "_notExport";

        DragonBones.OLD_BONE = "b";
        DragonBones.OLD_ANIMATION = "mov";
        DragonBones.OLD_TIMELINE = "b";
        DragonBones.OLD_DURATION_TO = "to";
        DragonBones.OLD_LOOP = "lp";
        DragonBones.OLD_DURATION_TWEEN = "drTW";
        DragonBones.OLD_TWEEN_EASING = "twE";
        DragonBones.OLD_SCALE = "sc";
        DragonBones.OLD_OFFSET = "dl";


        DragonBones.getConfigPath = function ()
        {
            var path = fl.configURI + "WindowSWF" + "/" + DragonBones.CONFIG_FOLDER;
            if (!FLfile.exists(path))
            {
                FLfile.createFolder(path);
            }
            return path;
        };

        DragonBones.formatTransform = function (transform)
        {
            assert(transform);

            var dSkew = Utils.formatAngle(transform.skewY - transform.skewX);

            if (dSkew > 90 || dSkew < -90)
            {
                transform.scaleX *= -1;
                transform.skewY = Utils.formatAngle(transform.skewY - 180);
            }
        };
        // 

        /**
         * @param   {String}    name
         * @param   {String}    prefix
         * @return  {Array}     result:[formatName, prefix, name, params]
         */
        DragonBones.getNameParameters = function (name, prefix)
        {
            assert(name);

            var reg = /^([\~\`\!\@\#\$\%\^\&\*]*)\s*([^\~\`\!\@\#\$\%\^\&\*]*?)\s*(?:\(\s*([^()]*?)\s*\))?$/;

            var result = null;
            if (name.indexOf("/") >= 0)
            {
                var tempArr = name.split("/");
                name = tempArr.pop();
                result = name.match(reg);
                if (prefix)
                {
                    result[0] = tempArr.join("/") + "/" + prefix + result[0];
                    result[1] = prefix;
                    result[2] = tempArr.join("/") + "/" + result[2];
                }
                else
                {
                    result[0] = tempArr.join("/") + "/" + result[0];
                    result[2] = tempArr.join("/") + "/" + result[2];
                }
            }
            else
            {
                result = name.match(reg);
                if (prefix)
                {
                    result[0] = prefix + result[0];
                    result[1] = prefix;
                }
            }

            return result;
        };

        DragonBones.formatObjectName = function (object, isItem)
        {
            assert(object && object.name);

            var oldName = object.name;
            var nameList = DragonBones.getNameParameters(oldName);
            var newName = nameList[0];
            if (oldName != newName)
            {
                if (isItem)
                {
                    object.name = newName.split("/").pop();
                }
                else
                {
                    object.name = newName;
                }
                
            }

            return nameList;
        };

        DragonBones.formatSameName = function (object, nameList)
        {
            assert(object && nameList);

            var name = object.name || "unnamed";
            var i = 0;
            while (nameList.indexOf(name) >= 0)
            {
                name = object.name + "_" + i;
                i ++;
            }
            if (i > 0)
            {
                object.name = name;
            }
            nameList.push(name);
            return name;
        };

        DragonBones.isMainFrame = function (frame)
        {
            assert(frame);
            
            if (frame.labelType == "name" && frame.name)
            {
                var result = DragonBones.getNameParameters(frame.name);
                if (!result[2] || (result[1] && result[1] != DragonBones.NO_EASING))
                {
                    return false;
                }

                return true;
            }

            return false;
        };

        DragonBones.isMainLayer = function (layer)
        {
            assert(layer);

            var keyFrames = Utils.toUniqueArray(layer.frames);
            for each (var frame in keyFrames)
            {
                if (DragonBones.isMainFrame(frame))
                {
                    return true;
                }
            }

            return false;
        };

        DragonBones.isBoneLayer = function (layer, currentFrame)
        {
            assert(layer);

            if (!layer.name)
            {
                return false;
            }

            switch (layer.layerType)
            {
                case "normal":
                case "guided":
                case "masked":
                    break;

                default:
                    return false;
            }

            var keyFrames = Utils.toUniqueArray(layer.frames);
            for each (var frame in keyFrames)
            {
                if (currentFrame != null? (frame.startFrame <= currentFrame && frame.startFrame + frame.duration > currentFrame): true)
                {
                    if (frame.elements.length > 0)
                    {
                        return true;
                    }
                }
            }

            return false;
        };

        //To determine whether the item is valide armature.
        //If yes, return mainLayer and boneLayers
        DragonBones.isArmatureItem = function (item, isChildArmature)
        {
            if (
                !item ||
                (
                    item.itemType != "movie clip" && 
                    item.itemType != "graphic"
                )
            )
            {
                return null;
            }

            var layersFiltered = [];
            var layers = item.timeline.layers;
            var mainLayer = null;
            for each (var layer in layers)
            {
                if (!mainLayer && DragonBones.isMainLayer(layer))
                {
                    mainLayer = layer;
                }
                else if (DragonBones.isBoneLayer(layer))
                {
                    layersFiltered.unshift(layer);
                }
            }
            
            if (layersFiltered.length > 0)
            {
                if (mainLayer)
                {
                    // 
                    layersFiltered.unshift(mainLayer);
                    return layersFiltered;
                }
                else if (isChildArmature && item.timeline.frameCount > 1)
                {
                    // 伪造一个 mainLayer 和 mainFrame
                    mainLayer = {};
                    mainLayer.frameCount = item.timeline.frameCount;
                    mainLayer.frames = [];
                    mainLayer.noLabelChildArmature = true;
                    layersFiltered.unshift(mainLayer);

                    var frame = {};
                    frame.labelType = "name";
                    frame.name = "unnamed";
                    frame.startFrame = 0;
                    frame.duration = mainLayer.frameCount;
                    
                    mainLayer.frames.push(frame);
                    return layersFiltered;
                }
            }
            return null;
        };

        DragonBones.isTextLayerHasColorAnimation = function (textLayer)
        {
            if (!textLayer)
            {
                return false;
            }

            var frames = Utils.toUniqueArray(textLayer.frames);
            var color = null;
            for each (var frame in frames)
            {
                var text = frame? frame.elements[0]: null;
                if (text && text.elementType == "text")
                {
                    if (color)
                    {
                        if (color != text.getTextAttr("fillColor"))
                        {
                            return true;
                        }
                    }
                    else
                    {
                        color = text.getTextAttr("fillColor");
                    }
                }
            }

            return false;
        };

        DragonBones.getMainFrameList = function (frames)
        {
            var keyFrames = Utils.toUniqueArray(frames);
            var nameList = [];
            var mainFrameList = [];
            var mainFrame = null;
            for (var i = 0, l = keyFrames.length; i < l; i ++)
            {
                var frame = keyFrames[i];
                if (DragonBones.isMainFrame(frame))
                {
                    // new main frame
                    mainFrame = {};
                    mainFrame.frame = frame;
                    mainFrame.duration = frame.duration;
                    mainFrame.frames = [frame];
                    DragonBones.formatSameName(frame, nameList);
                }
                else if (mainFrame)
                {
                    // continue
                    mainFrame.duration += frame.duration;
                    mainFrame.frames.push(frame);
                }
                else
                {
                    // ignore
                    continue;
                }

                if (
                    mainFrame && 
                    (
                        i + 1 == l || 
                        DragonBones.isMainFrame(keyFrames[i + 1])
                    )
                )
                {
                    // end
                    mainFrameList.push(mainFrame);
                }
            }
            return mainFrameList;
        };

        //Write armatureConnection data by armatureName
        DragonBones.changeArmatureConnection = function (domID, armatureName, armatureXML)
        {
            var currentDOM = Utils.getDOM(domID, true);
            if (!currentDOM)
            {
                return false;
            }
            
            var armatureItem = Utils.filter(currentDOM.library.items, null, ["name", armatureName])[0];
            if (!armatureItem)
            {
                return false;
            }
            armatureItem.addData(DragonBones.ARMATURE_DATA, "string", armatureXML.toXMLString());

            //Jsfl api Or Flash pro bug
            armatureItem.symbolType = "graphic";
            armatureItem.symbolType = "movie clip";
            return true;
        };

        DragonBones.changeAnimation = function (domID, armatureName, animationName, animationXML)
        {
            var currentDOM = Utils.getDOM(domID, true);
            if (!currentDOM)
            {
                return false;
            }
            
            var armatureItem = Utils.filter(currentDOM.library.items, null, ["name", armatureName])[0];
            if (!armatureItem || !animationName ||!animationXML)
            {
                return false;
            }
            
            var animationsXMLInItem = null;
            if (armatureItem.hasData(DragonBones.ANIMATION_DATA))
            {
                animationsXMLInItem = XML(armatureItem.getData(DragonBones.ANIMATION_DATA));
            }
            else
            {
                animationsXMLInItem = <{DragonBones.ANIMATION_DATA}/>;
            }
            
            var animationXMLInItem = animationsXMLInItem[DragonBones.ANIMATION].(@name == animationName)[0];
            if (animationXMLInItem)
            {
                var childIndex = animationXMLInItem.childIndex();
                delete animationsXMLInItem.elements()[childIndex];
            }

            animationsXMLInItem.appendChild(animationXML);
            
            armatureItem.addData(DragonBones.ANIMATION_DATA, "string", animationsXMLInItem.toXMLString());

            //Jsfl api Or Flash pro bug
            armatureItem.symbolType = "graphic";
            armatureItem.symbolType = "movie clip";
            return true;
        };

        DragonBones.selectBoneAndChildren = function ()
        {
            var currentDOM = fl.getDocumentDOM();
            if (!currentDOM)
            {
                return DragonBones.ERROR_NO_ACTIVE_DOM;
            }

            if (currentDOM.selection.length < 1)
            {
                return false;
            }

            var timeline = currentDOM.getTimeline();

            var armatureItem = timeline.libraryItem;
            armatureItem.hasData(DragonBones.ARMATURE_DATA)
            var armatureXML = XML(armatureItem.getData(DragonBones.ARMATURE_DATA));

            for each (var boneSymbol in currentDOM.selection)
            {
                selectBoneAndChildren(boneSymbol, timeline, armatureXML);
            }

            if (currentDOM.selection.length > 1)
            {
                fl.selectTool("arrow");
                fl.selectTool("freeXform");
                currentDOM.setTransformationPoint({x:boneSymbol.transformX, y:boneSymbol.transformY});
            }
            return true;
        }
            
        DragonBones._frameChangedHandler = function ()
        {
            DragonBones.selectBoneAndChildren();
        }


        function selectBoneAndChildren(boneSymbol, timeline, armatureXML)
        {
            if (!armatureXML)
            {
                return;
            }

            var layerNameList = DragonBones.getNameParameters(boneSymbol.layer.name);
            var boneName = layerNameList[2];
            var layerMap = {};
            for each (var eachLayer in timeline.layers)
            {
                if (DragonBones.isBoneLayer(eachLayer, timeline.currentFrame))
                {
                    var eachLayerNameList = DragonBones.getNameParameters(eachLayer.name);
                    layerMap[eachLayerNameList[2]] = eachLayer;
                }
            }

            boneSymbol.selected = true;

            for each (var boneXML in armatureXML[DragonBones.BONE])
            {
                if (boneXML.@[DragonBones.A_PARENT] == boneName)
                {
                    var childName = boneXML.@[DragonBones.A_NAME];
                    var childLayer = layerMap[childName];
                    if (childLayer && !childLayer.locked && childLayer.visible)
                    {
                        var childFrame = childLayer.frames[timeline.currentFrame];
                        if (childFrame && childFrame.startFrame == timeline.currentFrame)
                        {
                            var boneChildSymbol = Utils.filter(childFrame.elements, null, ["instanceType", "symbol", "bitmap"])[0];
                            if (boneChildSymbol)
                            {
                                selectBoneAndChildren(boneChildSymbol, timeline, armatureXML);
                            }
                        }
                    }
                }
            }
        }

        function addFrameToTimeline(frameXML, start, duration, timelineXML)
        {
            frameXML.@[DragonBones.A_START] = start;
            frameXML.@[DragonBones.A_DURATION] = duration;
            var frameXMLList = timelineXML[DragonBones.FRAME];
            for each (var eachFrameXML in frameXMLList)
            {
                if (Number(eachFrameXML.@[DragonBones.A_START]) > start)
                {
                    timelineXML.insertChildBefore(eachFrameXML, frameXML);
                    return;
                }
            }
            timelineXML.appendChild(frameXML);
        }

        DragonBones.prototype._getAnimationXML = function (armatureXML, animationName, armatureItem, duration, fadeInTime, noAutoTween)
        {
            var animationXML = armatureXML[DragonBones.ANIMATION].(@name == animationName)[0];
            if (!animationXML)
            {
                var playTimes = 1;
                var scale = 1;
                var tweenEasing = NaN;
                //var autoTween = this._defaultAutoTween;
                var autoTween = 1;
                
                var animationXMLInItem = null;
                if (armatureItem.hasData(DragonBones.ANIMATION_DATA))
                {
                    var animationsXMLInItem = XML(armatureItem.getData(DragonBones.ANIMATION_DATA));
                    if (animationsXMLInItem[DragonBones.ANIMATION].length() > 0)
                    {
                        animationXMLInItem = animationsXMLInItem[DragonBones.ANIMATION].(@name == animationName)[0];
                    }
                    
                    if (animationXMLInItem)
                    {
                        fadeInTime = Utils.getNumberFromObject(animationXMLInItem, DragonBones.A_FADE_IN_TIME, fadeInTime);
                        playTimes = Utils.getNumberFromObject(animationXMLInItem, DragonBones.A_LOOP, playTimes);
                        scale = Utils.getNumberFromObject(animationXMLInItem, DragonBones.A_SCALE, scale);
                        tweenEasing = Utils.getNumberFromObject(animationXMLInItem, DragonBones.A_TWEEN_EASING, tweenEasing);
                        autoTween = Utils.getNumberFromObject(animationXMLInItem, DragonBones.A_AUTO_TWEEN, 1);
                    }
                    else if (animationsXMLInItem[DragonBones.OLD_ANIMATION].length() > 0)
                    {
                        animationXMLInItem = animationsXMLInItem[DragonBones.OLD_ANIMATION].(@name == animationName)[0];
                        if (animationXMLInItem)
                        {
                            fadeInTime = Number(animationXMLInItem.@[DragonBones.OLD_DURATION_TO]) / fl.getDocumentDOM().frameRate;
                            playTimes = Number(animationXMLInItem.@[DragonBones.OLD_LOOP]);
                            if (playTimes == 1)
                            {
                                playTimes = 0;
                            }
                            else
                            {
                                playTimes = 1;
                            }
                            scale = Number(animationXMLInItem.@[DragonBones.OLD_DURATION_TWEEN]) / duration;
                            tweenEasing = Number(animationXMLInItem.@[DragonBones.OLD_TWEEN_EASING][0]);
                        }
                    }
                }
                
                if (!animationXMLInItem)
                {
                    if (duration == 2)
                    {
                        playTimes = 0;
                        scale = 5;
                        tweenEasing = 2;
                    }
                }
                
                if (noAutoTween)
                {
                    autoTween = 0;
                }
                
                animationXML = 
                    <{DragonBones.ANIMATION} 
                        {DragonBones.A_NAME}={animationName}
                        {DragonBones.A_FADE_IN_TIME}={fadeInTime || 0}
                        {DragonBones.A_DURATION}={duration}
                        {DragonBones.A_SCALE}={Utils.formatNumber(scale) || 1}
                        {DragonBones.A_LOOP}={playTimes}
                        {DragonBones.A_AUTO_TWEEN}={autoTween}
                        {DragonBones.A_TWEEN_EASING}={Utils.formatNumber(tweenEasing)}/>;

                Utils.appendXML(armatureXML, animationXML);
            }

            return animationXML;
        }

        DragonBones.prototype._getTimelineXML = function (animationXML, timelineName, armatureItem)
        {
            var timelineXML = animationXML[DragonBones.TIMELINE].(@name == timelineName)[0];
            if (!timelineXML)
            {
                var scale = 1;
                var offset = 0;
                if (armatureItem.hasData(DragonBones.ANIMATION_DATA))
                {
                    var animationName = animationXML.@[DragonBones.A_NAME];
                    var animationsXMLInItem = XML(armatureItem.getData(DragonBones.ANIMATION_DATA));
                    var animationXMLInItem;
                    var timelineXMLInItem;
                    if (animationsXMLInItem[DragonBones.ANIMATION].length() > 0)
                    {
                        animationXMLInItem = animationsXMLInItem[DragonBones.ANIMATION].(@name == animationName)[0];
                        if (animationXMLInItem)
                        {
                            timelineXMLInItem = animationXMLInItem[DragonBones.TIMELINE].(@name == timelineName)[0];
                            if (timelineXMLInItem)
                            {
                                scale = Utils.getNumberFromObject(timelineXMLInItem, DragonBones.A_SCALE, 1);
                                offset = Utils.getNumberFromObject(timelineXMLInItem, DragonBones.A_OFFSET, 0);
                            }
                        }
                    }
                    
                    if (!timelineXMLInItem && animationsXMLInItem[DragonBones.OLD_ANIMATION].length() > 0)
                    {
                        animationXMLInItem = animationsXMLInItem[DragonBones.OLD_ANIMATION].(@name == animationName)[0];
                        if (animationXMLInItem)
                        {
                            timelineXMLInItem = animationXMLInItem[DragonBones.OLD_TIMELINE].(@name == timelineName)[0];
                            if (timelineXMLInItem)
                            {
                                scale = Number(timelineXMLInItem.@[DragonBones.OLD_SCALE]);
                                offset = 1 - Number(timelineXMLInItem.@[DragonBones.OLD_OFFSET]);
                                offset %= 1;
                            }
                        }
                    }
                }
                
                timelineXML = 
                    <{DragonBones.TIMELINE}
                        {DragonBones.A_NAME}={timelineName}
                        {DragonBones.A_SCALE}={Utils.formatNumber(scale)}
                        {DragonBones.A_OFFSET}={Utils.formatNumber(offset)}/>;
                
                Utils.appendXML(animationXML, timelineXML);
            }

            return timelineXML;
        }

        DragonBones.prototype._getBoneXML = function (armatureXML, boneName, frameXML, frameStart)
        {
            var boneXML = armatureXML[DragonBones.BONE].(@name == boneName)[0];
            if (
                boneXML &&
                Number(boneXML.@[DragonBones.A_START]) > frameStart
            )
            {
                //update boneXML transform from frameXML
                boneXML.@[DragonBones.A_START] = frameStart;
                
                var boneTransformXML = boneXML[DragonBones.TRANSFORM][0];
                var frameTransformXML = frameXML[DragonBones.TRANSFORM][0];
                
                boneTransformXML.@[DragonBones.A_X] = frameTransformXML.@[DragonBones.A_X];
                boneTransformXML.@[DragonBones.A_Y] = frameTransformXML.@[DragonBones.A_Y];
                boneTransformXML.@[DragonBones.A_SKEW_X] = frameTransformXML.@[DragonBones.A_SKEW_X];
                boneTransformXML.@[DragonBones.A_SKEW_Y] = frameTransformXML.@[DragonBones.A_SKEW_Y];
                boneTransformXML.@[DragonBones.A_SCALE_X] = frameTransformXML.@[DragonBones.A_SCALE_X];
                boneTransformXML.@[DragonBones.A_SCALE_Y] = frameTransformXML.@[DragonBones.A_SCALE_Y];
            }
            return boneXML;
        }

        DragonBones.prototype._addBoneXML = function (armatureXML, boneName, frameXML, frameStart, armatureXMLInItem)
        {
            var transformXML = frameXML[DragonBones.TRANSFORM][0];
            var boneXML = 
                <{DragonBones.BONE} {DragonBones.A_NAME}={boneName}>
                    <{DragonBones.TRANSFORM}
                        {DragonBones.A_X}={transformXML.@[DragonBones.A_X]}
                        {DragonBones.A_Y}={transformXML.@[DragonBones.A_Y]}
                        {DragonBones.A_SKEW_X}={transformXML.@[DragonBones.A_SKEW_X]}
                        {DragonBones.A_SKEW_Y}={transformXML.@[DragonBones.A_SKEW_Y]}
                        {DragonBones.A_SCALE_X}={transformXML.@[DragonBones.A_SCALE_X]}
                        {DragonBones.A_SCALE_Y}={transformXML.@[DragonBones.A_SCALE_Y]}/>

                </{DragonBones.BONE}>;
                
            boneXML.@[DragonBones.A_START] = frameStart;
            
            if (armatureXMLInItem)
            {
                var connectionXML;
                if (armatureXMLInItem[DragonBones.BONE].length() > 0)
                {
                    connectionXML = armatureXMLInItem[DragonBones.BONE].(@name == boneName)[0];
                }
                else if (armatureXMLInItem[DragonBones.OLD_BONE].length() > 0)
                {
                    connectionXML = armatureXMLInItem[DragonBones.OLD_BONE].(@name == boneName)[0];
                }

                if (connectionXML && connectionXML.@[DragonBones.A_PARENT][0])
                {
                    boneXML.@[DragonBones.A_PARENT] = connectionXML.@[DragonBones.A_PARENT];
                }
            }
            Utils.appendXML(armatureXML, boneXML, false, true);
            
            return boneXML;
        }

        DragonBones.prototype._getSlotXML = function (armatureXML, boneXML, slotName, armatureItem, zOrder)
        {
            var skinXML = armatureXML[DragonBones.SKIN][0];
            var slotXML = skinXML[DragonBones.SLOT].(@name == slotName)[0];
            if (!slotXML)
            {
                slotXML = 
                    <{DragonBones.SLOT}
                        {DragonBones.A_NAME}={slotName}
                        {DragonBones.A_PARENT}={boneXML.@[DragonBones.A_NAME]}
                        {DragonBones.A_Z_ORDER}={zOrder}/>;
                    
                Utils.appendXML(skinXML, slotXML);
            }
            return slotXML;
        }

        DragonBones.prototype._getDisplayXML = function (slotXML, displayName, transform, armatureItem, displayType)
        {
            var displayXML = slotXML[DragonBones.DISPLAY].(@name == displayName)[0];
            if (!displayXML)
            {
                displayXML = 
                    <{DragonBones.DISPLAY} 
                        {DragonBones.A_NAME}={displayName || ""}
                        {DragonBones.A_TYPE}={displayType}
                    >
                        <{DragonBones.TRANSFORM}
                            {DragonBones.A_X}={Utils.formatNumber(transform.x) || 0}
                            {DragonBones.A_Y}={Utils.formatNumber(transform.y) || 0}
                            {DragonBones.A_SKEW_X}={Utils.formatNumber(transform.skewX) || 0}
                            {DragonBones.A_SKEW_Y}={Utils.formatNumber(transform.skewY) || 0}
                            {DragonBones.A_SCALE_X}={Utils.formatNumber(transform.scaleX, 6) || 1}
                            {DragonBones.A_SCALE_Y}={Utils.formatNumber(transform.scaleY, 6) || 1}/>
                    </{DragonBones.DISPLAY}>;

                Utils.appendXML(slotXML, displayXML);
            }
            return displayXML;
        }

        function getTextXML(displayXML, textSymbol, fontFace, textHasColorAnimation)
        {
            var textXML = displayXML[DragonBones.TEXT][0];
            if (!textXML)
            {
                var colorString = textSymbol.getTextAttr("fillColor");

                if (colorString.length < 9)
                {
                    colorString += "FF";
                }

                textXML = 
                    <{DragonBones.TEXT} 
                        {DragonBones.A_BOLD}={textSymbol.getTextAttr("bold")? 1: 0}
                        {DragonBones.A_ITALIC}={textSymbol.getTextAttr("italic")? 1: 0}
                        {DragonBones.A_WIDTH}={Math.ceil(textSymbol.width / textSymbol.scaleX)}
                        {DragonBones.A_HEIGHT}={Math.ceil(textSymbol.height / textSymbol.scaleY)}
                        {DragonBones.A_SIZE}={textSymbol.getTextAttr("size")}
                        {DragonBones.A_FACE}={fontFace}
                        {DragonBones.A_ALIGN_H}={textSymbol.getTextAttr("alignment")}
                        {DragonBones.A_ALIGN_V}={"top"}
                        {DragonBones.A_LINE_TYPE}={textSymbol.lineType}
                        {DragonBones.A_TEXT_TYPE}={textSymbol.textType}
                        {DragonBones.A_TEXT}={textSymbol.getTextString()}
                        {DragonBones.A_HTML_TEXT}={textSymbol.renderAsHTML}
                        {DragonBones.A_LETTER_SPACING}={textSymbol.getTextAttr("letterSpacing")}
                        {DragonBones.A_LINE_SPACING}={textSymbol.getTextAttr("lineSpacing")}
                        {DragonBones.A_MAX_CHARACTERS}={textSymbol.maxCharacters}
                    >
                        <{DragonBones.COLOR}
                         {DragonBones.A_ALPHA}={textHasColorAnimation? 255: parseInt(colorString.substr(7, 2), 16)}
                         {DragonBones.A_RED}={textHasColorAnimation? 255: parseInt(colorString.substr(1, 2), 16)}
                         {DragonBones.A_GREEN}={textHasColorAnimation? 255: parseInt(colorString.substr(3, 2), 16)}
                         {DragonBones.A_BLUE}={textHasColorAnimation? 255: parseInt(colorString.substr(5, 2), 16)}/>
                    </{DragonBones.TEXT}>;

                Utils.appendXML(displayXML, textXML);
            }

            return textXML;
        }

        DragonBones.prototype._generateArmature = function (armatureName, isChildArmature)
        {
            var currentDOM = fl.getDocumentDOM();
            if (this._xml[DragonBones.ARMATURE].(@name == armatureName)[0])
            {
                return;
            }

            if (armatureName.indexOf(DragonBones.NO_EASING) >= 0)
            {
                return;
            }

            this._currentArmatureItem = Utils.filter(currentDOM.library.items, null, ["name", armatureName])[0];

            if (!this._currentArmatureItem || this._currentArmatureItem.linkageImportForRS)
            {
                return;
            }

            fl.showIdleMessage(false);
            
            this._displayRegistPositionMap = {};
            this._textHasAnimationMap = {};
            this._currentArmatureXML = 
                <{DragonBones.ARMATURE} {DragonBones.A_NAME}={armatureName}>
                    <{DragonBones.SKIN} {DragonBones.A_NAME}="default"/>
                </{DragonBones.ARMATURE}>;

            this._xml.appendChild(this._currentArmatureXML);

            if (this.hasEventListener(DragonBones.ARMATURE))
            {
                this.dispatchEvent(new events.Event(DragonBones.ARMATURE, ["start", this._currentArmatureItem, this._currentArmatureXML]));
            }

            currentDOM.library.editItem(this._currentArmatureItem.name);
            var layersFiltered = DragonBones.isArmatureItem(this._currentArmatureItem, isChildArmature);
            var mainLayer = layersFiltered.shift();
            var mainFrameList = DragonBones.getMainFrameList(mainLayer.frames);
            var noLabelChildArmature = mainLayer.noLabelChildArmature;
            for each (var mainFrame in mainFrameList)
            {
                this._generateAnimation(mainFrame, layersFiltered, noLabelChildArmature);
            }

            this._generateArea(this._currentArmatureXML, this._currentArmatureItem);
            this._displayRegistPositionMap = null;
            this._textHasAnimationMap = null;

            if (this.hasEventListener(DragonBones.ARMATURE))
            {
                this.dispatchEvent(new events.Event(DragonBones.ARMATURE, ["end", this._currentArmatureItem, this._currentArmatureXML]));
            }

            fl.showIdleMessage(true);
        };

        DragonBones.prototype._generateAnimation = function (mainFrame, layers, noLabelChildArmature)
        {
            var currentDOM = fl.getDocumentDOM();
            var timeline = currentDOM.getTimeline();

            var start = mainFrame.frame.startFrame;
            var duration = mainFrame.duration;
            var frameNameList = DragonBones.formatObjectName(mainFrame.frame);
            var animationName = frameNameList[2];
            var noAutoEasing = frameNameList[1] == DragonBones.NO_EASING;
            var animationXML = this._getAnimationXML(this._currentArmatureXML, animationName, this._currentArmatureItem, duration, noLabelChildArmature? 0: this._defaultFadeInTime, noAutoEasing);

            timeline.currentFrame = 0;

            if (frameNameList[3])
            {
                var jsonData = Utils.decodeJSON(frameNameList[3]);
                if (jsonData[DragonBones.A_CUSTOM])
                {
                    animationXML.@[DragonBones.A_CUSTOM] = jsonData[DragonBones.A_CUSTOM];
                }
            }

            if (this.hasEventListener(DragonBones.ANIMATION))
            {
                this.dispatchEvent(new events.Event(DragonBones.ANIMATION, ["start", this._currentArmatureItem, animationXML, start, duration, animationName]));
            }

            var boneNameList = [];
            var boneZOrderMap = {};
            var zOrderList = [];
            var changeFrames = [];
            
            for (var i = 0, l = layers.length; i < l; ++i)
            {
                var layer = layers[i];
                var layerLockBackup = layer.locked;
                var layerVisibleBackup = layer.visible;
                layer.locked = false;
                layer.visible = true;

                var layerNameList = DragonBones.formatObjectName(layer);
                var boneName = layerNameList[2];
                boneZOrderMap[boneName] = boneZOrderMap[boneName] || [];

                var keyFrames = Utils.toUniqueArray(layer.frames.slice(start, start + duration));
                var timelineXML = null;

                for (var j = 0, lj = keyFrames.length; j < lj; j ++)
                {
                    var frame = keyFrames[j];

                    //形状补间，转换成关键帧动画
                    if (
                        frame.duration > 1 && 
                        (
                            frame.tweenType == "shape" ||
                            frame.tweenType == "motion object"
                        )
                    )
                    {
                        changeFrames.push({layer:layer, start:frame.startFrame + 1, end:frame.startFrame + frame.duration});
                        timeline.setSelectedLayers(timeline.layers.indexOf(layer));
                        timeline.convertToKeyframes(frame.startFrame, frame.startFrame + frame.duration);
                        
                        //更新frames和framesLength
                        keyFrames = Utils.toUniqueArray(layer.frames.slice(start, start + duration));
                        lj = keyFrames.length;
                    }
                    else if (frame.duration > 1)
                    {
                        //
                        var boneSymbol = Utils.filter(frame.elements, null, ["instanceType", "symbol"])[0];
                        if (boneSymbol && boneSymbol.libraryItem.timeline.frameCount > 1 && (boneSymbol.loop == "loop" || boneSymbol.loop == "play once") && !DragonBones.isArmatureItem(boneSymbol.libraryItem, false))
                        {
                            changeFrames.push({layer:layer, start:frame.startFrame + 1, end:frame.startFrame + frame.duration});
                            timeline.setSelectedLayers(timeline.layers.indexOf(layer));
                            timeline.convertToKeyframes(frame.startFrame, frame.startFrame + frame.duration);
                            
                            //更新frames和framesLength
                            keyFrames = Utils.toUniqueArray(layer.frames.slice(start, start + duration));
                            lj = keyFrames.length;
                        }
                    }

                    //
                    frame = keyFrames[j];
                    
                    var elements = frame.elements;
                    var boneSymbol = Utils.filter(elements, null, ["instanceType", "bitmap", "symbol"], ["textType", "static", "dynamic", "input"])[0];
                    var itemFolderName = null;
                    var noAutoEasingFrame = noAutoEasing;
                    if (!boneSymbol)
                    {
                        if (elements.length > 0)
                        {
                            //将不能识别为骨骼的元素转换为元件
                            currentDOM.library.editItem(this._currentArmatureItem.name);
                            currentDOM.getTimeline().currentFrame = frame.startFrame;
                            currentDOM.selectNone();
                            currentDOM.selection = elements.concat();
                            
                            if (currentDOM.selection && currentDOM.selection.length > 0)
                            {
                                var newItemName = boneName + "_" + frame.startFrame;
                                itemFolderName = DragonBones.TEXTURE_AUTO_CREATE + "/" + this._currentArmatureItem.name;
                                currentDOM.library.addNewItem("folder", itemFolderName);
                                currentDOM.convertToSymbol("movie clip", newItemName, "top left");
                                currentDOM.library.moveToFolder(itemFolderName, newItemName, true);
                                boneSymbol = currentDOM.selection[0];
                            }
                        }
                        
                        if (!boneSymbol)
                        {
                            continue;
                        }
                        //这种转换过的元件都不能自动补间
                        noAutoEasingFrame = true;
                    }
                    
                    //
                    var frameStart = 0;
                    var frameDuration = 0;
                    if (frame.startFrame < start)
                    {
                        frameStart = 0;
                        frameDuration = frame.duration - start + frame.startFrame;
                    }
                    else if (frame.startFrame + frame.duration > start + duration)
                    {
                        frameStart = frame.startFrame - start;
                        frameDuration = duration - frame.startFrame + start;
                    }
                    else
                    {
                        frameStart = frame.startFrame - start;
                        frameDuration= frame.duration;
                    }
                    
                    if (!timelineXML)
                    {
                        timelineXML = this._getTimelineXML(animationXML, boneName, this._currentArmatureItem);
                    }

                    //zOrder
                    for (var k = frameStart, lk = frameStart + frameDuration; k < lk; k ++)
                    {
                        var zOrder = zOrderList[k];
                        if (isNaN(zOrder))
                        {
                            zOrderList[k] = zOrder = 0;
                        }
                        else
                        {
                            zOrderList[k] = ++ zOrder;
                        }
                    }

                    var zOrder = zOrderList[frameStart];
                    var boneList = boneZOrderMap[boneName];
                    for (k = frameStart, lk = frameStart + frameDuration; k < lk; k ++)
                    {
                        if (!isNaN(boneList[k]))
                        {
                            boneNameList.push(boneName);
                            boneName = DragonBones.formatSameName(layer, boneNameList);
                            boneList = boneZOrderMap[boneName] = [];
                            timelineXML = this._getTimelineXML(animationXML, boneName, this._currentArmatureItem);
                        }
                        boneList[k] = zOrder;
                    }

                    //
                    var frameXML = this._generateFrame(layer, frame, boneName, boneSymbol, i, noAutoEasingFrame, frameStart);
                    if (frameXML)
                    {
                        addFrameToTimeline(frameXML, frameStart, frameDuration, timelineXML);
                    }

                    //还原
                    if (itemFolderName)
                    {
                        currentDOM.breakApart();
                        currentDOM.exitEditMode();
                    }
                }

                layer.locked = layerLockBackup;
                layer.visible = layerVisibleBackup;
            }
            
            //还原
            if (changeFrames.length > 0)
            {
                currentDOM.library.editItem(this._currentArmatureItem.name);
                for each (var object in changeFrames)
                {
                    timeline.setSelectedLayers(timeline.layers.indexOf(object.layer));
                    timeline.clearKeyframes(object.start, object.end);
                }
            }
            
            //
            for each (var timelineXML in animationXML[DragonBones.TIMELINE])
            {
                var prevFrameXML = null;
                for each (var frameXML in timelineXML[DragonBones.FRAME])
                {
                    var frameStart = Number(frameXML.@[DragonBones.A_START]);
                    if (frameXML.childIndex() == 0)
                    {
                        if (frameStart > 0)
                        {
                            timelineXML.prependChild(<{DragonBones.FRAME} {DragonBones.A_DURATION}={frameStart} {DragonBones.A_DISPLAY_INDEX}="-1"/>);
                        }
                    }
                    else 
                    {
                        var prevStart = Number(prevFrameXML.@[DragonBones.A_START]);
                        var prevDuration = Number(prevFrameXML.@[DragonBones.A_DURATION]);
                        if (frameStart > prevStart + prevDuration)
                        {
                            var frameDutation = frameStart - prevStart - prevDuration;
                            timelineXML.insertChildBefore(frameXML, <{DragonBones.FRAME} {DragonBones.A_DURATION}={frameDutation} {DragonBones.A_DISPLAY_INDEX}="-1"/>);
                        }
                    }
                    if (frameXML.childIndex() == timelineXML[DragonBones.FRAME].length() - 1)
                    {
                        var frameDutation = Number(frameXML.@[DragonBones.A_DURATION]);
                        if (frameStart + frameDutation < duration)
                        {
                            frameDutation = duration - frameStart - frameDutation;
                            timelineXML.appendChild(<{DragonBones.FRAME} {DragonBones.A_DURATION}={frameDutation} {DragonBones.A_DISPLAY_INDEX}="-1"/>);
                        }
                    }
                    
                    prevFrameXML = frameXML;
                }
            }

            delete animationXML[DragonBones.TIMELINE][DragonBones.FRAME].@[DragonBones.A_START];
            
            this._generateAnimationEventFrames(animationXML, mainFrame);

            if (this.hasEventListener(DragonBones.ANIMATION))
            {
                this.dispatchEvent(new events.Event(DragonBones.ANIMATION, ["end", this._currentArmatureItem, animationXML, start, duration, animationName]));
            }
        };

        DragonBones.prototype._generateFrame = function (layer, frame, boneName, boneSymbol, zOrder, noAutoEasing, frameStart)
        {
            var boneSymbolItem = boneSymbol.libraryItem;
            var transform = boneSymbol.getTransformationPoint();

            var displayType = null;
            //是否是多帧图形骨骼，TODO: 更完善的检测
            var isGraphicBone = false;
            //当空元件或空图形时，TODO: 更完善的检测
            var hasDisplay = false;

            var isArmature = Boolean(DragonBones.isArmatureItem(boneSymbolItem, boneSymbol.symbolType == "movie clip"));

            switch (boneSymbol.instanceType)
            {
                case "bitmap":
                    displayType = DragonBones.V_IMAGE;
                    //cs 5.5 cs 6 bug
                    if (
                        transform.x == 0 && 
                        transform.y == 0
                    )
                    {
                        transform.x = boneSymbol.hPixels * 0.5;
                        transform.y = boneSymbol.vPixels * 0.5;
                    }
                    hasDisplay = true;
                    break;

                case "symbol":
                    if (isArmature)
                    {
                        displayType = DragonBones.V_ARMATURE;
                        hasDisplay = true;
                    }
                    else if (
                        boneSymbol.symbolType == "graphic" &&
                        boneSymbolItem.timeline.frameCount > 1 &&
                        (boneSymbol.loop == "single frame" || boneSymbol.loop == "loop" || boneSymbol.loop == "play once"))
                    {
                        // TODO: multiply slots
                        displayType = DragonBones.V_IMAGE;
                        isGraphicBone = true;
                        hasDisplay = (boneSymbol.width > 0 || boneSymbol.height > 0);
                        hasDisplay = (boneSymbol.width > 0 || boneSymbol.height > 0);
                    }
                    else
                    {
                        displayType = DragonBones.V_IMAGE;
                        hasDisplay = (boneSymbol.width > 0 || boneSymbol.height > 0);
                        hasDisplay = (boneSymbol.width > 0 || boneSymbol.height > 0);
                    }
                    break;

                default:
                    if (boneSymbol.textType)
                    {
                        displayType = DragonBones.V_TEXT;
                        hasDisplay = true;
                        // flash cc bug
                        transform.x += 2;
                        transform.y += 2;
                        break;
                    }
                    return null;
            }

            var displayMap = this._displayRegistPositionMap[boneName];
            if (!displayMap)
            {
                displayMap = {};
                this._displayRegistPositionMap[boneName] = displayMap;
            }
            var displayRegistName = boneSymbolItem? boneSymbolItem.name: (boneName + " _default");
            var displayRegistPosition = displayMap[displayRegistName];
            if (!displayRegistPosition)
            {
                displayRegistPosition = {x:transform.x, y:transform.y};
                displayMap[displayRegistName] = displayRegistPosition;
            }
            transform.pivotOffsetX = displayRegistPosition.x - transform.x;
            transform.pivotOffsetY = displayRegistPosition.y - transform.y;
            transform.skewX = boneSymbol.skewX;
            transform.skewY = boneSymbol.skewY;
            transform.scaleX = boneSymbol.scaleX;
            transform.scaleY = boneSymbol.scaleY;
            DragonBones.formatTransform(transform);

            // TODO: 将形变与缩放分出部分值给display
            var frameXML = <{DragonBones.FRAME} {DragonBones.A_Z_ORDER}={zOrder}/>;
            var transformXML = 
                <{DragonBones.TRANSFORM}
                    {DragonBones.A_X}={Utils.formatNumber(boneSymbol.transformX)}
                    {DragonBones.A_Y}={Utils.formatNumber(boneSymbol.transformY)}
                    {DragonBones.A_SKEW_X}={Utils.formatNumber(transform.skewX)}
                    {DragonBones.A_SKEW_Y}={Utils.formatNumber(transform.skewY)}
                    {DragonBones.A_SCALE_X}={Utils.formatNumber(transform.scaleX, 6)}
                    {DragonBones.A_SCALE_Y}={Utils.formatNumber(transform.scaleY, 6)}
                    {DragonBones.A_PIVOT_X}={Utils.formatNumber(transform.pivotOffsetX, 4)}
                    {DragonBones.A_PIVOT_Y}={Utils.formatNumber(transform.pivotOffsetY, 4)}/>;
            frameXML.appendChild(transformXML);

            //
            var boneXML = this._getBoneXML(this._currentArmatureXML, boneName, frameXML, frameStart);
            if (!boneXML)
            {
                boneXML = this._addBoneXML(
                    this._currentArmatureXML, boneName, frameXML, frameStart, 
                    this._currentArmatureItem.hasData(DragonBones.ARMATURE_DATA)? XML(this._currentArmatureItem.getData(DragonBones.ARMATURE_DATA)): null
                );

                if (boneSymbol.instanceType == "symbol")
                {
                    this._generateArea(boneXML, boneSymbolItem);
                }

                if (this.hasEventListener(DragonBones.BONE))
                {
                    this.dispatchEvent(new events.Event(DragonBones.BONE, [this._currentArmatureItem, boneSymbol, boneXML]));
                }
            }

            //
            var slotXML = this._getSlotXML(this._currentArmatureXML, boneXML, boneName, this._currentArmatureItem, zOrder);
            if (boneSymbol.blendMode && boneSymbol.blendMode != "normal")
            {
                slotXML.@[DragonBones.A_BLEND_MODE] = boneSymbol.blendMode;
            }

            //
            if (hasDisplay)
            {
                //
                if (boneSymbol.visible === false)
                {
                    frameXML.@[DragonBones.A_HIDE] = 1;
                }

                //
                if (frameStart > 0 && boneSymbol.hasPersistentData(DragonBones.SCALE_OFFSET_DATA))
                {
                    var scaleOffset = boneSymbol.getPersistentData(DragonBones.SCALE_OFFSET_DATA);
                    frameXML.@[DragonBones.A_SCALE_X_OFFSET] = Utils.formatNumber(scaleOffset[0], 6);
                    frameXML.@[DragonBones.A_SCALE_Y_OFFSET] = Utils.formatNumber(scaleOffset[1], 6);
                }

                //
                var displayXML = null;
                var textXML = null;

                var textHasColorAnimation = false;

                var textAlpah = 0;
                var textRed = 0;
                var textGreen = 0;
                var textBlue = 0;

                if (boneSymbolItem)
                {
                    var symbolNameList = DragonBones.formatObjectName(boneSymbolItem, true);
                    var displayName = symbolNameList[2];
                    if (isGraphicBone)
                    {
                        if (symbolNameList[1] != DragonBones.NO_EASING)
                        {
                            displayXML = this._generateMultipleSlot(boneSymbol, boneXML, slotXML);
                        }
                    }
                    else
                    {
                        var displayTransform = {x:-transform.x, y:-transform.y};

                        displayXML = this._getDisplayXML(slotXML, displayName, displayTransform, this._currentArmatureItem, displayType);

                        if (displayType == DragonBones.V_ARMATURE)
                        {
                            if (this._armatureList.indexOf(displayName) < 0)
                            {
                                this._armatureList.push(displayName);
                                this._armatureList.push(true);
                            }
                        }
                    }

                    if (boneSymbolItem && boneSymbolItem.scalingGrid)
                    {
                        var scalingGridXML = 
                            <{DragonBones.SCALING_GRID}
                                {DragonBones.A_LEFT}={Math.round(boneSymbolItem.scalingGridRect.left)}
                                {DragonBones.A_RIGHT}={Math.round(boneSymbolItem.scalingGridRect.right)}
                                {DragonBones.A_TOP}={Math.round(boneSymbolItem.scalingGridRect.top)}
                                {DragonBones.A_BOTTOM}={Math.round(boneSymbolItem.scalingGridRect.bottom)}/>;
                        displayXML.appendChild(scalingGridXML);
                    }
                }
                else
                {
                    // text

                    textHasColorAnimation = this._textHasAnimationMap[boneName];
                    if (
                        textHasColorAnimation === false ||
                        textHasColorAnimation === true
                        )
                    {

                    }
                    else
                    {
                        textHasColorAnimation = DragonBones.isTextLayerHasColorAnimation(layer);
                        this._textHasAnimationMap[boneName] = textHasColorAnimation;
                    }

                    var displayTransform = {x:-transform.x, y:-transform.y};
                    displayXML = this._getDisplayXML(slotXML, "text", displayTransform, this._currentArmatureItem, displayType);
                    
                    if (textHasColorAnimation)
                    {
                        var colorString = boneSymbol.getTextAttr("fillColor");
                        if (colorString.length < 9)
                        {
                            colorString += "FF";
                        }
                        textAlpah = parseInt(colorString.substr(7, 2), 16);
                        textRed = parseInt(colorString.substr(1, 2), 16);
                        textGreen = parseInt(colorString.substr(3, 2), 16);
                        textBlue = parseInt(colorString.substr(5, 2), 16);
                    }

                    var fontFace = boneSymbol.getTextAttr("face");
                    var fontItem = this._fontItemMap[fontFace];
                    textXML = getTextXML(displayXML, boneSymbol, fontItem? fontItem.name: fontFace, textHasColorAnimation);
                }
                
                if (displayXML)
                {
                    var displayIndex = displayXML.childIndex();
                    if (displayIndex != 0)
                    {
                        frameXML.@[DragonBones.A_DISPLAY_INDEX] = displayIndex;
                    }
                }
                else
                {
                    //frameXML.@[DragonBones.A_DISPLAY_INDEX] = -1;
                }
            }

            //
            if (boneSymbol.instanceType == "symbol" || textHasColorAnimation)
            {
                var aO = 0;
                var rO = 0;
                var gO = 0;
                var bO = 0;
                var aM = 100;
                var rM = 100;
                var gM = 100;
                var bM = 100;

                if (textHasColorAnimation)
                {
                    aM = Math.ceil(textAlpah / 255 * 100);
                    rM = Math.ceil(textRed / 255 * 100);
                    gM = Math.ceil(textGreen / 255 * 100);
                    bM = Math.ceil(textBlue / 255 * 100);
                }
                else
                {
                    aO = boneSymbol.colorAlphaAmount;
                    rO = boneSymbol.colorRedAmount;
                    gO = boneSymbol.colorGreenAmount;
                    bO = boneSymbol.colorBlueAmount;
                    aM = boneSymbol.colorAlphaPercent;
                    rM = boneSymbol.colorRedPercent;
                    gM = boneSymbol.colorGreenPercent;
                    bM = boneSymbol.colorBluePercent;
                }

                if (
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
                        <{DragonBones.COLOR_TRANSFORM}
                            {DragonBones.A_ALPHA_OFFSET}={aO}
                            {DragonBones.A_RED_OFFSET}={rO}
                            {DragonBones.A_GREEN_OFFSET}={gO}
                            {DragonBones.A_BLUE_OFFSET}={bO}
                            {DragonBones.A_ALPHA_MULTIPLIER}={aM}
                            {DragonBones.A_RED_MULTIPLIER}={rM}
                            {DragonBones.A_GREEN_MULTIPLIER}={gM}
                            {DragonBones.A_BLUE_MULTIPLIER}={bM}/>;

                    frameXML.appendChild(colorTransformXML);
                }
            }

            if (frame.tweenType == "motion")
            {
                frameXML.@[DragonBones.A_TWEEN_EASING] = Utils.formatNumber(frame.tweenEasing * 0.01);
                var tweenRotate = 0;
                switch (frame.motionTweenRotate)
                {
                    case "clockwise":
                        tweenRotate = frame.motionTweenRotateTimes + 1;
                        break;
                        
                    case "counter-clockwise":
                        tweenRotate = - frame.motionTweenRotateTimes - 1;
                        break;
                }
                if (tweenRotate)
                {
                    frameXML.@[DragonBones.A_TWEEN_ROTATE] = tweenRotate;
                }
                if (!frame.motionTweenScale)
                {
                    frameXML.@[DragonBones.A_TWEEN_SCALE] = 0;
                }
            }
            else if (noAutoEasing)
            {
                frameXML.@[DragonBones.A_TWEEN_EASING] = NaN;
            }
            else
            {
                // auto tween frame
            }

            if (frame.labelType == "name" && frame.name)
            {
                var nameList = frame.name.split(DragonBones.DELIM_CHAR);
                for each (var eachName in nameList)
                {
                    this._generateFrameEvent(eachName, noAutoEasing, frameXML, slotXML, textXML);
                }
            }

            // sound
            if (frame.soundName)
            {
                frameXML.@[DragonBones.A_SOUND] = frame.soundLibraryItem.linkageClassName || frame.soundName;
            }
            
            return frameXML;
        };

        DragonBones.prototype._generateFrameEvent = function (eachName, noAutoEasing, frameXML, slotXML, textXML)
        {
            var frameNameList = DragonBones.getNameParameters(eachName);

            // modify ease
            if (frameNameList[1] == DragonBones.NO_EASING || (noAutoEasing && frame.tweenType != "motion"))
            {
                frameXML.@[DragonBones.A_TWEEN_EASING] = NaN;
            }
            
            // action
            if (frameNameList[1] == DragonBones.ACTION_PREFIX)
            {
                frameXML.@[DragonBones.A_ACTION] = frameNameList[2];
            }

            // event
            if (frameNameList[1] == DragonBones.EVENT_PREFIX)
            {
                frameXML.@[DragonBones.A_EVENT] = frameNameList[2];
                if (frameNameList[3])
                {
                    frameXML.@[DragonBones.A_EVENT_PARAMETERS] = frameNameList[3];
                }
            }

            // set values
            if (frameNameList[1] == DragonBones.SET_PREFIX && frameNameList[3])
            {
                var jsonData = Utils.decodeJSON(frameNameList[3]);

                switch (frameNameList[2])
                {
                    case DragonBones.SLOT:
                        for (var key in jsonData)
                        {
                            var value = jsonData[key];
                            switch (key)
                            {
                                case DragonBones.A_BLEND_MODE:
                                    slotXML.@[DragonBones.A_BLEND_MODE] = value;
                                    break;
                            }
                        }
                        break;

                    case DragonBones.TEXT:
                        if (!textXML)
                        {
                            break;
                        }

                        for (var key in jsonData)
                        {
                            var value = jsonData[key];
                            switch (key)
                            {
                                case DragonBones.A_ALIGN_V:
                                    textXML.@[DragonBones.A_ALIGN_V] = value;
                                    break;
                            }
                        }
                        break;
                }
            }
        };

        DragonBones.prototype._generateArea = function (containerXML, libraryItem)
        {
            var currentDOM = fl.getDocumentDOM();

            var areaNameList = [];
            for each (var layer in Utils.filter(libraryItem.timeline.layers, null, ["layerType", "guide"]))
            {
                DragonBones.formatSameName(layer, areaNameList);
                var layerNameList = DragonBones.formatObjectName(layer);
                if (layerNameList[1] == DragonBones.EVENT_PREFIX)
                {
                    var areaName = layerNameList[2];
                    var areaShape = Utils.filter(layer.frames[0].elements, null, ["isOvalObject", true], ["isRectangleObject", true])[0];
                    if (areaShape)
                    {
                        var areaXML;
                        if (areaShape.isRectangleObject)
                        {
                            areaXML = <{DragonBones.RECTANGLE}/>;
                        }
                        else if (areaShape.isOvalObject)
                        {
                            areaXML = <{DragonBones.ELLIPSE}/>;

                            /*
                            areaShape.selected = true;
                            currentDOM.setOvalObjectProperty("startAngle", 0);
                            currentDOM.setOvalObjectProperty("endAngle", 0);
                            areaShape.selected = false;
                            */
                        }

                        var matrix = areaShape.matrix;

                        areaShape.skewX = 0;
                        areaShape.skewY = 0;
                        areaShape.rotation = 0;
                        areaShape.scaleX = 1;
                        areaShape.scaleY = 1;

                        var width = areaShape.width;
                        var height = areaShape.height;
                        var x = areaShape.x;
                        var y = areaShape.y;

                        areaShape.matrix = matrix;
                        areaXML.@[DragonBones.A_NAME] = areaName;
                        areaXML.@[DragonBones.A_WIDTH] = Utils.formatNumber(width);
                        areaXML.@[DragonBones.A_HEIGHT] = Utils.formatNumber(height);

                        var transformXML = 
                            <{DragonBones.TRANSFORM}
                                {DragonBones.A_X}={Utils.formatNumber(areaShape.transformX)}
                                {DragonBones.A_Y}={Utils.formatNumber(areaShape.transformY)}
                                {DragonBones.A_SKEW_X}={Utils.formatNumber(areaShape.skewX)}
                                {DragonBones.A_SKEW_Y}={Utils.formatNumber(areaShape.skewY)}
                                {DragonBones.A_SCALE_X}={Utils.formatNumber(areaShape.scaleX, 6)}
                                {DragonBones.A_SCALE_Y}={Utils.formatNumber(areaShape.scaleY, 6)}
                                {DragonBones.A_PIVOT_X}={Utils.formatNumber(areaShape.transformX - (x - width * 0.5))}
                                {DragonBones.A_PIVOT_Y}={Utils.formatNumber(areaShape.transformY - (y - height * 0.5))}/>

                        areaXML.appendChild(transformXML);

                        Utils.appendXML(containerXML, areaXML);
                    }
                }
            }
        };

        DragonBones.prototype._generateAnimationEventFrames = function (animationXML, mainFrame)
        {
            if (mainFrame.frames.length == 1)
            {
                return;
            }

            var start = mainFrame.frame.startFrame;
            for (var i = 0, l = mainFrame.frames.length; i < l; i ++)
            {
                var frame = mainFrame.frames[i];
                var frameXML = <{DragonBones.FRAME} {DragonBones.A_DURATION}={frame.duration}/>;
                if (frame.labelType == "name" && frame.name)
                {
                    var frameNameList = DragonBones.getNameParameters(frame.name);
                    if (frameNameList[1] == DragonBones.ACTION_PREFIX)
                    {
                        frameXML.@[DragonBones.A_ACTION] = frameNameList[2];
                    }

                    if (frameNameList[1] == DragonBones.EVENT_PREFIX)
                    {
                        frameXML.@[DragonBones.A_EVENT] = frameNameList[2];
                        if (frameNameList[3])
                        {
                            frameXML.@[DragonBones.A_EVENT_PARAMETERS] = frameNameList[3];
                        }
                    }
                }

                if (frame.soundName)
                {
                    frameXML.@[DragonBones.A_SOUND] = frame.soundLibraryItem.linkageClassName || frame.soundName;
                }
                animationXML.appendChild(frameXML);
            }
        };

        DragonBones.prototype._generateMultipleSlot = function (displayContainer, boneXML, mainSlotXML)
        {
            //
            var displayContainerItem = displayContainer.libraryItem;
            var layers = displayContainerItem.timeline.layers;
            var layersFiltered = [];
            var layerNameList = [];
            var mainSlotName = mainSlotXML.@[DragonBones.A_NAME];
            var mainSlotZOrder = Number(mainSlotXML.@[DragonBones.A_Z_ORDER]);
            for each (var layer in layers)
            {
                if (!layer.name)
                {
                    layer.name = mainSlotName;
                }

                if (DragonBones.isBoneLayer(layer))
                {
                    DragonBones.formatObjectName(layer);
                    DragonBones.formatSameName(layer, layerNameList);
                    layersFiltered.push(layer);
                }
            }

            var mainDisplayXML = null;
            var layerIndex = 1;
            for each (var layer in layersFiltered)
            {
                var frame = layer.frames[displayContainer.firstFrame];
                var elements = null;
                var displaySymbol = null;

                if (frame)
                {
                    elements = frame.elements;
                    displaySymbol = Utils.filter(elements, null, ["instanceType", "bitmap", "symbol"], ["textType", "static", "dynamic", "input"])[0];
                }
                
                var itemFolderName = null;
                if (!displaySymbol)
                {

                }
                
                if (displaySymbol)
                {
                    var displaySymbolItem = displaySymbol.libraryItem;
                    if (displaySymbolItem)
                    {
                        var symbolNameList = DragonBones.formatObjectName(displaySymbolItem, true);
                        var displayName = symbolNameList[2];
                        var isArmature = Boolean(DragonBones.isArmatureItem(displaySymbolItem, true));
                        var transform = displayContainer.getTransformationPoint();
                        transform.x = displaySymbol.x - transform.x;
                        transform.y = displaySymbol.y - transform.y;
                        transform.skewX = displaySymbol.skewX;
                        transform.skewY = displaySymbol.skewY;
                        transform.scaleX = displaySymbol.scaleX;
                        transform.scaleY = displaySymbol.scaleY;

                        if (layersFiltered.length > 1 && layer.name != mainSlotName)
                        {
                            var slotXML = this._getSlotXML(this._currentArmatureXML, boneXML, layer.name, this._currentArmatureItem, mainSlotZOrder + layerIndex * 0.05);
                            if (displaySymbol.blendMode && displaySymbol.blendMode != "normal")
                            {
                                slotXML.@[DragonBones.A_BLEND_MODE] = displaySymbol.blendMode;
                            }
                            this._getDisplayXML(slotXML, displayName, transform, this._currentArmatureItem, isArmature? DragonBones.V_ARMATURE: DragonBones.V_IMAGE);
                        }
                        else
                        {
                            mainDisplayXML = this._getDisplayXML(mainSlotXML, displayName, transform, this._currentArmatureItem, isArmature? DragonBones.V_ARMATURE: DragonBones.V_IMAGE);
                        }

                        if (isArmature)
                        {
                            if (this._armatureList.indexOf(displayName) < 0)
                            {
                                this._armatureList.push(displayName);
                                this._armatureList.push(true);
                            }
                        }
                    }
                    else if (displaySymbol.textType)
                    {
                        // TODO:
                    }
                }
                
                //还原
                if (itemFolderName)
                {
                    currentDOM.breakApart();
                    currentDOM.exitEditMode();
                }

                layerIndex ++;
            }

            return mainDisplayXML;
        };

        DragonBones.prototype.getArmatureList = function (domID, isSelected, armatureNames)
        {
            fl.outputPanel.clear();
            
            //if frame count > 1, the skeleton have animation.
            /*
            if (mainLayer.frameCount > 1)
            {
                
            }
            */

            var currentDOM = Utils.getDOM(domID, true);
            if (!currentDOM)
            {
                return DragonBones.ERROR_NO_ACTIVE_DOM;
            }
            
            var timeline = currentDOM.getTimeline();
            this._currentItemBackup = timeline.libraryItem;
            if (this._currentItemBackup)
            {
                this._currentFrameBackup = timeline.currentFrame;
            }
            this._librarySelectItemsBackup = currentDOM.library.getSelectedItems().concat();
            currentDOM.exitEditMode();
            
            if (armatureNames)
            {
                armatureNames = armatureNames.split(",");
            }
            
            var items = null;
            if (armatureNames && armatureNames.length > 0)
            {
                items = [];
                for each (var armatureName in armatureNames)
                {
                    var item = Utils.filter(currentDOM.library.items, null, ["name", armatureName])[0];
                    if (item)
                    {
                        items.push(item);
                    }
                }
            }
            else
            {
                items = isSelected? this._librarySelectItemsBackup: currentDOM.library.items;
            }

            var dataName = currentDOM.name.split(".")[0];
            var xml = 
                <{DragonBones.DRAGON_BONES}
                    {DragonBones.A_NAME}={dataName}
                    {DragonBones.A_FRAME_RATE}={currentDOM.frameRate}
                    {DragonBones.A_ID}={currentDOM.id}
                    {DragonBones.A_URL}={currentDOM.pathURI}/>;
            
            var hasArmature = false;
            for each (var item in items)
            {
                if (DragonBones.isArmatureItem(item))
                {
                    DragonBones.formatObjectName(item, true);
                    xml.appendChild(
                        <{DragonBones.ARMATURE} 
                            {DragonBones.A_NAME}={item.name} 
                            {DragonBones.A_SCALE} ={1}/>
                    );
                    hasArmature = true;
                }
            }
            
            if (hasArmature)
            {
                return xml.toXMLString();
            }
            
            return DragonBones.ERROR_NO_ARMATURE_IN_DOM;
        };

        DragonBones.prototype.getArmature = function (domID, armatureName, dragonBonesXML, defaultFadeInTime, isMergeLayersInFolder, defaultAutoTween)
        {
            var currentDOM = Utils.getDOM(domID, true);
            if (!currentDOM)
            {
                return DragonBones.ERROR_NO_ACTIVE_DOM;
            }

            if (!armatureName || !dragonBonesXML)
            {
                return false;
            }

            this._defaultFadeInTime = defaultFadeInTime || 0;
            this._defaultAutoTween = defaultAutoTween || 1;
            this._isMergeLayersInFolder = Boolean(isMergeLayersInFolder);
            this._xml = <{DragonBones.DRAGON_BONES}/>;
            this._armatureList = [armatureName, false];
            this._fontItemMap = {};

            var fontItemList = Utils.filter(currentDOM.library.items, null, ["itemType", "font"]);
            for (var i = 0, l = fontItemList.length; i < l; ++i)
            {
                var fontItem = fontItemList[i];
                this._fontItemMap[fontItem.font] = fontItem;
            }

            while (this._armatureList.length > 0)
            {
                var eachArmatureName = this._armatureList.shift();
                var isChild = this._armatureList.shift();

                if (eachArmatureName != armatureName && dragonBonesXML[DragonBones.ARMATURE].(@name == eachArmatureName)[0])
                {
                    continue;
                }

                trace(eachArmatureName);
                this._generateArmature(eachArmatureName, isChild);
            }

            //
            delete this._xml[DragonBones.ARMATURE][DragonBones.BONE].@[DragonBones.A_START];
            
            var dragonBonesXMLURL = DragonBones.getConfigPath() + "/" + DragonBones.DRAGON_BONES_XML;
            FLfile.write(dragonBonesXMLURL, this._xml.toXMLString());

            this._xml = null;
            this._armatureList = null;
            this._fontItemMap = null;

            return dragonBonesXMLURL;
        };

        DragonBones.prototype.clearTextureSWFItem = function (domID)
        {
            var currentDOM = Utils.getDOM(domID, true);
            if (!currentDOM)
            {
                return DragonBones.ERROR_NO_ACTIVE_DOM;
            }
            
            if (!currentDOM.library.itemExists(DragonBones.TEXTURE_SWF_ITEM))
            {
                currentDOM.library.addNewItem("movie clip", DragonBones.TEXTURE_SWF_ITEM);
            }
            currentDOM.library.editItem(DragonBones.TEXTURE_SWF_ITEM);
            
            var timeline = currentDOM.getTimeline();
            timeline.currentLayer = 0;
            timeline.removeFrames(0, timeline.frameCount);
            timeline.insertBlankKeyframe(0);
            timeline.insertBlankKeyframe(1);

            return true;
        };

        DragonBones.prototype.addTextureToSWFItem = function (domID, textureName)
        {
            var currentDOM = Utils.getDOM(domID, true);
            if (!currentDOM)
            {
                return DragonBones.ERROR_NO_ACTIVE_DOM;
            }
            
            var textureItem = Utils.filter(currentDOM.library.items, null, ["name", textureName])[0];
            if (textureItem)
            {
                if (textureItem.linkageImportForRS)
                {
                    return DragonBones.NOT_EXPORT;
                }
            }
            else
            {
                var nameList = DragonBones.getNameParameters(textureName, DragonBones.NO_EASING);
                textureItem = Utils.filter(currentDOM.library.items, null, ["name", nameList[0]])[0];

                if (textureItem)
                {
                    return DragonBones.NOT_EXPORT;
                }
                return false;
            }
            
            currentDOM.getTimeline().currentFrame = 0;

            var textureSymbol = Utils.addItemToDocument(currentDOM, textureName);
            if (textureSymbol)
            {
                if (textureSymbol.width == 0 || textureSymbol.height == 0)
                {
                    currentDOM.deleteSelection();
                    return false;
                }
            
                switch (textureSymbol.instanceType)
                {
                    case "symbol":
                        if (textureSymbol.symbolType != "movie clip")
                        {
                            textureSymbol.symbolType = "movie clip";
                        }
                        break;
                        
                    case "bitmap":
                        var bitmapItem = textureSymbol.libraryItem;
                        bitmapItem.compressionType = "lossless";
                        bitmapItem.allowSmoothing = true;

                        if (!bitmapItem.linkageClassName)
                        {
                            bitmapItem.linkageExportForAS = true;
                            bitmapItem.linkageClassName = bitmapItem.name;
                        }
                        break;
                }
                
                currentDOM.getTimeline().currentFrame = 1;
                
                return textureName;
            }
            
            return false;
        };

        DragonBones.prototype.exportSWF = function (domID)
        {
            var currentDOM = Utils.getDOM(domID, true);
            if (!currentDOM)
            {
                return DragonBones.ERROR_NO_ACTIVE_DOM;
            }
            
            //
            currentDOM.getTimeline().removeFrames(1, 1);
            if (this._currentItemBackup)
            {
                currentDOM.library.editItem(this._currentItemBackup.name);
                currentDOM.getTimeline().currentFrame = this._currentFrameBackup;
                //select backup library items
            }
            
            var swfURL = DragonBones.getConfigPath() + "/" + DragonBones.TEXTURE_SWF;
            var textureSWFItem = Utils.filter(currentDOM.library.items, null, ["name", DragonBones.TEXTURE_SWF_ITEM])[0]
            textureSWFItem.exportSWF(swfURL);
            
            currentDOM.library.deleteItem(DragonBones.TEXTURE_AUTO_CREATE);
            currentDOM.library.deleteItem(DragonBones.TEXTURE_SWF_ITEM);
            
            return swfURL;
        };

        DragonBones.prototype.setBoneSelect = function (enabled)
        {
            if (DragonBones._frameChangedEventID != undefined)
            {
                fl.removeEventListener("frameChanged", DragonBones._frameChangedEventID);
            }

            if (enabled)
            {
                DragonBones._frameChangedEventID = fl.addEventListener("frameChanged", DragonBones._frameChangedHandler);
            }
        }

        return DragonBones;
    })(events.EventDispatcher);
    dragonBones.DragonBones = DragonBones;


}
)(dragonBones || (dragonBones = {}));

var db = new dragonBones.DragonBones();