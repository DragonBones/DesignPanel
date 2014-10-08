package plugin.mediator
{
	
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.ErrorEvent;
	import flash.events.ProgressEvent;
	
	import mx.controls.Alert;
	import mx.managers.PopUpManager;
	import mx.resources.ResourceManager;
	import mx.binding.utils.BindingUtils;
	
	import core.events.MediatorEvent;
	import core.events.ModelEvent;
	import core.events.ControllerEvent;
	import core.events.ViewEvent;
	import core.events.ServiceEvent;
	import core.model.ParsedModel;
	import core.service.ImportFLAService;
	import core.service.ImportFileService;
	import core.service.JSFLService;
	import core.suppotClass._BaseMediator;
	import core.utils.GlobalConstValues;
	
	import plugin.view.ArmaturesPanel;
	
	import dragonBones.Bone;
	import dragonBones.animation.AnimationState;
	import dragonBones.animation.WorldClock;
	
	public final class ArmaturesPanelMediator extends _BaseMediator
	{
		[Inject]
		public var parsedModel:ParsedModel;
		
		[Inject]
		public var jsflService:JSFLService;
		
		[Inject]
		public var importFLAService:ImportFLAService;
		
		[Inject]
		public var importFileService:ImportFileService;
		
		[Inject]
		public var view:ArmaturesPanel;
		
		private var _alert:Alert;
		
		override public function initialize():void
		{
			super.initialize();
			
			this.addContextListener(ModelEvent.PARSED_MODEL_DATA_CHANGE, modelHandler);
			this.addContextListener(ModelEvent.PARSED_MODEL_ARMATURE_CHANGE, modelHandler);
			this.addContextListener(ModelEvent.PARSED_MODEL_SKIN_CHANGE, modelHandler);
			this.addContextListener(ModelEvent.PARSED_MODEL_ANIMATION_CHANGE, modelHandler);
			this.addContextListener(ModelEvent.PARSED_MODEL_BONE_CHANGE, modelHandler);
			this.addContextListener(ModelEvent.PARSED_MODEL_ANIMATION_DATA_CHANGE, modelHandler);
			this.addContextListener(ModelEvent.PARSED_MODEL_BONE_PARENT_CHANGE, modelHandler);
			
			this.addContextListener(MediatorEvent.ROLL_OVER_BONE, mediatorHandler);
			this.addContextListener(MediatorEvent.ROLL_OUT_BONE, mediatorHandler);
			
			this.addViewListener(Event.ENTER_FRAME, enterFrameHandler);
			
			resetUI();
			
			BindingUtils.bindProperty(view.dropDownListArmature, "selectedItem", parsedModel, "armatureSelected", false);
			BindingUtils.bindProperty(view.dropDownListSkin, "selectedItem", parsedModel, "skinSelected", false);
			
			BindingUtils.bindProperty(parsedModel, "armatureSelected", view.dropDownListArmature, "selectedItem", false);
			BindingUtils.bindProperty(parsedModel, "skinSelected", view.dropDownListSkin, "selectedItem", false);
			
			view.armatureView.addEventListener(ViewEvent.ARMATURE_ANIMATION_CHANGE, armatureViewHandler);
			view.armatureView.addEventListener(ViewEvent.BONE_SELECTED_CHANGE, armatureViewHandler);
			view.armatureView.addEventListener(ViewEvent.BONE_PARENT_CHANGE, armatureViewHandler);
			
			view.buttonUpdate.addEventListener(MouseEvent.CLICK, buttonHandler);
			view.buttonRemove.addEventListener(MouseEvent.CLICK, buttonHandler);
			
			//
			this.addContextListener(ControllerEvent.IMPORT_FLA, commandHandler);
			this.addContextListener(ControllerEvent.IMPORT_FILE, commandHandler);
			this.addContextListener(ControllerEvent.IMPORT_CANCLE, commandHandler);
			this.addContextListener(ControllerEvent.IMPORT_ERROR, commandHandler);
			this.addContextListener(ControllerEvent.IMPORT_PROGRESS, commandHandler);
			this.addContextListener(ControllerEvent.IMPORT_COMPLETE, commandHandler);
			
			this.addContextListener(ControllerEvent.EXPORT_FILE, commandHandler);
			this.addContextListener(ControllerEvent.EXPORT_CANCEL, commandHandler);
			this.addContextListener(ControllerEvent.EXPORT_ERROR, commandHandler);
			this.addContextListener(ControllerEvent.EXPORT_COMPLETE, commandHandler);
			
			importFLAService.addEventListener(ImportFLAService.IMPORT_ARMATURE, importFLAHandler);
			importFLAService.addEventListener(ImportFLAService.IMPORT_SUBTEXTURE, importFLAHandler);
			importFLAService.addEventListener(ImportFLAService.IMPORT_ARMATURE_ERROR, importFLAErrorHandler);
			importFLAService.addEventListener(ImportFLAService.IMPORT_SUBTEXTURE_ERROR, importFLAErrorHandler);
		}
		
		override public function destroy():void
		{
			super.destroy();
			
			this.removeContextListener(ModelEvent.PARSED_MODEL_DATA_CHANGE, modelHandler);
			this.removeContextListener(ModelEvent.PARSED_MODEL_ARMATURE_CHANGE, modelHandler);
			this.removeContextListener(ModelEvent.PARSED_MODEL_SKIN_CHANGE, modelHandler);
			this.removeContextListener(ModelEvent.PARSED_MODEL_ANIMATION_CHANGE, modelHandler);
			this.removeContextListener(ModelEvent.PARSED_MODEL_BONE_CHANGE, modelHandler);
			this.removeContextListener(ModelEvent.PARSED_MODEL_ANIMATION_DATA_CHANGE, modelHandler);
			this.removeContextListener(ModelEvent.PARSED_MODEL_BONE_PARENT_CHANGE, modelHandler);
			
			this.removeContextListener(MediatorEvent.ROLL_OVER_BONE, mediatorHandler);
			this.removeContextListener(MediatorEvent.ROLL_OUT_BONE, mediatorHandler);
			
			this.removeViewListener(Event.ENTER_FRAME, enterFrameHandler);
			
			view.armatureView.removeEventListener(ViewEvent.ARMATURE_ANIMATION_CHANGE, armatureViewHandler);
			view.armatureView.removeEventListener(ViewEvent.BONE_SELECTED_CHANGE, armatureViewHandler);
			view.armatureView.removeEventListener(ViewEvent.BONE_PARENT_CHANGE, armatureViewHandler);
			
			view.buttonUpdate.removeEventListener(MouseEvent.CLICK, buttonHandler);
			view.buttonRemove.removeEventListener(MouseEvent.CLICK, buttonHandler);
			
			//
			this.removeContextListener(ControllerEvent.IMPORT_FLA, commandHandler);
			this.removeContextListener(ControllerEvent.IMPORT_FILE, commandHandler);
			this.removeContextListener(ControllerEvent.IMPORT_CANCLE, commandHandler);
			this.removeContextListener(ControllerEvent.IMPORT_ERROR, commandHandler);
			this.removeContextListener(ControllerEvent.IMPORT_PROGRESS, commandHandler);
			this.removeContextListener(ControllerEvent.IMPORT_COMPLETE, commandHandler);
			
			this.removeContextListener(ControllerEvent.EXPORT_FILE, commandHandler);
			this.removeContextListener(ControllerEvent.EXPORT_CANCEL, commandHandler);
			this.removeContextListener(ControllerEvent.EXPORT_ERROR, commandHandler);
			this.removeContextListener(ControllerEvent.EXPORT_COMPLETE, commandHandler);
			
			importFLAService.removeEventListener(ImportFLAService.IMPORT_ARMATURE, importFLAHandler);
			importFLAService.removeEventListener(ImportFLAService.IMPORT_SUBTEXTURE, importFLAHandler);
			importFLAService.removeEventListener(ImportFLAService.IMPORT_ARMATURE_ERROR, importFLAErrorHandler);
			importFLAService.removeEventListener(ImportFLAService.IMPORT_SUBTEXTURE_ERROR, importFLAErrorHandler);
		}
		
		private function resetUI():void
		{
			view.enabled = false;
			view.armatureView.armature = null;
			view.dropDownListArmature.dataProvider = parsedModel.armaturesAC;
			view.dropDownListSkin.dataProvider = parsedModel.skinsAC;
		}
		
		private function modelHandler(e:ModelEvent):void
		{
			if(parsedModel != e.model)
			{
				return;
			}
			
			switch(e.type)
			{
				case ModelEvent.PARSED_MODEL_DATA_CHANGE:
					break;
				
				case ModelEvent.PARSED_MODEL_ARMATURE_CHANGE:
					if(parsedModel.armatureSelected)
					{
						view.enabled = true;
						if(
							parsedModel.vo.importVO.importType == GlobalConstValues.IMPORT_TYPE_FLA_ALL_LIBRARY_ITEMS ||
							parsedModel.vo.importVO.importType == GlobalConstValues.IMPORT_TYPE_FLA_SELECTED_LIBRARY_ITEMS
							
						)
						{
							view.buttonUpdate.enabled = true;
						}
						else
						{
							view.buttonUpdate.enabled = false;
						}
						if(parsedModel.vo.skeleton.armatureDataList.length > 1)
						{
							view.buttonRemove.enabled = true;
						}
						else
						{
							view.buttonRemove.enabled = false;
						}
					}
					else
					{
						resetUI();
					}
					
					if(parsedModel.skinsAC.length > 1)
					{
						view.dropDownListSkin.visible = true;
						view.dropDownListSkin.includeInLayout = true;
					}
					else
					{
						view.dropDownListSkin.visible = false;
						view.dropDownListSkin.includeInLayout = false;
					}
					break;
				
				case ModelEvent.PARSED_MODEL_SKIN_CHANGE:
					view.armatureView.armature = parsedModel.factory.buildArmature(parsedModel.armatureSelected.name, null, null, null, parsedModel.skinSelected?parsedModel.skinSelected.name:null);
					view.armatureView.selectBone(parsedModel.boneSelected?parsedModel.boneSelected.name:null);
					break;
				
				case ModelEvent.PARSED_MODEL_ANIMATION_CHANGE:
					if(parsedModel.animationSelected)
					{
						view.armatureView.armature.animation.gotoAndPlay(parsedModel.animationSelected.name);
					}
					break;
				
				case ModelEvent.PARSED_MODEL_BONE_CHANGE:
					view.armatureView.selectBone(parsedModel.boneSelected?parsedModel.boneSelected.name:null);
					break;
				
				case ModelEvent.PARSED_MODEL_ANIMATION_DATA_CHANGE:
					//
					var animationState:AnimationState = view.armatureView.armature.animation.lastAnimationState;
					if(animationState)
					{
						animationState.setTimeScale(1 / parsedModel.animationSelected.scale);
						animationState.setPlayTimes(parsedModel.animationSelected.playTimes);
						
						animationState.autoTween = parsedModel.animationSelected.autoTween;
						if(animationState.isComplete)
						{
							view.armatureView.armature.animation.play();
						}
					}
					break;
				
				case ModelEvent.PARSED_MODEL_BONE_PARENT_CHANGE:
					var boneName:String = e.data[0];
					var parentName:String = e.data[1];
					
					var bone:Bone = view.armatureView.armature.getBone(boneName);
					bone.origin.copy(parsedModel.armatureSelected.getBoneData(boneName).transform);
					
					var boneParent:Bone = view.armatureView.armature.getBone(parentName);
					if(boneParent && boneParent.parent == bone)
					{
						boneParent.origin.copy(parsedModel.armatureSelected.getBoneData(parentName).transform);
						view.armatureView.armature.addBone(boneParent, bone.parent?bone.parent.name:null);
					}
					
					view.armatureView.armature.addBone(bone, parentName);
					bone.invalidUpdate();
					view.armatureView.armature.advanceTime(0);
					break;
			}
		}
		
		private function mediatorHandler(e:MediatorEvent):void
		{
			switch(e.type)
			{
				case MediatorEvent.ROLL_OVER_BONE:
					view.armatureView.rollOverBone(e.data);
					break;
				
				case MediatorEvent.ROLL_OUT_BONE:
					view.armatureView.rollOverBone(null);
					break;
			}
		}
		
		private function enterFrameHandler(e:Event):void
		{
			WorldClock.clock.advanceTime(-1);
		}
		
		private function armatureViewHandler(e:ViewEvent):void
		{
			switch(e.type)
			{
				case ViewEvent.ARMATURE_ANIMATION_CHANGE:
					parsedModel.animationSelected = parsedModel.armatureSelected.getAnimationData(e.data);
					break;
				
				case ViewEvent.BONE_SELECTED_CHANGE:
					parsedModel.boneSelected = parsedModel.armatureSelected.getBoneData(e.data);
					break;
				
				case ViewEvent.BONE_PARENT_CHANGE:
					parsedModel.changeBoneParent(e.data[0], e.data[1]);
					break;
			}
		}
		
		private function buttonHandler(e:Event):void
		{
			switch(e.target)
			{
				case view.buttonUpdate:
					this.dispatch(new MediatorEvent(MediatorEvent.UPDATE_FLA_ARMATURE, this, parsedModel.armatureSelected.name));
					break;
				
				case view.buttonRemove:
					this.dispatch(new MediatorEvent(MediatorEvent.REMOVE_ARMATURE, this, parsedModel.armatureSelected.name));
					break;
			}
		}
		
		private function commandHandler(e:ControllerEvent):void
		{
			switch(e.type)
			{
				case ControllerEvent.IMPORT_FLA:
					_alert = Alert.show(ResourceManager.getInstance().getString('resources','importFLAWaitting'));
					break;
				
				case ControllerEvent.IMPORT_FILE:
					_alert = Alert.show(ResourceManager.getInstance().getString('resources','importFileWaitting'));
					break;
				
				case ControllerEvent.IMPORT_CANCLE:
					clearAlert();
					break;
				
				case ControllerEvent.IMPORT_ERROR:
					importErrorHandler(e.data as ErrorEvent);
					clearAlert();
					break;
				
				case ControllerEvent.IMPORT_PROGRESS:
					if (_alert)
					{
						var progressEvent:ProgressEvent = e.data as ProgressEvent;
						_alert.title = ResourceManager.getInstance().getString('resources', 'importFileProgress', [Math.round(progressEvent.bytesLoaded / progressEvent.bytesTotal * 100) || 0]);
					}
					break;
				
				case ControllerEvent.IMPORT_COMPLETE:
					clearAlert();
					break;
				
				case ControllerEvent.EXPORT_FILE:
					_alert = Alert.show(ResourceManager.getInstance().getString('resources', 'exportWaitting'));
					break;
				
				case ControllerEvent.EXPORT_CANCEL:
					clearAlert();
					break;
				
				case ControllerEvent.EXPORT_ERROR:
					exportErrorHandler(e.data as ErrorEvent);
					clearAlert();
					break;
				
				case ControllerEvent.EXPORT_COMPLETE:
					clearAlert();
					break;
			}
			
		}
		
		private function importErrorHandler(event:ErrorEvent):void
		{	
			switch(event.text)
			{
				case ImportFLAService.ERROR_NO_ACTIVE_DOM:
					Alert.show("请打开fla后再导入","导入错误");
					break;
				
				case ImportFLAService.ERROR_NO_ARMATURE_IN_DOM:
					Alert.show("没有找到可以导入的元件","导入错误");
					break;
				
				case ImportFLAService.ERROR_JSFL_SERVICE_ERROR:
					Alert.show("请打开DragonBones插件后再导入","导入错误");
					break;
				
				case ImportFileService.IMPORT_FILE_ERROR:
					Alert.show("打开文件失败","导入错误");
					break;
				
				default:
					Alert.show("未知错误，错误码:" + event.text,"导入错误");
					break;
			}
		}
		
		private function exportErrorHandler(event:ErrorEvent):void
		{	
			switch(event.text)
			{
				default:
					Alert.show(ResourceManager.getInstance().getString('resources', 'exportError'));
					break;
			}
		}
		
		private function importFLAHandler(e:ServiceEvent):void
		{
			switch (e.type)
			{
				case ImportFLAService.IMPORT_ARMATURE:
					if (_alert)
					{
						_alert.title = ResourceManager.getInstance().getString('resources', 'importSkeletonProgress', [e.data[1], e.data[2]]);
					}
					break;
				
				case ImportFLAService.IMPORT_SUBTEXTURE:
					if (_alert)
					{
						_alert.title = ResourceManager.getInstance().getString('resources', 'importTextureProgress', [e.data[1], e.data[2]]);
					}
					break;
			}
		}
		
		private function importFLAErrorHandler(e:ErrorEvent):void
		{
			switch (e.type)
			{
				case ImportFLAService.IMPORT_ARMATURE_ERROR:
					jsflService.runJSFLMethod(null, "trace", "import armature error");
					break;
				
				case ImportFLAService.IMPORT_SUBTEXTURE_ERROR:
					jsflService.runJSFLMethod(null, "trace", "import texture error");
					break;
			}
		}
		
		private function clearAlert():void
		{
			if (_alert)
			{
				PopUpManager.removePopUp(_alert);
				_alert = null;
			}
		}
	}
}