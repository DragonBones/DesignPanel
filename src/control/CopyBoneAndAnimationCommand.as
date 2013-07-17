package control
{
	import message.Message;
	import message.MessageDispatcher;
	
	import model.JSFLProxy;
	import model.vo.CopyAnimationVO;
	import model.vo.CopyBoneVO;

	public class CopyBoneAndAnimationCommand
	{
		public static const instance:CopyBoneAndAnimationCommand = new CopyBoneAndAnimationCommand();
		
		private var _copyAnimationTotal:uint;
		private var _copyAnimationVOList:Vector.<CopyAnimationVO>;
		
		private var _isCopying:Boolean;
		
		public function CopyBoneAndAnimationCommand()
		{
		}
		
		public function copy(copyBoneVOList:Vector.<CopyBoneVO>, copyAnimationVOList:Vector.<CopyAnimationVO>):void
		{
			if(_isCopying)
			{
				return;
			}
			
			_isCopying = true;
			_copyAnimationVOList = copyAnimationVOList;
			
			for each(var copyBoneVO:CopyBoneVO in copyBoneVOList)
			{
				JSFLProxy.getInstance().changeArmatureConnection(copyBoneVO.armatureName, copyBoneVO.armatureXML);
			}
			
			_copyAnimationTotal = _copyAnimationVOList.length;
			if(_copyAnimationTotal > 0)
			{
				MessageDispatcher.dispatchEvent(MessageDispatcher.SAVE_ANIMATION_START);
				MessageDispatcher.addEventListener(JSFLProxy.COPY_ANIMATION, copyAnimationHandler);
				copyAnimationHandler(null);
			}
		}
		
		private function copyAnimationHandler(e:Message):void
		{
			if(_copyAnimationVOList.length > 0)
			{
				MessageDispatcher.dispatchEvent(MessageDispatcher.SAVE_ANIMATION_PROGRESS, _copyAnimationTotal - _copyAnimationVOList.length, _copyAnimationTotal);
				
				var copyAnimationVO:CopyAnimationVO = _copyAnimationVOList.pop();
				
				JSFLProxy.getInstance().copyAnimation(
					copyAnimationVO.armatureName,
					copyAnimationVO.sourceArmatureName, 
					copyAnimationVO.animationName, 
					copyAnimationVO.animationXML
				);
			}
			else
			{
				MessageDispatcher.removeEventListener(JSFLProxy.COPY_ANIMATION, copyAnimationHandler);
				MessageDispatcher.dispatchEvent(MessageDispatcher.SAVE_ANIMATION_COMPLETE);
				_isCopying = false;
			}
		}
	}
}