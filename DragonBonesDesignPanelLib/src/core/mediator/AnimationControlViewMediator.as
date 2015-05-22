package core.mediator
{
	import core.events.ModelEvent;
	import core.model.ParsedModel;
	import core.suppotClass._BaseMediator;
	import core.view.AnimationControlView;
	
	import flash.events.Event;
	import flash.events.MouseEvent;
	
	import mx.binding.utils.BindingUtils;
	
	public final class AnimationControlViewMediator extends _BaseMediator
	{
		[Inject]
		public var parsedModel:ParsedModel;
		
		[Inject]
		public var view:AnimationControlView;
		
		override public function initialize():void
		{
			super.initialize();
			
			this.addContextListener(ModelEvent.PARSED_MODEL_DATA_CHANGE, modelHandler);
			this.addContextListener(ModelEvent.PARSED_MODEL_ARMATURE_CHANGE, modelHandler);
			this.addContextListener(ModelEvent.PARSED_MODEL_ANIMATION_CHANGE, modelHandler);
			
			resetUI();
			
			BindingUtils.bindProperty(view.animationList, "selectedItem", parsedModel, "animationSelected", false);
			BindingUtils.bindProperty(parsedModel, "animationSelected", view.animationList, "selectedItem", false);
			
			view.numFadeInTime.addEventListener(Event.CHANGE, animationControlHandler);
			view.numAnimationScale.addEventListener(Event.CHANGE, animationControlHandler);
			view.numLoop.addEventListener(Event.CHANGE, animationControlHandler);
			view.checkAutoTween.addEventListener(Event.CHANGE, animationControlHandler);
			//view.numTweenEasing.addEventListener(Event.CHANGE, animationControlHandler);
			//view.checkTweenEasing.addEventListener(Event.CHANGE, animationControlHandler);
		}
		
		override public function destroy():void
		{
			super.destroy();
			
			this.removeContextListener(ModelEvent.PARSED_MODEL_DATA_CHANGE, modelHandler);
			this.removeContextListener(ModelEvent.PARSED_MODEL_ANIMATION_CHANGE, modelHandler)
			
			view.numFadeInTime.removeEventListener(Event.CHANGE, animationControlHandler);
			view.numAnimationScale.removeEventListener(Event.CHANGE, animationControlHandler);
			view.numLoop.removeEventListener(Event.CHANGE, animationControlHandler);
			view.checkAutoTween.removeEventListener(Event.CHANGE, animationControlHandler);
			//view.numTweenEasing.addEventListener(Event.CHANGE, animationControlHandler);
			//view.checkTweenEasing.addEventListener(Event.CHANGE, animationControlHandler);
		}
		
		private function resetUI():void
		{
			view.enabled = false;
			view.animationList.dataProvider = parsedModel.animationsAC;
			view.animationList.selectedItem = null;
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
					if(!parsedModel.armatureSelected)
					{
						resetUI();
					}
					break;
				case ModelEvent.PARSED_MODEL_ANIMATION_CHANGE:
					if(parsedModel.animationSelected)
					{
						view.enabled = true;
						
						var isMultipleFrameAnimation:Boolean = parsedModel.isMultipleFrameAnimation;
						
						view.numFadeInTime.value = parsedModel.fadeInTime;
						
						if(isMultipleFrameAnimation)
						{
							view.numAnimationScale.value = parsedModel.animationScale * 100;
							view.numAnimationScale.enabled = true;
							view.numAnimationTotalTime.text = parsedModel.durationScaled.toString();
							view.numLoop.enabled = true;
							view.numLoop.value = parsedModel.playTimes;
							
							view.checkAutoTween.enabled = true;
							view.checkAutoTween.selected = parsedModel.autoTween;
							
							/*view.checkTweenEasing.enabled = true;
							if(isNaN(tweenEasing))
							{
								view.checkTweenEasing.selected = false;
								view.numTweenEasing.enabled = false;
								view.numTweenEasing.value = 0;
							}
							else
							{
								view.checkTweenEasing.selected = true;
								view.numTweenEasing.enabled = true;
								view.numTweenEasing.value = tweenEasing;
							}*/
						}
						else
						{
							view.numAnimationScale.enabled = false;
							view.numAnimationScale.value = 100;
							view.numAnimationTotalTime.text = "0";
							view.numLoop.enabled = false;
							view.numLoop.value = 1;
							view.checkAutoTween.enabled = false;
							view.checkAutoTween.selected = false;
							//view.checkTweenEasing.enabled = false;
							//view.numTweenEasing.enabled = false;
						}
					}
					else
					{
						view.enabled = false;
					}
					break;
			}
		}
		
		private function animationControlHandler(e:Event):void
		{
			switch(e.target)
			{
				case view.numFadeInTime:
					parsedModel.fadeInTime = view.numFadeInTime.value;
					view.numFadeInTime.value = parsedModel.fadeInTime;
					break;
				
				case view.numAnimationScale:
					parsedModel.animationScale = view.numAnimationScale.value * 0.01;
					view.numAnimationScale.value = parsedModel.animationScale * 100;
					view.numAnimationTotalTime.text = parsedModel.durationScaled.toString();;
					break;
				
				case view.numLoop:
					parsedModel.playTimes = view.numLoop.value;
					view.numLoop.value = parsedModel.playTimes;
					break;
				
				case view.checkAutoTween:
					parsedModel.autoTween = view.checkAutoTween.selected;
					break;
				
				/*
				case view.numTweenEasing:
					model.tweenEasing = view.numTweenEasing.value;
					break;
				
				case view.checkTweenEasing:
					if(view.checkTweenEasing.selected)
					{
						model.tweenEasing = 0;
					}
					else
					{
						model.tweenEasing = NaN;
					}
					break;
				*/
			}
		}
	}
}