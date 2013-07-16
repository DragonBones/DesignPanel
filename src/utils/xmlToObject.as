package utils
{
	public function xmlToObject(xml:XML, listNames:Vector.<String> = null):Object
	{
		if (xml == null)
		{
			return null;
		}
		
		var result:Object;
		var isSimpleType:Boolean = false;
		
		if (xml.children().length() > 0 && xml.hasSimpleContent())
		{
			isSimpleType = true;
			result = simpleType(xml.toString());
		} 
		else if (xml.hasComplexContent())
		{
			result = {};
			for each(var childXML:XML in xml.elements())
			{
				var objectName:String = childXML.localName();
				var object:Object = xmlToObject(childXML, listNames);
				var existing:Object = result[objectName];
				if (existing != null)
				{
					if (existing is Array)
					{
						existing.push(object);
					} 
					else 
					{
						existing = [existing];
						existing.push(object);
						result[objectName] = existing;
					}
				}
				else if(listNames && listNames.indexOf(objectName) >= 0)
				{
					result[objectName] = [object];
				}
				else
				{
					result[objectName] = object;
				}
			}
		}
		
		for each(var attributeXML:XML in xml.attributes())
		{
			/*if (attribute == "xmlns" || attribute.indexOf("xmlns:") != -1)
			{
				continue;
			}*/
			if (result == null)
			{
				result = {};
			}
			if (isSimpleType && !(result is ComplexString))
			{
				result = new ComplexString(result.toString());
				isSimpleType = false;
			}
			var attributeName:String = attributeXML.localName();
			result[attributeName] = simpleType(attributeXML.toString());
		}
		return result;
	}
}

function simpleType(value:Object):Object 
{
	switch(value) 
	{
		case "NaN":
			return NaN;
		case "true":
			return true;
		case "false":
			return false;
		case "null":
			return null;
		case "undefined":
			return undefined;
	}
	if (isNaN(Number(value))) 
	{
		return value;
	}
	return Number(value);
}

dynamic class ComplexString
{
	public var value:String;
	
	public function ComplexString(val:String)
	{
		value = val;
	}
	
	public function toString():String 
	{
		return value;
	}
	
	public function valueOf():Object 
	{
		return simpleType(value);
	}
}