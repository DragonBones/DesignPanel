package core.controller
{
	import com.adobe.serialization.json.JSON;
	
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.URLLoaderDataFormat;
	import flash.utils.ByteArray;
	
	import core.SettingManager;
	import core.events.ControllerEvent;
	import core.events.ServiceEvent;
	import core.model.vo.ExportVO;
	import core.model.vo.ImportVO;
	import core.service.ImportDataToExportDataService;
	import core.service.ImportFLAService;
	import core.service.ImportFileService;
	import core.service.JSFLService;
	import core.suppotClass._BaseCommand;
	import core.utils.GlobalConstValues;
	
	import light.managers.RequestManager;
	
	public final class MultipleImportAndExportCommand extends _BaseCommand
	{
		private static const BROWSE_FILES:String = "browseFiles";
		private static const OPEN_FLA_DOCUMENT:String = "openFLADocument";
		
		private static const _jsflScript:XML = 
			<root>
				<browseFLA>
<![CDATA[
	(function()
	{
		var folderURL = fl.browseForFolderURL("Select a folder that contains flas.");
		if (!folderURL)
		{
			return false;
		}
		return utils.Utils.encodeJSON(utils.Utils.filterFileList(folderURL, /\.(fla)$/i));
	})();
]]>
				</browseFLA>
				<browseExportedFile>
<![CDATA[
	(function()
	{
		var folderURL = fl.browseForFolderURL("Select a folder that contains exported files.");
		if (!folderURL)
		{
			return false;
		}
		return utils.Utils.encodeJSON(utils.Utils.filterFileList(folderURL, /\.(png|dbswf|xml|zip)$/i));
	})();
]]>
				</browseExportedFile>
			</root>;
		
		[Inject]
		public var event:ControllerEvent;
		
		[Inject]
		public var jsflService:JSFLService;
		
		[Inject]
		public var importFLAService:ImportFLAService;
		
		[Inject]
		public var importFileService:ImportFileService;
		
		[Inject]
		public var importDataToExportDataService:ImportDataToExportDataService;
		
		private var _isFLAFile:Boolean;
		private var _fileList:Array;
		
		private var _saveFunction:Function;
		
		private var _settingManager:SettingManager;
		
		override public function execute():void
		{
			this.directCommandMap.detain(this);
			
			_settingManager = SettingManager.getInstance();
			
			_isFLAFile = _settingManager.importTypeAC.source[_settingManager.importTypeIndex].value != GlobalConstValues.IMPORT_TYPE_EXPORTED;
			
			var params:Array = event.data as Array;
			_fileList = params? params[0]: null;
			_saveFunction = params? params[1]: null;
			
			if (_fileList)
			{
				importNextFile();
			}
			else
			{
				jsflService.runJSFLCode(BROWSE_FILES, _isFLAFile? _jsflScript.browseFLA.text(): _jsflScript.browseExportedFile.text(), jsflServerHandler);
			}
		}
		
		private function jsflServerHandler(e:ServiceEvent):void
		{
			switch(e.type)
			{
				case BROWSE_FILES:
					var result:String = e.data as String;
					if (result != "false")
					{
						try
						{
							_fileList = com.adobe.serialization.json.JSON.decode(result);
							importNextFile();
							return;
						}
						catch(error:Error)
						{
						}
					}
					directCommandMap.release(this);
					break;
				
				case OPEN_FLA_DOCUMENT:
					importCurrentFLAFile();
					break;
			}
		}
		
		private function loadFileHandler(e:Event):void
		{
			switch(e.type)
			{
				case IOErrorEvent.IO_ERROR:
					// log
					importNextFile();
					break;
				
				case SecurityErrorEvent.SECURITY_ERROR:
					// log
					importNextFile();
					break;
				
				case Event.COMPLETE:
					importCurrentExportedFile(e.target.data);
					break;
			}
		}
		
		private function importNextFile():void
		{
			if (_fileList && _fileList.length > 0)
			{
				var file:Object = _fileList.pop();
				if (_isFLAFile)
				{
					jsflService.runJSFLMethod(OPEN_FLA_DOCUMENT, "fl.openDocument", file.url, jsflServerHandler);
				}
				else
				{
					RequestManager.getInstance().load(file.url, loadFileHandler, true, null, null, null, null, URLLoaderDataFormat.BINARY);
				}
			}
			else
			{
				directCommandMap.release(this);
			}
		}
		
		private function importCurrentExportedFile(fileData:ByteArray):void
		{
			var importVO:ImportVO = new ImportVO();
			_settingManager.setImportVOValues(importVO);
			importVO.importType = GlobalConstValues.IMPORT_TYPE_EXPORTED;
			importVO.isToMerge = false;
			importVO.data = fileData;
			//importVO.url = url;
			
			importFileService.addEventListener(ImportFileService.IMPORT_FILE_ERROR, importServiceHandler);
			importFileService.addEventListener(ImportFileService.IMPORT_FILE_COMPLETE, importServiceHandler);
			importFileService.startImport(importVO);
		}
		
		private function importCurrentFLAFile():void
		{
			var importVO:ImportVO = new ImportVO();
			_settingManager.setImportVOValues(importVO);
			importVO.importType = GlobalConstValues.IMPORT_TYPE_FLA_ALL_LIBRARY_ITEMS;
			importVO.isToMerge = false;
			//importVO.url = url;
			
			importFLAService.addEventListener(ImportFLAService.IMPORT_FLA_ERROR, importServiceHandler);
			importFLAService.addEventListener(ImportFLAService.IMPORT_FLA_COMPLETE, importServiceHandler);
			importFLAService.startImport(importVO);
		}
		
		private function importServiceHandler(e:Event):void
		{
			importFileService.removeEventListener(ImportFileService.IMPORT_FILE_ERROR, importServiceHandler);
			importFileService.removeEventListener(ImportFileService.IMPORT_FILE_COMPLETE, importServiceHandler);
			importFLAService.removeEventListener(ImportFLAService.IMPORT_FLA_ERROR, importServiceHandler);
			importFLAService.removeEventListener(ImportFLAService.IMPORT_FLA_COMPLETE, importServiceHandler);
			switch(e.type)
			{
				case ImportFileService.IMPORT_FILE_ERROR:
					// log
					importNextFile();
					break;
				
				case ImportFLAService.IMPORT_FLA_ERROR:
					// log
					importNextFile();
					break;
				
				case ImportFileService.IMPORT_FILE_COMPLETE:
				case ImportFLAService.IMPORT_FLA_COMPLETE:
					var importVO:ImportVO = (e as ServiceEvent).data;
					importToExport(importVO);
					break;
			}
		}
		
		private function importToExport(importVO:ImportVO):void
		{
			var exportVO:ExportVO = new ExportVO();
			_settingManager.setExportVOValues(exportVO);
			
			importDataToExportDataService.addEventListener(ImportDataToExportDataService.IMPORT_TO_EXPORT_ERROR, exportChangeServiceHandler);
			importDataToExportDataService.addEventListener(ImportDataToExportDataService.IMPORT_TO_EXPORT_COMPLETE, exportChangeServiceHandler);
			importDataToExportDataService.export(importVO, exportVO);
		}
		
		private function exportChangeServiceHandler(e:Event):void
		{
			importDataToExportDataService.removeEventListener(ImportDataToExportDataService.IMPORT_TO_EXPORT_ERROR, exportChangeServiceHandler);
			importDataToExportDataService.removeEventListener(ImportDataToExportDataService.IMPORT_TO_EXPORT_COMPLETE, exportChangeServiceHandler);
			switch(e.type)
			{
				case ImportDataToExportDataService.IMPORT_TO_EXPORT_ERROR:
					// log
					importNextFile();
					break;
				
				case ImportDataToExportDataService.IMPORT_TO_EXPORT_COMPLETE:
					if (_isFLAFile)
					{
						jsflService.runJSFLCode(null, "fl.getDocumentDOM().close(false);");
					}
					var serverEvent:ServiceEvent = (e as ServiceEvent);
					if (_saveFunction != null)
					{
						_saveFunction.call(this, serverEvent.data[0], serverEvent.data[1], importNextFile);
					}
					else
					{
						RequestManager.getInstance().save(serverEvent.data[0], (serverEvent.data[1] as ExportVO).name, saveHandler);
					}
					break;
			}
		}
		
		private function saveHandler(e:Event):void
		{
			switch(e.type)
			{
				case Event.CANCEL:
					this.directCommandMap.release(this);
					break;
				
				case IOErrorEvent.IO_ERROR:
					// log
					importNextFile();
					break;
				
				case Event.COMPLETE:
					// log
					importNextFile();
					break;
			}
		}
	}
}