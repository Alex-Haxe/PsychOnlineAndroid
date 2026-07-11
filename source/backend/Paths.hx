package backend;


import openfl.utils.Future;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flxanimate.data.SpriteMapData.FlxSpriteMap;
import flxanimate.frames.FlxAnimateFrames;
import flixel.graphics.frames.FlxFrame.FlxFrameAngle;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.FlxGraphic;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;

import openfl.display.BitmapData;
import openfl.display3D.textures.RectangleTexture;
import openfl.utils.AssetType;
import openfl.utils.Assets as OpenFlAssets;
import openfl.system.System;
import openfl.geom.Rectangle;

import lime.utils.Assets;
import openfl.media.Sound;

#if sys
import sys.io.File;
import sys.FileSystem;
#if linux
import haxe.io.Path;
#end
#end
import tjson.TJSON as Json;


#if MODS_ALLOWED
import backend.Mods;
#end

class Paths
{
	inline public static var SOUND_EXT = #if web "mp3" #else "ogg" #end;
	inline public static var VIDEO_EXT = "mp4";
	inline public static var PATH_SLASH = #if windows '\\' #else '/' #end;

	inline static public function sysPath(file:String):String {
		#if android
		var appDir:String = lime.system.System.applicationStorageDirectory;
		if (appDir != null) {
			if (!StringTools.endsWith(appDir, "/")) appDir += "/";
			if (!StringTools.startsWith(file, appDir)) return appDir + file;
		}
		#end
		return file;
	}

	public static function excludeAsset(key:String) {
		if (!dumpExclusions.contains(key))
			dumpExclusions.push(key);
	}

	public static var dumpExclusions:Array<String> =
	[
		'assets/music/freakyMenu.$SOUND_EXT',
		'assets/shared/music/breakfast.$SOUND_EXT',
		'assets/shared/music/tea-time.$SOUND_EXT',
		'assets/images/bf1.png',
		'assets/images/bf2.png',
	];
	/// haya I love you for the base cache dump I took to the max
	public static function clearUnusedMemory() {
		for (key in currentTrackedAssets.keys()) {
			if (!localTrackedAssets.contains(key) && !dumpExclusions.contains(key)) {
				var obj = currentTrackedAssets.get(key);
				@:privateAccess
				if (obj != null) {
					FlxG.bitmap._cache.remove(key);
					openfl.Assets.cache.removeBitmapData(key);
					currentTrackedAssets.remove(key);

					obj.persist = false;
					obj.destroyOnNoUse = true;
					obj.destroy();
				}
			}
		}

		System.gc();
	}

	public static var localTrackedAssets:Array<String> = [];
	public static function clearStoredMemory(?cleanUnused:Bool = false) {
		@:privateAccess
		for (key => obj in FlxG.bitmap._cache)
		{
			if (obj != null && !currentTrackedAssets.exists(key) && !dumpExclusions.contains(key)) {
				openfl.Assets.cache.removeBitmapData(key);
				FlxG.bitmap._cache.remove(key);
				try {
					obj.destroy();
				} catch (exc) {
					trace(exc);
				}
			}
		}

		for (key in currentTrackedSounds.keys()) {
			if (!localTrackedAssets.contains(key) && !dumpExclusions.contains(key) && key != null) {
				Assets.cache.clear(key);
				currentTrackedSounds.remove(key);
			}
		}
		sparrowAtlasCache.clear();
		packerAtlasCache.clear();
		localTrackedAssets = [];
		#if !html5 openfl.Assets.cache.clear("songs"); #end
	}

	static public var currentLevel:String = 'week1';
	static public function setCurrentLevel(name:String)
	{
		currentLevel = name.toLowerCase();
	}

	public static function getPath(file:String, ?type:AssetType = TEXT, ?library:Null<String> = null, ?modsAllowed:Bool = false, ?modDir:String):String
	{
		#if MODS_ALLOWED
		if(modsAllowed)
		{
			var modded:String = modFolders(file, modDir);
			if(FileSystem.exists(sysPath(modded))) return modded;
		}
		#end

		if (library != null)
			return getLibraryPath(file, library);

		if (currentLevel != null)
		{
			var levelPath:String = '';
			if(currentLevel != 'shared') {
				levelPath = getLibraryPathForce(file, 'week_assets', currentLevel);
				if (OpenFlAssets.exists(levelPath, type))
					return levelPath;
			}

			levelPath = getLibraryPathForce(file, "shared");
			if (OpenFlAssets.exists(levelPath, type))
				return levelPath;
		}

		return getPreloadPath(file);
	}

