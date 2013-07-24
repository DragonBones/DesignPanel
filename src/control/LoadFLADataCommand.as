package control
{
	import dragonBones.utils.ConstValues;
	
	import message.Message;
	import message.MessageDispatcher;
	
	import model.JSFLProxy;
	import model.XMLDataProxy;
	
	public class LoadFLADataCommand
	{
		public static const instance:LoadFLADataCommand = new LoadFLADataCommand();
		
		private var _jsflProxy:JSFLProxy;
		
		private var _xmlDataProxy:XMLDataProxy;
		
		private var _subTextureList:Vector.<String>;
		private var _subTextureListSuccess:Vector.<String>;
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
				MessageDispatcher.dispatchEvent(MessageDispatcher.LOAD_FLADATA, _totalCount, flaDomName);
				if(_totalCount > 0)
				{
					_loadIndex = _totalCount - 1;
					_isLoading = true;
					_xmlDataProxy = new XMLDataProxy();
					readNextArmature();
				}
			}
		}
		
		private function readNextArmature():void
		{
			if(_loadIndex >= 0)
			{
				var armatureXML:XML = _armatureXMLList[_loadIndex];
				var armatureName:String = armatureXML.@[ConstValues.A_NAME];
				
				MessageDispatcher.dispatchEvent(MessageDispatcher.LOAD_ARMATURE_DATA, armatureName, _totalCount - _loadIndex, _totalCount);
				
				delete _armatureXMLList[_loadIndex --];
				if(_xmlDataProxy.xml && _xmlDataProxy.getArmatureXMLList(armatureName)[0])
				{
					readNextArmature();
				}
				else
				{
					MessageDispatcher.addEventListener(JSFLProxy.GENERATE_ARMATURE, readNextArmatureHandler);
					_jsflProxy.generateArmature(armatureName);
				}
			}
			else
			{
				//load texture complete, start to place texture
				MessageDispatcher.dispatchEvent(MessageDispatcher.LOAD_ARMATURE_DATA_COMPLETE);
				MessageDispatcher.addEventListener(JSFLProxy.CLEAR_TEXTURE_SWFITEM, clearTextureAtlasSWFHandler);
				_jsflProxy.clearTextureSWFItem();
			}
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
					for each(var armatureXML:XML in xml[ConstValues.ARMATURE])
					{
						_xmlDataProxy.addArmatureXML(armatureXML);
						
					}
				}
				else
				{
					_xmlDataProxy.xml = xml;
				}
			}
			
			readNextArmature();
		}
		
		private function clearTextureAtlasSWFHandler(e:Message):void
		{
			MessageDispatcher.removeEventListener(JSFLProxy.CLEAR_TEXTURE_SWFITEM, clearTextureAtlasSWFHandler);
			_subTextureListSuccess = new Vector.<String>;
			_subTextureList = _xmlDataProxy.getSubTextureListFromDisplayList();
			_totalCount = _subTextureList.length;
			
			if(_totalCount == 0)
			{
				MessageDispatcher.dispatchEvent(MessageDispatcher.LOAD_FLADATA_ERROR);
				_isLoading = false;
				return;
			}
			_loadIndex = _totalCount - 1;
			//start to place texture
			readNextSubTexture();
		}
		
		private function readNextSubTexture():void
		{
			var subTextureName:String = _subTextureList[_loadIndex];
			MessageDispatcher.dispatchEvent(MessageDispatcher.LOAD_TEXTURE_DATA, subTextureName, _totalCount - _loadIndex, _totalCount);
			
			MessageDispatcher.addEventListener(JSFLProxy.ADD_TEXTURE_TO_SWFITEM, readNextSubTextureHandler);
			_jsflProxy.addTextureToSWFItem(subTextureName, _loadIndex == 0);
			
			_subTextureList.splice(_loadIndex --, 1);
		}
		
		private function readNextSubTextureHandler(e:Message):void
		{
			MessageDispatcher.removeEventListener(JSFLProxy.ADD_TEXTURE_TO_SWFITEM, readNextSubTextureHandler);
			
			var result:String = e.parameters[0];
			if(result != "true")
			{
				_subTextureListSuccess.push(result);
			}
			
			if(_loadIndex >= 0)
			{
				readNextSubTexture();
			}
			else
			{
				MessageDispatcher.addEventListener(MessageDispatcher.FLA_TEXTURE_ATLAS_SWF_LOADED, flaExportSWFHandler);
				FLAExportSWFCommand.instance.exportSWF(_xmlDataProxy, _subTextureListSuccess);
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