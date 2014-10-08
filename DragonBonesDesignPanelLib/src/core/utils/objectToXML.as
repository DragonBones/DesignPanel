package core.utils
{
	public function objectToXML(object:*, rootName:String = "root"):XML
	{
		var xml:XML = <xml/>;
		_objectToXML(xml, rootName, object);
		return xml.children()[0];
	}
}

function _objectToXML(xml:XML, name:String, value:*):void
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