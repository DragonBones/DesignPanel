var dragonBonesExtensions;
(function (dragonBonesExtensions)
{


    var Utils = utils.Utils;
    var DragonBones = dragonBones.DragonBones;


    function getRotationListFromBoneItemTimeline(boneItem)
    {
        var boneRotationList = [];
        for each (var frame in boneItem.timeline.layers[0].frames)
        {
            if (frame.labelType == "comment")
            {
                var rotation = frame.name.split("_");
                rotation[0] = Number(rotation[0]);
                rotation[1] = Number(rotation[1]);
                rotation[2] = Number(rotation[2]);
                boneRotationList[frame.startFrame] = rotation;
            }
        }
        return boneRotationList;
    }

    function formatDistance(d)
    {
        if (d > Math.PI - 2)
        {
            return (Math.PI - 2) * 2 - d;
        }
        return d;
    }

    function getResult(n)
    {
        var result = n - Math.sin(n) * sgn(Math.cos(n));
        if (n > Math.PI * 0.5)
        {
            result -= 2;
        }
        else if (n < -Math.PI * 0.5)
        {
            result += 2;
        }
        return result;
    }

    function sgn(n)
    {
        if (n > 0)
        {
            return 1;
        }
        if (n < 0)
        {
            return -1;
        }
        return 0;
    }

    function getBoneScale(currentFrameRotation, currentBoneRotation, kMin, kMax)
    {
        var cos = Math.abs(Math.cos(currentBoneRotation[1] * Utils.ANGLE_TO_RADIAN));
        var scaleX = Math.abs(Math.cos(currentFrameRotation[1] * Utils.ANGLE_TO_RADIAN) / cos);

        scaleX = Math.max(Math.min(scaleX, 1 + kMax * cos), 1 - kMin * cos);
        return [scaleX, 0];
    }

    function importBoneTextures(armatureName, boneName, boneTextureList)
    {
        var currentDOM = fl.getDocumentDOM();
        
        var boneItemName = armatureName + "_" + "folder" + "/" + boneName;
        
        if (!currentDOM.library.itemExists(boneItemName))
        {
            var noExportItemName = armatureName + "_" + "folder" + "/" + DragonBones.NO_EASING + boneName;
            if (currentDOM.library.itemExists(noExportItemName))
            {
                boneItemName = noExportItemName;
            }
            else
            {
                currentDOM.library.addNewItem("graphic", boneItemName);
            }
        }

        currentDOM.library.editItem(boneItemName);
        
        var timeline = currentDOM.getTimeline();
        timeline.currentLayer = timeline.layers.indexOf(Utils.filter(timeline.layers, null, ["layerType", "normal"])[0]);
        timeline.removeFrames(0, timeline.frameCount);
        
        var layer = timeline.layers[timeline.currentLayer];
        var frameIndex = 0;
        for each (var textureFile in boneTextureList)
        {
            var moveList = textureFile["move"];
            var angleList = textureFile["angle"];
            
            var rotationX = Number(angleList[0]);
            var rotationY = Number(angleList[1]);
            var rotationZ = Number(angleList[2]);
            
            timeline.convertToBlankKeyframes(frameIndex, frameIndex);
            timeline.currentFrame = frameIndex;
            
            currentDOM.importFile(textureFile.url);
            var frame = layer.frames[frameIndex];
            
            frame.name = rotationX + "_" + rotationY + "_" + rotationZ;
            frame.labelType = "comment";
            
            var symbol = frame.elements[0];
            
            symbol.libraryItem.allowSmoothing = true;
            symbol.libraryItem.compressionType = "lossless";
            
            if (moveList.length == 2)
            {
                symbol.x = Number(moveList[0]);
                symbol.y = Number(moveList[1]);
            }
            else
            {
                symbol.x = -Math.round(symbol.width * 0.5);
                symbol.y = -Math.round(symbol.height * 0.5);
            }
            
            currentDOM.library.selectNone();
            currentDOM.library.selectItem(textureFile.name);
            currentDOM.library.deleteItem(armatureName + "_" + "folder" + "/" + "textures" + "/" + boneName + "_" + frameIndex);
            currentDOM.library.renameItem(boneName + "_" + frameIndex);
            currentDOM.library.moveToFolder(armatureName + "_" + "folder" + "/" + "textures");
            
            frameIndex ++;
        }
    }

    function importArmatureTextures(textureFolderURL, armatureName)
    {
        var currentDOM = fl.getDocumentDOM();
        
        if (!currentDOM.library.itemExists(armatureName + "_" + "folder"))
        {
            currentDOM.library.newFolder(armatureName + "_" + "folder");
        }

        if (!currentDOM.library.itemExists(armatureName + "_" + "folder" + "/" + "textures"))
        {
            currentDOM.library.newFolder(armatureName + "_" + "folder" + "/" + "textures");
        }

        var textureFileList = Utils.filterFileList(textureFolderURL, /\.(png)$/i, 1);
        var boneTextureListMap = {};
        for each (var textureFile in textureFileList)
        {
            var textureName = textureFile.name;
            if (textureName.indexOf("_offset_") <= 0)
            {
                continue;
            }
            var paramsList = textureName.split(".")[0].split("_offset_");
            var moveList = paramsList.pop().split("_");
            
            paramsList = paramsList[0].split("_angle_");
            var angleList = paramsList.pop().split("_");
            var boneName = paramsList[0];
            var boneTextureList = boneTextureListMap[boneName];
            if (!boneTextureList)
            {
                boneTextureListMap[boneName] = boneTextureList = [];
            }
            textureFile["move"] = moveList;
            textureFile["angle"] = angleList;
            boneTextureList.push(textureFile);
        }
        
        for (var boneName in boneTextureListMap)
        {
            var boneTextureList = boneTextureListMap[boneName];
            importBoneTextures(armatureName, boneName, boneTextureList);
        }
    }

    function updateBoneFrame(boneSymbol, boneRotationList)
    {
        if (!boneSymbol || !boneSymbol.hasPersistentData(DragonBones.FRAME_DATA) || !boneRotationList || boneRotationList.length <= 0)
        {
            return;
        }

        var transformXML = XML(boneSymbol.getPersistentData(DragonBones.FRAME_DATA));
        var rotationX = Number(transformXML.@[DragonBones.A_ROTATION_X]);
        var rotationY = Number(transformXML.@[DragonBones.A_ROTATION_Y]);
        var rotationZ = Number(transformXML.@[DragonBones.A_ROTATION_Z]);
        
        var minD = 2048;
        var currentBoneRotation = null;

        for each (var rotation in boneRotationList)
        {
            if (rotation)
            {
                var dX = formatDistance(Math.abs(getResult(rotationX * Utils.ANGLE_TO_RADIAN) - getResult(rotation[0] * Utils.ANGLE_TO_RADIAN)));
                var dY = formatDistance(Math.abs(getResult(rotationY * Utils.ANGLE_TO_RADIAN) - getResult(rotation[1] * Utils.ANGLE_TO_RADIAN)));
                
                var d = dX * dX + dY * dY;
                if (minD > d)
                {
                    minD = d;
                    currentBoneRotation = rotation;
                }
            }
        }
        if (currentBoneRotation)
        {
            boneSymbol.firstFrame = boneRotationList.indexOf(currentBoneRotation);
        }
    }

    function updateBoneScaleAndScaleOffset(boneSymbol, currentBoneRotation, prevSymbol, prevBoneRotation, prevScale, updateScale)
    {
        if (!boneSymbol || !boneSymbol.hasPersistentData(DragonBones.FRAME_DATA) || (boneSymbol.width < 1 && boneSymbol.height < 1) || !currentBoneRotation)
        {
            return null;
        }

        var transformXML = XML(boneSymbol.getPersistentData(DragonBones.FRAME_DATA));
        var rotationX = Number(transformXML.@[DragonBones.A_ROTATION_X]);
        var rotationY = Number(transformXML.@[DragonBones.A_ROTATION_Y]);
        var rotationZ = Number(transformXML.@[DragonBones.A_ROTATION_Z]);
        
        var currentFrameRotation = [rotationX, rotationY, rotationZ];
        var currentScale = getBoneScale(currentFrameRotation, currentBoneRotation, 0.35, 0.65);
        if (updateScale)
        {
            boneSymbol.scaleX = currentScale[0];
        }

        if (prevSymbol && prevBoneRotation && prevScale && (prevSymbol.width >= 1 || prevSymbol.height >= 1) && prevSymbol.firstFrame != boneSymbol.firstFrame)
        {
            var prevCurrentScale = getBoneScale(currentFrameRotation, prevBoneRotation, 0.35, 0.65);
            prevCurrentScale[0] -= boneSymbol.scaleX - prevScale[0] + prevSymbol.scaleX;
            boneSymbol.setPersistentData(DragonBones.SCALE_OFFSET_DATA, "doubleArray", prevCurrentScale);
        }
        else
        {
            boneSymbol.removePersistentData(DragonBones.SCALE_OFFSET_DATA);
        }

        return currentScale;
    }

    function offsetContainerContents(containerSymbol, x, y)
    {
        var timeline = containerSymbol.libraryItem.timeline;
        //
        for each (var layer in timeline.layers)
        {
            for each (var frame in layer.frames)
            {
                for each (var element in frame.elements)
                {
                    element.x += x;
                    element.y += y;
                }
            }
        }
    }

    function swapBoneSymbol(layer, frame, args)
    {
        var currentDOM = fl.getDocumentDOM();
        var swapBoneItemNameDic = args[0];
        if (!swapBoneItemNameDic)
        {
            swapBoneItemNameDic = args[0] = {};
        }

        var boneSymbol = Utils.filter(frame.elements, null, ["instanceType", "symbol", "bitmap"])[0];

        if (boneSymbol)
        {
            var swapBoneItemName = swapBoneItemNameDic[layer.mame];
            if (swapBoneItemName)
            {
                currentDOM.selectNone();
                boneSymbol.selected = true;
                currentDOM.swapElement(swapBoneItemName);
            }
            else
            {
                swapBoneItemNameDic[layer.mame] = boneSymbol.libraryItem.name;
            }
        }
    }

    function modifyBoneContentsPonsition(layer, frame, args)
    {
        var currentDOM = fl.getDocumentDOM();
        var modifiedBoneItems = args[1];
        var bonePositionOffsetDic = args[2];
        if (!modifiedBoneItems)
        {
            modifiedBoneItems = args[1] = [];
        }

        if (!bonePositionOffsetDic)
        {
            bonePositionOffsetDic = args[2] = {};
        }

        var boneSymbol = Utils.filter(frame.elements, null, ["symbolType", "movie clip", "graphic"])[0];

        if (boneSymbol)
        {
            var boneItem = boneSymbol.libraryItem;
            if (modifiedBoneItems.indexOf(boneItem.name) < 0)
            {
                modifiedBoneItems.push(boneItem.name);

                var x = boneSymbol.x;
                var y = boneSymbol.y;
                var transformX = boneSymbol.transformX;
                var transformY = boneSymbol.transformY;

                if (x == transformX && y == transformY)
                {
                    return;
                }

                var offset = {x: transformX, y: transformY};
                offset = fl.Math.transformPoint(fl.Math.invertMatrix(boneSymbol.matrix), offset);
                bonePositionOffsetDic[boneItem.name] = offset;
                offsetContainerContents(boneSymbol, -offset.x, -offset.y);

                boneSymbol.x = boneSymbol.transformX;
                boneSymbol.y = boneSymbol.transformY;
                boneSymbol.setTransformationPoint({x:0, y:0});
            }
            else
            {
                var offset = bonePositionOffsetDic[boneItem.name];
                offset = fl.Math.transformPoint(boneSymbol.matrix, offset);
                boneSymbol.x = offset.x;
                boneSymbol.y = offset.y;
                //
                boneSymbol.setTransformationPoint({x:0, y:0});
            }
        }
    }

    function modifyBoneTransform(layer, frame, args)
    {
        if (layer.locked || !layer.visible)
        {
            return;
        }

        var boneSymbol = Utils.filter(frame.elements, null, ["instanceType", "symbol", "bitmap"])[0];
        if (boneSymbol)
        {
            var modifyType = args[0];
            var transformType = args[1];
            var valueX = args[2];
            var valueY = args[3];

            switch (modifyType)
            {
                case 0:
                    // set
                    switch (transformType)
                    {
                        case "translate":
                            boneSymbol.x = valueX || 0;
                            boneSymbol.y = valueY || 0;
                            break;

                        case "scale":
                            boneSymbol.scaleX = valueX || 0;
                            boneSymbol.scaleY = valueY || 0;
                            break;

                        case "skew":
                            boneSymbol.skewX = valueX || 0;
                            boneSymbol.skewY = valueY || 0;
                            break;
                    }
                    break;

                case 1:
                    // offset
                    switch (transformType)
                    {
                        case "translate":
                            boneSymbol.x += valueX || 0;
                            boneSymbol.y += valueY || 0;
                            break;

                        case "scale":
                            boneSymbol.scaleX += valueX || 0;
                            boneSymbol.scaleY += valueY || 0;
                            break;

                        case "skew":
                            boneSymbol.skewX += valueX || 0;
                            boneSymbol.skewY += valueY || 0;
                            break;
                    }
                    break;

                case 2:
                    // scale
                    switch (transformType)
                    {
                        case "translate":
                            boneSymbol.x *= valueX || 0;
                            boneSymbol.y *= valueY || 0;
                            break;

                        case "scale":
                            boneSymbol.scaleX *= valueX || 0;
                            boneSymbol.scaleY *= valueY || 0;
                            break;

                        case "skew":
                            boneSymbol.skewX *= valueX || 0;
                            boneSymbol.skewY *= valueY || 0;
                            break;
                    }
                    break;
            }

            boneSymbol.removePersistentData(DragonBones.SCALE_OFFSET_DATA);
        }
    }

    function traceBoneUsedFrame(layer, frame, args)
    {
        if (layer.locked || !layer.visible)
        {
            return;
        }

        var boneSymbol = Utils.filter(frame.elements, null, ["instanceType", "symbol"])[0];
        if (boneSymbol)
        {
            trace(boneSymbol.libraryItem.name, frame.startFrame + 1, boneSymbol.firstFrame + 1);
        }
    }

    function moveBonesToParentPosition(layer, frame, args)
    {
        if (layer.locked || !layer.visible)
        {
            return;
        }

        var currentDOM = fl.getDocumentDOM();

        var boneSymbol = Utils.filter(frame.elements, null, ["instanceType", "symbol", "bitmap"])[0];
        if (boneSymbol)
        {
            var boneDataMap = args[0];
            if (!boneDataMap)
            {
                boneDataMap = {};
                args[0] = boneDataMap;
                boneDataMap.parentLayer = null;
                boneDataMap.position = null;
                boneDataMap.childrenLayerMap = {};

                var timeline = currentDOM.getTimeline();
                var armatureItem = timeline.libraryItem;
                if (armatureItem.hasData(DragonBones.ARMATURE_DATA))
                {
                    var layerMap = {};
                    for each (var eachLayer in timeline.layers)
                    {
                        layerMap[eachLayer.name] = eachLayer;
                    }

                    var armatureXML = XML(armatureItem.getData(DragonBones.ARMATURE_DATA));
                    for each (var boneXML in armatureXML[DragonBones.BONE])
                    {
                        if (boneXML.@[DragonBones.A_NAME] == boneName)
                        {
                            var boneParent = boneXML.@[DragonBones.A_PARENT];
                            boneDataMap.parentLayer = layerMap[boneParent];
                            break;
                        }
                        else if (boneXML.@[DragonBones.A_PARENT] == boneName)
                        {
                            var childName = boneXML.@[DragonBones.A_NAME];
                            var childLayer = layerMap[childName];
                            if (childLayer && !childLayer.locked && childLayer.visible)
                            {
                                boneDataMap.childrenLayerMap[childName] = childLayer;
                            }
                        }
                    }
                }
            }

            if (!boneDataMap.parentLayer)
            {
                return;
            }

            var boneName = layer.name;
            if (boneDataMap.position)
            {
                for each (var parentFrame in Utils.toUniqueArray(boneDataMap.parentLayer.layers))
                {
                    if (parentFrame.startFrame == frame.startFrame)
                    {
                        var boneParentSymbol = Utils.filter(parentFrame.elements, null, ["instanceType", "symbol", "bitmap"])[0];
                        if (boneParentSymbol)
                        {
                            var matrix = boneParentSymbol.matrix;
                            var position = Math.transformPoint(matrix, boneDataMap.position);
                            currentDOM.selectNone();
                            boneSymbol.selected = true;

                            for each (var childLayer in boneDataMap.childrenLayerMap)
                            {
                                for each (var childFrame in childLayer.frames)
                                {
                                    if (childFrame.startFrame == frame.startFrame)
                                    {
                                        var boneChildSymbol = Utils.filter(childFrame.elements, null, ["instanceType", "symbol", "bitmap"])[0];
                                        if (boneChildSymbol)
                                        {
                                            boneChildSymbol.selected = true;
                                        }
                                    }
                                }
                            }

                            currentDOM.moveSelectionBy({x:position.x - boneSymbol.x, y:position.y - boneSymbol.y});
                        }
                        break;
                    }
                }
            }
            else
            {
                for each (var parentFrame in Utils.toUniqueArray(boneDataMap.parentLayer.layers))
                {
                    if (parentFrame.startFrame == frame.startFrame)
                    {
                        var boneParentSymbol = Utils.filter(parentFrame.elements, null, ["instanceType", "symbol", "bitmap"])[0];
                        if (boneParentSymbol)
                        {
                            boneDataMap.position = {x:boneSymbol.x, y:boneSymbol.y};
                            var matrix = boneParentSymbol.matrix;
                            matrix = Math.invertMatrix(matrix);
                            boneDataMap.position = Math.transformPoint(matrix, boneDataMap.position);
                        }
                        break;
                    }
                }
            }
        }
    }

    function changeSelectedBoneFrame(layer, frame, args)
    {

    }

    function changeSelectedBoneToSingleFrame(layer, frame, args)
    {
        if (layer.locked || !layer.visible)
        {
            return;
        }

        var boneSymbol = Utils.filter(frame.elements, null, ["instanceType", "symbol", "bitmap"])[0];
        if (boneSymbol)
        {
            if (args[0] == undefined)
            {
                if (args[1] != layer)
                {
                    args[1] = layer;
                    frameIndex = boneSymbol.firstFrame;
                    args[2] = frameIndex;
                }
                else
                {
                    frameIndex = Number(args[2]);
                    boneSymbol.firstFrame = frameIndex;
                }
            }
            else
            {
                frameIndex = Number(args[0]);
                boneSymbol.firstFrame = frameIndex;
            }
        }
    }

    function updateArmatureBonesFrameAndScale(layer, frame, args)
    {
        if (layer.locked || !layer.visible)
        {
            return;
        }

        var updateFrame = args[0];
        var updateScale = args[1];
        var loopResult = args[2];

        if (!loopResult)
        {
            args[2] = loopResult = {};
        }

        if (loopResult.layer != layer)
        {
            loopResult.layer = layer;
            loopResult.boneRotationList = null;
            loopResult.currentBoneRotation = null;
            loopResult.prevSymbol = null;
            loopResult.prevBoneRotation = null;
            loopResult.prevScale = null;
        }

        var boneSymbol = Utils.filter(frame.elements, null, ["symbolType", "graphic"])[0];
        if (boneSymbol)
        {
            if (!loopResult.boneRotationList)
            {
                loopResult.boneRotationList = getRotationListFromBoneItemTimeline(boneSymbol.libraryItem);
            }

            if (updateFrame)
            {
                updateBoneFrame(boneSymbol, loopResult.boneRotationList);
            }
            
            loopResult.currentBoneRotation = loopResult.boneRotationList[boneSymbol.firstFrame];
            loopResult.prevScale = updateBoneScaleAndScaleOffset(boneSymbol, loopResult.currentBoneRotation, loopResult.prevSymbol, loopResult.prevBoneRotation, loopResult.prevScale, updateScale);
            loopResult.prevBoneRotation = loopResult.currentBoneRotation;
            loopResult.prevSymbol = boneSymbol;
        }
    }

    /**
     * set the selected bones frame transform translate/skew/scale by specified value.
     * @param   {String}    type:["translate", "scale", "skew"]
     * @param   {Number}    value
     */
    dragonBonesExtensions.setBonesTransform = function(type, valueX, valueY)
    {
        var currentDOM = fl.getDocumentDOM();
        if (!currentDOM)
        {
            return DragonBones.ERROR_NO_ACTIVE_DOM;
        }

        Utils.forEachSelected(3, modifyBoneTransform, [0, type, valueX, valueY]);

        return true;
    }

    /**
     * offset the selected bones frame transform translate/skew/scale by specified value.
     * @param   {String}    type:["translate", "scale", "skew"]
     * @param   {Number}    value
     */
    dragonBonesExtensions.offsetBonesTransform = function(type, valueX, valueY)
    {
        var currentDOM = fl.getDocumentDOM();
        if (!currentDOM)
        {
            return DragonBones.ERROR_NO_ACTIVE_DOM;
        }

        Utils.forEachSelected(3, modifyBoneTransform, [1, type, valueX, valueY]);

        return true;
    }

    /**
     * scale the selected bones frame transform translate/skew/scale by specified value.
     * @param   {String}    type:["translate", "scale", "skew"]
     * @param   {Number}    value
     */
    dragonBonesExtensions.scaleBonesTransform = function(type, valueX, valueY)
    {
        var currentDOM = fl.getDocumentDOM();
        if (!currentDOM)
        {
            return DragonBones.ERROR_NO_ACTIVE_DOM;
        }

        Utils.forEachSelected(3, modifyBoneTransform, [2, type, valueX, valueY]);
        
        return true;
    }

    dragonBonesExtensions.swapBonesSymbol = function ()
    {
        var currentDOM = fl.getDocumentDOM();
        if (!currentDOM)
        {
            return DragonBones.ERROR_NO_ACTIVE_DOM;
        }
        Utils.forEachSelected(3, swapBoneSymbol, []);
    }

    dragonBonesExtensions.modifyBonesContentsPonsition = function ()
    {
        var currentDOM = fl.getDocumentDOM();
        if (!currentDOM)
        {
            return DragonBones.ERROR_NO_ACTIVE_DOM;
        }
        Utils.forEachSelected(3, modifyBoneContentsPonsition, []);

        return true;
    }

    dragonBonesExtensions.moveBonesToParentPosition = function()
    {
        var currentDOM = fl.getDocumentDOM();
        if (!currentDOM)
        {
            return DragonBones.ERROR_NO_ACTIVE_DOM;
        }

        Utils.forEachSelected(3, moveBonesToParentPosition, []);

        return true;
    }

    dragonBonesExtensions.changeSelectedBonesToSingleFrame = function(frameIndex)
    {
        var currentDOM = fl.getDocumentDOM();
        if (!currentDOM)
        {
            return DragonBones.ERROR_NO_ACTIVE_DOM;
        }

        Utils.forEachSelected(3, changeSelectedBoneToSingleFrame, [frameIndex]);

        return true;
    }

    dragonBonesExtensions.changeSelectedBonesFrames = function()
    {
        var currentDOM = fl.getDocumentDOM();
        if (!currentDOM)
        {
            return DragonBones.ERROR_NO_ACTIVE_DOM;
        }

        //Utils.forEachSelected(3, changeSelectedBoneFrame);

        var timeline = currentDOM.getTimeline();
        var currentFrame = timeline.currentFrame;
        var selectedFrames = timeline.getSelectedFrames();
        for (var i = 0, l = selectedFrames.length; i < l; i += 3)
        {
            var layerIndex = selectedFrames[i];
            var frameStart = selectedFrames[i + 1];
            var frameDuration = selectedFrames[i + 2] - frameStart;
            var layer = timeline.layers[layerIndex];
            var keyFrames = Utils.toUniqueArray(layer.frames.slice(frameStart, frameStart + frameDuration));

            var changeFrames = [];
            for each (var frame in keyFrames)
            {
                var boneSymbol = Utils.filter(frame.elements, null, ["symbolType", "graphic"])[0];

                if (!boneSymbol)
                {
                    continue;
                }

                if (changeFrames.indexOf(boneSymbol.firstFrame) < 0)
                {
                    changeFrames.push(boneSymbol.firstFrame);
                }
            }

            if (changeFrames.length < 2)
            {
                continue;
            }

            for each (var frame in keyFrames)
            {
                var boneSymbol = Utils.filter(frame.elements, null, ["symbolType", "graphic"])[0];
                if (!boneSymbol)
                {
                    continue;
                }

                if (frame.startFrame < currentFrame)
                {
                    boneSymbol.firstFrame = changeFrames[0];
                }
                else if (frame.startFrame >= currentFrame)
                {
                    boneSymbol.firstFrame = changeFrames[1];
                }
            }
        }

        dragonBonesExtensions.updateArmatureBonesFrameAndScale(false, true);

        return true;
    }

    dragonBonesExtensions.traceBoneUsedFrame = function ()
    {
        var currentDOM = fl.getDocumentDOM();
        if (!currentDOM)
        {
            return DragonBones.ERROR_NO_ACTIVE_DOM;
        }
        Utils.forEachSelected(3, traceBoneUsedFrame);
    }

    dragonBonesExtensions.updateArmatureBonesFrameAndScale = function (updateFrame, updateScale)
    {    
        var currentDOM = fl.getDocumentDOM();
        if (!currentDOM)
        {
            return DragonBones.ERROR_NO_ACTIVE_DOM;
        }
        var timeline = currentDOM.getTimeline();
        var armatureItem = timeline.libraryItem;
        if (armatureItem)
        {
            fl.showIdleMessage(false);
            Utils.forEachSelected(3, updateArmatureBonesFrameAndScale, [updateFrame, updateScale]);
            fl.showIdleMessage(true);
        }

        return true;
    }

    dragonBonesExtensions.import3DTextures = function()
    {
        var currentDOM = fl.getDocumentDOM();
        if (!currentDOM)
        {
            return DragonBones.ERROR_NO_ACTIVE_DOM;
        }

        var folderURL = fl.browseForFolderURL("Select a folder that contains textures.");

        if (folderURL)
        {
            var armatureName = currentDOM.getTimeline().libraryItem ? currentDOM.getTimeline().libraryItem.name : currentDOM.name.split(".")[0];
            armatureName = prompt("Input Armature Name", armatureName);
            if (armatureName)
            {        
                importArmatureTextures(folderURL, armatureName);
                return true;
            }
        }
        
        return false;
    }

    dragonBonesExtensions.importFrameTextures = function()
    {
        var currentDOM = fl.getDocumentDOM();
        if (!currentDOM)
        {
            return DragonBones.ERROR_NO_ACTIVE_DOM;
        }

        var texturesFolderURL = fl.browseForFolderURL("Select a folder that contains textures.");
        if (!texturesFolderURL)
        {
            return false;
        }

        var textureFileList = Utils.filterFileList(texturesFolderURL, /\.(png)$/i, 1);

        var itemName = prompt("Input Item Name", currentDOM.getTimeline().libraryItem ? currentDOM.getTimeline().libraryItem.name : currentDOM.name.split(".")[0]);

        if (itemName)
        {
            if (!currentDOM.library.itemExists(itemName))
            {
                currentDOM.library.addNewItem("graphic", itemName);
                if (!currentDOM.library.itemExists(itemName + "_" + "folder"))
                {
                    currentDOM.library.newFolder(itemName + "_" + "folder");
                }
            }
            currentDOM.library.editItem(itemName);
        }
        
        var timeline = currentDOM.getTimeline();
        timeline.currentLayer = timeline.layers.indexOf(Utils.filter(timeline.layers, null, ["layerType", "normal"])[0]);
        timeline.removeFrames(0, timeline.frameCount);
        
        var layer = timeline.layers[timeline.currentLayer];
        var frameIndex = 0;
        
        for each (var textureFile in textureFileList)
        {
            timeline.convertToBlankKeyframes(frameIndex, frameIndex);
            timeline.currentFrame = frameIndex;
            currentDOM.importFile(textureFile.url);

            var frame = layer.frames[frameIndex];
            var symbol = frame.elements[0];
            symbol.libraryItem.allowSmoothing = true;
            symbol.libraryItem.compressionType = "lossless";

            var textureName = textureFile.name;
            if (textureName.indexOf("_offset_") > 0)
            {
                var paramsList = textureName.split(".")[0].split("_offset_");
                var moveList = paramsList.pop().split("_");
                if (moveList.length == 2)
                {
                    symbol.x = Number(moveList[0]);
                    symbol.y = Number(moveList[1]);
                }
            }
            else
            {
                symbol.x = -Math.round(symbol.width * 0.5);
                symbol.y = -Math.round(symbol.height * 0.5);
            }

            if (itemName)
            {
                currentDOM.library.selectNone();
                currentDOM.library.selectItem(textureName);
                currentDOM.library.deleteItem(itemName + "_" + "folder" + "/" + "texture_" + frameIndex);
                currentDOM.library.renameItem("texture_" + frameIndex);
                currentDOM.library.moveToFolder(itemName + "_" + "folder");
            }
            frameIndex ++;
        }

        return true;
    }


}
)(dragonBonesExtensions || (dragonBonesExtensions = {}));