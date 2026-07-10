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
import flixel.input.FlxInput.FlxInputState;

class MobileButton extends FlxSprite 
{
	public var justPressed:Bool = false;
	public var justReleased:Bool = false;
	public var pressed:Bool = false;
}

class FunkinPad extends FlxSpriteGroup
{
	public static var activePads:Array<FunkinPad> = [];
	public static var inputBlockFrames:Int = 0;
	public static var usedTouches:Array<flixel.input.touch.FlxTouch> = [];
	public static var lastUpdateFrame:Int = 0;
	
	public var blockInput:Bool = false;
	
	public var buttonA:MobileButton;
	public var buttonB:MobileButton;
	public var buttonC:MobileButton;
	public var buttonY:MobileButton;
	public var buttonX:MobileButton;
	public var buttonLeft:MobileButton;
	public var buttonUp:MobileButton;
	public var buttonRight:MobileButton;
	public var buttonDown:MobileButton;
	
	public var buttonLeft2:MobileButton;
	public var buttonUp2:MobileButton;
	public var buttonRight2:MobileButton;
	public var buttonDown2:MobileButton;

	public var buttonE:MobileButton;
	public var buttonM:MobileButton;
	public var buttonBack:MobileButton;

	public var virtualpadCamera:FlxCamera;
	public static var touchingPad:Bool = false;

	private inline static var B_W:Int = 132;
	private inline static var B_H:Int = 135;
	
	public static inline var HOLD_DELAY:Float = 0.15;
	public static inline var HOLD_REPEAT:Float = 0.05;

	public var boundActions:Map<MobileButton, Array<String>> = new Map();
	private var holdTimers:Map<String, Float> = new Map();
	private var holdActive:Map<String, Bool> = new Map();
	private var atlasFrames:FlxAtlasFrames;

	public var keyBinds:Map<String, FlxKey> = [
		"up" => FlxKey.UP,
		"down" => FlxKey.DOWN,
		"left" => FlxKey.LEFT,
		"right" => FlxKey.RIGHT,
		"a" => FlxKey.ENTER,
		"b" => FlxKey.BACKSPACE,
		"c" => FlxKey.SHIFT,
		"x" => FlxKey.SEVEN,
		"y" => FlxKey.TAB,
		"e" => FlxKey.SEVEN,
		"m" => FlxKey.TAB,
		"back" => FlxKey.ESCAPE
	];
	
