package mobile.ui.menus;

#if mobile
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.group.FlxSpriteGroup;
import flixel.input.keyboard.FlxKey;
import flixel.input.touch.FlxTouch;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.frames.FlxTileFrames;
import flixel.math.FlxPoint;
import flixel.util.FlxDestroyUtil;

class FunkinJoystick extends FlxSpriteGroup
{
	public static var isJoystickDragging:Bool = false;
	public static var activeTouchID:Int = -1;

	public var base:FlxSprite;
	public var thumb:FlxSprite;
	
	public var virtualpadCamera:FlxCamera;
	private var atlasFrames:FlxAtlasFrames;
	
	public var isDragging:Bool = false;
	private var currentTouch:FlxTouch = null;
	
	private var baseRadius:Float = 126;
	private var thumbRadius:Float = 78;
	private var maxDragRadius:Float = 70;
	
	public var deadzone:Float = 0.35;
	private var centerPoint:FlxPoint;
	
	public var keyUp:FlxKey = FlxKey.W;
	public var keyDown:FlxKey = FlxKey.S;
	public var keyLeft:FlxKey = FlxKey.A;
	public var keyRight:FlxKey = FlxKey.D;

	private var pressedUp:Bool = false;
	private var pressedDown:Bool = false;
	private var pressedLeft:Bool = false;
	private var pressedRight:Bool = false;

	public function new(x:Float, y:Float)
	{
		super();
		
		virtualpadCamera = new FlxCamera();
		virtualpadCamera.bgColor = 0x00000000;
		FlxG.cameras.add(virtualpadCamera, false);
		this.cameras = [virtualpadCamera];
		
		atlasFrames = FlxAtlasFrames.fromSpriteSheetPacker(
			'assets/shared/images/mobile/virtualpad/virtual-input.png',
			'assets/shared/images/mobile/virtualpad/charter/virtual-input.txt');
    
		base = new FlxSprite(x, y);
		base.frames = FlxTileFrames.fromFrame(atlasFrames.getByName("base"), FlxPoint.get(252, 252));
		base.solid = false;
		base.immovable = true;
		base.scrollFactor.set();
		add(base);
		
		centerPoint = FlxPoint.get(x + baseRadius, y + baseRadius);
		thumb = new FlxSprite(centerPoint.x - thumbRadius, centerPoint.y - thumbRadius);
		thumb.frames = FlxTileFrames.fromFrame(atlasFrames.getByName("thumb"), FlxPoint.get(156, 156));
		thumb.solid = false;
		thumb.immovable = true;
		thumb.scrollFactor.set();
		add(thumb);
	}

	override function update(elapsed:Float) 
	{
		if (!active || !visible) {
			super.update(elapsed);
			return;
		}

		var currentOpacity = ClientPrefs.virtualPadOpacity;
		base.alpha = currentOpacity;
		thumb.alpha = currentOpacity;

		if (!isDragging) 
		{
			for (touch in FlxG.touches.list) {
				if (touch.justPressed) {
					var point = touch.getWorldPosition(virtualpadCamera);
					var dx = point.x - centerPoint.x;
					var dy = point.y - centerPoint.y;
					var dist = Math.sqrt(dx * dx + dy * dy);
					
					if (dist <= baseRadius) {
						isDragging = true;
						isJoystickDragging = true;
						activeTouchID = touch.touchPointID;
						currentTouch = touch;
						point.put();
						break;
					}
					point.put();
				}
			}
		}

		var normX:Float = 0;
		var normY:Float = 0;

		if (isDragging && currentTouch != null) 
		{
			if (!currentTouch.pressed) {
				isDragging = false;
				isJoystickDragging = false;
				activeTouchID = -1;
				currentTouch = null;
				thumb.x = centerPoint.x - thumbRadius;
				thumb.y = centerPoint.y - thumbRadius;
			} else {
				var point = currentTouch.getWorldPosition(virtualpadCamera);
				var dx = point.x - centerPoint.x;
				var dy = point.y - centerPoint.y;
				var dist = Math.sqrt(dx * dx + dy * dy);
				
				if (dist > maxDragRadius) {
					var ratio = maxDragRadius / dist;
					dx *= ratio;
					dy *= ratio;
				}
				
				thumb.x = centerPoint.x + dx - thumbRadius;
				thumb.y = centerPoint.y + dy - thumbRadius;
				
				normX = dx / maxDragRadius;
				normY = dy / maxDragRadius;
				
				point.put();
			}
		}

		var wasUp = pressedUp;
		var wasDown = pressedDown;
		var wasLeft = pressedLeft;
		var wasRight = pressedRight;

		pressedUp = isDragging && normY < -deadzone;
		pressedDown = isDragging && normY > deadzone;
		pressedLeft = isDragging && normX < -deadzone;
		pressedRight = isDragging && normX > deadzone;

		injectKey(keyUp, pressedUp, wasUp);
		injectKey(keyDown, pressedDown, wasDown);
		injectKey(keyLeft, pressedLeft, wasLeft);
		injectKey(keyRight, pressedRight, wasRight);

		super.update(elapsed);
	}
	
	private function injectKey(key:FlxKey, isCurrentlyPressed:Bool, wasPreviouslyPressed:Bool):Void 
	{
		if (key == FlxKey.NONE) return;
		
		@:privateAccess 
		{
			var keyObj = FlxG.keys._keyListMap[key];
			if (keyObj != null) 
			{
				if (isCurrentlyPressed && !wasPreviouslyPressed) {
					keyObj.current = JUST_PRESSED;
				} else if (!isCurrentlyPressed && wasPreviouslyPressed) {
					keyObj.current = JUST_RELEASED;
				} else if (isCurrentlyPressed && wasPreviouslyPressed) {
					if (keyObj.current == JUST_PRESSED) keyObj.current = PRESSED;
				} else {
					if (keyObj.current == JUST_RELEASED) keyObj.current = RELEASED;
				}
			}
		}
	}
	
	override public function destroy():Void
	{
		isJoystickDragging = false;
		activeTouchID = -1;

		if (virtualpadCamera != null) {
			FlxG.cameras.remove(virtualpadCamera, false);
			virtualpadCamera = null;
		}

		base = FlxDestroyUtil.destroy(base);
		thumb = FlxDestroyUtil.destroy(thumb);
		centerPoint = FlxDestroyUtil.put(centerPoint);
		atlasFrames = null;

		super.destroy();
	}
}
#end
	
