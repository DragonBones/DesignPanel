var dragonBonesExtensions;
(function (dragonBonesExtensions)
{


    var Utils = utils.Utils;
    var DragonBones = dragonBones.DragonBones;


    var A_FRAME_TYPE = "frameType";
    var V_FRAME_TYPE_VALUE_KEY_FRAME = "keyFrame";
    var V_FRAME_TYPE_VALUE_TIMELINE_FRAME = "timelineFrame";
    var V_FRAME_TYPE_VALUE_DISPLAY_FRAME = "displayFrame";
    var V_FRAME_TYPE_VALUE_FRAME = "frame";
    

    function sortTimelineList(animationXML)
    {
        var timelineList = [];

        for each (var timelineXML in animationXML[DragonBones.TIMELINE])
        {
            timelineList.push(timelineXML);
        }

        if (timelineList[0][DragonBones.FRAME][0].@[DragonBones.A_Z_ORDER].length() > 0)
        {
            timelineList.sort(sortTimeline1);
        }
        else
        {
            timelineList.sort(sortTimeline2);
        }

        return timelineList;
    }

    function sortTimeline1(timeline1, timeline2)
    {
        return Number(timeline1[DragonBones.FRAME][0].@[DragonBones.A_Z_ORDER]) > Number(timeline2[DragonBones.FRAME][0].@[DragonBones.A_Z_ORDER])? 1: -1;
    }

    function sortTimeline2(timeline1, timeline2)
    {
        return Number(timeline1[DragonBones.FRAME][DragonBones.TRANSFORM][0].@[DragonBones.A_Z]) > Number(timeline2[DragonBones.FRAME][DragonBones.TRANSFORM][0].@[DragonBones.A_Z])? 1: -1;
    }

    dragonBonesExtensions.createArmatureAnimation = function (armatureName, animationName, animationXMLData, armatureXMLData, isFirstData)
    {
        var currentDOM = fl.getDocumentDOM();
        if (!currentDOM)
        {
            return DragonBones.ERROR_NO_ACTIVE_DOM;
        }
        
        animationXMLData = XML(animationXMLData).toXMLString();
        animationXMLData = animationXMLData.split("&lt;").join("<");
        animationXMLData = animationXMLData.split("&gt;").join(">");
        animationXML = XML(animationXMLData);
        if (animationXML[DragonBones.TIMELINE].length() < 1)
        {
            return false;
        }

        if (isFirstData)
        {
            armatureName = prompt("Input Armature Name", armatureName);
            if (!armatureName)
            {
                return false;
            }
        }
        
        var armatureItem = Utils.filter(currentDOM.library.items, null, ["name", armatureName])[0];
        var createNewArmatureItem = false;
        if (!armatureItem)
        {
            createNewArmatureItem = true;
            currentDOM.library.addNewItem("movie clip", armatureName);
        }
        else if (!DragonBones.isArmatureItem(armatureItem))
        {

        }
        else
        {
            
        }
        
        if (!currentDOM.library.itemExists(armatureName + "_" + "folder"))
        {
            currentDOM.library.newFolder(armatureName + "_" + "folder");
        }
        
        if (armatureXMLData)
        {
            DragonBones.changeArmatureConnection(currentDOM.id, armatureName, armatureXMLData)
        }
        
        currentDOM.library.editItem(armatureName);

        var animationDuration = Number(animationXML.@[DragonBones.A_DURATION]);
        
        var timeline = currentDOM.getTimeline();
        var startFrame = timeline.frameCount;
        
        var exLayerMap = {};
        
        for each (var layer in timeline.layers)
        {
            exLayerMap[layer.name] = layer;
            layer.locked = false;
            layer.visible = true;
        }
        
        var point = {x:0, y:0};

        var timelineList = sortTimelineList(animationXML);

        for (var i = 0, l = timelineList.length; i < l; i ++)
        {
            var timelineXML = timelineList[i];
            var timelineName = timelineXML.@[DragonBones.A_NAME];
            var layer = exLayerMap[timelineName];
            if (layer)
            {
                timeline.currentLayer = timeline.layers.indexOf(layer);
                delete exLayerMap[timelineName];
            }
            else
            {
                timeline.currentLayer = timeline.addNewLayer(timelineName, "normal", false);
                layer = timeline.layers[timeline.currentLayer];
            }
            
            var boneItemName = armatureName + "_" + "folder" + "/" + timelineName;
            if (!currentDOM.library.itemExists(boneItemName))
            {
                var noExportItemName = armatureName + "_" + "folder" + "/" + DragonBones.NO_EASING + timelineName;
                if (currentDOM.library.itemExists(noExportItemName))
                {
                    boneItemName = noExportItemName;
                }
                else
                {
                    currentDOM.library.addNewItem("graphic", boneItemName);
                }
            }
            
            var frameIndex = startFrame;
            var frame;
            for each (var frameXML in timelineXML[DragonBones.FRAME])
            {
                frame = layer.frames[frameIndex];
                var frameType = frameXML.@[A_FRAME_TYPE];
                if (frameType == V_FRAME_TYPE_VALUE_FRAME)
                {
                    frameIndex += Number(frameXML.@[DragonBones.A_DURATION]);
                    continue;
                }
                
                if (!frame || frame.startFrame != frameIndex)
                {
                    timeline.convertToBlankKeyframes(frameIndex, frameIndex);
                }
                
                frame = layer.frames[frameIndex];
                
                if (frameType == V_FRAME_TYPE_VALUE_TIMELINE_FRAME)
                {
                    frame.name = V_FRAME_TYPE_VALUE_TIMELINE_FRAME;
                    frame.labelType = "comment";
                }
                else if (frameType == V_FRAME_TYPE_VALUE_DISPLAY_FRAME)
                {
                    frame.name = V_FRAME_TYPE_VALUE_DISPLAY_FRAME;
                    frame.labelType = "comment";
                }
                else if (frameType == V_FRAME_TYPE_VALUE_KEY_FRAME)
                {
                    
                }
                else
                {
                    
                }
                
                timeline.currentFrame = frameIndex;
                var transformXML = frameXML[DragonBones.TRANSFORM][0];
                var boneSymbol = Utils.addItemToDocument(currentDOM, boneItemName);
                if (boneSymbol)
                {
                    boneSymbol.symbolType = "graphic";
                    boneSymbol.loop = "single frame";
                    boneSymbol.x = Number(transformXML.@[DragonBones.A_X]);
                    boneSymbol.y = Number(transformXML.@[DragonBones.A_Y]);

                    boneSymbol.setTransformationPoint(point);
                    
                    var skewX = Number(transformXML.@[DragonBones.A_SKEW_X]);
                    var skewY = Number(transformXML.@[DragonBones.A_SKEW_Y]);
                    if (skewX || skewY)
                    {
                        boneSymbol.skewX = skewX;
                        boneSymbol.skewY = skewY;
                        if (boneSymbol.skewX * skewX < 0)
                        {
                            boneSymbol.skewX = skewX;
                        }
                        if (boneSymbol.skewY * skewY < 0)
                        {
                            boneSymbol.skewY = skewY;
                        }
                    }
                    boneSymbol.scaleX = Number(transformXML.@[DragonBones.A_SCALE_X]);
                    boneSymbol.scaleY = Number(transformXML.@[DragonBones.A_SCALE_Y]);
                    boneSymbol.setPersistentData(DragonBones.FRAME_DATA, "string", transformXML.toXMLString());
                }
                else
                {
                    
                }
                frameIndex += Number(frameXML.@[DragonBones.A_DURATION]);
            }

            if (frame && frame.startFrame + frame.duration < startFrame + animationDuration)
            {
                timeline.insertFrames(1, false, startFrame + animationDuration);
            }
        }

        var mainLayer;

        for each (var layer in exLayerMap)
        {
            if (DragonBones.isMainLayer(layer))
            {
                mainLayer = layer;
                break;
            }
            else if (!mainLayer)
            {
                mainLayer = layer;
            }
        }

        if (!mainLayer) 
        {
            timeline.currentLayer = 0;
            timeline.addNewLayer("Main Layer", "normal", true);
            mainLayer = timeline.layers[0];
        }

        timeline.currentLayer = timeline.layers.indexOf(mainLayer);

        timeline.insertKeyframe(startFrame);
        if (animationDuration > 1)
        {
            timeline.insertFrames(animationDuration - 1, false, startFrame + 1);
        }

        var mainFrame = mainLayer.frames[startFrame];
        mainFrame.name = animationName;
        mainFrame.labelType = "name";

        if (createNewArmatureItem)
        {
            timeline.currentFrame = 0;
            timeline.removeFrames();
        }

        return armatureName;
    }


}
)(dragonBonesExtensions || (dragonBonesExtensions = {}));