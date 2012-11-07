package model{
	import dragonBones.utils.ConstValues;
	import dragonBones.utils.generateBoneData;
	
	import flash.events.Event;
	
	import message.MessageDispatcher;
	
	import mx.collections.XMLListCollection;
	
	/**
	 * Manage selected armature data
	 */
	public class ArmatureDataProxy{
		public var bonesMC:XMLListCollection;
		public var displaysMC:XMLListCollection;
		
		private var xml:XML;
		private var bonesXMLList:XMLList;
		
		private var boneXML:XML;
		private var displaysXMLList:XMLList;
		private var displayXML:XML;
		
		public function get armatureName():String{
			return ImportDataProxy.getElementName(xml);
		}
		
		public function get boneName():String{
			return ImportDataProxy.getElementName(boneXML);
		}
		
		public function get displayName():String{
			return ImportDataProxy.getElementName(displayXML);
		}
		
		public function ArmatureDataProxy(){
			bonesMC = new XMLListCollection();
			displaysMC = new XMLListCollection();
		}
		
		public function setData(_xml:XML):void{
			xml = _xml;
			bonesMC.removeAll();
			if(xml){
				bonesXMLList = xml.elements(ConstValues.BONE);
				bonesMC.source = getBoneList();
			}else{
				bonesXMLList = null;
				bonesMC.source = null;
			}
			
			ImportDataProxy.getInstance().changeRenderArmature(armatureName);
			MessageDispatcher.dispatchEvent(MessageDispatcher.CHANGE_ARMATURE_DATA, armatureName);
			
			changeBone();
			
			ImportDataProxy.getInstance().animationDataProxy.setData(ImportDataProxy.getInstance().getAnimationXMLByName(armatureName));
		}
		
		public function changeBone(_boneName:String = null):void{
			var _boneXML:XML = ImportDataProxy.getElementByName(bonesXMLList, _boneName, true);
			if(boneXML == _boneXML){
				return;
			}
			boneXML = _boneXML;
			displaysXMLList = boneXML.elements(ConstValues.DISPLAY);
			
			displaysMC.source = displaysXMLList;
			
			MessageDispatcher.dispatchEvent(MessageDispatcher.CHANGE_BONE_DATA, boneName);
			
			changeBoneDisplay();
		}
		
		public function changeBoneDisplay(_displayName:String = null):void{
			displayXML = ImportDataProxy.getElementByName(displaysXMLList, _displayName, true);
			MessageDispatcher.dispatchEvent(MessageDispatcher.CHANGE_DISPLAY_DATA, displayName);
		}
		
		public function checkParent(_name:String, _parentName:String):Boolean{
			var _boneXML:XML = ImportDataProxy.getElementByName(bonesXMLList, _name);
			var _parentXML:XML = ImportDataProxy.getElementByName(bonesXMLList, _parentName);
			
			var _ancestor:XML = _parentXML;
			while (_ancestor != _boneXML && _ancestor != null){
				_ancestor = ImportDataProxy.getElementByName(bonesXMLList, _ancestor.attribute(ConstValues.A_PARENT));
			}
			if (_ancestor == _boneXML){
				return false;
			}
			return true;
		}
		
		public function updateBoneParent(_name:String, _parentName:String):void{
			var _boneXML:XML = ImportDataProxy.getElementByName(bonesXMLList, _name);
			var _parentXML:XML = ImportDataProxy.getElementByName(bonesXMLList, _parentName);
			
			var _isChange:Boolean;
			if(_parentXML){
				if(_boneXML.attribute(ConstValues.A_PARENT) != _parentName){
					_boneXML[ConstValues.AT + ConstValues.A_PARENT] = _parentName;
					_isChange = true;
				}
			}else{
				if(_boneXML.attribute(ConstValues.A_PARENT).length() > 0){
					_isChange = true;
					delete _boneXML[ConstValues.AT + ConstValues.A_PARENT];
				}
			}
			
			if(_isChange){
				generateBoneData(
					_name, 
					_boneXML, 
					_parentXML, 
					ImportDataProxy.getInstance().skeletonData.getArmatureData(armatureName).getData(_name)
				);
				
				if(!ImportDataProxy.getInstance().isExportedSource){
					JSFLProxy.getInstance().changeArmatureConnection(armatureName, xml);
				}
				
				ImportDataProxy.getInstance().animationDataProxy.updateBoneParent(boneName);
				bonesMC.source = getBoneList();
				
				MessageDispatcher.dispatchEvent(MessageDispatcher.UPDATE_BONE_PARENT, _name, _parentName);
			}
		}
		
		private function getBoneList():XMLList{
			var _boneXMLList:XMLList = xml.copy().elements(ConstValues.BONE);
			var _dic:Object = {};
			var _parentXML:XML;
			var _parentName:String;
			var _boneXML:XML;
			var _length:int = _boneXMLList.length();
			for(var _i:int = _length-1;_i >= 0;_i --){
				_boneXML = _boneXMLList[_i];
				delete _boneXML[ConstValues.DISPLAY];
				_dic[_boneXML.attribute(ConstValues.A_NAME)] = _boneXML;
				_parentName = _boneXML.attribute(ConstValues.A_PARENT);
				if (_parentName){
					_parentXML = _dic[_parentName] || _boneXMLList.(attribute(ConstValues.A_NAME) == _parentName)[0];
					if (_parentXML){
						delete _boneXMLList[_i];
						_parentXML.appendChild(_boneXML);
					}
				}
			}
			return _boneXMLList;
		}
	}
}