package model
{
	import dragonBones.objects.ArmatureData;
	import dragonBones.objects.XMLDataParser;
	import dragonBones.utils.ConstValues;
	import dragonBones.utils.dragonBones_internal;
	
	import flash.events.Event;
	
	import message.MessageDispatcher;
	
	import mx.collections.XMLListCollection;
	
	use namespace dragonBones_internal;
	
	[Bindable]
	/**
	 * Manage selected armature data
	 */
	public class ArmatureDataProxy
	{
		public var bonesMC:XMLListCollection;
		public var displaysMC:XMLListCollection;
		
		private var _xml:XML;
		private var _bonesXMLList:XMLList;
		
		private var _boneXML:XML;
		private var _displaysXMLList:XMLList;
		private var _displayXML:XML;
		
		public function get armatureName():String
		{
			return _xml?_xml.attribute(ConstValues.A_NAME):"";
		}
		
		public function get boneName():String
		{
			return _boneXML?_boneXML.attribute(ConstValues.A_NAME):"";
		}
		
		public function get displayName():String
		{
			return _displayXML?_displayXML.attribute(ConstValues.A_NAME):"";
		}
		
		public function ArmatureDataProxy()
		{
			bonesMC = new XMLListCollection();
			displaysMC = new XMLListCollection();
		}
		
		public function setData(xml:XML):void
		{
			_xml = xml;
			bonesMC.removeAll();
			if(_xml)
			{
				_bonesXMLList = _xml.elements(ConstValues.BONE);
				bonesMC.source = getBoneList();
			}
			else
			{
				_bonesXMLList = null;
				bonesMC.source = null;
			}
			
			ImportDataProxy.getInstance().changeRenderArmature(armatureName);
			MessageDispatcher.dispatchEvent(MessageDispatcher.CHANGE_ARMATURE_DATA, armatureName);
			
			changeBone();
			ImportDataProxy.getInstance().animationDataProxy.setData(ImportDataProxy.getInstance().getAnimationXMLByName(armatureName));
		}
		
		public function changeBone(boneName:String = null):void
		{
			var boneXML:XML = ImportDataProxy.getElementByName(_bonesXMLList, boneName, true);
			if(_boneXML == boneXML)
			{
				return;
			}
			_boneXML = boneXML;
			_displaysXMLList = _boneXML.elements(ConstValues.DISPLAY);
			
			displaysMC.source = _displaysXMLList;
			
			MessageDispatcher.dispatchEvent(MessageDispatcher.CHANGE_BONE_DATA, this.boneName);
			
			changeBoneDisplay();
		}
		
		public function changeBoneDisplay(displayName:String = null):void
		{
			_displayXML = ImportDataProxy.getElementByName(_displaysXMLList, displayName, true);
			MessageDispatcher.dispatchEvent(MessageDispatcher.CHANGE_DISPLAY_DATA, this.displayName);
		}
		
		public function checkParent(name:String, parentName:String):Boolean
		{
			var boneXML:XML = ImportDataProxy.getElementByName(_bonesXMLList, name);
			var parentXML:XML = ImportDataProxy.getElementByName(_bonesXMLList, parentName);
			
			var ancestor:XML = parentXML;
			while (ancestor != boneXML && ancestor != null)
			{
				ancestor = ImportDataProxy.getElementByName(_bonesXMLList, ancestor.attribute(ConstValues.A_PARENT));
			}
			if (ancestor == boneXML)
			{
				return false;
			}
			return true;
		}
		
		public function updateBoneParent(name:String, parentName:String):void
		{
			var boneXML:XML = ImportDataProxy.getElementByName(_bonesXMLList, name);
			var parentXML:XML = ImportDataProxy.getElementByName(_bonesXMLList, parentName);
			
			var isChange:Boolean;
			if(parentXML)
			{
				if(boneXML.attribute(ConstValues.A_PARENT) != parentName)
				{
					boneXML.@[ConstValues.A_PARENT] = parentName;
					isChange = true;
				}
			}
			else
			{
				if(boneXML.attribute(ConstValues.A_PARENT).length() > 0)
				{
					isChange = true;
					delete boneXML.@[ConstValues.A_PARENT];
				}
			}
			
			if(isChange)
			{
				var armatureData:ArmatureData = ImportDataProxy.getInstance().skeletonData.getArmatureData(armatureName);
				XMLDataParser.parseBoneData(
					boneXML,
					parentXML,
					armatureData.getBoneData(name)
				);
				
				armatureData.updateBoneList();
				
				ImportDataProxy.getInstance().animationDataProxy.updateBoneParent(boneName);
				bonesMC.source = getBoneList();
				
				if(!ImportDataProxy.getInstance().isExportedSource)
				{
					JSFLProxy.getInstance().changeArmatureConnection(armatureName, _xml);
				}
				
				MessageDispatcher.dispatchEvent(MessageDispatcher.UPDATE_BONE_PARENT, name, parentName);
			}
		}
		
		private function getBoneList():XMLList
		{
			var boneXMLList:XMLList = _xml.copy().elements(ConstValues.BONE);
			var dic:Object = {};
			var parentXML:XML;
			var parentName:String;
			var boneXML:XML;
			for(var i:int = boneXMLList.length() - 1;i >= 0;i --)
			{
				boneXML = boneXMLList[i];
				delete boneXML[ConstValues.DISPLAY];
				dic[boneXML.attribute(ConstValues.A_NAME)] = boneXML;
				parentName = boneXML.attribute(ConstValues.A_PARENT);
				if (parentName)
				{
					parentXML = dic[parentName] || XMLDataParser.getElementsByAttribute(boneXMLList, ConstValues.A_NAME, parentName)[0];
					if (parentXML)
					{
						delete boneXMLList[i];
						parentXML.appendChild(boneXML);
					}
				}
			}
			return boneXMLList;
		}
	}
}