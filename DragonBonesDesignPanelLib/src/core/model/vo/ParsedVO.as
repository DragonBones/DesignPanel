package core.model.vo
{
	import dragonBones.objects.SkeletonData;
	import dragonBones.textures.NativeTextureAtlas;

	public final class ParsedVO
	{
		public var importVO:ImportVO = null;
		
		public var skeleton:SkeletonData = null;
		public var textureAtlas:NativeTextureAtlas = null;
		
		public function ParsedVO()
		{
		}
	}
}