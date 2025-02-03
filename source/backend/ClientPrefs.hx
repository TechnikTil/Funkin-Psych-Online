package backend;

import options.NotesSubState;
import online.network.FunkinNetwork;
import online.GameClient;
import flixel.util.FlxSave;
import flixel.input.keyboard.FlxKey;
import flixel.input.gamepad.FlxGamepadInputID;

import states.TitleState;

// Add a variable here and it will get automatically saved
@:structInit class SaveVariables {
	// Mobile and Mobile Controls Releated
	public var extraButtons:String = "NONE"; // mobile extra button option
	public var hitboxPos:Bool = true; // hitbox extra button position option
	public var dynamicColors:Bool = true; // yes cause its cool -Karim
	public var controlsAlpha:Float = FlxG.onMobile ? 0.6 : 0;
	public var screensaver:Bool = false;
	public var wideScreen:Bool = false;
	#if android
	public var storageType:String = "EXTERNAL_DATA";
	#end
	public var hitboxType:String = "Gradient";
	public var popUpRating:Bool = true;
	public var vsync:Bool = false;
	public var disableOnlineShaders:Bool = false;

	public var downScroll:Bool = false;
	public var middleScroll:Bool = false;
	public var opponentStrums:Bool = true;
	public var showFPS:Bool = true;
	public var flashing:Bool = true;
	public var autoPause:Bool = true;
	public var antialiasing:Bool = true;
	public var noteSkin:String = 'Default';
	public var splashSkin:String = 'Psych';
	public var splashAlpha:Float = 0.6;
	public var holdSplashAlpha:Float = 0.6;
	public var holdAlpha:Float = 0.6;
	public var lowQuality:Bool = false;
	public var shaders:Bool = true;
	public var cacheOnGPU:Bool = #if !switch false #else true #end; //From Stilic
	public var framerate:Int = 60;
	public var camZooms:Bool = true;
	public var hideHud:Bool = false;
	public var noteOffset:Int = 0;
	public var arrowRGB:Array<Array<FlxColor>> = [
		[0xFFC24B99, 0xFFFFFFFF, 0xFF3C1F56],
		[0xFF00FFFF, 0xFFFFFFFF, 0xFF1542B7],
		[0xFF12FA05, 0xFFFFFFFF, 0xFF0A4447],
		[0xFFF9393F, 0xFFFFFFFF, 0xFF651038]];
	public var arrowRGBPixel:Array<Array<FlxColor>> = [
		[0xFFE276FF, 0xFFFFF9FF, 0xFF60008D],
		[0xFF3DCAFF, 0xFFF4FFFF, 0xFF003060],
		[0xFF71E300, 0xFFF6FFE6, 0xFF003100],
		[0xFFFF884E, 0xFFFFFAF5, 0xFF6C0000]];

	public var ghostTapping:Bool = true;
	public var timeBarType:String = 'Time Left';
	public var scoreZoom:Bool = true;
	public var noReset:Bool = false;
	public var healthBarAlpha:Float = 1;
	public var hitsoundVolume:Float = 0;
	public var pauseMusic:String = 'Tea Time';
	public var checkForUpdates:Bool = true;
	public var comboStacking:Bool = true;
	public var gameplaySettings:Map<String, Dynamic> = [
		'scrollspeed' => 1.0,
		'scrolltype' => 'multiplicative',
		'songspeed' => 1.0,
		'healthgain' => 1.0,
		'healthloss' => 1.0,
		'instakill' => false,
		'practice' => false,
		'botplay' => false,
		'opponentplay' => false,
		'nobadnotes' => false,
	];

	public var comboOffset:Array<Int> = [0, 0, 0, 0];
	public var ratingOffset:Int = 0;
	public final sickWindow:Int = 45;
	public final goodWindow:Int = 90;
	public final badWindow:Int = 135;
	public var safeFrames:Float = 10;
	public var discordRPC:Bool = true;
	// PSYCH ONLINE
	private var nickname:String = "Boyfriend";
	public var serverAddress:String = null;
	public var modSkin:Array<String> = null;
	public var trustedSources:Array<String> = ["https://gamebanana.com/"];
	public var comboOffsetOP1:Array<Int> = [0, 0, 0, 0];
	public var comboOffsetOP2:Array<Int> = [0, 0, 0, 0];
	public var disableStrumMovement:Bool = false;
	public var unlockFramerate:Bool = false;
	public var debugMode:Bool = false;
	public var disableReplays:Bool = false;
	public var disableSubmiting:Bool = false;
	public var showNoteTiming:Bool = false;
	public var disableAutoDownloads:Bool = false;
	public var disableSongComments:Bool = false;
	public var disableFreeplayIcons:Bool = false;
	public var showFP:Bool = false;
	public var disableFreeplayAlphabet:Bool = false;
	public var disableLagDetection:Bool = false;
	public var groupSongsBy:String = 'No Grouping';
	public var hiddenSongs:Array<String> = []; //format: 'songname-originfolder'
	public var favSongs:Array<String> = []; //format: 'songname-originfolder'
	public var modchartSkinChanges:Bool = false;

	public function new()
	{
		//Why does haxe needs this again?
	}
}