	public function new(?DPad:FlxDPadMode, ?Action:FlxActionMode)
	{
		super();
		FunkinPad.activePads.push(this);

		virtualpadCamera = new FlxCamera();
		virtualpadCamera.bgColor = 0x00000000;
		FlxG.cameras.add(virtualpadCamera, false);
		this.cameras = [virtualpadCamera];

		atlasFrames = FlxAtlasFrames.fromSpriteSheetPacker(
			'assets/shared/images/mobile/virtualpad/virtual-input.png',
			'assets/shared/images/mobile/virtualpad/charter/virtual-input.txt');

		switch (DPad)
		{
			case NONE:
			case UP_DOWN:
				add(buttonUp = createButton(0, FlxG.height - 255, B_W, B_H, "up"));
				add(buttonDown = createButton(0, FlxG.height - 135, B_W, B_H, "down"));
			case LEFT_RIGHT:
				add(buttonLeft = createButton(0, FlxG.height - 135, B_W, B_H, "left"));
				add(buttonRight = createButton(126, FlxG.height - 135, B_W, B_H, "right"));
			case FULL:
				add(buttonUp = createButton(105, FlxG.height - 348, B_W, B_H, "up"));
				add(buttonLeft = createButton(0, FlxG.height - 243, B_W, B_H, "left"));
				add(buttonRight = createButton(207, FlxG.height - 243, B_W, B_H, "right"));
				add(buttonDown = createButton(105, FlxG.height - 135, B_W, B_H, "down"));
      /**
			case DOUBLE:
             	add(buttonUp = createButton(105, FlxG.height - 348, B_W, B_H, "up"));
	            add(buttonLeft = createButton(0, FlxG.height - 243, B_W, B_H, "left"));
            	add(buttonRight = createButton(210, FlxG.height - 243, B_W, B_H, "right"));
             	add(buttonDown = createButton(105, FlxG.height - 135, B_W, B_H, "down"));

            	var rightCenter = FlxG.width - 105 - B_W;
   
	            add(buttonUp2 = createButton(rightCenter, FlxG.height - 348, B_W, B_H, "up"));
              	add(buttonLeft2 = createButton(rightCenter - 105, FlxG.height - 243, B_W, B_H, "left"));
                add(buttonRight2 = createButton(rightCenter + 105, FlxG.height - 243, B_W, B_H, "right"));
             	add(buttonDown2 = createButton(rightCenter, FlxG.height - 135, B_W, B_H, "down"));
    	    case CUSTOM:
				add(buttonUp = createButton(105, FlxG.height - 348, B_W, B_H, "up"));
				add(buttonLeft = createButton(0, FlxG.height - 243, B_W, B_H, "left"));
				add(buttonRight = createButton(207, FlxG.height - 243, B_W, B_H, "right"));
				add(buttonDown = createButton(105, FlxG.height - 135, B_W, B_H, "down"));

				if (FlxG.save.data.customPadPos != null) 
				{
					if (FlxG.save.data.customPadPos.upX != null) buttonUp.x = FlxG.save.data.customPadPos.upX;
					if (FlxG.save.data.customPadPos.upY != null) buttonUp.y = FlxG.save.data.customPadPos.upY;
					if (FlxG.save.data.customPadPos.downX != null) buttonDown.x = FlxG.save.data.customPadPos.downX;
					if (FlxG.save.data.customPadPos.downY != null) buttonDown.y = FlxG.save.data.customPadPos.downY;
					if (FlxG.save.data.customPadPos.leftX != null) buttonLeft.x = FlxG.save.data.customPadPos.leftX;
					if (FlxG.save.data.customPadPos.leftY != null) buttonLeft.y = FlxG.save.data.customPadPos.leftY;
					if (FlxG.save.data.customPadPos.rightX != null) buttonRight.x = FlxG.save.data.customPadPos.rightX;
					if (FlxG.save.data.customPadPos.rightY != null) buttonRight.y = FlxG.save.data.customPadPos.rightY;
				}
      **/
			default:
				add(buttonUp = createButton(105, FlxG.height - 348, B_W, B_H, "up"));
				add(buttonLeft = createButton(0, FlxG.height - 243, B_W, B_H, "left"));
				add(buttonRight = createButton(207, FlxG.height - 243, B_W, B_H, "right"));
				add(buttonDown = createButton(105, FlxG.height - 135, B_W, B_H, "down"));
		}

		switch (Action)
		{
			case A: add(buttonA = createButton(FlxG.width - 132, FlxG.height - 135, B_W, B_H, "a"));
			case B: add(buttonB = createButton(FlxG.width - 132, FlxG.height - 135, B_W, B_H, "b"));
			case X: add(buttonX = createButton(FlxG.width - 132, FlxG.height - 135, B_W, B_H, "x"));
			case Y: add(buttonY = createButton(FlxG.width - 132, FlxG.height - 135, B_W, B_H, "y"));
			case C: add(buttonC = createButton(FlxG.width - 132, FlxG.height - 135, B_W, B_H, "c"));
			case A_B:
				add(buttonA = createButton(FlxG.width - 132, FlxG.height - 135, B_W, B_H, "a"));
				add(buttonB = createButton(FlxG.width - 258, FlxG.height - 135, B_W, B_H, "b"));
			case A_C:
				add(buttonA = createButton(FlxG.width - 132, FlxG.height - 135, B_W, B_H, "a"));
				add(buttonC = createButton(FlxG.width - 258, FlxG.height - 135, B_W, B_H, "c"));
			case A_X:
				add(buttonA = createButton(FlxG.width - 132, FlxG.height - 135, B_W, B_H, "a"));
				add(buttonX = createButton(FlxG.width - 258, FlxG.height - 135, B_W, B_H, "x"));
			case A_Y:
				add(buttonA = createButton(FlxG.width - 132, FlxG.height - 135, B_W, B_H, "a"));
				add(buttonY = createButton(FlxG.width - 258, FlxG.height - 135, B_W, B_H, "y"));
			case A_B_C:
				add(buttonA = createButton(FlxG.width - 132, FlxG.height - 135, B_W, B_H, "a"));
				add(buttonB = createButton(FlxG.width - 258, FlxG.height - 135, B_W, B_H, "b"));
				add(buttonC = createButton(FlxG.width - 381, FlxG.height - 135, B_W, B_H, "c"));
			case A_X_Y:
				add(buttonA = createButton(FlxG.width - 132, FlxG.height - 135, B_W, B_H, "a"));
				add(buttonY = createButton(FlxG.width - 258, FlxG.height - 135, B_W, B_H, "y"));
				add(buttonX = createButton(FlxG.width - 381, FlxG.height - 135, B_W, B_H, "x"));
			case A_B_X_Y:
				add(buttonY = createButton(FlxG.width - 258, FlxG.height - 255, B_W, B_H, "y"));
				add(buttonX = createButton(FlxG.width - 132, FlxG.height - 255, B_W, B_H, "x"));
				add(buttonB = createButton(FlxG.width - 258, FlxG.height - 135, B_W, B_H, "b"));
				add(buttonA = createButton(FlxG.width - 132, FlxG.height - 135, B_W, B_H, "a"));
			case A_B_C_X_Y:
				add(buttonY = createButton(FlxG.width - 258, FlxG.height - 255, B_W, B_H, "y"));
				add(buttonX = createButton(FlxG.width - 132, FlxG.height - 255, B_W, B_H, "x"));
				add(buttonC = createButton(FlxG.width - 381, FlxG.height - 135, B_W, B_H, "c"));
				add(buttonB = createButton(FlxG.width - 258, FlxG.height - 135, B_W, B_H, "b"));
				add(buttonA = createButton(FlxG.width - 132, FlxG.height - 135, B_W, B_H, "a"));
			case B_C:
				add(buttonB = createButton(FlxG.width - 132, FlxG.height - 135, B_W, B_H, "b"));
				add(buttonC = createButton(FlxG.width - 258, FlxG.height - 135, B_W, B_H, "c"));
			case B_X:
				add(buttonB = createButton(FlxG.width - 132, FlxG.height - 135, B_W, B_H, "b"));
				add(buttonX = createButton(FlxG.width - 258, FlxG.height - 135, B_W, B_H, "x"));
			case B_Y:
				add(buttonB = createButton(FlxG.width - 132, FlxG.height - 135, B_W, B_H, "b"));
				add(buttonY = createButton(FlxG.width - 258, FlxG.height - 135, B_W, B_H, "y"));
			case X_Y:
				add(buttonY = createButton(FlxG.width - 132, FlxG.height - 135, B_W, B_H, "y"));
				add(buttonX = createButton(FlxG.width - 258, FlxG.height - 135, B_W, B_H, "x"));
			case B_X_Y:
				add(buttonB = createButton(FlxG.width - 132, FlxG.height - 135, B_W, B_H, "b"));
				add(buttonY = createButton(FlxG.width - 258, FlxG.height - 135, B_W, B_H, "y"));
				add(buttonX = createButton(FlxG.width - 381, FlxG.height - 135, B_W, B_H, "x"));
			case B_C_X_Y:
				add(buttonY = createButton(FlxG.width - 258, FlxG.height - 255, B_W, B_H, "y"));
				add(buttonX = createButton(FlxG.width - 132, FlxG.height - 255, B_W, B_H, "x"));
				add(buttonC = createButton(FlxG.width - 258, FlxG.height - 135, B_W, B_H, "c"));
				add(buttonB = createButton(FlxG.width - 132, FlxG.height - 135, B_W, B_H, "b"));
			case A_C_X_Y:
				add(buttonY = createButton(FlxG.width - 258, FlxG.height - 255, B_W, B_H, "y"));
				add(buttonX = createButton(FlxG.width - 132, FlxG.height - 255, B_W, B_H, "x"));
				add(buttonC = createButton(FlxG.width - 258, FlxG.height - 135, B_W, B_H, "c"));
				add(buttonA = createButton(FlxG.width - 132, FlxG.height - 135, B_W, B_H, "a"));
      /**
			case E:
				add(buttonE = createExtraImageButton(50, 475, "menus/EButton"));
			case E_M:
				add(buttonE = createExtraImageButton(50, 475, "menus/EButton"));
				add(buttonM = createExtraImageButton(1000, 475, "menus/MButton"));
			case M:
				add(buttonM = createExtraImageButton(1000, 475, "menus/MButton"));
			case BACK:
				add(buttonBack = createExtraSparrowButton(1000, 475, "menus/backButton", "back"));
      **/
			case NONE:
			default:
		}

		scrollFactor.set();
	}

