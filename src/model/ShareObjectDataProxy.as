package model{
	import flash.errors.IllegalOperationError;
	import flash.net.SharedObject;
	
	/**
	 * 管理面板ShareObject
	 */
	public class ShareObjectDataProxy{
		private static const SHARE_LOCAL:String = "DragonBones/SkeletonDesignPanel/V1";
		
		private static var instance:ShareObjectDataProxy;
		public static function getInstance():ShareObjectDataProxy{
			if(!instance){
				instance = new ShareObjectDataProxy();
			}
			return instance;
		}
		
		private var shareObject:SharedObject;
		
		public function ShareObjectDataProxy(){
			if (instance) {
				throw new IllegalOperationError("Singleton already constructed!");
			}
			
			shareObject = SharedObject.getLocal(SHARE_LOCAL, "/");
		}
		
		/**
		 * 判断 ShareObject 中是否设置过指定的值
		 */
		public function hasData(_key:String):Boolean{
			return Boolean(_key in shareObject.data);
		}
		
		/**
		 * 从 ShareObject 中获取指定的值
		 */
		public function getData(_key:String):*{
			return shareObject.data[_key];
		}
		
		/**
		 * 设置 ShareObject 中指定的值
		 */
		public function setData(_key:String, _value:*):void{
			shareObject.data[_key] = _value;
			shareObject.flush();
		}
		
		/**
		 * 从 ShareObject 中获取指定的值，如果未赋值，则向 ShareObject 添加值
		 */
		public function getOrSetData(_key:String, _value:*):*{
			if(hasData(_key)){
				return getData(_key);
			}
			setData(_key, _value);
			return _value;
		}
	}
}