package model{
	import flash.errors.IllegalOperationError;
	
	[Bindable]
	/**
	 * Manage data to export
	 */
	public class ExportDataProxy{
		private static var instance:ExportDataProxy;
		public static function getInstance():ExportDataProxy{
			if(!instance){
				instance = new ExportDataProxy();
			}
			return instance;
		}
		
		private var __dataExportID:int = 0;
		public function get dataExportID():int{
			return __dataExportID;
		}
		
		public function set dataExportID(value:int):void{
			__dataExportID = value;
			ShareObjectDataProxy.getInstance().setData("dataExportID", __dataExportID);
		}
		
		public function ExportDataProxy(){
			if (instance) {
				throw new IllegalOperationError("Singleton already constructed!");
			}
			
			__dataExportID = ShareObjectDataProxy.getInstance().getOrSetData("dataExportID", 0);
		}
	}
}