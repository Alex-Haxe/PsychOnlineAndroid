package mobile.backend.assets;

using StringTools;

#if mobile
import haxe.io.Bytes;
import haxe.io.Path;
import sys.FileSystem;
import sys.io.File;
import openfl.utils.Assets;
import backend.PopupAPI;

class Files
{
	#if android
	private static var _androidDir:String = null;

	private static function getAndroidStorageDir():String
	{
		if (_androidDir != null && _androidDir != "")
			return _androidDir;

		var dir:String = null;

		try {
			if (VERSION.SDK_INT >= VERSION_CODES.R)
			{
				dir = Context.getObbDir();
			}
			else
			{
				dir = Context.getExternalFilesDir();
			}
		} catch (e:Dynamic) {
		}

		if (dir == null || dir == "") 
		{
			dir = lime.system.System.documentsDirectory;
		}

		if (dir != null && dir != "") 
		{
			_androidDir = Path.addTrailingSlash(dir);
		} 
		else 
		{
			_androidDir = ""; 
		}

		return _androidDir;
	}
	#end
	
	public static function getAssetsDir():String
	{
		#if android
		return getAndroidStorageDir();
		#elseif ios
		var dir = lime.system.System.documentsDirectory;
		if (dir != null && !dir.endsWith("/")) dir += "/";
		return dir != null ? dir : "";
		#else
		return Sys.getCwd();
		#end
	}

	public static function getModsDir():String
	{
		#if android
		return getAndroidStorageDir();
		#elseif ios
		var dir = lime.system.System.documentsDirectory;
		if (dir != null && !dir.endsWith("/")) dir += "/";
		return dir != null ? dir : "";
		#else
		return Sys.getCwd();
		#end
	}
	
	public static function init():Void
	{
		try {
			var assetsBase = Path.addTrailingSlash(getAssetsDir());
			var modsBase = Path.addTrailingSlash(getModsDir());

			if (assetsBase == "/" || assetsBase == "") return;

			createDirRecursive(assetsBase);
			createDirRecursive(modsBase + "mods/");

			copyFolderOnce("assets", assetsBase + "assets/");
		} catch (e:Dynamic) {
			#if COMPILE_EXPERIMENTAL
			PopupAPI.showMessageBox("Error Initializing", "Failed to initialize directories: " + Std.string(e), "Got It!");
			#end
		}
	}
	
	static function copyFolderOnce(folder:String, target:String):Void
	{
		#if sys
		try {
			var marker = Path.addTrailingSlash(target) + ".copy_complete";
			
			if (FileSystem.exists(marker) && FileSystem.exists(Path.addTrailingSlash(target) + "data/") && FileSystem.exists(Path.addTrailingSlash(target) + "songs/") && FileSystem.exists(Path.addTrailingSlash(target) + "languages/"))
			{
				return;
			}
			
			if (FileSystem.exists(marker))
			{
				FileSystem.deleteFile(marker);
			}
			
			if (copyAssets(folder, target))
			{
				File.saveContent(marker, "1");
			}
			else
			{
				#if COMPILE_EXPERIMENTAL
				PopupAPI.showMessageBox("Copy Failed", "Some asset files failed to copy correctly. Please check permissions or storage space.", "Got It!");
				#end
			}
		} catch (e:Dynamic) {
			#if COMPILE_EXPERIMENTAL
			PopupAPI.showMessageBox("Copy Error", "An error occurred during asset extraction: " + Std.string(e), "Got It!");
			#end
		}
		#end
	}

	static function copyAssets(source:String, target:String):Bool
	{
		var success = true;
		try {
			var list:Array<String> = Assets.list();
			if (list == null || list.length == 0) return false;

			for (asset in list)
			{
				if (!asset.startsWith(source)) continue;

				var relative = asset.substr(source.length);
				if (relative.startsWith("/")) relative = relative.substr(1);

				if (!relative.startsWith("data/") && !relative.startsWith("languages/") && !relative.startsWith("songs/")) continue;

				if (relative.endsWith(".ogg") || relative.endsWith(".mp3")) continue;

				var outPath = Path.addTrailingSlash(target) + relative;
				var dir = Path.directory(outPath);

				createDirRecursive(dir);

				var fileSuccess = false;
				try {
					var bytes:Bytes = Assets.getBytes(asset);
					if (bytes != null) {
						File.saveBytes(outPath, bytes);
						fileSuccess = true;
					} else {
						var text:String = Assets.getText(asset);
						if (text != null) {
							File.saveContent(outPath, text);
							fileSuccess = true;
						}
					}
				} catch (e:Dynamic) {
					#if COMPILE_EXPERIMENTAL
					PopupAPI.showMessageBox("Write Error", "Could not copy asset to " + outPath + "\nError: " + Std.string(e), "Got It!");
					#end
					fileSuccess = false;
				}

				if (!fileSuccess) {
					success = false;
				}
			}
		} catch (e:Dynamic) {
			#if COMPILE_EXPERIMENTAL
			PopupAPI.showMessageBox("Asset List Error", "Failed to access asset package: " + Std.string(e), "Got It!");
			#end
			return false;
		}
		return success;
	}

	static function createDirRecursive(path:String):Void
	{
		#if sys
		if (path == null || path == "") return;

		try {
			path = Path.normalize(path);

			var parts = path.split("/");
			var current = "";
			
			if (path.startsWith("/")) {
				current = "/";
			}
			
			for (part in parts) {
				if (part == "") continue;
				
				if (current == "/") {
					current += part;
				} else if (current == "") {
					current = part;
				} else {
					current += "/" + part;
				}
				
				if (!FileSystem.exists(current)) {
					try {
						FileSystem.createDirectory(current);
					} catch(e:Dynamic) {
					}
				}
			}

			if (!FileSystem.exists(path)) {
				throw "Could not create directory: " + path;
			}
		} catch (e:Dynamic) {
			#if COMPILE_EXPERIMENTAL
			PopupAPI.showMessageBox("Directory Error", "Failed to create directory path: " + path + "\nError: " + Std.string(e), "Got It!");
			#end
		}
		#end
	}
}
#end