	static public function getLibraryPath(file:String, library = "preload")
	{
		return if (library == "preload" || library == "default") getPreloadPath(file); else getLibraryPathForce(file, library);
	}

	inline public static function getLibraryPathForce(file:String, library:String, ?level:String)
	{
		if(level == null) level = library;
		var returnPath = '$library:assets/$level/$file';
		return returnPath;
	}

	inline public static function getPreloadPath(file:String = '')
	{
		return 'assets/$file';
	}

	inline static public function getFolderPath(file:String, folder = "shared")
		return 'assets/$folder/$file';

	inline public static function getSharedPath(file:String = '')
		return getFolderPath(file);

	inline static public function txt(key:String, ?library:String)
	{
		return getPath('data/$key.txt', TEXT, library);
	}

	inline static public function xml(key:String, ?library:String)
	{
		return getPath('data/$key.xml', TEXT, library);
	}

	inline static public function json(key:String, ?library:String)
	{
		return getPath('data/$key.json', TEXT, library);
	}

	inline static public function shaderFragment(key:String, ?library:String)
	{
		return getPath('shaders/$key.frag', TEXT, library);
	}
	inline static public function shaderVertex(key:String, ?library:String)
	{
		return getPath('shaders/$key.vert', TEXT, library);
	}
	inline static public function lua(key:String, ?library:String)
	{
		return getPath('$key.lua', TEXT, library);
	}

	static public function video(key:String)
	{
		#if MODS_ALLOWED
		var file:String = modsVideo(key);
		if(FileSystem.exists(sysPath(file))) {
			return file;
		}
		#end
		return 'assets/videos/$key.$VIDEO_EXT';
	}

	static public function sound(key:String, ?library:String):Sound
	{
		var sound:Sound = returnSound('sounds', key, library);
		return sound;
	}

	inline static public function soundRandom(key:String, min:Int, max:Int, ?library:String)
	{
		return sound(key + FlxG.random.int(min, max), library);
	}

	inline static public function music(key:String, ?library:String):Sound
	{
		var file:Sound = returnSound('music', key, library);
		return file;
	}

	inline static public function voices(song:String, postfix:String = null, songSuffix:String = null):Any {
		var voices:Sound = null;
		try {
			var songKey:String = '${formatToSongPath(song)}/Voices' + (songSuffix ?? "");
			if (postfix != null)
				songKey += '-' + postfix;
			var sound = returnSound('songs', songKey);
			if (sound == null || sound.length <= 0)
				sound = null;
			voices = sound;
		}
		catch (_) {
			voices = null;
		}

		return voices;
	}

	inline static public function inst(song:String, songSuffix:String = null):Any
	{
		#if html5
		return 'songs:assets/songs/${formatToSongPath(song)}/Inst.$SOUND_EXT';
		#else
		var songKey:String = '${formatToSongPath(song)}/Inst' + (songSuffix ?? "");
		var inst = returnSound('songs', songKey);
		return inst;
		#end
	}

	static var lastImageErrorFile:String = null;

	public static var currentTrackedAssets:Map<String, FlxGraphic> = [];
	static public function image(key:String, ?library:String = null, ?allowGPU:Bool = true):FlxGraphic
	{
		var bitmap:BitmapData = null;
		var file:String = null;

		#if MODS_ALLOWED
		file = modsImages(key);
		if (currentTrackedAssets.exists(file))
		{
			localTrackedAssets.push(file);
			return currentTrackedAssets.get(file);
		}
		else if (FileSystem.exists(sysPath(file)))
			bitmap = BitmapData.fromFile(sysPath(file));
		else
		#end
		{
			file = getPath('images/$key.png', IMAGE, library);
			if (currentTrackedAssets.exists(file))
			{
				localTrackedAssets.push(file);
				return currentTrackedAssets.get(file);
			}
			else if (OpenFlAssets.exists(file, IMAGE))
				bitmap = OpenFlAssets.getBitmapData(file);
		}

		if (bitmap != null) {
			return bitmapToGraphic(file, bitmap);
		}

		if (lastImageErrorFile != file && ClientPrefs.isDebug()) {
			Sys.println('Paths.image(): oh no its returning null NOOOO ($file)');
			lastImageErrorFile = file;
		}
		return null;
	}