	public function rebind(button:String, key:String):Void
	{
		var btnLower = button.toLowerCase();
		var keyFormatted = FlxKey.fromString(key.toUpperCase());

		if (keyBinds.exists(btnLower) && keyFormatted != FlxKey.NONE)
		{
			keyBinds.set(btnLower, keyFormatted);
		}
	}

	function resetButton(btn:MobileButton)
    {
	    if (btn == null) return;
    	btn.justPressed = false;
    	btn.justReleased = false;
    	btn.pressed = false;
    }

	function playBackAnim(btn:MobileButton, pressed:Bool)
    {
		if (btn == null)
            return;
		
        if (pressed)
        {
            btn.animation.play("pressed", true);
        }

        if (btn.animation.curAnim != null
            && btn.animation.curAnim.name == "pressed"
            && btn.animation.curAnim.finished)
        {
            btn.animation.play("normal");
        }
    }
      
	override function update(elapsed:Float) 
	{
		if (!active || !visible) {
			super.update(elapsed);
			return;
		}

		var padButtons = [buttonY, buttonX, buttonC, buttonB, buttonA, buttonDown2, buttonRight2, buttonUp2, buttonLeft2, buttonDown, buttonRight, buttonUp, buttonLeft, buttonE, buttonM, buttonBack];
		
		var currentOpacity = ClientPrefs.virtualPadOpacity;
		for (btn in padButtons) {
			if (btn != null) {
				if (btn == buttonE || btn == buttonM || btn == buttonBack) {
					btn.alpha = 1.0;
				} else {
					btn.alpha = currentOpacity;
				}
			}
		}

		if (FunkinPad.lastUpdateFrame != FlxG.game.ticks) {
			FunkinPad.usedTouches = [];
			FunkinPad.lastUpdateFrame = FlxG.game.ticks;
		}

		if (blockInput || inputBlockFrames > 0)
        {
        	if (inputBlockFrames > 0) inputBlockFrames--;
            for (btn in padButtons) resetButton(btn);

            if (!blockInput) {
         	    FlxG.mouse.reset();
        	    FlxG.touches.reset();
            }

            super.update(elapsed);
         	return;
        }

		var overlappingPad:Bool = false;
		var cam = virtualpadCamera != null ? virtualpadCamera : (this.cameras != null && this.cameras.length > 0 ? this.cameras[0] : FlxG.camera);

		for (btn in padButtons) {
			if (btn == null || !btn.exists || !btn.active || !btn.visible) continue;

			var isPressed = false;

			for (touch in FlxG.touches.list) {
				if (touch.pressed && !FunkinPad.usedTouches.contains(touch)) { 
					var point = touch.getWorldPosition(cam);
					if (btn.overlapsPoint(point, true, cam)) {
						isPressed = true;
						overlappingPad = true;
						FunkinPad.usedTouches.push(touch);
						point.put();
						break;
					}
					point.put();
				}
			}

			var wasPressed = btn.pressed;
			btn.justPressed = isPressed && !wasPressed;
			btn.justReleased = !isPressed && wasPressed;
			btn.pressed = isPressed;

			var key = getBindForButton(btn);

			if (key != FlxKey.NONE)
			{
				@:privateAccess
				{
					if (btn.justPressed)
						FlxG.keys._keyListMap[key].current = JUST_PRESSED;
					else if (btn.justReleased)
						FlxG.keys._keyListMap[key].current = JUST_RELEASED;
					else if (btn.pressed)
					{
						if (FlxG.keys._keyListMap[key].current == JUST_PRESSED)
							FlxG.keys._keyListMap[key].current = PRESSED;
					}
					else
					{
						if (FlxG.keys._keyListMap[key].current == JUST_RELEASED)
							FlxG.keys._keyListMap[key].current = RELEASED;
					}
				}
			}
			playBackAnim(buttonBack, FlxG.keys.justPressed.ESCAPE || FlxG.keys.justPressed.BACKSPACE);
		}
		
		if (overlappingPad)
		{
			@:privateAccess
			FlxG.mouse._leftButton.current = FlxInputState.RELEASED;
		}

		FunkinPad.touchingPad = overlappingPad;
		super.update(elapsed);

		for (btn in padButtons)
		{
			if (btn != null && btn.exists && btn.visible)
			{
				if (btn.pressed)
					btn.animation.play("pressed");
				else
					btn.animation.play("normal");
			}
		}
	}
	
