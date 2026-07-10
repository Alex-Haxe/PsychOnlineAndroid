package mobile.ui.game;

import states.PlayState;

typedef HitboxCallback = {
    var callback:Void->Void;
}

class FunkinHitbox extends FlxSpriteGroup {
    public var hitboxCamera:FlxCamera;

    public var buttonLeft:HitboxButton;
    public var buttonDown:HitboxButton;
    public var buttonUp:HitboxButton;
    public var buttonRight:HitboxButton;

    public var hintLeft:HitboxButton;
    public var hintDown:HitboxButton;
    public var hintUp:HitboxButton;
    public var hintRight:HitboxButton;

    public var buttons:Array<HitboxButton> = [];
    public var hints:Array<HitboxButton> = [];

    public var LEFT(get, never):HitboxButton; inline function get_LEFT() return buttonLeft;
    public var DOWN(get, never):HitboxButton; inline function get_DOWN() return buttonDown;
    public var UP(get, never):HitboxButton; inline function get_UP() return buttonUp;
    public var RIGHT(get, never):HitboxButton; inline function get_RIGHT() return buttonRight;

    public function new(hitboxStyle:String = "Simple", hintStyle:String = "Simple") {
        super();

        var w:Int = Std.int(FlxG.width / 4);
        var h:Int = Std.int(FlxG.height);
        
        var hintH:Int = ClientPrefs.data.fullHint ? Std.int(FlxG.height) : Std.int(FlxG.height / 28);
        var hintY:Int = hintStyle == "Gradient" ? 0 : (ClientPrefs.data.downscroll ? FlxG.height - hintH : 0);

        hitboxCamera = new FlxCamera(0, 0, FlxG.width, FlxG.height);
        hitboxCamera.bgColor = 0x00000000;

        var colors:Array<Int> = [0xFFC24B99, 0xFF00FFFF, 0xFF12FA05, 0xFFF9393F];

        for (i in 0...4) {
            var btn = new HitboxButton(w * i, 0, w, h, colors[i], hitboxCamera, false);
            buttons.push(btn);
            add(btn);
            
            var hint = new HitboxButton(w * i, hintY, w, hintH, colors[i], hitboxCamera, true);
            hints.push(hint);
            add(hint);
            
            hint.parentButton = btn;
        }

        buttonLeft = buttons[0]; buttonDown = buttons[1]; buttonUp = buttons[2]; buttonRight = buttons[3];
        hintLeft = hints[0]; hintDown = hints[1]; hintUp = hints[2]; hintRight = hints[3];

        if (hitboxStyle == "Gradient") applyGradientSafe(buttons, colors, w, h);
        if (hintStyle == "Gradient") applyGradientSafe(hints, colors, w, hintH);

        for (item in buttons) { item.cameras = [hitboxCamera]; item.scrollFactor.set(0, 0); }
        for (item in hints) { item.cameras = [hitboxCamera]; item.scrollFactor.set(0, 0); }
    }
    
    private function applyGradientSafe(buttons:Array<HitboxButton>, colors:Array<Int>, width:Int, height:Int):Void {
        for (i in 0...buttons.length) {
            var btn = buttons[i];
            var shape = new Shape();

            shape.graphics.lineStyle(2, colors[i], 0.6);
            shape.graphics.drawRect(0, 0, width, height);

            shape.graphics.beginFill(colors[i], 0.08);
            shape.graphics.drawRect(1, 1, width - 2, height - 2);
            shape.graphics.endFill();

            var glowMatrix = new Matrix();
            glowMatrix.createGradientBox(width * 3, width * 3, 0, -width * 1.5, -width * 1.5);

            shape.graphics.beginGradientFill(GradientType.RADIAL, [colors[i], 0x00000000], [0.7, 0], [0, 255], glowMatrix, SpreadMethod.PAD, InterpolationMethod.RGB);

            shape.graphics.drawRect(1, 1, width - 2, height - 2);
            shape.graphics.endFill();

            var bitmap = new BitmapData(width, height, true, 0x00000000);
            bitmap.draw(shape);

            btn.pixels = bitmap;
            btn.updateHitbox();
        }
    }
    
    public function setupCamera():Void {
        if (!FlxG.cameras.list.contains(hitboxCamera)) {
            FlxG.cameras.add(hitboxCamera, false);
        }
    }

    override public function destroy():Void {
        super.destroy();
        if (FlxG.cameras.list.contains(hitboxCamera)) {
            FlxG.cameras.remove(hitboxCamera);
        }
    }
}

class HitboxButton extends FlxSprite {
    public var onDown:HitboxCallback = {callback: null};
    public var onUp:HitboxCallback = {callback: null};
    public var onOut:HitboxCallback = {callback: null};

    public var pressed:Bool = false;
    public var justPressed:Bool = false;
    public var justReleased:Bool = false;

    private var _wasPressed:Bool = false;
    private var _assignedCamera:FlxCamera;
    private var _touchPoint:FlxPoint = new FlxPoint();

    public var isHint:Bool = false;
    public var parentButton:HitboxButton = null;

    public function new(x:Float, y:Float, width:Int, height:Int, color:FlxColor, camera:FlxCamera, isHint:Bool) {
        super(x, y);

        this.isHint = isHint;
        _assignedCamera = camera;

        makeGraphic(width, height, color);
        alpha = 0.00001;
        antialiasing = false;
    }

    override public function update(elapsed:Float) {
        _wasPressed = pressed;
        pressed = false;

        checkInputs();

        justPressed = pressed && !_wasPressed;
        justReleased = !pressed && _wasPressed;

        if (justPressed && onDown.callback != null) {
            onDown.callback();
        } 
        else if (justReleased) {
            if (overlapPointCheck(_touchPoint)) {
                if (onUp.callback != null) onUp.callback();
            } else {
                if (onOut.callback != null) onOut.callback();
            }
        }

        var effectivePressed:Bool = pressed || (parentButton != null && parentButton.pressed);

        if (effectivePressed) {
            alpha = isHint ? 0.00001 : ClientPrefs.data.hitboxOpacity;
        } else {
            if (isHint) {
                alpha = ClientPrefs.data.hintOpacity;
            } else {
                if (alpha > 0.00001) {
                    alpha -= (ClientPrefs.data.hitboxOpacity / 0.10) * elapsed;
                    if (alpha < 0.00001) {
                        alpha = 0.00001;
                    }
                }
            }
        }

        super.update(elapsed);
    }

    private function checkInputs():Void {
        #if FLX_TOUCH
        for (touch in FlxG.touches.list) {
            if (mobile.ui.menus.FunkinJoystick.activeTouchID != -1 && touch.touchPointID == mobile.ui.menus.FunkinJoystick.activeTouchID) {
                continue; 
            }

            if (touch.justPressed || touch.pressed) {
                touch.getWorldPosition(_assignedCamera, _touchPoint);
                if (overlapPointCheck(_touchPoint)) {
                    pressed = true;
                    return;
                }
            }
        }
        #end

        #if FLX_MOUSE
        if (mobile.ui.menus.FunkinJoystick.isJoystickDragging) {
            return;
        }

        if (FlxG.mouse.justPressed || FlxG.mouse.pressed) {
            FlxG.mouse.getWorldPosition(_assignedCamera, _touchPoint);
            if (overlapPointCheck(_touchPoint)) {
                pressed = true;
            }
        }
        #end
    }

    private function overlapPointCheck(point:FlxPoint):Bool {
        return (point.x >= x && point.x < x + width && point.y >= y && point.y < y + height);
    }

    override public function destroy():Void {
        _touchPoint = null;
        super.destroy();
    }
}