	static public function asyncBitmap(key:String, ?library:String = null, ?modDir:String):Null<Future<BitmapData>> {
		var file:String = null;

		#if MODS_ALLOWED
		file = modsImages(key, modDir);
		if (currentTrackedAssets.exists(file))
		{
			localTrackedAssets.push(file);
			return Future.withValue(currentTrackedAssets.get(file).bitmap);
		}
		else if (FileSystem.exists(sysPath(file)))
			return BitmapData.loadFromFile(sysPath(file));
		else
		#end
		{
			file = getPath('images/$key.png', IMAGE, library);
			if (currentTrackedAssets.exists(file))
			{
				localTrackedAssets.push(file);
				return Future.withValue(currentTrackedAssets.get(file).bitmap);
			}
			else if (OpenFlAssets.exists(file, IMAGE))
				return OpenFlAssets.loadBitmapData(file);
		}

		if (lastImageErrorFile != file && ClientPrefs.isDebug()) {
			Sys.println('Paths.asyncBitmap(): oh no its returning null NOOOO ($file)');
			lastImageErrorFile = file;
		}
		return null;
	}

	static public function bitmapToGraphic(file:String, bitmap:BitmapData) {
		localTrackedAssets.push(file);
		var newGraphic:FlxGraphic = FlxGraphic.fromBitmapData(bitmap, false, file);
		newGraphic.persist = true;
		newGraphic.destroyOnNoUse = false;
		currentTrackedAssets.set(file, newGraphic);
		return newGraphic;
	}

	static public function getTextFromFile(key:String, ?ignoreMods:Bool = false):String
	{
		#if sys
		#if MODS_ALLOWED
		if (!ignoreMods && FileSystem.exists(sysPath(modFolders(key))))
			return File.getContent(sysPath(modFolders(key)));
		#end

		if (FileSystem.exists(sysPath(getPreloadPath(key))))
			return File.getContent(sysPath(getPreloadPath(key)));

		if (currentLevel != null)
		{
			var levelPath:String = '';
			if(currentLevel != 'shared') {
				levelPath = getLibraryPathForce(key, 'week_assets', currentLevel);
				if (FileSystem.exists(sysPath(levelPath)))
					return File.getContent(sysPath(levelPath));
			}

			levelPath = getLibraryPathForce(key, 'shared');
			if (FileSystem.exists(sysPath(levelPath)))
				return File.getContent(sysPath(levelPath));
		}
		#end
		var path:String = getPath(key, TEXT);
		if(OpenFlAssets.exists(path, TEXT)) return Assets.getText(path);
		return null;
	}

	inline static public function font(key:String)
	{
		#if MODS_ALLOWED
		var file:String = modsFont(key);
		if(FileSystem.exists(sysPath(file))) {
			return file;
		}
		#end
		return 'assets/fonts/$key';
	}

	public static function fileExists(key:String, type:AssetType, ?ignoreMods:Bool = false, ?library:String = null)
	{
		#if MODS_ALLOWED
		if(!ignoreMods)
		{
			for(mod in Mods.getGlobalMods())
				if (FileSystem.exists(sysPath(mods('$mod/$key'))))
					return true;

			if (FileSystem.exists(sysPath(mods(Mods.currentModDirectory + '/' + key))) || FileSystem.exists(sysPath(mods(key))))
				return true;
		}
		#end

		if(OpenFlAssets.exists(getPath(key, type, library, false))) {
			return true;
		}
		return false;
	}

	static public function getAtlas(key:String, ?library:String = null):FlxAtlasFrames
	{
		#if MODS_ALLOWED
		if(FileSystem.exists(sysPath(modsXml(key))) || OpenFlAssets.exists(getPath('images/$key.xml', library), TEXT))
		#else
		if(OpenFlAssets.exists(getPath('images/$key.xml', library)))
		#end
		{
			return getSparrowAtlas(key, library);
		}
		return getPackerAtlas(key, library);
	}

