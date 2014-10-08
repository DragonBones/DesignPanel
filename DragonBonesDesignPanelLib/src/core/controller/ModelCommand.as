package core.controller
{
	import core.events.ModelEvent;
	import core.model.ImportModel;
	import core.model.ParsedModel;
	import core.service.JSFLService;
	import core.suppotClass._BaseCommand;
	
	import dragonBones.utils.ConstValues;
	
	public final class ModelCommand extends _BaseCommand
	{
		[Inject]
		public var event:ModelEvent;
		
		[Inject]
		public var jsflService:JSFLService;
		
		[Inject (name="importModel")]
		public var importModel:ImportModel;
		
		[Inject]
		public var parsedModel:ParsedModel;
		
		override public function execute():void
		{
			var armatureName:String = parsedModel.armatureSelected.name;
			var animationName:String = parsedModel.animationSelected.name;
			var animation:XML;
			
			switch(event.type)
			{
				case ModelEvent.PARSED_MODEL_ANIMATION_DATA_CHANGE:
					armatureName = parsedModel.armatureSelected.name;
					animationName = parsedModel.animationSelected.name;
					
					importModel.updateAnimationFromData(armatureName, parsedModel.animationSelected);
					
					if(importModel.vo.isImportFromFLA)
					{
						animation = importModel.getAnimationList(armatureName, animationName)[0].copy();
						delete animation[ConstValues.TIMELINE].*;
						delete animation[ConstValues.FRAME];
						
						jsflService.runJSFLMethod(null, "dragonBones.DragonBones.changeAnimation", parsedModel.vo.importVO.id, armatureName, animationName, animation);
					}
					
					break;
					
				case ModelEvent.PARSED_MODEL_TIMELINE_DATA_CHANGE:
					armatureName = parsedModel.armatureSelected.name;
					animationName = parsedModel.animationSelected.name;
					
					importModel.updateTransformTimelineFromData(armatureName, animationName, parsedModel.animationSelected.getTimeline(parsedModel.boneSelected.name));
					
					if(importModel.vo.isImportFromFLA)
					{
						animation = importModel.getAnimationList(armatureName, animationName)[0].copy();
						delete animation[ConstValues.TIMELINE].*;
						delete animation[ConstValues.FRAME];
						
						jsflService.runJSFLMethod(null, "dragonBones.DragonBones.changeAnimation", parsedModel.vo.importVO.id, armatureName, animationName, animation);
					}
					break;
				
				case ModelEvent.PARSED_MODEL_BONE_PARENT_CHANGE:
					armatureName = parsedModel.armatureSelected.name;
					
					importModel.changeBoneParent(armatureName, event.data[0], event.data[1]);
					
					if(importModel.vo.isImportFromFLA)
					{
						var armature:XML = importModel.getArmatureList(armatureName)[0].copy();
						delete armature[ConstValues.ANIMATION];
						delete armature[ConstValues.SKIN];
						delete armature[ConstValues.BONE].*;
						
						jsflService.runJSFLMethod(null, "dragonBones.DragonBones.changeArmatureConnection", parsedModel.vo.importVO.id, armatureName, armature);
					}
					break;
			}
		}
	}
}