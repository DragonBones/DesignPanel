package control
{
	import dragonBones.objects.AnimationData;
	import dragonBones.objects.ArmatureData;
	import dragonBones.objects.BoneData;
	import dragonBones.objects.FrameData;
	import dragonBones.objects.MovementBoneData;
	import dragonBones.objects.MovementData;
	import dragonBones.objects.Node;
	import dragonBones.objects.SkeletonData;
	import dragonBones.objects.XMLDataParser;
	import dragonBones.utils.ConstValues;
	import dragonBones.utils.TransformUtils;
	import dragonBones.utils.dragonBones_internal;
	
	import flash.geom.Matrix;
	import flash.geom.Point;
	
	import message.Message;
	import message.MessageDispatcher;
	
	import model.JSFLProxy;
	
	use namespace dragonBones_internal;
	
	public class CopyArmatureCommand
	{
		public static const instance:CopyArmatureCommand = new CopyArmatureCommand();
		
		private var _boneData:BoneData;
		private var _frameNode:Node;
		private var _parentFrameData:FrameData;
		private var _tweenFrameData:FrameData;
		private var _helpMatrix:Matrix;
		private var _helpPoint:Point;
		
		private var _targetArmatureName:String;
		private var _sourceArmatureName:String;
		private var _sourceAnimationData:AnimationData;
		private var _sourceAnimationXML:XML;
		private var _targetArmatureXML:XML;
		
		private var _sourceMovementList:Vector.<String>;
		private var _targetMovementList:Vector.<String>;
		private var _boneList:Array;
		
		
		public function CopyArmatureCommand()
		{
			_boneData = new BoneData();
			_frameNode = new Node();
			_parentFrameData = new FrameData();
			_tweenFrameData = new FrameData();
			_helpMatrix = new Matrix();
			_helpPoint = new Point();
		}
		
		public function copyArmatureFrom(targetArmatureXML:XML, sourceArmatureXML:XML, sourceAnimationXML:XML, skeletonData:SkeletonData):void
		{
			//目标骨架xml，并制作副本，需要修改这个副本中的骨骼从属关系（<b parent=""/>），并把此xml传递给JSFL写入从属关系，其中的坐标数据会被用到重新建立相对坐标
			_targetArmatureXML = targetArmatureXML.copy();
			_sourceAnimationXML = sourceAnimationXML;
			
			var targetBoneXMLList:XMLList = _targetArmatureXML.elements(ConstValues.BONE);
			var sourceBoneXMLList:XMLList = sourceArmatureXML.elements(ConstValues.BONE);
			
			var hasSameBone:Boolean;
			//骨架中骨骼复制替换原则
			var boneNames:Object = {};
			for each(var targetBoneXML:XML in targetBoneXMLList)
			{
				var boneName:String = targetBoneXML.attribute(ConstValues.A_NAME);
				//遍历目标骨架中每个骨骼，从源骨架中找到同名骨骼数据
				var sourceBoneXML:XML = XMLDataParser.getElementsByAttribute(sourceBoneXMLList, ConstValues.A_NAME, boneName)[0];
				
				if(sourceBoneXML)
				{
					//获取该骨骼在源骨架中匹配的父骨骼
					//比如源骨架A 骨骼从属为a>b>c
					//目标骨架B 骨骼无从属关系（有没有都无所谓，以A骨骼从属关系为准），有骨骼a、c
					//则之后B的骨骼从属关系会变为a>c
					//因为考虑到动画细致程度，比如细致些的动画有手臂>手>武器，而粗糙一点的动画则为手臂>武器，这样继承感觉更加合理
					var parentName:String = getBoneParentName(boneName, targetBoneXMLList, sourceBoneXMLList);
					
					//写入从属关系
					if(parentName)
					{
						targetBoneXML.@[ConstValues.A_PARENT] = parentName;
						boneNames[boneName] = parentName;
					}
					else
					{
						delete targetBoneXML.@[ConstValues.A_PARENT];
						boneNames[boneName] = false;
					}
					hasSameBone = true;
				}
			}
			
			if(!hasSameBone)
			{
				//没有一个同名的骨骼，则不执行
				return;
			}
			
			//得到一个按照从属关系充根到叶排序的骨骼列表boneList
			var boneList:Array = [];
			for(boneName in boneNames)
			{
				parentName = boneNames[boneName];
				var depth:int = 0;
				while(parentName)
				{
					depth ++;
					parentName = boneNames[parentName];
				}
				boneList.push({depth:depth, boneName:boneName});
			}
			var length:int = boneList.length;
			if(length > 0)
			{
				boneList.sortOn("depth", Array.NUMERIC);
				var i:int = 0;
				while(i < length)
				{
					boneList[i] = boneList[i].boneName;
					i ++;
				}
			}
			
			//暂存分布JSFL运算需要用到的变量
			_targetArmatureName = _targetArmatureXML.attribute(ConstValues.A_NAME);
			_sourceArmatureName = sourceArmatureXML.attribute(ConstValues.A_NAME);
			_sourceAnimationData = skeletonData.getAnimationData(_sourceArmatureName);
			_sourceMovementList = _sourceAnimationData.movementList;
			var targetAnimationData:AnimationData = skeletonData.getAnimationData(_targetArmatureName);
			if(targetAnimationData)
			{
				_targetMovementList = targetAnimationData.movementList;
			}
			else
			{
				_targetMovementList = new Vector.<String>;
			}
			_boneList = boneList;
			
			copyNextMovement();
		}
		
		private function getBoneParentName(boneName:String, targetBoneXMLList:XMLList, sourceBoneXMLList:XMLList):String
		{
			while(true)
			{
				var boneXML:XML = XMLDataParser.getElementsByAttribute(sourceBoneXMLList, ConstValues.A_NAME, boneName)[0];
				boneName = boneXML.attribute(ConstValues.A_PARENT);
				if(boneName)
				{
					boneXML = XMLDataParser.getElementsByAttribute(targetBoneXMLList, ConstValues.A_NAME, boneName)[0];
					if(boneXML)
					{
						break;
					}
				}
				else
				{
					break;
				}
			}
			return boneName;
		}
		
		private function copyNextMovement():void
		{
			//过滤掉目标骨架和源骨架同名的动画，比如都有run，或者以后可以考虑删除覆盖源数据中的动画？
			do
			{
				if(_sourceMovementList.length > 0)
				{
					var movementName:String = _sourceMovementList.shift();
				}
				else
				{
					commandComplete();
					return;
				}
			}
			while(movementName && _targetMovementList.indexOf(movementName) >= 0);
			
			var movementData:MovementData = _sourceAnimationData.getMovementData(movementName);
			var movementXML:XML = XMLDataParser.getElementsByAttribute(_sourceAnimationXML.elements(ConstValues.MOVEMENT), ConstValues.A_NAME, movementName)[0];
			//源骨架动画单个动作的数据movementXML，其内部坐标数据没有意义，会被全部重写，被当作动画数据模板
			movementXML = movementXML.copy();
			var targetBoneXMLList:XMLList = _targetArmatureXML.elements(ConstValues.BONE);
			
			//遍历目标骨架的每个骨骼
			for each(var boneName:String in _boneList)
			{
				var movementBoneData:MovementBoneData = movementData.getMovementBoneData(boneName);
				if(movementBoneData)
				{
					//找到目标骨骼和其父骨骼，重新计算相对新的父骨骼（可能骨骼从属关系在复制骨架的时候被改变了）坐标，并存储在_boneData中
					var boneXML:XML = XMLDataParser.getElementsByAttribute(targetBoneXMLList, ConstValues.A_NAME, boneName)[0];
					var parentName:String = boneXML.attribute(ConstValues.A_PARENT);
					var parentXML:XML = XMLDataParser.getElementsByAttribute(targetBoneXMLList, ConstValues.A_NAME, parentName)[0];
					XMLDataParser.parseBoneData(boneXML, parentXML, _boneData);
					
					//找到当前源骨架同名骨骼以及其父骨骼的动画数据
					var movementBoneXMLList:XMLList = movementXML.elements(ConstValues.BONE);
					var movementBoneXML:XML = XMLDataParser.getElementsByAttribute(movementBoneXMLList, ConstValues.A_NAME, boneName)[0];
					var parentMovementBoneXML:XML = XMLDataParser.getElementsByAttribute(movementBoneXMLList, ConstValues.A_NAME, parentName)[0];
					
					//有父骨骼，则需要做准备工作，需要坐标变换
					if(parentMovementBoneXML)
					{
						var i:uint = 0;
						var parentTotalDuration:uint = 0;
						var totalDuration:uint = 0;
						var currentDuration:uint = 0;
						var parentFrameXMLList:XMLList = parentMovementBoneXML.elements(ConstValues.FRAME);
						var parentFrameCount:uint = parentFrameXMLList.length();
						var parentFrameXML:XML = null;
					}
					
					//遍历每个骨骼关键帧
					var frameXMLList:XMLList = movementBoneXML.elements(ConstValues.FRAME);
					var frameCount:uint = frameXMLList.length();
					for(var j:int = 0;j < frameCount;j ++)
					{
						var frameData:FrameData = movementBoneData.getFrameDataAt(j);
						
						//目标的动画坐标为目标骨架坐标 +关键帧相对坐标
						_frameNode.x = _boneData.x + frameData.x;
						_frameNode.y = _boneData.y + frameData.y;
						_frameNode.skewX = _boneData.skewX + frameData.skewX;
						_frameNode.skewY = _boneData.skewY + frameData.skewY;
						_frameNode.scaleX = _boneData.scaleX + frameData.scaleX;
						_frameNode.scaleY = _boneData.scaleY + frameData.scaleY;
						_frameNode.pivotX = _boneData.pivotX + frameData.pivotX;
						_frameNode.pivotY = _boneData.pivotY + frameData.pivotY;
						
						//如果有从属关系
						if(parentMovementBoneXML)
						{
							//找到父级动画的当前关键帧
							while(i < parentFrameCount && (parentFrameXML?(totalDuration < parentTotalDuration || totalDuration >= parentTotalDuration + currentDuration):true))
							{
								parentFrameXML = parentFrameXMLList[i];
								parentTotalDuration += currentDuration;
								currentDuration = int(parentFrameXML.attribute(ConstValues.A_DURATION));
								i++;
							}
							XMLDataParser.parseFrameData(parentFrameXML, _parentFrameData);
							
							//找到父级动画的下一个关键帧，并计算补间进度，因为动画的关键帧可能不是一一对应的
							var tweenFrameXML:XML = parentFrameXMLList[i];
							var progress:Number;
							if(tweenFrameXML)
							{
								progress = (totalDuration - parentTotalDuration) / currentDuration;
							}
							else
							{
								tweenFrameXML = parentFrameXML;
								progress = 0;
							}
							XMLDataParser.parseFrameData(tweenFrameXML, _tweenFrameData);
							
							//将两个XML转成的node计算出补间关键点，再转换为矩阵
							var parentNode:Node = TransformUtils.getTweenNode(_parentFrameData, _tweenFrameData, progress, _parentFrameData.tweenEasing);
							TransformUtils.nodeToMatrix(parentNode, _helpMatrix);
							
							//坐标变换
							_helpPoint.x = _frameNode.x;
							_helpPoint.y = _frameNode.y;
							_helpPoint = _helpMatrix.transformPoint(_helpPoint);
							_frameNode.x = _helpPoint.x;
							_frameNode.y = _helpPoint.y;
							_frameNode.skewX += _parentFrameData.skewX;
							_frameNode.skewY += _parentFrameData.skewY;
						}
						
						//写入关键帧坐标
						var frameXML:XML = frameXMLList[j];
						totalDuration += int(frameXML.attribute(ConstValues.A_DURATION));
						frameXML.@[ConstValues.A_X] = _frameNode.x;
						frameXML.@[ConstValues.A_Y] = _frameNode.y;
						frameXML.@[ConstValues.A_SKEW_X] = _frameNode.skewX * 180 / Math.PI;
						frameXML.@[ConstValues.A_SKEW_Y] = _frameNode.skewY * 180 / Math.PI;
						frameXML.@[ConstValues.A_SCALE_X] = _frameNode.scaleX;
						frameXML.@[ConstValues.A_SCALE_Y] = _frameNode.scaleY;
						frameXML.@[ConstValues.A_PIVOT_X] = _frameNode.pivotX;
						frameXML.@[ConstValues.A_PIVOT_Y] = _frameNode.pivotY;
					}
				}
			}
			
			//JSFL输出当前动作数据
			MessageDispatcher.addEventListener(JSFLProxy.COPY_MOVEMENT, jsflProxyHandler);
			JSFLProxy.getInstance().copyMovement(_targetArmatureName, _sourceArmatureName, movementName, movementXML);
		}
		
		private function jsflProxyHandler(e:Message):void
		{
			MessageDispatcher.removeEventListener(JSFLProxy.COPY_MOVEMENT, jsflProxyHandler);
			
			if(_sourceMovementList.length > 0)
			{
				//继续复制下一个动作
				copyNextMovement();
			}
			else
			{
				commandComplete();
			}
		}
		
		private function commandComplete():void
		{
			//向目标骨架写入从属数据
			JSFLProxy.getInstance().changeArmatureConnection(_targetArmatureName, _targetArmatureXML);
			
			//此时需要自动同步FLA的数据到面板中，即自动import？
		}
	}
}