	static var sparrowAtlasCache:Map<String, FlxAtlasFrames> = new Map();
	inline static public function getSparrowAtlas(key:String, ?library:String = null, ?allowGPU:Bool = true):FlxAtlasFrames
	{
		if (sparrowAtlasCache.exists(key + library))
			return sparrowAtlasCache.get(key + library);

		#if MODS_ALLOWED
		var imageLoaded:FlxGraphic = image(key, allowGPU);
		var xmlExists:Bool = false;

		var xml:String = modsXml(key);
		if(FileSystem.exists(sysPath(xml))) {
			xmlExists = true;
		}

		var frames = FlxAtlasFrames.fromSparrow((imageLoaded != null ? imageLoaded : image(key, library, allowGPU)), (xmlExists ? File.getContent(sysPath(xml)) : getPath('images/$key.xml', library)));
		#else
		var frames = FlxAtlasFrames.fromSparrow(image(key, library, allowGPU), getPath('images/$key.xml', library));
		#end

		if (frames != null)
			sparrowAtlasCache.set(key + library, frames);

		return frames;
	}

	static var packerAtlasCache:Map<String, FlxAtlasFrames> = new Map();
	inline static public function getPackerAtlas(key:String, ?library:String = null, ?allowGPU:Bool = true):FlxAtlasFrames
	{
		if (packerAtlasCache.exists(key + library))
			return packerAtlasCache.get(key + library);

		#if MODS_ALLOWED
		var imageLoaded:FlxGraphic = image(key, allowGPU);
		var txtExists:Bool = false;
		
		var txt:String = modsTxt(key);
		if(FileSystem.exists(sysPath(txt))) {
			txtExists = true;
		}

		var frames = FlxAtlasFrames.fromSpriteSheetPacker((imageLoaded != null ? imageLoaded : image(key, library, allowGPU)), (txtExists ? File.getContent(sysPath(txt)) : getPath('images/$key.txt', library)));
		#else
		var frames = FlxAtlasFrames.fromSpriteSheetPacker(image(key, library, allowGPU), getPath('images/$key.txt', library));
		#end

		if (frames != null)
			packerAtlasCache.set(key + library, frames);

		return frames;
	}

