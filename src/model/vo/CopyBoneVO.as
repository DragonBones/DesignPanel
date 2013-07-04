package model.vo
{
	public class CopyBoneVO
	{
		public var armatureName:String;
		public var armatureXML:XML;
		
		public function CopyBoneVO(armatureName:String, armatureXML:XML)
		{
			this.armatureName = armatureName;
			this.armatureXML = armatureXML;
		}
	}
}