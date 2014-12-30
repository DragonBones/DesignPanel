package core.utils
{
	public class DataFormatUtils
	{
		public static function xmlToObject(xml:XML, listNames:Vector.<String> = null):Object
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
				result = ComplexString.simpleType(xml.toString());
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
				result[attributeName] = ComplexString.simpleType(attributeXML.toString());
			}
			return result;
		}
		
		public static function objectToXML(object:*, rootName:String = "root"):XML
		{
			var xml:XML = <xml/>;
			_objectToXML(xml, rootName, object);
			return xml.children()[0];
		}
		
		private static function _objectToXML(xml:XML, name:String, value:*):void
		{
			
			switch(value)
			{
				case true:
				case false:
				case null:
				case undefined:
					xml.@[name]=value;
					break;
				default:
					if(
						value is Number ||
						value is String
					)
					{
						xml.@[name]=value;
					}
					else
					{
						if(value is Array)
						{
							for each(var subValue:* in value)
							{
								switch(subValue)
								{
									case true:
									case false:
									case null:
									case undefined:
										xml.appendChild(<{name}>{subValue}</{name}>);
										break;
									default:
										if(
											subValue is Number ||
											subValue is String
										)
										{
											xml.appendChild(<{name}>{subValue}</{name}>);
										}
										else
										{
											if(subValue is Array)
											{
												var node:XML = <{name}/>;
												xml.appendChild(node);
												_objectToXML(node,name,subValue);
											}
											else
											{
												_objectToXML(xml,name,subValue);
											}
										}
										break;
								}
							}
						}
						else
						{
							node = <{name}/>;
							xml.appendChild(node);
							for(name in value)
							{
								_objectToXML(node, name, value[name]);
							}
						}
					}
					break;
			}
		}
	}
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
	
	public static function simpleType(value:Object):Object 
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
}