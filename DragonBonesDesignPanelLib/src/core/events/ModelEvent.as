package core.events
{
	import flash.events.Event;
	
	import core.suppotClass._BaseModel;
	
	public final class ModelEvent extends Event
	{
		//parsed model event
		public static const PARSED_MODEL_DATA_CHANGE:String = "PARSED_MODEL_DATA_CHANGE";
		public static const PARSED_MODEL_ARMATURE_CHANGE:String = "PARSED_MODEL_ARMATURE_CHANGE";
		public static const PARSED_MODEL_SKIN_CHANGE:String = "PARSED_MODEL_SKIN_CHANGE";
		public static const PARSED_MODEL_ANIMATION_CHANGE:String = "PARSED_MODEL_ANIMATION_CHANGE";
		public static const PARSED_MODEL_BONE_CHANGE:String = "PARSED_MODEL_BONE_CHANGE";
		public static const PARSED_MODEL_ANIMATION_DATA_CHANGE:String = "PARSED_MODEL_ANIMATION_DATA_CHANG";
		public static const PARSED_MODEL_BONE_PARENT_CHANGE:String = "PARSED_MODEL_BONE_PARENT_CHANGE";
		public static const PARSED_MODEL_TIMELINE_DATA_CHANGE:String = "PARSED_MODEL_TIMELINE_DATA_CHANG";
		
		public var model:_BaseModel;
		public var data:*;
		
		public function ModelEvent(type:String, model:_BaseModel, data:* = null, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
			
			this.model = model;
			this.data = data;
		}
	}
}