package mobile.backend.utils;

import flixel.FlxG;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;

class MobileTrace
{
	public static var text:FlxText;

	public static var enabled:Bool = false;

	private static var tween:FlxTween;

	public static function init()
	{
		if (!Options.devMode)
			return;

		if (text != null)
			return;

		if (FlxG.state == null)
			return;

		text = new FlxText(10, 10, FlxG.width - 20, "");
		text.setFormat("assets/fonts/vcr.ttf", 16, FlxColor.LIME);
		text.scrollFactor.set();
		text.alpha = 0;
		text.borderSize = 1;

		if (FlxG.cameras.list.length > 0)
			text.cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];

		FlxG.state.add(text);
	}
	
	public static function log(msg:Dynamic, ?color:FlxColor)
	{
		if (!Options.devMode) return;

		if (!enabled) return;
		
		if (text == null) return;

		if (tween != null)
			tween.cancel();

		text.alpha = 0.7;

		tween = FlxTween.tween(text, {alpha: 0}, 0.5, {
			startDelay: 2,
			onComplete: function(twn:FlxTween) {
				text.text = "";
			}
		});

		if (color != null)
			text.color = color;
		else
			text.color = FlxColor.LIME;

		text.text += Std.string(msg) + "\n";

		var lines = text.text.split("\n");
		if (lines.length > 15)
			lines.shift();

		text.text = lines.join("\n");
	}
}
