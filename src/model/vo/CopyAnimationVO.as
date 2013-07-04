package model.vo
{
	public class CopyAnimationVO
	{
		public var armatureName:String;
		public var sourceArmatureName:String;
		public var animationName:String;
		public var animationXML:XML;
		
		public function CopyAnimationVO(armatureName:String, sourceArmatureName:String, animationName:String, animationXML:XML)
		{
			this.armatureName = armatureName;
			this.sourceArmatureName = sourceArmatureName;
			this.animationName = animationName;
			this.animationXML = animationXML;
		}
	}
}