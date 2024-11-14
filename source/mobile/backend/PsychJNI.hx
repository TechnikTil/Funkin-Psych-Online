/*
 * Copyright (C) 2024 Mobile Porting Team
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <https://www.gnu.org/licenses/>.
 */

package mobile.backend;

/**
 * ...
 * @author Lily Ross (mcagabe19)
 */
#if android
import lime.system.JNI;

class PsychJNI #if (lime >= "8.0.0") implements JNISafety #end
{
	public static final SDL_ORIENTATION_UNKNOWN:Int = 0;
	public static final SDL_ORIENTATION_LANDSCAPE:Int = 1;
	public static final SDL_ORIENTATION_LANDSCAPE_FLIPPED:Int = 2;
	public static final SDL_ORIENTATION_PORTRAIT:Int = 3;
	public static final SDL_ORIENTATION_PORTRAIT_FLIPPED:Int = 4;

	public static inline function setOrientation(width:Int, height:Int, resizeable:Bool, hint:String):Dynamic
		return setOrientation_jni(width, height, resizeable, hint);

	public static inline function getCurrentOrientationAsString():String
	{
		return switch (getCurrentOrientation_jni())
		{
			case SDL_ORIENTATION_PORTRAIT: "Portrait";
			case SDL_ORIENTATION_LANDSCAPE: "LandscapeRight";
			case SDL_ORIENTATION_PORTRAIT_FLIPPED: "PortraitUpsideDown";
			case SDL_ORIENTATION_LANDSCAPE_FLIPPED: "LandscapeLeft";
			default: "Unknown";
		}
	}

	public static inline function isScreenKeyboardShown():Dynamic
		return isScreenKeyboardShown_jni();

	public static inline function clipboardHasText():Dynamic
		return clipboardHasText_jni();

	public static inline function clipboardGetText():Dynamic
		return clipboardGetText_jni();

	public static inline function clipboardSetText(string:String):Dynamic
		return clipboardSetText_jni(string);

	public static inline function manualBackButton():Dynamic
		return manualBackButton_jni();

	public static inline function setActivityTitle(title:String):Dynamic
		return setActivityTitle_jni(title);

	@:noCompletion private static var setOrientation_jni:Dynamic = JNI.createStaticMethod('org/libsdl/app/SDLActivity', 'setOrientation',
		'(IIZLjava/lang/String;)V');
	@:noCompletion private static var getCurrentOrientation_jni:Dynamic = JNI.createStaticMethod('org/libsdl/app/SDLActivity', 'getCurrentOrientation', '()I');
	@:noCompletion private static var isScreenKeyboardShown_jni:Dynamic = JNI.createStaticMethod('org/libsdl/app/SDLActivity', 'isScreenKeyboardShown', '()Z');
	@:noCompletion private static var clipboardHasText_jni:Dynamic = JNI.createStaticMethod('org/libsdl/app/SDLActivity', 'clipboardHasText', '()Z');
	@:noCompletion private static var clipboardGetText_jni:Dynamic = JNI.createStaticMethod('org/libsdl/app/SDLActivity', 'clipboardGetText',
		'()Ljava/lang/String;');
	@:noCompletion private static var clipboardSetText_jni:Dynamic = JNI.createStaticMethod('org/libsdl/app/SDLActivity', 'clipboardSetText',
		'(Ljava/lang/String;)V');
	@:noCompletion private static var manualBackButton_jni:Dynamic = JNI.createStaticMethod('org/libsdl/app/SDLActivity', 'manualBackButton', '()V');
	@:noCompletion private static var setActivityTitle_jni:Dynamic = JNI.createStaticMethod('org/libsdl/app/SDLActivity', 'setActivityTitle',
		'(Ljava/lang/String;)Z');
}
#end
