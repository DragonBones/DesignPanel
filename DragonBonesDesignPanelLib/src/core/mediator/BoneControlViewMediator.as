package core.mediator
{
	import flash.events.Event;
	
	import mx.events.DragEvent;
	import mx.events.ListEvent;
	
	import core.events.MediatorEvent;
	import core.events.ModelEvent;
	import core.model.ParsedModel;
	import core.suppotClass._BaseMediator;
	import core.view.BoneControlView;
	
	public final class BoneControlViewMediator extends _BaseMediator
	{
		[Inject]
		public var parsedModel:ParsedModel;
		
		[Inject]
		public var view:BoneControlView;
		
		override public function initialize():void
		{
			super.initialize();
			
			this.addContextListener(ModelEvent.PARSED_MODEL_DATA_CHANGE, modelHandler);
			this.addContextListener(ModelEvent.PARSED_MODEL_ARMATURE_CHANGE, modelHandler);
			this.addContextListener(ModelEvent.PARSED_MODEL_ANIMATION_CHANGE, modelHandler);
			this.addContextListener(ModelEvent.PARSED_MODEL_BONE_CHANGE, modelHandler);
			this.addContextListener(ModelEvent.PARSED_MODEL_BONE_PARENT_CHANGE, modelHandler);
			
			resetUI();
			
			view.boneTree.addEventListener(ListEvent.CHANGE, boneTreeHandler);
			view.boneTree.addEventListener(DragEvent.DRAG_COMPLETE, boneTreeHandler);
			view.boneTree.addEventListener(ListEvent.ITEM_ROLL_OVER, boneTreeHandler);
			view.boneTree.addEventListener(ListEvent.ITEM_ROLL_OUT, boneTreeHandler);
			view.numOffset.addEventListener(Event.CHANGE, timelineControlHandler);
			view.numScale.addEventListener(Event.CHANGE, timelineControlHandler);
		}
		
		override public function destroy():void
		{
			super.destroy();
			
			this.removeContextListener(ModelEvent.PARSED_MODEL_DATA_CHANGE, modelHandler);
			this.removeContextListener(ModelEvent.PARSED_MODEL_ANIMATION_CHANGE, modelHandler);
			this.removeContextListener(ModelEvent.PARSED_MODEL_BONE_CHANGE, modelHandler);
			this.removeContextListener(ModelEvent.PARSED_MODEL_BONE_PARENT_CHANGE, modelHandler);
			
			view.boneTree.removeEventListener(ListEvent.CHANGE, boneTreeHandler);
			view.boneTree.removeEventListener(DragEvent.DRAG_COMPLETE, boneTreeHandler);
			view.boneTree.removeEventListener(ListEvent.ITEM_ROLL_OVER, boneTreeHandler);
			view.boneTree.removeEventListener(ListEvent.ITEM_ROLL_OUT, boneTreeHandler);
			view.numOffset.removeEventListener(Event.CHANGE, timelineControlHandler);
			view.numScale.removeEventListener(Event.CHANGE, timelineControlHandler);
		}
		
		private function resetUI():void
		{
			view.enabled = false;
			view.boneTree.dataProvider = parsedModel.bonesMC;
		}
		
		private function modelHandler(e:ModelEvent):void
		{
			switch(e.type)
			{
				case ModelEvent.PARSED_MODEL_DATA_CHANGE:
					break;
				case ModelEvent.PARSED_MODEL_ARMATURE_CHANGE:
					if(!parsedModel.armatureSelected)
					{
						resetUI();
					}
					break;
				case ModelEvent.PARSED_MODEL_ANIMATION_CHANGE:
					updateTimelineControl();
					break;
				
				case ModelEvent.PARSED_MODEL_BONE_CHANGE:
					updateTimelineControl();
					view.boneTree.selectItemByName(parsedModel.boneSelected?parsedModel.boneSelected.name:null);
					break;
				
				case ModelEvent.PARSED_MODEL_BONE_PARENT_CHANGE:
					view.boneTree.selectItemByName(parsedModel.boneSelected?parsedModel.boneSelected.name:null);
					break;
				
			}
		}
		
		private function boneTreeHandler(e:Event):void
		{
			var boneName:String;
			switch(e.type)
			{
				case ListEvent.CHANGE:
					var bone:XML = view.boneTree.selectedItem as XML;
					boneName = bone?bone.@name:"";
					parsedModel.boneSelected = parsedModel.armatureSelected.getBoneData(boneName);
					break;
				
				case DragEvent.DRAG_COMPLETE:
					if(view.boneTree.lastMoveNode)
					{
						boneName = view.boneTree.lastMoveNode.@name;
						var boenParent:XML = view.boneTree.lastMoveNode.parent();
						var parentName:String = boenParent.@name;
						if(boenParent.localName() != view.boneTree.lastMoveNode.localName())
						{
							parentName = null;
						}
						
						parsedModel.changeBoneParent(boneName, parentName);
					}
					break;
				
				case ListEvent.ITEM_ROLL_OVER:
					boneName = (e as ListEvent).itemRenderer.data.@name;
					
					this.dispatch(new MediatorEvent(MediatorEvent.ROLL_OVER_BONE, this, boneName));
					break;
				
				case ListEvent.ITEM_ROLL_OUT:
					boneName = (e as ListEvent).itemRenderer.data.@name;
					
					this.dispatch(new MediatorEvent(MediatorEvent.ROLL_OUT_BONE, this, boneName));
					break;
			}
		}
		
		private function timelineControlHandler(e:Event):void
		{
			switch(e.target)
			{
				case view.numScale:
					parsedModel.timelineScale = isNaN(view.numScale.value)?0:view.numScale.value;
					break;
				
				case view.numOffset:
					parsedModel.timelineOffset = isNaN(view.numOffset.value)?0:view.numOffset.value;
					break;
			}
		}
		
		private function updateTimelineControl():void
		{
			view.enabled = true;
			var isMultipleFrameAnimation:Boolean = parsedModel.isMultipleFrameAnimation;
			if(parsedModel.animationSelected && parsedModel.boneSelected && isMultipleFrameAnimation)
			{
				var timelineScale:Number = parsedModel.timelineScale;
				var timelineOffset:Number = parsedModel.timelineOffset;
				view.numScale.enabled = true;
				view.numScale.value = timelineScale;
				
				view.numOffset.enabled = true;
				view.numOffset.value = timelineOffset;
			}
			else
			{
				view.numScale.enabled = false;
				view.numScale.value = 100;
				view.numOffset.enabled = false;
				view.numOffset.value = 0;
			}
		}
	}
}