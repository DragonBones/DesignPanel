var __extends = this.__extends || function (d, b) 
{
    for (var p in b)
    {
        if (b.hasOwnProperty(p))
        {
            d[p] = b[p];
        }
    }
    function __()
    { 
        this.constructor = d;
    }
    __.prototype = b.prototype;
    d.prototype = new __();
};


function trace()
{
    fl.outputPanel.trace(Array.slice.call(this, arguments).join(', '));
}

function assert(condition, message) 
{
    if (!condition) 
    {
        message = message || "Assertion failed";
        if (typeof Error !== "undefined") 
        {
            throw new Error(message);
        }
        throw message;
    }
}

var utils;
(function (utils)
{

    var Utils = (function () 
    {
        function Utils() 
        {
        }

        Utils.ANGLE_TO_RADIAN = Math.PI / 180;
        Utils.RADIAN_TO_ANGLE = 180 / Math.PI;

        var escapeable = /["\\\x00-\x1f\x7f-\x9f]/g;
        var meta = {
            '\b': '\\b',
            '\t': '\\t',
            '\n': '\\n',
            '\f': '\\f',
            '\r': '\\r',
            '"': '\\"',
            '\\': '\\\\'
        };

        function quoteString(string) 
        {
            if (string.match(escapeable)) 
            {
                return '"' + string.replace(escapeable, function(a) 
                {
                    var c = meta[a];
                    if (typeof c === 'string') 
                    {
                        return c;
                    }
                    c = a.charCodeAt();
                    return '\\u00' + Math.floor(c / 16).toString(16) + (c % 16).toString(16);
                }) + '"';
            }

            return '"' + string + '"';
        };

        Utils.formatNumber = function (number, decimals)
        {
            if (
                decimals == undefined || 
                isNaN(decimals)
            )
            {
                decimals = 2;
            }
            var round = Math.pow(10, decimals);
            return Math.round(number * round) / round;
        };

        Utils.formatAngle = function (number)
        {
            number %= 360;
            if (number > 180)
            {
                number -= 360;
            }
            if (number < -180)
            {
                number += 360;
            }
            return number;
        };

        Utils.formatRadion = function (number)
        {
            if (number > Math.PI)
            {
                number -= Math.PI * 2;
            }
            if (number < -Math.PI)
            {
                number += Math.PI * 2;
            }
            return number;
        };

        Utils.getNumberFromObject = function (object, property, defaultValue)
        {
            assert(object && (object instanceof Object));

            var numberString;
            if (object instanceof XML)
            {
                var attributeXML = object.@[property][0];
                if (attributeXML != undefined)
                {
                    numberString = String(attributeXML);
                }
                else
                {
                    return Number(defaultValue);
                }
            }
            else if (object instanceof Array)
            {
                if (object.length > Number(property))
                {
                    numberString = String(object[property]);
                }
                else
                {
                    return Number(defaultValue);
                }
            }
            else
            {
                if (property in object)
                {
                    numberString = String(object[property]);
                }
                else
                {
                    return Number(defaultValue);
                }
            }

            switch (numberString)
            {
                case "NaN":
                case "":
                case "false":
                case "null":
                case "undefined":
                    return NaN;

                default:
                    return Number(numberString);
            }
        };

        Utils.toUniqueArray = function (elements, property)
        {
            assert(elements instanceof Array);
            var filtered = [];
            if (property)
            {
                var properties = [];
                for each (var element in elements)
                {
                    var value = element[property];
                    if (properties.indexOf(value) < 0)
                    {
                        properties.push(value);
                        filtered.push(element);
                    }
                }
            }
            else
            {
                for each (var element in elements)
                {
                    if (filtered.indexOf(element) < 0)
                    {
                        filtered.push(element);
                    }
                }
            }
            return filtered;
        };

        Utils.filter = function (elements, property)
        {
            elements = Utils.toUniqueArray(elements, property);
            if (arguments.length > 2)
            {
                var filteredElements = [];
                for (var i = 2, l = arguments.length; i < l; i ++)
                {
                    var match = arguments[i];
                    if (
                        !(match instanceof Array) || 
                        match.length < 1 || 
                        (match[0] === false && match.length < 2)
                    )
                    {
                        assert(false);
                    }

                    if (match[0] === false)
                    {
                        match.shift();
                        var matchProperty = match.shift();
                        for each (var element in elements)
                        {
                            if (match.length == 0)
                            {
                                if (!(matchProperty in element))
                                {
                                    filteredElements.push(element);
                                }
                            }
                            else if (matchProperty in element)
                            {
                                if (match.indexOf(element[matchProperty]) < 0)
                                {
                                    filteredElements.push(element);
                                }
                            }
                        }
                    }
                    else
                    {
                        var matchProperty = match.shift();
                        for each (var element in elements)
                        {
                            if (matchProperty in element)
                            {
                                if (match.length == 0 || match.indexOf(element[matchProperty]) >= 0)
                                {
                                    filteredElements.push(element);
                                }
                            }
                        }
                    }
                }
                return filteredElements;
            }
            return elements;
        };

        //0:selectedItems, 1:selectedElements, 2:selectedLayers, 3:selectedFrames
        Utils.forEachSelected = function (selectedType, callback, args)
        {
            var currentDOM = fl.getDocumentDOM();
            if (!currentDOM)
            {
                return;
            }

            switch (selectedType)
            {
                case 0:
                    var selectedItems = currentDOM.library.getSelectedItems().concat();
                    for each (var item in selectedItems)
                    {
                        if (callback(item, args) === false)
                        {
                            break;
                        }
                    }
                    break;

                case 1:
                    var selectedElements = currentDOM.selection.concat();
                    for each (var element in selectedElements)
                    {
                        if (callback(element, args) === false)
                        {
                            break;
                        }
                    }
                    break;

                case 2:
                    var selectedLayers = currentDOM.getTimeline().getSelectedLayers().concat();
                    for each (var layer in selectedLayers)
                    {
                        if (callback(layer, args) === false)
                        {
                            break;
                        }
                    }
                    break;

                case 3:
                    var timeline = currentDOM.getTimeline();
                    var selectedFrames = timeline.getSelectedFrames().concat();
                    for (var i = 0, l = selectedFrames.length; i < l; i += 3)
                    {
                        var layerIndex = selectedFrames[i];
                        var frameStart = selectedFrames[i + 1];
                        var frameDuration = selectedFrames[i + 2] - frameStart;
                        var layer = timeline.layers[layerIndex];

                        var keyFrames = Utils.toUniqueArray(layer.frames.slice(frameStart, frameStart + frameDuration));

                        for each (var frame in keyFrames)
                        {
                            if (callback(layer, frame, args) === false)
                            {
                                break;
                            }
                        }
                    }
                    break;
            }
        };

        Utils.appendXML = function (parentXML, childXML, isBefore, isPrepend)
        {
            var xmlList = parentXML[childXML.localName()];
            var lastXML = (xmlList && xmlList.length() > 0)? xmlList[xmlList.length() - 1]: null;
            if (lastXML)
            {
                if (isBefore)
                {
                    parentXML.insertChildBefore(lastXML, childXML);
                }
                else
                {
                    parentXML.insertChildAfter(lastXML, childXML);
                }
            }
            else if(isPrepend)
            {
                parentXML.prependChild(childXML);
            }
            else
            {
                parentXML.appendChild(childXML);
            }
        };

        Utils.getDOM = function (domID, activeDOM)
        {
            var dom;
            if (domID)
            {
                dom = fl.findDocumentDOM(Number(domID));
                if (activeDOM && dom && fl.getDocumentDOM() != dom)
                {
                    fl.setActiveWindow(dom);
                }
            }
            else
            {
                dom = fl.getDocumentDOM();
            }

            return dom;
        };
        
        Utils.addItemToDocument = function (document, itemName)
        {
            var helpPoint = {x:0, y:0};
            var tryAddTimes = 0;
            var added = false;
            var instance;
            do
            {
                added = document.library.addItemToDocument(helpPoint, itemName);
                instance = document.selection[0];
                tryAddTimes ++;
            }
            while ((!added || !instance) && tryAddTimes < 10);
            
            if (instance)
            {
                return instance;
            }
            trace("Add item to document Error!", itemName);
            return null;
        };

        Utils.filterFileList = function (folderURL, fileURLTester, maxLevel, level)
        {
            if (typeof maxLevel === "undefined")
            {
                maxLevel = 0;
            }
            if (typeof level === "undefined")
            {
                level = 0;
            }

            var fileFilteredList = [];
            var fileList = FLfile.listFolder(folderURL, "files");
            for each (var file in fileList)
            {
                if (fileURLTester.test(file))
                {
                    fileFilteredList.push({name:file, url:folderURL + "/" + file, folder:folderURL});
                }
            }

            if (maxLevel > 0 && level >= maxLevel - 1)
            {
            }
            else
            {
                var folderList = FLfile.listFolder(folderURL, "directories");
                for each (var folder in folderList)
                {
                    fileFilteredList = fileFilteredList.concat(Utils.filterFileList(folderURL + "/" + folder, fileURLTester, maxLevel, level + 1));
                }
            }

            return fileFilteredList;
        };

        Utils.decodeJSON = function (jsonString)
        {
            return eval('(' + jsonString + ')');
        }

        /**
         * JSON
         * @overview    JSON functionality for JSFL
         *
         * jQuery JSON Plugin v2.3-edge (2011-09-25)
         *
         * @author      Brantley Harris, 2009-2011
         * @author      Timo Tijhof, 2011
         * @source      This plugin is heavily influenced by MochiKit's serializeJSON, which is
         *              copyrighted 2005 by Bob Ippolito.
         * @source      Brantley Harris wrote this plugin. It is based somewhat on the JSON.org
         *              website's http://www.json.org/json2.js, which proclaims:
         *              "NO WARRANTY EXPRESSED OR IMPLIED. USE AT YOUR OWN RISK.", a sentiment that
         *              I uphold.
         * @license     MIT License <http://www.opensource.org/licenses/mit-license.php>
         */
        Utils.encodeJSON = function (object)
        {
            if (object === null) 
            {
                return 'null';
            }

            var type = typeof object;

            if (type === 'undefined') 
            {
                return undefined;
            }
            else if (type === 'number' || type === 'boolean') 
            {
                return '' + object;
            }
            else if (type === 'string') 
            {
                return quoteString(object);
            }
            else if (type === 'object') 
            {
                if (object.constructor === Date) 
                {
                    var month = object.getUTCMonth() + 1;
                    var day = object.getUTCDate();
                    var year = object.getUTCFullYear();
                    var hours = object.getUTCHours();
                    var minutes = object.getUTCMinutes();
                    var seconds = object.getUTCSeconds();
                    var milli = object.getUTCMilliseconds();

                    if (month < 10) 
                    {
                        month = '0' + month;
                    }

                    if (day < 10) 
                    {
                        day = '0' + day;
                    }

                    if (hours < 10) 
                    {
                        hours = '0' + hours;
                    }

                    if (minutes < 10) 
                    {
                        minutes = '0' + minutes;
                    }

                    if (seconds < 10) 
                    {
                        seconds = '0' + seconds;
                    }

                    if (milli < 100) 
                    {
                        milli = '0' + milli;
                    }

                    if (milli < 10) 
                    {
                        milli = '0' + milli;
                    }

                    return '"' + year + '-' + month + '-' + day + 'T' + hours + ':' + minutes + ':' + seconds + '.' + milli + 'Z"';
                }
                else if (object.constructor === Array) 
                {
                    var result = [];
                    for (var i = 0, l = object.length; i < l; ++i)
                    {
                        result.push(Utils.encodeJSON(object[i]) || 'null');
                    }
                    return '[' + result.join(',') + ']';
                }

                var pairs = [];
                for (var k in object)
                {
                    if (!Object.prototype.hasOwnProperty.call(object, k))
                    {
                        continue;
                    }

                    var name = null;
                    type = typeof k;
                    if (type === 'number') 
                    {
                        name = '"' + k + '"';
                    } 
                    else if (type === 'string') 
                    {
                        name = quoteString(k);
                    } 
                    else 
                    {
                        continue;
                    }

                    type = typeof object[k];
                    if (type === 'function' || type === 'undefined') 
                    {
                        continue;
                    }

                    var value = Utils.encodeJSON(object[k]);
                    pairs.push(name + ':' + value);
                }

                return '{' + pairs.join(',') + '}';
            }

            return 'null';
        }

        return Utils;
    })();
    utils.Utils = Utils;


}
)(utils || (utils = {}));