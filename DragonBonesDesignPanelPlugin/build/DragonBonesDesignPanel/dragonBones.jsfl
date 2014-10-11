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
            this._defaultFadeInTime = 0.3;

            this._xml = null;
            this._armatureList = null;
            this._currentArmatureItem = null;
            this._currentArmatureXML = null;
            this._displayRegistPositionMap = null;
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
        
        DragonBones.A_Z = "z";
        DragonBones.A_ROTATION_X = "rotationX";
        DragonBones.A_ROTATION_Y = "rotationY";
        DragonBones.A_ROTATION_Z = "rotationZ";
        DragonBones.A_OFFSET_ROTATION_X = "offsetRotationX"
        DragonBones.A_OFFSET_ROTATION_Y = "offsetRotationY"
        DragonBones.A_OFFSET_ROTATION_Z = "offsetRotationZ"
        DragonBones.A_MATRIX3D = "matrix3D";

        DragonBones.A_ID = "id";
        DragonBones.A_URL = "url";

        DragonBones.A_START = "start";

        DragonBones.V_IMAGE = "image";
        DragonBones.V_ARMATURE = "armature";

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

        DragonBones.isMainLayer = function (layer)
        {
            assert(layer);

            var keyFrames = Utils.toUniqueArray(layer.frames);
            for (var i = keyFrames.length; i--; )
            {
                if (DragonBones.isMainFrame(keyFrames[i]))
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
            for (var i = 0, l = keyFrames.length; i < l; ++i)
            {
                //
                var frame = keyFrames[i];
                if (currentFrame? (frame.startFrame <= currentFrame && frame.startFrame + frame.duration > currentFrame): true)
                {
                    if (frame.elements.length > 0)
                    {
                        return true;
                    }
                }
            }

            return false;
        };

        DragonBones.isMainFrame = function (frame)
        {
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

        //To determine whether the item is valide armature.
        //If yes, return mainLayer and boneLayers
        DragonBones.isArmatureItem = function (item, isChildArmature)
        {
            if (
                item.itemType != "movie clip" && 
                item.itemType != "graphic"
            )
            {
                return null;
            }

            var layersFiltered = [];
            var layers = item.timeline.layers;
            var mainLayer = null;
            for (var i = layers.length; i--; )
            {
                var layer = layers[i];
                if (!mainLayer && DragonBones.isMainLayer(layer))
                {
                    mainLayer = layer;
                }
                else if (DragonBones.isBoneLayer(layer))
                {
                    layersFiltered.push(layer);
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
                    // 检测未加标签的子动画时，虽然frameCount大于1，但应更深入的检查是否各个图层只有一帧
                    mainLayer = {};
                    mainLayer.frameCount = item.timeline.frameCount;
                    mainLayer.frames = [];
                    mainLayer.noLabelChildArmature = true;
                    var frame = {};
                    frame.labelType = "name";
                    frame.name = "unnamed";
                    frame.startFrame = 0;
                    frame.duration = mainLayer.frameCount;
                    
                    mainLayer.frames.push(frame);
                    layersFiltered.unshift(mainLayer);
                    return layersFiltered;
                }
            }
            return null;
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

        DragonBones.canMergeLayersInFolder = function (item)
        {
            var folderMap = {};
            var hasFolder = false;
            for each (var layer in item.timeline.layers)
            {
                if (layer.layerType == "folder")
                {
                    folderMap[layer.name] = 0;
                    hasFolder = true;
                }
            }

            if (hasFolder)
            {
                for each (var layer in item.timeline.layers)
                {
                    if (layer.layerType != "folder" && layer.parentLayer)
                    {
                        var count = folderMap[layer.parentLayer.name] || 0;
                        count ++;
                        if (count > 1)
                        {
                            return true;
                        }
                        folderMap[layer.parentLayer.name] = count;
                    }
                }
            }
            return false;
        };

        DragonBones.mergeLayersInFolder = function (item)
        {
            var currentDOM = fl.getDocumentDOM();
            var library = currentDOM.library;
            
            library.selectNone();
            library.duplicateItem(item.name);
            
            var itemCopy = library.getSelectedItems()[0];
            
            library.addNewItem("folder", DragonBones.TEXTURE_AUTO_CREATE);
            library.moveToFolder(DragonBones.TEXTURE_AUTO_CREATE, itemCopy.name, true);
            
            library.editItem(itemCopy.name);
            var timeline = itemCopy.timeline;
            
            //搜索所有图层，把补间转换为关键帧，去掉嵌套的文件夹，标记需要删除的图层
            var folderObjArr = [];
            var currFolderLayer = null;
            var junkLayerMark = [];
            var junkLayerCount = 0;
            var layerID = -1;
            for each (var layer in timeline.layers)
            {
                layerID++;
                if (currFolderLayer)
                {
                    if (folderObj)
                    {
                    }
                    else
                    {
                        var folderObj = {folderLayerID:layerID - 1 - junkLayerCount, layerIdArr:[]};
                    }
                }
                else
                {
                    if (layer.layerType == "folder")
                    {
                        //找到一个文件夹
                        currFolderLayer = layer;
                    }
                    continue;
                }
                
                if (layer.parentLayer)
                {
                    if (layer.parentLayer == currFolderLayer)
                    {
                        if (layer.layerType == "folder")
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
                    if (layer.layerType == "folder")
                    {
                        //找到一个文件夹
                        currFolderLayer = layer;
                    }
                    continue;
                }
                
                switch (layer.layerType)
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
                if (layer.animationType == "none")
                {
                    //无补间，或传统补间，或形状补间
                    for (var i = layer.frames.length; i--; )
                    {
                        var startFrameIndex = layer.frames[i].startFrame;
                        var frame = layer.frames[i];
                        
                        var hasPlayOnceOrLoopGraphic = false;
                        for each (var element in frame.elements)
                        {
                            if (
                                element.libraryItem &&
                                element.libraryItem.timeline &&
                                element.libraryItem.timeline.frameCount > 1 &&
                                element.symbolType == "graphic" &&
                                (
                                    element.loop=="play once" ||
                                    element.loop=="loop"
                                )
                            )
                            {
                                hasPlayOnceOrLoopGraphic=true;
                                break;
                            }
                        }

                        if (hasPlayOnceOrLoopGraphic)
                        {
                            timeline.convertToKeyframes(startFrameIndex + 1, i + 1);
                        }
                        else
                        {
                            switch (frame.tweenType)
                            {
                                case "motion":
                                case "shape":
                                    if (startFrameIndex != i)
                                    {
                                        timeline.convertToKeyframes(startFrameIndex + 1, i + 1);
                                    }
                                    break;
                                
                                case "none":
                                    //
                                    break;
                            }
                        }
                        i = startFrameIndex;
                    }
                }
                else
                {
                    //motion object 或 IK pose 全部转成关键帧
                    //timeline.convertToKeyframes(0, layer.frames.length);//失败
                    for (var i = layer.frames.length; i--; )
                    {
                        timeline.convertToKeyframes(i);
                    }
                }
            }

            if (folderObj)
            {
                folderObjArr.push(folderObj);
                folderObj = null;
            }
            
            for (var layerID = junkLayerMark.length; --layerID >= 0; )
            {
                if (junkLayerMark[layerID])
                {
                    timeline.deleteLayer(layerID);
                }
            }
            junkLayerMark = null;
            
            for (var folderObjID = folderObjArr.length; folderObjID--; )
            {
                for each (var layer in timeline.layers)
                {
                    layer.locked = true;
                    layer.visible = true;
                }
                
                var folderObj = folderObjArr[folderObjID];
                
                //获取最大帧数
                var maxFrameCount = -1;
                for each (var layerID in folderObj.layerIdArr)
                {
                    var layer = timeline.layers[layerID];
                    layer.locked = false;
                    if (maxFrameCount < layer.frames.length)
                    {
                        maxFrameCount = layer.frames.length;
                    }
                }
                
                //根据最大帧数补齐不足最大帧数的图层
                for each (var layerID in folderObj.layerIdArr)
                {
                    var layer = timeline.layers[layerID];
                    if (layer.frames.length < maxFrameCount)
                    {
                        timeline.currentLayer = layerID;
                        timeline.convertToBlankKeyframes(layer.frames.length);
                        //没这句有时候不行很奇怪
                        timeline.currentLayer = layerID;
                        timeline.insertFrames(maxFrameCount - layer.frames.length, false, layer.frames.length);
                    }
                }
                
                //标记公共关键帧
                var keyFrameIdMark = new Array();
                for each (var layerID in folderObj.layerIdArr)
                {
                    var layer = timeline.layers[layerID];
                    for (var i = maxFrameCount; i--; )
                    {
                        i = layer.frames[i].startFrame;
                        keyFrameIdMark[i] = true;
                    }
                }
                
                //同步关键帧
                for each (var layerID in folderObj.layerIdArr)
                {
                    var layer = timeline.layers[layerID];
                    timeline.currentLayer = layerID;
                    for (var i = keyFrameIdMark.length; i--; )
                    {
                        if (keyFrameIdMark[i])
                        {
                            var frame = layer.frames[i];
                            if (frame.startFrame == i)
                            {
                            }
                            else
                            {
                                timeline.convertToKeyframes(i);
                            }
                        }
                    }
                }
                
                var folderLayer = timeline.layers[folderObj.folderLayerID];
                folderLayer.locked = false;
                folderLayer.layerType = "normal";
                timeline.currentLayer = folderObj.folderLayerID;
                if (folderLayer.length < maxFrameCount)
                {
                    timeline.insertFrames(maxFrameCount - folderLayer.length, false, folderLayer.length);
                }
                
                for (var i = keyFrameIdMark.length; i--; )
                {
                    if (keyFrameIdMark[i])
                    {
                        timeline.currentLayer = folderObj.folderLayerID;
                        timeline.convertToKeyframes(i);
                        timeline.currentFrame = i;
                        currentDOM.selectAll();
                        if (currentDOM.selection.length)
                        {
                            currentDOM.group();
                            var itemName = item.name + "_" + folderLayer.name + "_" + (i + 1);
                            if (library.itemExists(itemName))
                            {
                                var itemID = 1;
                                while (library.itemExists(itemName + "(" + (++ itemID) + ")"))
                                {
                                }
                                itemName += "(" + itemID + ")";
                            }
                            currentDOM.convertToSymbol("movie clip", itemName, "top left");
                            
                            var element = currentDOM.selection[0];
                            itemName = element.libraryItem.name;
                            timeline.currentLayer = folderObj.folderLayerID;
                            var frame = timeline.layers[folderObj.folderLayerID].frames[i];
                            frame.labelType = "name";
                            frame.name = DragonBones.NO_EASING;
                            library.addItemToDocument({x:0, y:0}, itemName);
                            currentDOM.selection[0].matrix = element.matrix;
                            
                            currentDOM.library.moveToFolder(DragonBones.TEXTURE_AUTO_CREATE, itemName, true);
                        }
                    }
                }
                
                for (var i = folderObj.layerIdArr.length; i--; )
                {
                    var layerID = folderObj.layerIdArr[i];
                    timeline.deleteLayer(layerID);
                }
            }
            return itemCopy;
        };

        //Write armatureConnection data by armatureName
        DragonBones.changeArmatureConnection = function (domID, armatureName, armatureXMLData)
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
            
            armatureXMLData = XML(armatureXMLData).toXMLString();
            armatureXMLData = armatureXMLData.split("&lt;").join("<");
            armatureXMLData = armatureXMLData.split("&gt;").join(">");
            
            armatureItem.addData(DragonBones.ARMATURE_DATA, "string", armatureXMLData);
            //Jsfl api Or Flash pro bug
            armatureItem.symbolType = "graphic";
            armatureItem.symbolType = "movie clip";
            
            return true;
        };

        DragonBones.changeAnimation = function (domID, armatureName, animationName, animationXMLData)
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
            
            animationXMLData = XML(animationXMLData).toXMLString();
            animationXMLData = animationXMLData.split("&lt;").join("<");
            animationXMLData = animationXMLData.split("&gt;").join(">");
            animationXML = XML(animationXMLData);
            
            var animationsXMLInItem;
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

        DragonBones.selectBoneAndChildren = function()
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
            
        DragonBones._frameChangedHandler = function()
        {
            DragonBones.selectBoneAndChildren();
        }


        function selectBoneAndChildren(boneSymbol, timeline, armatureXML)
        {
            if (armatureXML)
            {
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

        function getAnimationXML(armatureXML, animationName, armatureItem, duration, fadeInTime, noAutoTween)
        {
            var animationXML = armatureXML[DragonBones.ANIMATION].(@name == animationName)[0];
            if (!animationXML)
            {
                var playTimes = 1;
                var scale = 1;
                var tweenEasing = NaN;
                var autoTween = 1;
                
                var animationXMLInItem;
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
                
                if (!animationXMLInItem && duration == 2)
                {
                    playTimes = 0;
                    scale = 5;
                    tweenEasing = 2;
                }
                
                if (noAutoTween)
                {
                    autoTween = 0;
                }
                
                animationXML = 
                    <{DragonBones.ANIMATION} 
                        {DragonBones.A_NAME}={animationName}
                        {DragonBones.A_FADE_IN_TIME}={fadeInTime}
                        {DragonBones.A_DURATION}={duration}
                        {DragonBones.A_SCALE}={Utils.formatNumber(scale)}
                        {DragonBones.A_LOOP}={playTimes}
                        {DragonBones.A_AUTO_TWEEN}={Utils.formatNumber(autoTween)}
                        {DragonBones.A_TWEEN_EASING}={Utils.formatNumber(tweenEasing)}/>;

                Utils.appendXML(armatureXML, animationXML);
            }
            
            return animationXML;
        }

        function getTimelineXML(animationXML, timelineName, armatureItem)
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

        function getBoneXML(armatureXML, boneName, frameXML, frameStart)
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

        function addBoneXML(armatureXML, boneName, frameXML, frameStart, armatureXMLInItem)
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

        function getSlotXML(armatureXML, boneXML, slotName, armatureItem, zOrder)
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

        function getDisplayXML(slotXML, displayName, transform, armatureItem, isArmature)
        {
            var displayXML = slotXML[DragonBones.DISPLAY].(@name == displayName)[0];
            if (!displayXML)
            {
                displayXML = 
                    <{DragonBones.DISPLAY} 
                        {DragonBones.A_NAME}={displayName}
                        {DragonBones.A_TYPE}={isArmature? DragonBones.V_ARMATURE: DragonBones.V_IMAGE}
                    >
                        <{DragonBones.TRANSFORM}
                            {DragonBones.A_X}={Utils.formatNumber(transform.x) || 0}
                            {DragonBones.A_Y}={Utils.formatNumber(transform.y) || 0}
                            {DragonBones.A_SKEW_X}={Utils.formatNumber(transform.skewX) || 0}
                            {DragonBones.A_SKEW_Y}={Utils.formatNumber(transform.skewY) || 0}
                            {DragonBones.A_SCALE_X}={Utils.formatNumber(transform.scaleX) || 1}
                            {DragonBones.A_SCALE_Y}={Utils.formatNumber(transform.scaleY) || 1}/>
                    </{DragonBones.DISPLAY}>;

                Utils.appendXML(slotXML, displayXML);
            }
            return displayXML;
        }


        DragonBones.prototype._generateAnimation = function (mainFrame, layers, noLabelChildArmature)
        {
            var currentDOM = fl.getDocumentDOM();
            var start = mainFrame.frame.startFrame;
            var duration = mainFrame.duration;
            var frameNameList = DragonBones.formatObjectName(mainFrame.frame);
            var animationName = frameNameList[2];
            var noAutoEasing = frameNameList[1] == DragonBones.NO_EASING;
            var animationXML = getAnimationXML(this._currentArmatureXML, animationName, this._currentArmatureItem, duration, noLabelChildArmature? 0: this._defaultFadeInTime, noAutoEasing);

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

            currentDOM.library.editItem(this._currentArmatureItem.name);
            currentDOM.getTimeline().currentFrame = 0;

            var boneNameList = [];
            var boneZOrderMap = {};
            var zOrderList = [];
            var changeFrames = [];
            
            for (var i = 0, l = layers.length; i < l; i ++)
            {
                var layer = layers[i];
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
                        currentDOM.library.editItem(this._currentArmatureItem.name);
                        var timeline = currentDOM.getTimeline();
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
                            currentDOM.library.editItem(this._currentArmatureItem.name);
                            var timeline = currentDOM.getTimeline();
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
                    var boneSymbol = Utils.filter(elements, null, ["instanceType", "bitmap", "symbol"])[0];
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
                        timelineXML = getTimelineXML(animationXML, boneName, this._currentArmatureItem);
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
                            timelineXML = getTimelineXML(animationXML, boneName, this._currentArmatureItem);
                        }
                        boneList[k] = zOrder;
                    }

                    //
                    var frameXML = this._generateFrame(frame, boneName, boneSymbol, i, noAutoEasingFrame, frameStart);
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
            }
            
            //还原
            if (changeFrames.length > 0)
            {
                currentDOM.library.editItem(this._currentArmatureItem.name);
                timeline = currentDOM.getTimeline();
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

        DragonBones.prototype._generateFrame = function (frame, boneName, boneSymbol, zOrder, noAutoEasing, frameStart)
        {
            var boneSymbolItem = boneSymbol.libraryItem;
            var transform = boneSymbol.getTransformationPoint();

            var isChildArmature = false;
            var isArmature = false;
            var isGraphicBone = false;
            var hasDisplay = false;

            switch (boneSymbol.instanceType)
            {
                case "bitmap":
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
                    var isChildArmature = boneSymbol.symbolType == "movie clip";
                    var isArmature = Boolean(DragonBones.isArmatureItem(boneSymbolItem, isChildArmature));

                    if (isArmature)
                    {
                        hasDisplay = true;
                    }
                    else if (
                        boneSymbol.symbolType == "graphic" &&
                        boneSymbolItem.timeline.frameCount > 1 &&
                        (boneSymbol.loop == "single frame" || boneSymbol.loop == "play once")    // TODO: multiply slots
                    )
                    {
                        isGraphicBone = true;
                        hasDisplay = (boneSymbol.width > 0 || boneSymbol.height > 0);
                    }
                    else
                    {
                        hasDisplay = (boneSymbol.width > 0 || boneSymbol.height > 0);
                    }
                    break;

                default:
                    return null;
            }

            //
            var displayMap = this._displayRegistPositionMap[boneName];
            if (!displayMap)
            {
                displayMap = {};
                this._displayRegistPositionMap[boneName] = displayMap;
            }
            var displayRegistPosition = displayMap[boneSymbolItem.name];
            if (!displayRegistPosition)
            {
                displayRegistPosition = {x:transform.x, y:transform.y};
                displayMap[boneSymbolItem.name] = displayRegistPosition;
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
                    {DragonBones.A_SCALE_X}={Utils.formatNumber(transform.scaleX)}
                    {DragonBones.A_SCALE_Y}={Utils.formatNumber(transform.scaleY)}
                    {DragonBones.A_PIVOT_X}={Utils.formatNumber(transform.pivotOffsetX)}
                    {DragonBones.A_PIVOT_Y}={Utils.formatNumber(transform.pivotOffsetY)}/>;
            frameXML.appendChild(transformXML);

            //
            var boneXML = getBoneXML(this._currentArmatureXML, boneName, frameXML, frameStart);
            if (!boneXML)
            {
                boneXML = addBoneXML(
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
            var slotXML = getSlotXML(this._currentArmatureXML, boneXML, boneName, this._currentArmatureItem, zOrder);
            if (boneSymbol.blendMode != "normal")
            {
                slotXML.@[DragonBones.A_BLEND_MODE] = boneSymbol.blendMode;
            }

            //
            if (hasDisplay)
            {
                if (boneSymbol.instanceType != "bitmap")
                {
                    var aO = boneSymbol.colorAlphaAmount;
                    var rO = boneSymbol.colorRedAmount;
                    var gO = boneSymbol.colorGreenAmount;
                    var bO = boneSymbol.colorBlueAmount;
                    var aM = boneSymbol.colorAlphaPercent;
                    var rM = boneSymbol.colorRedPercent;
                    var gM = boneSymbol.colorGreenPercent;
                    var bM = boneSymbol.colorBluePercent;
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

                //
                if (boneSymbol.visible === false)
                {
                    frameXML.@[DragonBones.A_HIDE] = 1;
                }

                //
                if (frameStart > 0 && boneSymbol.hasPersistentData(DragonBones.SCALE_OFFSET_DATA))
                {
                    var scaleOffset = boneSymbol.getPersistentData(DragonBones.SCALE_OFFSET_DATA);
                    frameXML.@[DragonBones.A_SCALE_X_OFFSET] = Utils.formatNumber(scaleOffset[0]);
                    frameXML.@[DragonBones.A_SCALE_Y_OFFSET] = Utils.formatNumber(scaleOffset[1]);
                }

                //
                var symbolNameList = DragonBones.formatObjectName(boneSymbolItem, true);
                var displayName = symbolNameList[2];
                var displayXML = null;
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

                    displayXML = getDisplayXML(slotXML, displayName, displayTransform, this._currentArmatureItem, isArmature);

                    if (isArmature && symbolNameList[1] != DragonBones.NO_EASING)
                    {
                        if (this._armatureList.indexOf(displayName) < 0)
                        {
                            this._armatureList.push(displayName);
                            this._armatureList.push(true);
                        }
                    }
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
                var frameNameList = DragonBones.getNameParameters(frame.name);

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
                    if (frameNameList[2] == DragonBones.SLOT)
                    {
                        var blendMode = jsonData[DragonBones.A_BLEND_MODE];
                        if (blendMode)
                        {
                            slotXML.@[DragonBones.A_BLEND_MODE] = blendMode;
                        }
                    }
                }
            }

            // sound
            if (frame.soundName)
            {
                frameXML.@[DragonBones.A_SOUND] = frame.soundLibraryItem.linkageClassName || frame.soundName;
            }
            
            return frameXML;
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
                                {DragonBones.A_SCALE_X}={Utils.formatNumber(areaShape.scaleX)}
                                {DragonBones.A_SCALE_Y}={Utils.formatNumber(areaShape.scaleY)}
                                {DragonBones.A_PIVOT_X}={-Utils.formatNumber(areaShape.transformX - (x - width * 0.5))}
                                {DragonBones.A_PIVOT_Y}={-Utils.formatNumber(areaShape.transformY - (y - height * 0.5))}/>

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

                var sound = frame.soundName && (frame.soundLibraryItem.linkageClassName || frame.soundName);
                if (sound)
                {
                    frameXML.@[DragonBones.A_SOUND] = sound;
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
                    displaySymbol = Utils.filter(elements, null, ["instanceType", "bitmap", "symbol"])[0];
                }
                
                var itemFolderName = null;
                if (!displaySymbol)
                {

                }
                
                if (displaySymbol)
                {
                    var displaySymbolItem = displaySymbol.libraryItem;
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
                        var slotXML = getSlotXML(this._currentArmatureXML, boneXML, layer.name, this._currentArmatureItem, mainSlotZOrder + layerIndex * 0.05);
                        if (displaySymbol.blendMode != "normal")
                        {
                            slotXML.@[DragonBones.A_BLEND_MODE] = displaySymbol.blendMode;
                        }
                        getDisplayXML(slotXML, displayName, transform, this._currentArmatureItem, isArmature);
                    }
                    else
                    {
                        mainDisplayXML = getDisplayXML(mainSlotXML, displayName, transform, this._currentArmatureItem, isArmature);
                    }

                    if (isArmature && symbolNameList[1] != DragonBones.NO_EASING)
                    {
                        if (this._armatureList.indexOf(displayName) < 0)
                        {
                            this._armatureList.push(displayName);
                            this._armatureList.push(true);
                        }
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

        DragonBones.prototype._generateArmature = function (armatureName, isChildArmature)
        {
            var currentDOM = fl.getDocumentDOM();
            if (this._xml[DragonBones.ARMATURE].(@name == armatureName)[0])
            {
                return false;
            }

            if (armatureName.indexOf(DragonBones.NO_EASING) >= 0)
            {
                return false;
            }

            fl.showIdleMessage(false);
            
            this._displayRegistPositionMap = {};
            this._currentArmatureItem = Utils.filter(currentDOM.library.items, null, ["name", armatureName])[0];
            
            if (this._isMergeLayersInFolder && DragonBones.canMergeLayersInFolder(this._currentArmatureItem))
            {
                this._currentArmatureItem = DragonBones.mergeLayersInFolder(this._currentArmatureItem);
            }
            
            this._currentArmatureXML = 
                <{DragonBones.ARMATURE} {DragonBones.A_NAME}={armatureName}>
                    <{DragonBones.SKIN} {DragonBones.A_NAME}="default"/>
                </{DragonBones.ARMATURE}>;

            this._xml.appendChild(this._currentArmatureXML);

            if (this.hasEventListener(DragonBones.ARMATURE))
            {
                this.dispatchEvent(new events.Event(DragonBones.ARMATURE, ["start", this._currentArmatureItem, this._currentArmatureXML]));
            }
            
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

            if (this.hasEventListener(DragonBones.ARMATURE))
            {
                this.dispatchEvent(new events.Event(DragonBones.ARMATURE, ["end", this._currentArmatureItem, this._currentArmatureXML]));
            }

            fl.showIdleMessage(true);

            return true;
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
            
            var items;
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

        DragonBones.prototype.getArmature = function (domID, armatureName, dragonBonesData, defaultFadeInTime, isMergeLayersInFolder)
        {
            var currentDOM = Utils.getDOM(domID, true);
            if (!currentDOM)
            {
                return DragonBones.ERROR_NO_ACTIVE_DOM;
            }

            dragonBonesData = XML(dragonBonesData).toXMLString();
            dragonBonesData = dragonBonesData.split("&lt;").join("<");
            dragonBonesData = dragonBonesData.split("&gt;").join(">");
            dragonBonesData = XML(dragonBonesData);

            this._defaultFadeInTime = defaultFadeInTime || 0;
            this._isMergeLayersInFolder = Boolean(isMergeLayersInFolder);
            this._xml = <{DragonBones.DRAGON_BONES}/>;
            this._armatureList = [armatureName, false];

            while (this._armatureList.length > 0)
            {
                var eachArmatureName = this._armatureList.shift();
                var isChild = this._armatureList.shift();

                if (eachArmatureName != armatureName && dragonBonesData[DragonBones.ARMATURE].(@name == eachArmatureName)[0])
                {
                    continue;
                }
                this._generateArmature(eachArmatureName, isChild);
            }

            //
            delete this._xml[DragonBones.ARMATURE][DragonBones.BONE].@[DragonBones.A_START];
            
            var dragonBonesXMLURL = DragonBones.getConfigPath() + "/" + DragonBones.DRAGON_BONES_XML;
            FLfile.write(dragonBonesXMLURL, this._xml.toXMLString());
            this._xml = null;

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
            if (!textureItem)
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
                        bitmapItem.linkageExportForAS = true;
                        bitmapItem.linkageClassName = bitmapItem.name;
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