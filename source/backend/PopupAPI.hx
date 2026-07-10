package backend;

#if android
import extension.androidtools.Tools;
#elseif ios
import iostools.ui.IOSAlert; 
#end

class PopupAPI {
  /**
	 * Shows a message box
	 */
	public static function showMessageBox(caption:String, message:String, buttonName:String = "OK", icon:MessageBoxIcon = MSG_WARNING) {
    #if android
    extension.androidtools.Tools.showAlertDialog(caption, message, {name: buttonName, func: null});
		#elseif ios
	  IOSAlert.show(caption, message, buttonName);
    #elseif (windows && !macro)
    var iconInt:Int = cast(icon, Int);
    untyped __cpp__('MessageBoxA(GetActiveWindow(), {0}.c_str(), {1}.c_str(), {2})', message, caption, iconInt);
    #else
    lime.app.Application.current.window.alert(message, caption);
    #end
  }
