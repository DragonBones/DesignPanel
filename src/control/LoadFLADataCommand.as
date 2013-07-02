package control
{
	import dragonBones.utils.ConstValues;
	
	import message.Message;
	import message.MessageDispatcher;
	
	import model.JSFLProxy;
	import model.SettingDataProxy;
	import model.XMLDataProxy;
	
	public class LoadFLADataCommand
	{
		public static const instance:LoadFLADataCommand = new LoadFLADataCommand();
		
		private var _jsflProxy:JSFLProxy;
		
		private var _xmlDataProxy:XMLDataProxy;
		
		private var _displayList:Vector.<String>;
		private var _armatureXMLList:XMLList;
		private var _totalCount:int;
		private var _loadIndex:int;
		
		private var _isLoading:Boolean;
		public function get isLoading():Boolean
		{
			return _isLoading;
		}
		
		public function LoadFLADataCommand()
		{
			_jsflProxy = JSFLProxy.getInstance();
		}
		
		public function load(isSelected:Boolean, armatureNames:Vector.<String> = null):void
		{
			if(_isLoading)
			{
				return;
			}
			//Load bone elements from Flash Pro
			MessageDispatcher.addEventListener(JSFLProxy.GET_ARMATURE_LIST, getArmatureListHandler);
			_jsflProxy.getArmatureList(isSelected, armatureNames);
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
				var resultXML:XML = XML(result);
				var flaDomName:String = resultXML.@[ConstValues.A_NAME];
				_armatureXMLList = resultXML[ConstValues.ARMATURE];
				
				_totalCount = _armatureXMLList.length();
				_loadIndex = _totalCount - 1;
				MessageDispatcher.dispatchEvent(MessageDispatcher.LOAD_FLADATA, _totalCount, flaDomName);
				if(_totalCount > 0)
				{
					_isLoading = true;
					_xmlDataProxy = new XMLDataProxy();
					readNextArmature();
				}
			}
		}
		
		private function readNextArmature():void
		{
			var armatureXML:XML = _armatureXMLList[_loadIndex];
			var armatureName:String = armatureXML.@[ConstValues.A_NAME];
			var scale:Number = Number(armatureXML.@["scale"]);
			
			MessageDispatcher.dispatchEvent(MessageDispatcher.LOAD_ARMATURE_DATA, armatureName, _totalCount - _loadIndex, _totalCount);
			MessageDispatcher.addEventListener(JSFLProxy.GENERATE_ARMATURE, readNextArmatureHandler);
			_jsflProxy.generateArmature(armatureName, scale);
			
			delete _armatureXMLList[_loadIndex --];
		}
		
		private function readNextArmatureHandler(e:Message):void
		{
			MessageDispatcher.removeEventListener(JSFLProxy.GENERATE_ARMATURE, readNextArmatureHandler);
			var result:String = e.parameters[0];
			var xml:XML = result != "false"?XML(result):null;
			if(xml)
			{
				if(_xmlDataProxy.xml)
				{
					_xmlDataProxy.addXML(xml);
				}
				else
				{
					_xmlDataProxy.xml = xml;
				}
			}
			
			if(_loadIndex >= 0)
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
			
			var result:String = e.parameters[0];
			var textureAtlasXML:XML = result != "false"?XML(result):null;
			if(textureAtlasXML)
			{
				_xmlDataProxy.textureAtlasXML = textureAtlasXML;
			}
			
			_displayList = _xmlDataProxy.getDisplayList();
			_totalCount = _displayList.length;
			
			if(_totalCount == 0)
			{
				MessageDispatcher.dispatchEvent(MessageDispatcher.LOAD_FLADATA_ERROR);
				return;
			}
			_loadIndex = _totalCount - 1;
			//start to place texture
			readNextSubTexture();
		}
		
		private function readNextSubTexture():void
		{
			var subTextureName:String = _displayList[_loadIndex];
			MessageDispatcher.dispatchEvent(MessageDispatcher.LOAD_TEXTURE_DATA, subTextureName, _totalCount - _loadIndex, _totalCount);
			
			MessageDispatcher.addEventListener(JSFLProxy.ADD_TEXTURE_TO_SWFITEM, readNextSubTextureHandler);
			_jsflProxy.addTextureToSWFItem(subTextureName, _loadIndex == 0);
			
			_displayList.splice(_loadIndex --, 1);
		}
		
		private function readNextSubTextureHandler(e:Message):void
		{
			MessageDispatcher.removeEventListener(JSFLProxy.ADD_TEXTURE_TO_SWFITEM, readNextSubTextureHandler);
			
			var result:String = e.parameters[0];
			var subTextureXML:XML = result != "false"?XML(result):null;
			if(subTextureXML)
			{
				_xmlDataProxy.addSubTextureXML(subTextureXML);
			}
			
			if(_loadIndex >= 0)
			{
				readNextSubTexture();
			}
			else
			{
				MessageDispatcher.addEventListener(MessageDispatcher.FLA_TEXTURE_ATLAS_SWF_LOADED, flaExportSWFHandler);
				FLAExportSWFCommand.instance.exportSWF(_xmlDataProxy);
			}
		}
		
		private function flaExportSWFHandler(e:Message):void
		{
			MessageDispatcher.removeEventListener(MessageDispatcher.FLA_TEXTURE_ATLAS_SWF_LOADED, flaExportSWFHandler);
			_isLoading = false;
			_xmlDataProxy.setVersion();
			MessageDispatcher.dispatchEvent(MessageDispatcher.LOAD_FLA_COMPLETE, _xmlDataProxy, e.parameters[0]);
		}
	}
}