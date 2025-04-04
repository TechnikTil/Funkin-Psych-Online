package;

import online.GameClient;
import lumod.Lumod;
#if AWAY_TEST
import states.stages.AwayStage;
#end
import states.MainMenuState;
import externs.WinAPI;
import haxe.Exception;
import flixel.graphics.FlxGraphic;

import flixel.FlxGame;
import flixel.FlxState;
import openfl.Assets;
import openfl.Lib;
import openfl.display.FPS;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.display.StageScaleMode;
import lime.app.Application;
import states.TitleState;

#if linux
import lime.graphics.Image;
#end

import sys.FileSystem;

//crash handler stuff
import openfl.events.UncaughtErrorEvent;
import haxe.CallStack;
import haxe.io.Path;
import sys.io.File;
import sys.io.Process;

class Main extends Sprite
{
	var game = {
		width: 1280, // WINDOW width
		height: 720, // WINDOW height
		initialState: TitleState, // initial game state
		zoom: -1.0, // game state bounds
		framerate: 60, // default framerate
		skipSplash: true, // if the default flixel splash screen should be skipped
		startFullscreen: false // if the game should start at fullscreen mode
	};

	public static var fpsVar:FPS;
	#if AWAY_TEST
	public static var stage3D:AwayStage;
	#end

	public static final PSYCH_ONLINE_VERSION:String = "0.11.4";
	public static final CLIENT_PROTOCOL:Float = 8;
	public static final GIT_COMMIT:String = online.backend.Macros.getGitCommitHash();
	public static final LOW_STORAGE:Bool = online.backend.Macros.hasNoCapacity();

	public static var wankyUpdate:String = 'version';

	// You can pretty much ignore everything from here on - your code should go in your states.

	public static function main():Void
	{
		if (Path.normalize(Sys.getCwd()) != Path.normalize(lime.system.System.applicationDirectory)) {
			Lib.application.window.alert("Your path is either not run from the game directory,\nor contains illegal UTF-8 characters!\n\nRun from: "
				+ Sys.getCwd()
				+ "\nExpected path: " + lime.system.System.applicationDirectory, 
			"Invalid Runtime Path!");
			Sys.exit(1);
		}
		
		Lib.current.addChild(new Main());
		Lib.current.addChild(new online.gui.sidebar.SideUI());
		Lib.current.addChild(new online.gui.Alert());
		Lib.current.addChild(new online.gui.LoadingScreen());
	}

	public function new()
	{
		super();

		if (stage != null)
		{
			init();
		}
		else
		{
			addEventListener(Event.ADDED_TO_STAGE, init);
		}
	}