	private inline function getBind(keyName:String):FlxKey 
	{
		return keyBinds.exists(keyName) ? keyBinds.get(keyName) : FlxKey.NONE;
	}

	private function getBindForButton(btn:MobileButton):FlxKey 
	{
		if (btn == buttonUp || btn == buttonUp2) return getBind("up");
		if (btn == buttonDown || btn == buttonDown2) return getBind("down");
		if (btn == buttonLeft || btn == buttonLeft2) return getBind("left");
		if (btn == buttonRight || btn == buttonRight2) return getBind("right");
		if (btn == buttonA) return getBind("a");
		if (btn == buttonB) return getBind("b");
		if (btn == buttonC) return getBind("c");
		if (btn == buttonX) return getBind("x");
		if (btn == buttonY) return getBind("y");
		if (btn == buttonE) return getBind("e");
		if (btn == buttonM) return getBind("m");
		if (btn == buttonBack) return getBind("back");
		return FlxKey.NONE;
	}

	override public function draw():Void {
		if (virtualpadCamera != null && !FlxG.cameras.list.contains(virtualpadCamera)) return; 
		super.draw();
	}

	private function addAction(btn:MobileButton, action:String):Void
	{
		if (btn == null || action == null || action == "") return;
		if (!boundActions.exists(btn)) boundActions.set(btn, []);
		
		var list = boundActions.get(btn);
		if (!list.contains(action)) list.push(action);
	}

