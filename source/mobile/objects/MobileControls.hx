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

// I wanted to delete this but i have no idea how i coded MobileControlSelectSubState so idk how to implement IMobileControls into it... yet...

/**
 * ...
 * @author: Karim Akra
 */
class MobileControls extends FlxTypedSpriteGroup<MobileInputManager>
{
	public var touchPad:TouchPad = new TouchPad('NONE', 'NONE', NONE);
	public var hitbox:Hitbox = new Hitbox(NONE);

	public function new(?forceType:Int, ?extra:Bool = true)
	{
		super();
		MobileData.forcedMode = forceType;
		switch (MobileData.mode)
		{
			case 0: // RIGHT_FULL
				initControler(0, extra);
			case 1: // LEFT_FULL
				initControler(1, extra);
			case 2: // CUSTOM
				initControler(2, extra);
			case 3: // HITBOX
				initControler(3, extra);
		}
		alpha = ClientPrefs.data.controlsAlpha;
	}

	private function initControler(controlMode:Int = 0, ?extra:Bool = true):Void
	{
		var extraAction = MobileData.extraActions.get(ClientPrefs.data.extraButtons);
		if (!extra)
			extraAction = NONE;
		switch (controlMode)
		{
			case 0:
				touchPad = new TouchPad('RIGHT_FULL', 'NONE', extraAction);
				touchPad = MobileData.setButtonsColors(touchPad);
				add(touchPad);
			case 1:
				touchPad = new TouchPad('LEFT_FULL', 'NONE', extraAction);
				touchPad = MobileData.setButtonsColors(touchPad);
				add(touchPad);
			case 2:
				touchPad = MobileData.getTouchPadCustom(new TouchPad('RIGHT_FULL', 'NONE', extraAction));
				touchPad = MobileData.setButtonsColors(touchPad);
				add(touchPad);
			case 3:
				hitbox = new Hitbox(extraAction);
				hitbox = MobileData.setButtonsColors(hitbox);
				add(hitbox);
		}
	}

	override public function destroy():Void
	{
		super.destroy();

		if (touchPad != null)
		{
			touchPad = FlxDestroyUtil.destroy(touchPad);
			touchPad = null;
		}

		if (hitbox != null)
		{
			hitbox = FlxDestroyUtil.destroy(hitbox);
			hitbox = null;
		}
		MobileData.forcedMode = null;
	}
}
