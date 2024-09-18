package mobile.objects;
import flixel.util.FlxSignal;

/**
 * ...
 * @author: Karim Akra
 */
interface IMobileControls
{
	public var buttonLeft:TouchButton;
	public var buttonUp:TouchButton;
	public var buttonRight:TouchButton;
	public var buttonDown:TouchButton;
	public var buttonExtra:TouchButton;
	public var buttonExtra2:TouchButton;
	public var onButtonUp:FlxTypedSignal<(TouchButton, Array<MobileInputID>)->Void>;
	public var onButtonDown:FlxTypedSignal<(TouchButton, Array<MobileInputID>)->Void>;
	public var instance:MobileInputManager;
}
