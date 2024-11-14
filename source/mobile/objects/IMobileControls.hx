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
