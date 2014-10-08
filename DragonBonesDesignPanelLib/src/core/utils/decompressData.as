package core.utils
{
	import flash.utils.ByteArray;
	
	import dragonBones.objects.DecompressedData;
	import dragonBones.utils.BytesType;
		
	public function decompressData(bytes:ByteArray):DecompressedData
	{
		var dataType:String = BytesType.getType(bytes);
		switch (dataType)
		{
			case BytesType.SWF:
			case BytesType.PNG:
			case BytesType.JPG:
			case BytesType.ATF:
				try
				{
					var bytesCopy:ByteArray = new ByteArray();
					bytesCopy.writeBytes(bytes);
					bytes = bytesCopy;
					
					bytes.position = bytes.length - 4;
					var strSize:int = bytes.readInt();
					var position:uint = bytes.length - 4 - strSize;
					
					var dataBytes:ByteArray = new ByteArray();
					dataBytes.writeBytes(bytes, position, strSize);
					dataBytes.uncompress();
					bytes.length = position;
					
					var dragonBonesData:Object;
					if(checkBytesTailisXML(dataBytes))
					{
						dragonBonesData = XML(dataBytes.readUTFBytes(dataBytes.length));
					}
					else
					{
						dragonBonesData = dataBytes.readObject();
					}
					
					bytes.position = bytes.length - 4;
					strSize = bytes.readInt();
					position = bytes.length - 4 - strSize;
					
					dataBytes.length = 0;
					dataBytes.writeBytes(bytes, position, strSize);
					dataBytes.uncompress();
					bytes.length = position;
					
					var textureAtlasData:Object;
					if(checkBytesTailisXML(dataBytes))
					{
						textureAtlasData = XML(dataBytes.readUTFBytes(dataBytes.length));
					}
					else
					{
						textureAtlasData = dataBytes.readObject();
					}
				}
				catch (e:Error)
				{
					throw new Error("Data error!");
				}
				
				var decompressedData:DecompressedData = new DecompressedData(dragonBonesData, textureAtlasData, bytes);
				decompressedData.textureBytesDataType = dataType;
				return decompressedData;
				
			case BytesType.ZIP:
				throw new Error("Can not decompress zip!");
				
			default: 
				throw new Error("Nonsupport data!");
		}
		return null;
	}
}