	public function bindDPad(up:String, down:String, left:String, right:String):Void
	{
		addAction(buttonUp, up);
		addAction(buttonDown, down);
		addAction(buttonLeft, left);
		addAction(buttonRight, right);

		addAction(buttonUp2, up);
		addAction(buttonDown2, down);
		addAction(buttonLeft2, left);
		addAction(buttonRight2, right);
	}

	public function bindActionGroup(a:String = "", b:String = "", x:String = "", y:String = "", c:String = ""):Void
	{
		addAction(buttonA, a);
		addAction(buttonB, b);
		addAction(buttonX, x);
		addAction(buttonY, y);
		addAction(buttonC, c);
	}

	public function pressed(action:String, elapsed:Float):Bool
	{
		if (boundActions == null) return false;

		for (btn => actions in boundActions) {
			if (actions != null && actions.contains(action)) {
				if (btn.pressed) return true;
			}
		}
		return false;
	}
	
	public function anyPressed():Bool
	{
		var padButtons = [buttonLeft, buttonRight, buttonUp, buttonDown, buttonLeft2, buttonRight2, buttonUp2, buttonDown2, buttonA, buttonB, buttonC, buttonX, buttonY, buttonE, buttonM, buttonBack];
		for (btn in padButtons) {
			if (btn != null && btn.pressed) return true;
		}
		return false;
	}

	public function isTouchOnPad(point:FlxPoint):Bool
	{
		var padButtons = [buttonLeft, buttonRight, buttonUp, buttonDown, buttonLeft2, buttonRight2, buttonUp2, buttonDown2, buttonA, buttonB, buttonC, buttonX, buttonY, buttonE, buttonM, buttonBack];
		for (btn in padButtons) {
			if (btn != null && btn.overlapsPoint(point)) return true;
		}
		return false;
	}
	
	public function justPressed(action:String):Bool
	{
		if (boundActions == null) return false; 

		for (btn => actions in boundActions) {
			if (actions != null && actions.contains(action)) {
				if (btn.justPressed) return true;
			}
		}
		return false;
	}

	public function justReleased(action:String):Bool
	{
		if (boundActions == null) return false; 

		for (btn => actions in boundActions) {
			if (actions != null && actions.contains(action)) {
				if (btn.justReleased) return true;
			}
		}
		return false;
	}

	public function justPressedRepeated(action:String, elapsed:Float):Bool
	{
		if (boundActions == null) return false;

		var isDown:Bool = false;
		for (btn => actions in boundActions) {
			if (actions != null && actions.contains(action)) {
				if (btn.pressed) {
					isDown = true;
					break;
				}
			}
		}
  
		if (!isDown) {
			holdTimers.remove(action);
			holdActive.remove(action);
			return false;
		}

		if (!holdTimers.exists(action)) {
			holdTimers.set(action, 0);
			holdActive.set(action, false);
			return true; 
		}

		var timer = holdTimers.get(action);
		var active = holdActive.exists(action) ? holdActive.get(action) : false;
		timer += elapsed;

		if (!active) {
			if (timer >= HOLD_DELAY) {
				holdActive.set(action, true);
				holdTimers.set(action, 0);
				return true;
			}
		 } else {
			if (timer >= HOLD_REPEAT) {
				holdTimers.set(action, 0);
				return true;
			}
		}

		holdTimers.set(action, timer);
		return false;
	}
	