	private function init(?E:Event):Void
	{
		if (hasEventListener(Event.ADDED_TO_STAGE))
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);
		}

		setupGame();
	}

	private function setupGame():Void
	{
		var stageWidth:Int = Lib.current.stage.stageWidth;
		var stageHeight:Int = Lib.current.stage.stageHeight;

		if (game.zoom == -1.0)
		{
			var ratioX:Float = stageWidth / game.width;
			var ratioY:Float = stageHeight / game.height;
			game.zoom = Math.min(ratioX, ratioY);
			game.width = Math.ceil(stageWidth / game.zoom);
			game.height = Math.ceil(stageHeight / game.zoom);
		}

		CoolUtil.setDarkMode(true);

		Lumod.scriptPathHandler = scriptPath -> {
			var defaultPath:String = 'lumod/' + scriptPath;

			// check if script exists in any of loaded mods
			var path:String = Paths.modFolders(defaultPath);
			if (FileSystem.exists(path))
				return path;

			return defaultPath;
		}
		Lumod.classResolver = Deflection.resolveClass;

		#if hl
		sys.ssl.Socket.DEFAULT_VERIFY_CERT = false;
		#end

		#if AWAY_TEST
		addChild(stage3D = new AwayStage());
		#end
	
		#if LUA_ALLOWED Lua.set_callbacks_function(cpp.Callable.fromStaticFunction(psychlua.CallbackHandler.call)); #end
		Controls.instance = new Controls();
		ClientPrefs.loadDefaultKeys();
		addChild(new FlxGame(game.width, game.height, game.initialState, #if (flixel < "5.0.0") game.zoom, #end game.framerate, game.framerate, game.skipSplash, game.startFullscreen));

		#if !mobile
		fpsVar = new FPS(10, 3, 0xFFFFFF);
		addChild(fpsVar);
		Lib.current.stage.align = "tl";
		Lib.current.stage.scaleMode = StageScaleMode.NO_SCALE;
		if(fpsVar != null) {
			fpsVar.visible = ClientPrefs.data.showFPS;
		}
		#end

		#if linux
		Lib.current.stage.window.setIcon(Image.fromFile("icon.png"));
		#end

		#if html5
		FlxG.autoPause = false;
		FlxG.mouse.visible = false;
		#end
		
		//haxe errors caught by openfl
		Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, (e) -> {
			onCrash(e.error);
		});
		//internal c++ exceptions
		untyped __global__.__hxcpp_set_critical_error_handler(onCrash);

		#if DISCORD_ALLOWED
		DiscordClient.start();
		#end

		// shader coords fix
		FlxG.signals.gameResized.add(function (w, h) {
		     if (FlxG.cameras != null) {
			   for (cam in FlxG.cameras.list) {
				@:privateAccess
				if (cam != null && cam._filters != null)
					resetSpriteCache(cam.flashSprite);
			   }
		     }

		     if (FlxG.game != null)
			 resetSpriteCache(FlxG.game);
		});

		//ONLINE STUFF, BELOW CODE USE FOR BACKPORTING

		var http = new haxe.Http("https://raw.githubusercontent.com/Snirozu/Funkin-Psych-Online/main/server_addresses.txt");
		http.onData = function(data:String) {
			for (address in data.split(',')) {
				online.GameClient.serverAddresses.push(address.trim());
			}
		}
		http.onError = function(error) {
			trace('error: $error');
		}
		http.request();
		#if LOCAL
		online.GameClient.serverAddresses.insert(0, "ws://localhost:2567");
		#else
		online.GameClient.serverAddresses.push("ws://localhost:2567");
		#end
		online.network.FunkinNetwork.client = new online.http.HTTPHandler(online.GameClient.addressToUrl());

		online.mods.ModDownloader.checkDeleteDlDir();

		addChild(new online.gui.DownloadAlert.DownloadAlerts());

		FlxG.plugins.add(new online.backend.Waiter());

		online.backend.Thread.repeat(() -> {
			try {
				online.network.FunkinNetwork.ping();
			}
			catch (exc) {
				trace(exc);
			}
		}, 60, _ -> {}); // ping the server every minute
		
		//for some reason only cancels 2 downloads
		Lib.application.window.onClose.add(() -> {
			#if DISCORD_ALLOWED
			DiscordClient.shutdown();
			#end
			online.mods.ModDownloader.cancelAll();
			online.mods.ModDownloader.checkDeleteDlDir();
			online.network.Auth.saveClose();
		});

		Lib.application.window.onDropFile.add(path -> {
			if (FileSystem.isDirectory(path))
				return;

			if (path.endsWith(".json") && (path.contains("-chart") || path.contains("-metadata"))) {
				online.util.vslice.VUtil.convertVSlice(path);
			}
			else {
				online.backend.Thread.run(() -> {
					online.gui.LoadingScreen.toggle(true);
					online.mods.OnlineMods.installMod(path);
					online.gui.LoadingScreen.toggle(false);
				});
			}
		});

		// clear messages before the current state gets destroyed and replaced with another
		FlxG.signals.preStateSwitch.add(() -> {
			GameClient.clearOnMessage();
		});

		FlxG.signals.postGameReset.add(() -> {
			online.gui.Alert.alert('Warning!', 'The game has been resetted, and there may occur visual bugs with the sidebar!\n\nIt\'s recommended to restart the game instead.');
		});
		
		#if HSCRIPT_ALLOWED
		FlxG.signals.postStateSwitch.add(() -> {
			online.backend.SyncScript.dispatch("switchState", [FlxG.state]);

			FlxG.state.subStateOpened.add(substate -> {
				online.backend.SyncScript.dispatch("openSubState", [substate]);
			});
		});

		FlxG.signals.postUpdate.add(() -> {
			if (online.backend.SyncScript.activeUpdate)
				online.backend.SyncScript.dispatch("update", [FlxG.elapsed]);
		});

		online.backend.SyncScript.resyncScript(false, () -> {
			online.backend.SyncScript.dispatch("init");
		});
		#end

		online.network.URIData.generateSave();
	}

	public static function handleArguments():Void
	{
		var appArgs:Array<String> = Sys.args();

		while(appArgs.length > 0)
		{
			var arg:String = appArgs.shift();
			switch(arg)
			{
				case '--replay':
					var id:Null<String> = appArgs.shift();

					if(id == null)
					{
						online.gui.Alert.alert('Argument Error!', '--replay requires two arguments!');
					}
					else
					{
						var downloadModURL:Null<String> = null;
						var playReplay:Void->Void = function() {
							var piss = online.network.Leaderboard.fetchReplay(id);
							var shit = haxe.Json.parse(piss);
							PlayState.replayData = cast shit;
							PlayState.replayData.gameplay_modifiers = online.replay.ReplayPlayer.objToMap(shit.gameplay_modifiers);
							PlayState.replayID = id;

							var gottaDownloadMod:Bool = true;
							if(shit.mod_url == null || shit.mod_url == '')
							{
								gottaDownloadMod = false;
								Mods.currentModDirectory = '';
							}

							if(gottaDownloadMod)
							{
								for(mod in Mods.parseList().enabled)
								{
									var url:Null<String> = online.mods.OnlineMods.getModURL(mod);
									if(url != null && url == shit.mod_url)
									{
										gottaDownloadMod = false;
										Mods.currentModDirectory = mod;
										break;
									}
								}
							}

							if(gottaDownloadMod)
							{
								downloadModURL = shit.mod_url;
								PlayState.replayData = null;
								return;
							}

							var songLowercase:String = Paths.formatToSongPath(shit.song);

							backend.WeekData.reloadWeekFiles(false);
							for(i=>week in backend.WeekData.weeksList)
							{
								var data:backend.WeekData = backend.WeekData.weeksLoaded.get(week);
								if(data == null || data.folder != Mods.currentModDirectory && data.folder != null)
									continue;

								var weGood:Bool = false;
								for(song in data.songs)
								{
									var songID:String = Paths.formatToSongPath(song[0]);
									if(songID == songLowercase)
									{
										weGood = true;
										Difficulty.forceErect = song[3];
										Difficulty.forceNightmare = song[4];
										trace(song);
										break;
									}
								}

								if(weGood)
								{
									PlayState.storyWeek = i;
									Difficulty.loadFromWeek();
									break;
								}
							}

							trace(Difficulty.list);
							PlayState.storyDifficulty = Difficulty.list.indexOf(shit.difficulty);

							var poop:String = backend.Highscore.formatSong(songLowercase, PlayState.storyDifficulty);
							trace(poop);

							if (PlayState.replayData.chart_hash == haxe.crypto.Md5.encode(backend.Song.loadRawSong(poop, songLowercase)))
							{
								try
								{
									PlayState.loadSong(poop, songLowercase);
									PlayState.isStoryMode = false;
								}
								catch(e)
								{
									online.gui.Alert.alert('Replay Error!', 'Song could not be loaded.');
									return;
								}

								LoadingState.loadAndSwitchState(new PlayState());

								Difficulty.forceErect = false;
								Difficulty.forceNightmare = false;
							}
							else
							{
								PlayState.replayData = null;

								online.gui.Alert.alert('Replay Error!', 'Song could not be found, or the replay is invalid.');
								return;
							}
						};

						playReplay();

						if(downloadModURL != null)
						{
							online.mods.OnlineMods.downloadMod(downloadModURL, true, function(_) { // technically is manually, cuz the user did open the game with this...
								downloadModURL = null;
								Mods.updatedOnState = false;
								playReplay();
							});
							FlxG.switchState(flixel.FlxState.new); // no fun for you mister (also for safety)
						}
					}
			}
		}
	}

	static function resetSpriteCache(sprite:Sprite):Void {
		@:privateAccess {
		        sprite.__cacheBitmap = null;
			sprite.__cacheBitmapData = null;
		}
	}

	static function onCrash(exc:Dynamic):Void
	{
		if (exc == null)
			exc = new Exception("Empty Uncaught Exception");

		var alertMsg:String = "";
		var daError:String = "";
		var path:String;
		var callStack:Array<StackItem> = CallStack.exceptionStack(true);
		var dateNow:String = Date.now().toString();

		dateNow = dateNow.replace(" ", "_");
		dateNow = dateNow.replace(":", "'");

		path = "./crash/" + "PsychEngine_" + dateNow + ".txt";

		alertMsg += exc + "\n";
		daError += CallStack.toString(callStack) + "\n";
		if (exc is Exception)
			daError += "\n" + cast(exc, Exception).stack.toString() + "\n";
		alertMsg += daError;

		Sys.println(alertMsg);

		if (!FileSystem.exists("./crash/"))
			FileSystem.createDirectory("./crash/");
		File.saveContent(path, alertMsg + "\n\n === \n\nCommit: " + GIT_COMMIT + "\n");
		Sys.println("Crash dump saved in " + Path.normalize(path));
		
		var daLine:Int = 0;
		var daFile:String = '';

		if (callStack.length > 0)
			switch (callStack[0]) {
				case FilePos(s, file, line, col):
					daLine = line;
					daFile = file;
					if (s != null && daFile != null && daFile.startsWith('lumod/LuaScriptClass'))
						switch (s) {
							case Method(cname, meth): // haxe has meth confirm?
								if (cname != null)
									daFile = cname.replace('.', '/') + ".hx";
							default:
						}
				default:
			}

		var cookUrl = 'https://github.com/Snirozu/Funkin-Psych-Online/blob/$GIT_COMMIT/source/$daFile#L$daLine';

		#if (windows && cpp)
		alertMsg += "\nDo you wish to report this error on GitHub?";
		alertMsg += "\nPress Yes to draft a new GitHub issue";
		alertMsg += "\nPress No to jump into the origin error point (on GitHub)";
		WinAPI.ask("Uncaught Exception!", alertMsg,
		() -> { //yes
			daError += '\nVersion: ${Main.PSYCH_ONLINE_VERSION} ([$GIT_COMMIT]($cookUrl))';
			FlxG.openURL('https://github.com/Snirozu/Funkin-Psych-Online/issues/new?title=${StringTools.urlEncode('Exception: ${exc}')}&body=${StringTools.urlEncode(daError)}');
		}, () -> { //no
			FlxG.openURL(cookUrl);
		});
		#else
		Application.current.window.alert(alertMsg, "Uncaught Exception!");
		#end
		online.network.Auth.saveClose();
		Sys.exit(1);
	}
}
