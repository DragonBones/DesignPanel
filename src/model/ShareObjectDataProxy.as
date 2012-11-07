package model{
	import flash.errors.IllegalOperationError;
	import flash.net.SharedObject;
	
	/**
	 * Manage UI Panel's SharedObject
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
		 * Determine if key is exist
		 */
		public function hasData(_key:String):Boolean{
			return Boolean(_key in shareObject.data);
		}
		
		/**
		 * Get data by key
		 */
		public function getData(_key:String):*{
			return shareObject.data[_key];
		}
		
		/**
		 * Set data by key and value
		 */
		public function setData(_key:String, _value:*):void{
			shareObject.data[_key] = _value;
			shareObject.flush();
		}
		
		/**
		 * Get key or Set key
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