	override public function destroy():Void
	{
		FunkinPad.activePads.remove(this);
		
		if (boundActions != null) {
			boundActions.clear();
			boundActions = null;
		}
		
		if (holdTimers != null) {
		    holdTimers.clear();
		    holdTimers = null;
		}
		
		if (holdActive != null) {
		    holdActive.clear();
		    holdActive = null;
		}

		if (virtualpadCamera != null) {
			FlxG.cameras.remove(virtualpadCamera, false);
			virtualpadCamera = null;
		}

		buttonA = FlxDestroyUtil.destroy(buttonA);
		buttonB = FlxDestroyUtil.destroy(buttonB);
		buttonC = FlxDestroyUtil.destroy(buttonC);
		buttonX = FlxDestroyUtil.destroy(buttonX);
		buttonY = FlxDestroyUtil.destroy(buttonY);
		
		buttonLeft = FlxDestroyUtil.destroy(buttonLeft);
		buttonDown = FlxDestroyUtil.destroy(buttonDown);
		buttonUp = FlxDestroyUtil.destroy(buttonUp);
		buttonRight = FlxDestroyUtil.destroy(buttonRight);

		buttonLeft2 = FlxDestroyUtil.destroy(buttonLeft2);
		buttonDown2 = FlxDestroyUtil.destroy(buttonDown2);
		buttonUp2 = FlxDestroyUtil.destroy(buttonUp2);
		buttonRight2 = FlxDestroyUtil.destroy(buttonRight2);

		buttonE = FlxDestroyUtil.destroy(buttonE);
		buttonM = FlxDestroyUtil.destroy(buttonM);
		buttonBack = FlxDestroyUtil.destroy(buttonBack);

		this.cameras = null;
		atlasFrames = null;

		super.destroy();
	}
	
	private function createButton(x:Float, y:Float, width:Int, height:Int, graphic:String):MobileButton
	{
		var button:MobileButton = new MobileButton(x, y);
		button.frames = FlxTileFrames.fromFrame(atlasFrames.getByName(graphic), FlxPoint.get(width, height));
		button.resetSizeFromFrame();
		button.solid = false;
		button.immovable = true;
		button.scrollFactor.set();
		
		button.animation.add("normal", [0]);
		button.animation.add("highlight", [1]);
		button.animation.add("pressed", [2]);
		
		return button;
	}

	private function createExtraSparrowButton(x:Float, y:Float, path:String, animName:String):MobileButton
    {
        var btn = new MobileButton(x, y);
        var atlas = Paths.getSparrowAtlas(path);

        if (atlas != null)
        {
            btn.frames = atlas;

            btn.animation.addByPrefix("normal", animName, 24, false);
            btn.animation.addByPrefix("pressed", animName + " click", 24, false);

            btn.animation.play("normal");
        }
        else
        {
            btn.makeGraphic(132, 135, 0xFFFFFFFF);
            btn.animation.add("normal", [0], 0, false);
            btn.animation.add("pressed", [0], 0, false);

            btn.animation.play("normal");
        }

        btn.scale.set(0.8, 0.8);
        btn.updateHitbox();
        btn.solid = false;
        btn.immovable = true;
        btn.scrollFactor.set();

        return btn;
    }
	
	private function createExtraImageButton(x:Float, y:Float, path:String):MobileButton {
		var btn = new MobileButton(x, y);
		var img = Paths.image(path);
		
		if (img != null) {
			btn.loadGraphic(img);
		} else {
			btn.makeGraphic(132, 135, 0xFFFFFFFF);
		}
		
		btn.animation.add("normal", [0]);
		btn.animation.add("pressed", [0]);
		
		btn.scale.set(0.8, 0.8);
		btn.updateHitbox();
		btn.solid = false;
		btn.immovable = true;
		btn.scrollFactor.set();
		return btn;
	}
}

enum FlxDPadMode {
	NONE; UP_DOWN; LEFT_RIGHT; UP_LEFT_RIGHT; DOWN_LEFT_RIGHT; RIGHT_FULL; FULL; DOUBLE; CUSTOM;
}

enum FlxActionMode {
	NONE; A; B; X; Y; C; A_B; A_C; A_X; A_Y; A_B_C; A_X_Y; A_B_X_Y; A_C_X_Y; A_B_C_X_Y; B_C; B_X; B_Y; B_C_X_Y; B_X_Y; X_Y; E; E_M; M; BACK;
}
#end
