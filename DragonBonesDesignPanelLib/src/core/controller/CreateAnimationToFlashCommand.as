package core.controller
{
	import core.events.ControllerEvent;
	import core.events.ServiceEvent;
	import core.model.ImportModel;
	import core.model.ParsedModel;
	import core.service.JSFLService;
	import core.suppotClass._BaseCommand;
	
	import dragonBones.utils.ConstValues;
	
	public final class CreateAnimationToFlashCommand extends _BaseCommand
	{
		[Inject]
		public var event:ControllerEvent;
		
		[Inject]
		public var jsflService:JSFLService;
		
		[Inject (name="importModel")]
		public var importModel:ImportModel;
		
		[Inject]
		public var parsedModel:ParsedModel;
		
		private var _createAnimationList:Vector.<String>;
		private var _armatureName:String;
		private var _armature:XML;
		private var _animationList:XMLList;
		private var _index:int;
		private var _isPassedFirst:Boolean;
		
		override public function execute():void
		{
			if (parsedModel.vo.importVO)
			{
				this.directCommandMap.detain(this);
				_armatureName = parsedModel.armatureSelected.name;				
				if (event.data && event.data[0])
				{
					_createAnimationList = new Vector.<String>;
					_createAnimationList.push(parsedModel.animationSelected.name);
				}
				
				_armature = importModel.getArmatureList(_armatureName)[0].copy();
				delete _armature[ConstValues.ANIMATION];
				delete _armature[ConstValues.SKIN];
				delete _armature[ConstValues.BONE].*;
				
				_animationList = importModel.getAnimationList(_armatureName);
				_index = 0;
				
				nextAnimation(true);
			}
		}
			
		private function nextAnimation(isFirstData:Boolean):void
		{
			if(_index >= _animationList.length())
			{
				directCommandMap.release(this);
				return;
			}
			
			var animation:XML = _animationList[_index];
			var animationName:String = animation.@[ConstValues.A_NAME];
			_index ++;
			
			if (_createAnimationList && _createAnimationList.length > 0)
			{
				if (_createAnimationList.indexOf(animationName) < 0)
				{
					nextAnimation(!_isPassedFirst);
					return;
				}
			}
			_isPassedFirst = true;
			jsflService.runJSFLMethod(null, "dragonBonesExtensions.createArmatureAnimation", _armatureName, animationName, animation, _armature, isFirstData?true:"", jsflServerHandler);
		}
		
		private function jsflServerHandler(e:ServiceEvent):void
		{
			var result:String = e.data as String;
			if(result != "false")
			{
				_armatureName = result;
				nextAnimation(false);
			}
			else
			{
				directCommandMap.release(this);
			}
		}
	}
}