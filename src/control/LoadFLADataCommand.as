package control{
	import dragonBones.utils.ConstValues;
	
	import flash.events.Event;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	
	import makeswfs.make;
	
	import message.Message;
	import message.MessageDispatcher;
	
	import model.ImportDataProxy;
	import model.JSFLProxy;
	
	import utils.GlobalConstValues;
	import utils.TextureUtil;
	
	public class LoadFLADataCommand{
		public static var instance:LoadFLADataCommand = new LoadFLADataCommand();
		
		private var isLoading:Boolean;
		
		private var jsflProxy:JSFLProxy;
		
		private var urlLoader:URLLoader;
		private var skeletonXML:XML;
		private var textureAtlasXML:XML;
		private var subTextureXMLList:XMLList;
		
		private var totalCount:int;
		private var armatureNameList:Array;
		private var subTextureAddedIndex:int;
		
		public function LoadFLADataCommand(){
			urlLoader = new URLLoader();
			jsflProxy = JSFLProxy.getInstance();
			
			MessageDispatcher.addEventListener(JSFLProxy.GET_ARMATURE_LIST, jsflProxyHandler);
			MessageDispatcher.addEventListener(JSFLProxy.GENERATE_ARMATURE, jsflProxyHandler);
			MessageDispatcher.addEventListener(JSFLProxy.CLEAR_TEXTURE_SWFITEM, jsflProxyHandler);
			MessageDispatcher.addEventListener(JSFLProxy.ADD_TEXTURE_TO_SWFITEM, jsflProxyHandler);
		}
		
		public function load(_isSelected:Boolean):void{
			if(isLoading){
				return;
			}
			//读取 Flash Pro 中符合骨骼结构的 element 列表
			jsflProxy.getArmatureList(_isSelected);
		}
		
		private function addAndReadNextArmature(_skeletonXML:XML = null):void{
			if(_skeletonXML){
				addSkeletonXML(_skeletonXML);
			}
			if(armatureNameList.length == 0){
				//骨骼读取完毕，放置贴图
				MessageDispatcher.dispatchEvent(MessageDispatcher.LOAD_ARMATURE_DATA_COMPLETE);
				jsflProxy.clearTextureSWFItem();
				return;
			}
			var _armatureName:String = armatureNameList.shift();
			MessageDispatcher.dispatchEvent(MessageDispatcher.LOAD_ARMATURE_DATA, _armatureName, totalCount - armatureNameList.length, totalCount);
			jsflProxy.generateArmature(_armatureName);
		}
		
		private function addAndReadNextSubTexture(_subTextureXML:XML = null):void{
			if(_subTextureXML){
				textureAtlasXML.appendChild(_subTextureXML);
			}
			if(subTextureAddedIndex < 0){
				//贴图放置完毕，排序贴图
				MessageDispatcher.dispatchEvent(MessageDispatcher.LOAD_TEXTURE_DATA_COMPLETE);
				MessageDispatcher.addEventListener(JSFLProxy.PACK_TEXTURES, jsflProxyHandler);
				TextureUtil.packTextures(ImportDataProxy.getInstance().textureMaxWidth, ImportDataProxy.getInstance().texturePadding, textureAtlasXML);
				jsflProxy.packTextures(textureAtlasXML);
				return;
			}
			var _subTextureName:String = subTextureXMLList[subTextureAddedIndex].attribute(ConstValues.A_NAME)
			MessageDispatcher.dispatchEvent(MessageDispatcher.LOAD_TEXTURE_DATA, _subTextureName, totalCount - subTextureAddedIndex, totalCount);
			jsflProxy.addTextureToSWFItem(_subTextureName, subTextureAddedIndex == 0);
			delete subTextureXMLList[subTextureAddedIndex];
			subTextureAddedIndex --;
		}
		
		private function jsflProxyHandler(_e:Message):void{
			var _result:String = _e.parameters[0];
			switch(_e.type){
				case JSFLProxy.GET_ARMATURE_LIST:
					if(_result == "false"){
						//没有符合骨骼结构的 element
						MessageDispatcher.dispatchEvent(MessageDispatcher.LOAD_FLADATA, 0);
					}else{
						//开始逐个读取骨骼
						armatureNameList = _result.split(",");
						totalCount = armatureNameList.length - 1;
						MessageDispatcher.dispatchEvent(MessageDispatcher.LOAD_FLADATA, totalCount, armatureNameList.shift());
						if(totalCount > 0){
							isLoading = true;
							skeletonXML = null;
							addAndReadNextArmature();
						}
					}
					break;
				case JSFLProxy.GENERATE_ARMATURE:
					//逐个读取骨骼
					addAndReadNextArmature(_result != "false"?XML(_result):null);
					break;
				case JSFLProxy.CLEAR_TEXTURE_SWFITEM:
					textureAtlasXML = skeletonXML.elements(ConstValues.TEXTURE_ATLAS)[0];
					textureAtlasXML[ConstValues.AT + ConstValues.A_NAME] = skeletonXML[ConstValues.AT + ConstValues.A_NAME];
					delete skeletonXML[ConstValues.TEXTURE_ATLAS];
					subTextureXMLList = textureAtlasXML.elements(ConstValues.SUB_TEXTURE);
					totalCount = subTextureXMLList.length();
					subTextureAddedIndex = totalCount - 1;
					//开始逐个放置贴图
					addAndReadNextSubTexture();
					break;
				case JSFLProxy.ADD_TEXTURE_TO_SWFITEM:
					//逐个放置贴图
					addAndReadNextSubTexture(_result != "false"?XML(_result):null);
					break;
				case JSFLProxy.PACK_TEXTURES:
					//贴图排序完毕，从 Flash Pro 导出贴图 SWF
					MessageDispatcher.removeEventListener(JSFLProxy.PACK_TEXTURES, jsflProxyHandler);
					MessageDispatcher.addEventListener(JSFLProxy.EXPORT_SWF, jsflProxyHandler);
					jsflProxy.exportSWF();
					break;
				case JSFLProxy.EXPORT_SWF:
					//导出 SWF 完毕，读取 SWF
					MessageDispatcher.removeEventListener(JSFLProxy.EXPORT_SWF, jsflProxyHandler);
					MessageDispatcher.dispatchEvent(MessageDispatcher.LOAD_SWF);
					urlLoader.addEventListener(Event.COMPLETE, onURLLoaderCompleteHandler);
					urlLoader.dataFormat = URLLoaderDataFormat.BINARY;
					urlLoader.load(new URLRequest(_result));
					break;
			}
		}
		
		private function addSkeletonXML(_skeletonXML:XML):void{
			if(skeletonXML){
				var _xmlList1:XMLList;
				var _xmlList2:XMLList;
				var _node1:XML;
				var _node2:XML;
				var _name:String;
				
				_xmlList1 = skeletonXML.elements(ConstValues.ARMATURES).elements(ConstValues.ARMATURE);
				_xmlList2 = _skeletonXML.elements(ConstValues.ARMATURES).elements(ConstValues.ARMATURE);
				for each(_node2 in _xmlList2){
					_name = _node2.attribute(ConstValues.A_NAME);
					_node1 = _xmlList1.(attribute(ConstValues.A_NAME) == _name)[0];
					if(_node1){
						delete _xmlList1[_node1.childIndex()];
					}
					skeletonXML.elements(ConstValues.ARMATURES).appendChild(_node2);
				}
				
				_xmlList1 = skeletonXML.elements(ConstValues.ANIMATIONS).elements(ConstValues.ANIMATION);
				_xmlList2 = _skeletonXML.elements(ConstValues.ANIMATIONS).elements(ConstValues.ANIMATION);
				for each(_node2 in _xmlList2){
					_name = _node2.attribute(ConstValues.A_NAME);
					_node1 = _xmlList1.(attribute(ConstValues.A_NAME) == _name)[0];
					if(_node1){
						delete _xmlList1[_node1.childIndex()];
					}
					skeletonXML.elements(ConstValues.ANIMATIONS).appendChild(_node2);
				}
				
				_xmlList1 = skeletonXML.elements(ConstValues.TEXTURE_ATLAS).elements(ConstValues.SUB_TEXTURE);
				_xmlList2 = _skeletonXML.elements(ConstValues.TEXTURE_ATLAS).elements(ConstValues.SUB_TEXTURE);
				for each(_node2 in _xmlList2){
					_name = _node2.attribute(ConstValues.A_NAME);
					_node1 = _xmlList1.(attribute(ConstValues.A_NAME) == _name)[0];
					if(_node1){
						delete _xmlList1[_node1.childIndex()];
					}
					skeletonXML.elements(ConstValues.TEXTURE_ATLAS).appendChild(_node2);
				}
			}else{
				skeletonXML = _skeletonXML;
			}
		}
		
		private function onURLLoaderCompleteHandler(_e:Event):void{
			isLoading = false;
			urlLoader.removeEventListener(Event.COMPLETE, onURLLoaderCompleteHandler);
			skeletonXML[ConstValues.AT + ConstValues.A_VERSION] = ConstValues.VERSION;
			MessageDispatcher.dispatchEvent(MessageDispatcher.LOAD_SWF_COMPLETE, skeletonXML, textureAtlasXML, make(_e.target.data, textureAtlasXML), false);
		}
	}
}