class ClientPrefs {
	public static var data:SaveVariables = {};
	public static var defaultData:SaveVariables = {};

	//Every key has two binds, add your key bind down here and then add your control on options/ControlsSubState.hx and Controls.hx
	public static var keyBinds:Map<String, Array<FlxKey>> = [
		//Key Bind, Name for ControlsSubState
		'note_up'		=> [W, UP],
		'note_left'		=> [A, LEFT],
		'note_down'		=> [S, DOWN],
		'note_right'	=> [D, RIGHT],
		
		'ui_up'			=> [W, UP],
		'ui_left'		=> [A, LEFT],
		'ui_down'		=> [S, DOWN],
		'ui_right'		=> [D, RIGHT],
		
		'accept'		=> [SPACE, ENTER],
		'back'			=> [BACKSPACE, ESCAPE],
		'pause'			=> [ENTER, ESCAPE],
		'reset'			=> [R],
		'taunt'			=> [SPACE],
		'sidebar'		=> [GRAVEACCENT],
		'fav'			=> [Q],
		
		'volume_mute'	=> [ZERO],
		'volume_up'		=> [NUMPADPLUS, PLUS],
		'volume_down'	=> [NUMPADMINUS, MINUS],
		
		'debug_1'		=> [SEVEN],
		'debug_2'		=> [EIGHT]
	];
	public static var gamepadBinds:Map<String, Array<FlxGamepadInputID>> = [
		'note_up'		=> [DPAD_UP, Y],
		'note_left'		=> [DPAD_LEFT, X],
		'note_down'		=> [DPAD_DOWN, A],
		'note_right'	=> [DPAD_RIGHT, B],
		
		'ui_up'			=> [DPAD_UP, LEFT_STICK_DIGITAL_UP],
		'ui_left'		=> [DPAD_LEFT, LEFT_STICK_DIGITAL_LEFT],
		'ui_down'		=> [DPAD_DOWN, LEFT_STICK_DIGITAL_DOWN],
		'ui_right'		=> [DPAD_RIGHT, LEFT_STICK_DIGITAL_RIGHT],
		
		'accept'		=> [A, START],
		'back'			=> [B],
		'pause'			=> [START],
		'reset'			=> [BACK],
		'taunt'			=> [A],
		'sidebar'		=> [],
		'fav'			=> []
	];
	public static var mobileBinds:Map<String, Array<MobileInputID>> = [
		'note_up'		=> [NOTE_UP],
		'note_left'		=> [NOTE_LEFT],
		'note_down'		=> [NOTE_DOWN],
		'note_right'	=> [NOTE_RIGHT],

		'ui_up'			=> [UP],
		'ui_left'		=> [LEFT],
		'ui_down'		=> [DOWN],
		'ui_right'		=> [RIGHT],

		'accept'		=> [A],
		'back'			=> [B],
		'pause'			=> [#if android NONE #else P #end],
		'reset'			=> [NONE],
		'taunt'			=> [TAUNT]
	];
	public static var defaultMobileBinds:Map<String, Array<MobileInputID>> = null;
	public static var defaultKeys:Map<String, Array<FlxKey>> = null;
	public static var defaultButtons:Map<String, Array<FlxGamepadInputID>> = null;

	public static function resetKeys(controller:Null<Bool> = null) //Null = both, False = Keyboard, True = Controller
	{
		if(controller != true)
		{
			for (key in keyBinds.keys())
			{
				if(defaultKeys.exists(key))
					keyBinds.set(key, defaultKeys.get(key).copy());
			}
		}
		if(controller != false)
		{
			for (button in gamepadBinds.keys())
			{
				if(defaultButtons.exists(button))
					gamepadBinds.set(button, defaultButtons.get(button).copy());
			}
		}
	}

	public static function clearInvalidKeys(key:String) {
		var keyBind:Array<FlxKey> = keyBinds.get(key);
		var gamepadBind:Array<FlxGamepadInputID> = gamepadBinds.get(key);
		var mobileBind:Array<MobileInputID> = mobileBinds.get(key);
		while(keyBind != null && keyBind.contains(NONE)) keyBind.remove(NONE);
		while(gamepadBind != null && gamepadBind.contains(NONE)) gamepadBind.remove(NONE);
		while(mobileBind != null && mobileBind.contains(NONE)) mobileBind.remove(NONE);
	}

	public static function loadDefaultKeys() {
		defaultKeys = keyBinds.copy();
		defaultButtons = gamepadBinds.copy();
		defaultMobileBinds = mobileBinds.copy();
	}

	public static function saveSettings() {
		for (key in Reflect.fields(data)) {
			//trace('saved variable: $key');
			Reflect.setField(FlxG.save.data, key, Reflect.field(data, key));
		}
		FlxG.save.data.achievementsMap = Achievements.achievementsMap;
		FlxG.save.data.henchmenDeath = Achievements.henchmenDeath;
		FlxG.save.flush();

		//Placing this in a separate save so that it can be manually deleted without removing your Score and stuff
		var save:FlxSave = new FlxSave();
		save.bind('controls_v3', CoolUtil.getSavePath());
		save.data.keyboard = keyBinds;
		save.data.gamepad = gamepadBinds;
		save.data.mobile = mobileBinds;
		save.flush();
		FlxG.log.add("Settings saved!");
	}

	public static function loadPrefs() {
		for (key in Reflect.fields(data)) {
			if (key != 'gameplaySettings' && Reflect.hasField(FlxG.save.data, key)) {
				//trace('loaded variable: $key');
				Reflect.setField(data, key, Reflect.field(FlxG.save.data, key));
			}
		}
		
		if(Main.fpsVar != null) {
			Main.fpsVar.visible = data.showFPS;
		}

		#if (!html5 && !switch)
		FlxG.autoPause = ClientPrefs.data.autoPause;
		#end

		if (ClientPrefs.data.unlockFramerate) {
			FlxG.updateFramerate = 1000;
			FlxG.drawFramerate = 1000;
		} else if(data.framerate > FlxG.drawFramerate) {
			FlxG.updateFramerate = data.framerate;
			FlxG.drawFramerate = data.framerate;
		} else {
			FlxG.drawFramerate = data.framerate;
			FlxG.updateFramerate = data.framerate;
		}

		if(FlxG.save.data.gameplaySettings != null) {
			var savedMap:Map<String, Dynamic> = FlxG.save.data.gameplaySettings;
			for (name => value in savedMap)
				data.gameplaySettings.set(name, value);
		}
		
		// flixel automatically saves your volume!
		if(FlxG.save.data.volume != null)
			FlxG.sound.volume = FlxG.save.data.volume;
		if (FlxG.save.data.mute != null)
			FlxG.sound.muted = FlxG.save.data.mute;

		#if DISCORD_ALLOWED
		DiscordClient.check();
		#end

		// controls on a separate save file
		var save:FlxSave = new FlxSave();
		save.bind('controls_v3', CoolUtil.getSavePath());
		if(save != null)
		{
			if(save.data.keyboard != null) {
				var loadedControls:Map<String, Array<FlxKey>> = save.data.keyboard;
				for (control => keys in loadedControls) {
					if(keyBinds.exists(control)) keyBinds.set(control, keys);
				}
			}
			if(save.data.gamepad != null) {
				var loadedControls:Map<String, Array<FlxGamepadInputID>> = save.data.gamepad;
				for (control => keys in loadedControls) {
					if(gamepadBinds.exists(control)) gamepadBinds.set(control, keys);
				}
			}
			if(save.data.mobile != null) {
				var loadedControls:Map<String, Array<MobileInputID>> = save.data.mobile;
				for (control => keys in loadedControls)
					if(mobileBinds.exists(control)) mobileBinds.set(control, keys);
			}
			reloadVolumeKeys();
		}
	}

	inline public static function getGameplaySetting(name:String, defaultValue:Dynamic = null, ?customDefaultValue:Bool = false):Dynamic {
		if(!customDefaultValue) defaultValue = defaultData.gameplaySettings.get(name);
		var daGameplaySetting:Dynamic = GameClient.isConnected() && !GameClient.room.state.permitModifiers ? GameClient.getGameplaySetting(name) : data.gameplaySettings.get(name);
		if (PlayState.replayData?.gameplay_modifiers != null) {
			daGameplaySetting = PlayState.replayData?.gameplay_modifiers?.get(name);
		}
		return /*PlayState.isStoryMode ? defaultValue : */ (daGameplaySetting != null ? daGameplaySetting : defaultValue);
	}

	public static function reloadVolumeKeys() {
		TitleState.muteKeys = keyBinds.get('volume_mute').copy();
		TitleState.volumeDownKeys = keyBinds.get('volume_down').copy();
		TitleState.volumeUpKeys = keyBinds.get('volume_up').copy();
		toggleVolumeKeys(true);
	}
	public static function toggleVolumeKeys(?turnOn:Bool = true) {
		if(!Controls.instance.mobileC && turnOn)
		{
			FlxG.sound.muteKeys = TitleState.muteKeys;
			FlxG.sound.volumeDownKeys = TitleState.volumeDownKeys;
			FlxG.sound.volumeUpKeys = TitleState.volumeUpKeys;
		}
		else
		{
			FlxG.sound.muteKeys = [];
			FlxG.sound.volumeDownKeys = [];
			FlxG.sound.volumeUpKeys = [];
		}
	}
	public static function isDebug() {
		#if debug
		return true;
		#end

		if (PlayState.chartingMode)
			return true;
		
		return data.debugMode;
	}

	public static function getNickname() {
		if (FunkinNetwork.loggedIn)
			return FunkinNetwork.nickname;

		@:privateAccess
		return data.nickname;
	}

	public static function setNickname(name) {
		if (FunkinNetwork.loggedIn)
			return FunkinNetwork.updateName(name);

		if (name == "")
			return @:privateAccess data.nickname = "Boyfriend";

		return @:privateAccess data.nickname = name;
	}

	public static function getGhostTapping() {
		return PlayState.replayData?.ghost_tapping ?? data.ghostTapping;
	}

	public static function getRatingOffset() {
		return PlayState.replayData?.rating_offset ?? data.ratingOffset;
	}

	public static function getSafeFrames() {
		return PlayState.replayData?.safe_frames ?? data.safeFrames;
	}

	public static function getRGBColor(player:Int = 0):Array<Array<FlxColor>> {
		if (!GameClient.isConnected() || NotesSubState.isOpened)
			return data.arrowRGB;

		if (player == 0)
			return [ 
				CoolUtil.asta(GameClient.room.state.player1.arrowColor0),
				CoolUtil.asta(GameClient.room.state.player1.arrowColor1),
				CoolUtil.asta(GameClient.room.state.player1.arrowColor2),
				CoolUtil.asta(GameClient.room.state.player1.arrowColor3),
			];
		
		return [
			CoolUtil.asta(GameClient.room.state.player2.arrowColor0),
			CoolUtil.asta(GameClient.room.state.player2.arrowColor1),
			CoolUtil.asta(GameClient.room.state.player2.arrowColor2),
			CoolUtil.asta(GameClient.room.state.player2.arrowColor3),
		];
	}

	public static function getRGBPixelColor(player:Int = 0):Array<Array<FlxColor>> {
		if (!GameClient.isConnected() || NotesSubState.isOpened)
			return data.arrowRGBPixel;

		if (player == 0)
			return [
				CoolUtil.asta(GameClient.room.state.player1.arrowColorP0),
				CoolUtil.asta(GameClient.room.state.player1.arrowColorP1),
				CoolUtil.asta(GameClient.room.state.player1.arrowColorP2),
				CoolUtil.asta(GameClient.room.state.player1.arrowColorP3),
			];

		return [
			CoolUtil.asta(GameClient.room.state.player2.arrowColorP0),
			CoolUtil.asta(GameClient.room.state.player2.arrowColorP1),
			CoolUtil.asta(GameClient.room.state.player2.arrowColorP2),
			CoolUtil.asta(GameClient.room.state.player2.arrowColorP3),
		];
	}
}