	static var invalidChars = ~/[~&\\;:<>#]/;
	static var hideChars = ~/[.,'"%?!]/;

	inline static public function formatToSongPath(path:String) {
		var path = invalidChars.split(path.replace(' ', '-')).join("-");
		return hideChars.split(path).join("").toLowerCase();
	}

	public static var currentTrackedSounds:Map<String, Sound> = [];
	public static function returnSound(path:String, key:String, ?library:String) {
		#if MODS_ALLOWED
		var file:String = modsSounds(path, key);
		if(FileSystem.exists(sysPath(file))) {
			try {
				if(!currentTrackedSounds.exists(file)) {
					currentTrackedSounds.set(file, Sound.fromFile(sysPath(file)));
				}
			} catch (e:Dynamic) {
				if (ClientPrefs.isDebug())
					Sys.println('Paths.returnSound(): SOUND NOT FOUND: $key');
				return null;
			}
			localTrackedAssets.push(key);
			return currentTrackedSounds.get(file);
		}
		#end
		var gottenPath:String = getPath('$path/$key.$SOUND_EXT', SOUND, library);
		gottenPath = gottenPath.substring(gottenPath.indexOf(':') + 1, gottenPath.length);
		try {
			if(!currentTrackedSounds.exists(gottenPath))
			#if MODS_ALLOWED
				currentTrackedSounds.set(gottenPath, Sound.fromFile(#if !mobile './' + #end sysPath(gottenPath)));
			#else
			{
				var folder:String = '';
				if(path == 'songs') folder = 'songs:';
		
				currentTrackedSounds.set(gottenPath, OpenFlAssets.getSound(folder + getPath('$path/$key.$SOUND_EXT', SOUND, library)));
			}
			#end
		} catch (e:Dynamic) {
			if (ClientPrefs.isDebug())
				Sys.println('Paths.returnSound(): SOUND NOT FOUND: $key');
			return null;
		}
		localTrackedAssets.push(gottenPath);
		return currentTrackedSounds.get(gottenPath);
	}

	#if MODS_ALLOWED
	inline static public function mods(key:String = '') {
		return 'mods/' + key;
	}

	inline static public function modsFont(key:String) {
		return modFolders('fonts/' + key);
	}

	inline static public function modsJson(key:String) {
		return modFolders('data/' + key + '.json');
	}

	inline static public function modsVideo(key:String) {
		return modFolders('videos/' + key + '.' + VIDEO_EXT);
	}

	inline static public function modsSounds(path:String, key:String) {
		return modFolders(path + '/' + key + '.' + SOUND_EXT);
	}

	inline static public function modsImages(key:String, ?mod:String) {
		return modFolders('images/' + key + '.png', mod);
	}

	inline static public function modsXml(key:String) {
		return modFolders('images/' + key + '.xml');
	}

	inline static public function modsTxt(key:String) {
		return modFolders('images/' + key + '.txt');
	}

	#if linux
	static public function getFileLinux(path : String) {
		var fileName : String = Path.withoutDirectory(path);
		var dirToSearch : String = Path.directory(path);
		if (FileSystem.exists(dirToSearch)) {
			for (file in FileSystem.readDirectory(dirToSearch)) {
				var fullNewFilePath = Path.join([dirToSearch,file]);
				if (FileSystem.isDirectory(fullNewFilePath))
					continue;
				trace("Current file: " + file + ", looking for " + fileName);
				if (file.toLowerCase() == fileName.toLowerCase()) {
					trace("Filename is real! It's " + file);
					return fullNewFilePath;
				}
			}
			return null;
		} else {
			return null;
		}
	}
	#end

	static public function modFolders(key:String, ?modDirectory:String) {
		modDirectory ??= Mods.currentModDirectory;

		if(modDirectory != null && modDirectory.length > 0) {
			var fileToCheck:String = mods(modDirectory + '/' + key);
			#if linux
			var actualFile = getFileLinux(fileToCheck);
			if (actualFile != null && FileSystem.exists(sysPath(actualFile)))
				return actualFile;
			#else
			if(FileSystem.exists(sysPath(fileToCheck))) {
				return fileToCheck;
			}
			#end
		}

		for(mod in Mods.getGlobalMods()){
			var fileToCheck:String = mods(mod + '/' + key);
			#if linux
			var actualFile = getFileLinux(fileToCheck);
			if (actualFile != null && FileSystem.exists(sysPath(actualFile)))
				return actualFile;
			#else
			if(FileSystem.exists(sysPath(fileToCheck))) {
				return fileToCheck;
			}
			#end
		}
		return 'mods/' + key;
	}
	#end

	public static function loadAnimateAtlas(spr:FlxAnimate, folderOrImg:Dynamic, spriteJson:Dynamic = null, animationJson:Dynamic = null) {
		var changedAnimJson = false;
		var changedAtlasJson = false;
		var changedImage = false;

		if (spriteJson != null) {
			changedAtlasJson = true;
			spriteJson = File.getContent(sysPath(spriteJson));
		}

		if (animationJson != null) {
			changedAnimJson = true;
			animationJson = File.getContent(sysPath(animationJson));
		}

		var frames:FlxAnimateFrames = new FlxAnimateFrames();

		if (Std.isOfType(folderOrImg, String)) {
			var originalPath:String = folderOrImg;
			for (i in 0...10) {
				var st:String = '$i';
				if (i == 0)
					st = '';

				if (!changedAtlasJson) {
					spriteJson = getTextFromFile('images/$originalPath/spritemap$st.json');
					if (spriteJson != null) {
						changedImage = true;
						changedAtlasJson = true;
						loadSpriteMap(frames, spriteJson, folderOrImg = Paths.image('$originalPath/spritemap$st'));
						break;
					}
				}
				else if (Paths.fileExists('images/$originalPath/spritemap$st.png', IMAGE)) {
					changedImage = true;
					loadSpriteMap(frames, spriteJson, folderOrImg = Paths.image('$originalPath/spritemap$st'));
					break;
				}
			}

			if (!changedImage) {
				changedImage = true;
				loadSpriteMap(frames, spriteJson, folderOrImg = Paths.image(originalPath));
			}

			if (!changedAnimJson) {
				changedAnimJson = true;
				animationJson = getTextFromFile('images/$originalPath/Animation.json');
			}
		}

		spr.loadSeparateAtlas(animationJson, frames);
	}

	static function loadSpriteMap(frames:FlxAnimateFrames, spritemap:FlxSpriteMap, ?image:FlxGraphicAsset) {
		var spritemapFrames = FlxAnimateFrames.fromSpriteMap(spritemap, image);
		if (spritemapFrames != null)
			frames.addAtlas(spritemapFrames);
		return spritemapFrames;
	}
}
