package utils
{
	import dragonBones.utils.ConstValues;
	
	public function movePivotToSkeleton(skeletonXML:XML, textureAtlasXML:XML):void
	{
		var subTextureXMLList:XMLList = textureAtlasXML.elements(ConstValues.SUB_TEXTURE);
		var subTextureXML:XML = subTextureXMLList[0];
		if(subTextureXML)
		{
			var displayXMLList:XMLList = skeletonXML.elements(ConstValues.ARMATURES).elements(ConstValues.ARMATURE).elements(ConstValues.BONE).elements(ConstValues.DISPLAY);
			var displayXML:XML = displayXMLList[0];
			if(displayXML && displayXML.attribute(ConstValues.A_PIVOT_X).length() > 0)
			{
				return;
			}
			for each(subTextureXML in subTextureXMLList)
			{
				var subTextureName:String = subTextureXML.attribute(ConstValues.A_NAME);
				var pivotX:int = int(subTextureXML.attribute(ConstValues.A_PIVOT_X));
				var pivotY:int = int(subTextureXML.attribute(ConstValues.A_PIVOT_Y));
				
				for each(displayXML in displayXMLList)
				{
					var displayName:String = displayXML.attribute(ConstValues.A_NAME);
					if(displayName == subTextureName)
					{
						displayXML[ConstValues.AT + ConstValues.A_PIVOT_X] = pivotX;
						displayXML[ConstValues.AT + ConstValues.A_PIVOT_Y] = pivotY;
					}
				}
			}
		}
	}
}