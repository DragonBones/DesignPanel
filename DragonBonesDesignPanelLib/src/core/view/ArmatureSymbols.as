package core.view
{
	import flash.display.BlendMode;
	import flash.display.Sprite;
	import flash.filters.GlowFilter;
	import flash.geom.Matrix;
	
	import dragonBones.Armature;
	import dragonBones.Bone;
	import dragonBones.objects.EllipseData;
	import dragonBones.objects.IAreaData;
	import dragonBones.objects.RectangleData;
	import dragonBones.utils.TransformUtil;
	
	import light.managers.ElementManager;
	
	public final class ArmatureSymbols extends Sprite
	{
		private static const BONE_SYMBOL:String = "bone";
		
		private var _bonesContainer:Sprite;
		
		private var _armature:Armature;
		public function get armature():Armature
		{
			return _armature;
		}
		public function set armature(value:Armature):void
		{
			if(_armature == value)
			{
				return;
			}
			_armature = value;
			
			clearBones();
			if(_armature)
			{
				createBones();
			}
		}
		
		public function ArmatureSymbols()
		{
			super();
			
			_bonesContainer = new Sprite();
			_bonesContainer.alpha = 0.6;
			this.addChild(_bonesContainer);
			
			light.managers.ElementManager.getInstance().registerElement(BONE_SYMBOL, BoneSymbol);
		}
		
		private function clearBones():void
		{
			var i:int = _bonesContainer.numChildren;
			while(i --)
			{
				var boneSymbol:BoneSymbol = _bonesContainer.removeChildAt(i) as BoneSymbol;
				if(boneSymbol)
				{
					clearAreaContainer(boneSymbol);
					light.managers.ElementManager.getInstance().recycle(boneSymbol);
				}
			}
		}
		
		private function createBones():void
		{
			var areaContainer:Sprite = null;
			
			for each(var bone:Bone in _armature.getBones(false))
			{
				var boneSymbol:BoneSymbol = light.managers.ElementManager.getInstance().getElement(BONE_SYMBOL) as BoneSymbol;
				boneSymbol.blendMode = BlendMode.LAYER;
				boneSymbol.filters =[new GlowFilter(0x000000, 1, 4, 4, 2)];
				boneSymbol.name = bone.name;
				_bonesContainer.addChild(boneSymbol);
				
				boneSymbol.line.visible = false;
				
				addAreaShape(boneSymbol, _armature.armatureData.getBoneData(bone.name).areaDataList);
			}
			
			addAreaShape(_bonesContainer, _armature.armatureData.areaDataList);
		}
		
		private function addAreaShape(container:Sprite, areaDataList:Vector.<IAreaData>):void
		{
			var areaContainer:Sprite = null;
			var helpMatrix:Matrix = new Matrix();
			for each(var areaData:IAreaData in areaDataList)
			{
				var areaShape:Sprite;
				if(areaData is RectangleData)
				{
					if(!areaContainer)
					{
						areaContainer = createAreaContainer(container);
					}
					var rectangleData:RectangleData = areaData as RectangleData;
					
					areaShape = new Sprite();
					areaShape.name = rectangleData.name;
					areaShape.graphics.beginFill(0xFF00FF, 0.3);
					areaShape.graphics.drawRect(rectangleData.pivot.x, rectangleData.pivot.y, rectangleData.width, rectangleData.height);
					TransformUtil.transformToMatrix(rectangleData.transform, helpMatrix, true);
					areaShape.transform.matrix = helpMatrix;
					areaContainer.addChild(areaShape);
				}
				else if(areaData is EllipseData)
				{
					if(!areaContainer)
					{
						areaContainer = createAreaContainer(container);
					}
					var ellipseData:EllipseData = areaData as EllipseData;
					
					areaShape = new Sprite();
					areaShape.name = ellipseData.name;
					areaShape.graphics.beginFill(0xFF00FF, 0.3);
					areaShape.graphics.drawEllipse(ellipseData.pivot.x, ellipseData.pivot.y, ellipseData.width, ellipseData.height);
					TransformUtil.transformToMatrix(ellipseData.transform, helpMatrix, true);
					areaShape.transform.matrix = helpMatrix;
					areaContainer.addChild(areaShape);
				}
			}
		}
		
		private function getAreaContainer(container:Sprite):Sprite
		{
			return container.getChildByName("areaContainer") as Sprite;
		}
		
		private function createAreaContainer(container:Sprite):Sprite
		{
			var areaContainer:Sprite = getAreaContainer(container);
			if(!areaContainer)
			{
				areaContainer = new Sprite();
				areaContainer.name = "areaContainer";
				container.addChild(areaContainer);
			}
			return areaContainer;
		}
		
		private function clearAreaContainer(container:Sprite):void
		{
			var areaContainer:Sprite = getAreaContainer(container);
			if(areaContainer)
			{
				var i:int = areaContainer.numChildren;
				while(i --)
				{
					light.managers.ElementManager.getInstance().recycle(areaContainer.removeChildAt(i));
				}
			}
		}
		
		public function update(scale:Number = 1, selectedBone:Bone = null, isDragBone:Boolean = false):void
		{
			var i:int = 0;
			for each(var bone:Bone in _armature.getBones(false))
			{
				var boneSymbol:BoneSymbol = _bonesContainer.getChildAt(i) as BoneSymbol;
				
				if(!boneSymbol)
				{
					continue;
				}
				
				boneSymbol.x = bone.global.x;
				boneSymbol.y = bone.global.y;
				boneSymbol.rotation = bone.global.rotation * 180 / Math.PI;
				boneSymbol.scaleX = boneSymbol.scaleY = 1 / scale;
				
				if(selectedBone == bone)
				{
					boneSymbol.halo.scaleX = boneSymbol.halo.scaleY = 2;
				}
				else
				{
					boneSymbol.halo.scaleX = boneSymbol.halo.scaleY = 1;
				}
				
				var dX:Number;
				var dY:Number;
				
				if(isDragBone && selectedBone == bone)
				{
					dX = this.mouseX - boneSymbol.x;
					dY = this.mouseY - boneSymbol.y;
					boneSymbol.line.scaleX = Math.sqrt(dX * dX + dY * dY) * scale / 100;
					boneSymbol.line.rotation = Math.atan2(dY, dX) * 180 / Math.PI - boneSymbol.rotation;
					boneSymbol.line.visible = true;
					boneSymbol.visible = true;
				}
				else
				{
					boneSymbol.line.visible = false;
					
					if(bone.parent || bone.getBones().length > 0)
					{
						boneSymbol.visible = true;
					}
					else
					{
						boneSymbol.visible = false;
					}
				}
				
				if(bone.parent)
				{
					dX = bone.parent.global.x - boneSymbol.x;
					dY = bone.parent.global.y - boneSymbol.y;
					boneSymbol.parentLine.line.scaleX = Math.max(Math.sqrt(dX * dX + dY * dY) * scale - 10, 0) / 100;
					boneSymbol.parentLine.rotation = Math.atan2(dY, dX) * 180 / Math.PI - boneSymbol.rotation;
					boneSymbol.parentLine.visible = true;
				}
				else
				{
					boneSymbol.parentLine.visible = false;
				}
				
				var areaContainer:Sprite = getAreaContainer(boneSymbol);
				if(areaContainer)
				{
					areaContainer.scaleX = areaContainer.scaleY = scale;
				}
				
				i ++;
			}
		}
	}
}