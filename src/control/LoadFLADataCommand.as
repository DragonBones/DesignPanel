package control
{
	import dragonBones.objects.XMLDataParser;
	import dragonBones.utils.ConstValues;
	
	import message.Message;
	import message.MessageDispatcher;
	
	import model.JSFLProxy;
	import model.SettingDataProxy;
	
	import utils.GlobalConstValues;
	import utils.TextureUtil;
	
	public class LoadFLADataCommand
	{
		public static var instance:LoadFLADataCommand = new LoadFLADataCommand();
		
		private var _isLoading:Boolean;
		
		private var _jsflProxy:JSFLProxy;
		
		private var _skeletonXML:XML;
		private var _textureAtlasXML:XML;
		
		private var _subTextureXMLList:XMLList;
		private var _totalCount:int;
		private var _armatureNameList:Array;
		private var _subTextureAddedIndex:int;
		
		public function LoadFLADataCommand()
		{
			_jsflProxy = JSFLProxy.getInstance();
		}
		
		public function load(isSelected:Boolean):void
		{
			if(_isLoading)
			{
				return;
			}
			//Load bone elements from Flash Pro
			MessageDispatcher.addEventListener(JSFLProxy.GET_ARMATURE_LIST, getArmatureListHandler);
			_jsflProxy.getArmatureList(isSelected);
		}
		
		private function getArmatureListHandler(e:Message):void
		{
			MessageDispatcher.removeEventListener(JSFLProxy.GET_ARMATURE_LIST, getArmatureListHandler);
			var result:String = e.parameters[0];
			if(result == "false")
			{
				//no armature element
				MessageDispatcher.dispatchEvent(MessageDispatcher.LOAD_FLADATA, 0, "");
			}
			else
			{
				//start load armature data
				_armatureNameList = result.split(",");
				_totalCount = _armatureNameList.length - 1;
				MessageDispatcher.dispatchEvent(MessageDispatcher.LOAD_FLADATA, _totalCount, _armatureNameList.shift());
				if(_totalCount > 0)
				{
					_isLoading = true;
					_skeletonXML = null;
					readNextArmature();
				}
			}
		}
		
		private function readNextArmature():void
		{
			var armatureName:String = _armatureNameList.shift();
			MessageDispatcher.dispatchEvent(MessageDispatcher.LOAD_ARMATURE_DATA, armatureName, _totalCount - _armatureNameList.length, _totalCount);
			MessageDispatcher.addEventListener(JSFLProxy.GENERATE_ARMATURE, readNextArmatureHandler);
			_jsflProxy.generateArmature(armatureName);
		}
		
		private function readNextArmatureHandler(e:Message):void
		{
			MessageDispatcher.removeEventListener(JSFLProxy.GENERATE_ARMATURE, readNextArmatureHandler);
			var result:String = e.parameters[0];
			var skeletonXML:XML = result != "false"?XML(result):null
			if(skeletonXML)
			{
				addSkeletonXML(skeletonXML);
			}
			
			if(_armatureNameList.length > 0)
			{
				readNextArmature();
			}
			else
			{
				//load texture complete, start to place texture
				MessageDispatcher.dispatchEvent(MessageDispatcher.LOAD_ARMATURE_DATA_COMPLETE);
				MessageDispatcher.addEventListener(JSFLProxy.CLEAR_TEXTURE_SWFITEM, clearTextureAtlasSWFHandler);
				_jsflProxy.clearTextureSWFItem();
			}
		}
		
		private function clearTextureAtlasSWFHandler(e:Message):void
		{
			MessageDispatcher.removeEventListener(JSFLProxy.CLEAR_TEXTURE_SWFITEM, clearTextureAtlasSWFHandler);
			_textureAtlasXML = _skeletonXML.elements(ConstValues.TEXTURE_ATLAS)[0];
			_textureAtlasXML[ConstValues.AT + ConstValues.A_NAME] = _skeletonXML[ConstValues.AT + ConstValues.A_NAME];
			delete _skeletonXML[ConstValues.TEXTURE_ATLAS];
			_subTextureXMLList = _textureAtlasXML.elements(ConstValues.SUB_TEXTURE);
			_totalCount = _subTextureXMLList.length();
			_subTextureAddedIndex = _totalCount - 1;
			//start to place texture
			readNextSubTexture();
		}
		
		private function readNextSubTexture():void
		{
			var subTextureName:String = _subTextureXMLList[_subTextureAddedIndex].attribute(ConstValues.A_NAME)
			MessageDispatcher.dispatchEvent(MessageDispatcher.LOAD_TEXTURE_DATA, subTextureName, _totalCount - _subTextureAddedIndex, _totalCount);
			
			MessageDispatcher.addEventListener(JSFLProxy.ADD_TEXTURE_TO_SWFITEM, readNextSubTextureHandler);
			_jsflProxy.addTextureToSWFItem(subTextureName, _subTextureAddedIndex == 0);
			
			delete _subTextureXMLList[_subTextureAddedIndex];
			_subTextureAddedIndex --;
		}
		
		private function readNextSubTextureHandler(e:Message):void
		{
			MessageDispatcher.removeEventListener(JSFLProxy.ADD_TEXTURE_TO_SWFITEM, readNextSubTextureHandler);
			
			var result:String = e.parameters[0];
			var subTextureXML:XML = result != "false"?XML(result):null;
			if(subTextureXML)
			{
				_textureAtlasXML.appendChild(subTextureXML);
			}
			
			if(_subTextureAddedIndex >= 0)
			{
				readNextSubTexture();
			}
			else
			{
				//load texture complete, start to place texture
				MessageDispatcher.dispatchEvent(MessageDispatcher.LOAD_TEXTURE_DATA_COMPLETE);
				TextureUtil.packTextures(SettingDataProxy.getInstance().textureMaxWidth, SettingDataProxy.getInstance().texturePadding, _textureAtlasXML);
				MessageDispatcher.addEventListener(JSFLProxy.PACK_TEXTURES, packTextureAtlasHandler);
				_jsflProxy.packTextures(_textureAtlasXML);
			}
		}
		
		private function packTextureAtlasHandler(e:Message):void
		{
			MessageDispatcher.removeEventListener(JSFLProxy.PACK_TEXTURES, packTextureAtlasHandler);
			MessageDispatcher.addEventListener(MessageDispatcher.FLA_TEXTURE_ATLAS_SWF_LOADED, flaExportSWFHandler);
			FLAExportSWFCommand.instance.exportSWF(_textureAtlasXML);
		}
		
		private function flaExportSWFHandler(e:Message):void
		{
			_isLoading = false;
			_skeletonXML[ConstValues.AT + ConstValues.A_VERSION] = ConstValues.VERSION;
			MessageDispatcher.dispatchEvent(MessageDispatcher.LOAD_SWF_COMPLETE, _skeletonXML, _textureAtlasXML, e.parameters[0], e.parameters[1]);
		}
		
		private function addSkeletonXML(skeletonXML:XML):void
		{
			if(_skeletonXML)
			{
				var xmlList1:XMLList;
				var xmlList2:XMLList;
				var node1:XML;
				var node2:XML;
				var nodeName:String;
				
				xmlList1 = _skeletonXML.elements(ConstValues.ARMATURES).elements(ConstValues.ARMATURE);
				xmlList2 = skeletonXML.elements(ConstValues.ARMATURES).elements(ConstValues.ARMATURE);
				for each(node2 in xmlList2)
				{
					nodeName = node2.attribute(ConstValues.A_NAME);
					node1 = XMLDataParser.getElementByAttribute(xmlList1, ConstValues.A_NAME, nodeName)[0];
					if(node1)
					{
						delete xmlList1[node1.childIndex()];
					}
					_skeletonXML.elements(ConstValues.ARMATURES).appendChild(node2);
				}
				
				xmlList1 = _skeletonXML.elements(ConstValues.ANIMATIONS).elements(ConstValues.ANIMATION);
				xmlList2 = skeletonXML.elements(ConstValues.ANIMATIONS).elements(ConstValues.ANIMATION);
				for each(node2 in xmlList2)
				{
					nodeName = node2.attribute(ConstValues.A_NAME);
					node1 = XMLDataParser.getElementByAttribute(xmlList1, ConstValues.A_NAME, nodeName)[0];
					if(node1)
					{
						delete xmlList1[node1.childIndex()];
					}
					_skeletonXML.elements(ConstValues.ANIMATIONS).appendChild(node2);
				}
				
				xmlList1 = _skeletonXML.elements(ConstValues.TEXTURE_ATLAS).elements(ConstValues.SUB_TEXTURE);
				xmlList2 = skeletonXML.elements(ConstValues.TEXTURE_ATLAS).elements(ConstValues.SUB_TEXTURE);
				for each(node2 in xmlList2)
				{
					nodeName = node2.attribute(ConstValues.A_NAME);
					node1 = XMLDataParser.getElementByAttribute(xmlList1, ConstValues.A_NAME, nodeName)[0];
					if(node1)
					{
						delete xmlList1[node1.childIndex()];
					}
					_skeletonXML.elements(ConstValues.TEXTURE_ATLAS).appendChild(node2);
				}
			}
			else
			{
				_skeletonXML = skeletonXML;
			}
		}
	}
}