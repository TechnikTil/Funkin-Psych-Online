package online.states;

import objects.HealthIcon;
import flixel.FlxSubState;
import flixel.FlxObject;
import states.FreeplayState;
import states.editors.CharacterEditorState;
import backend.WeekData;
import haxe.io.Path;
import sys.FileSystem;
import flixel.group.FlxGroup;
import objects.Character;

class SkinsState extends MusicBeatState {
	var charactersName:Array<String> = new Array<String>();
	var charactersLength:Int = 0;
    var character:FlxTypedGroup<Character>;
    static var curCharacter:Int = -1;
    var charactersMod:Map<String, String> = new Map<String, String>();
	var characterCamera:FlxCamera;

	var hud:FlxCamera;
	var charSelect:FlxText;

	var bg:FlxSprite;
	var title:Alphabet;

	var arrowLeft:Alphabet;
	var arrowRight:Alphabet;
	var alX:Float = 0;
	var arX:Float = 0;

	static var flipped:Bool = false;

	final accept:String = (Controls.instance.mobileC) ? "A" : "ACCEPT";
	static var backClass:Class<Dynamic>;

	var reloadedState:Bool = false;
	public function new() {
		super();

		if (FlxG.state is SkinsState) {
			reloadedState = true;
			return;
		}

		if (FlxG.state is CharacterEditorState)
			return;

		backClass = Type.getClass(FlxG.state);
	}

	var blackRectangle:FlxSprite;

	var staticSound:FlxSound;
	public static var music:FlxSound;
	// public static var musicIntro:FlxSound;
	
	static var prevConBPM:Float;
	static var prevConBPMChanges:Array<backend.BPMChangeEvent>;
	static var prevConTime:Float;

	var staticMan:FlxSprite;
	var selectTimer:FlxTimer;

	var stageCrowd:FlxAnimate;
	var stageSpeakers:FlxAnimate;
	var defaultGirlfriend:FlxAnimate;
	var camFollow:FlxObject;
	// static var introPlayed:Bool = false;

    override function create() {
		Paths.clearUnusedMemory();
		Paths.clearStoredMemory();

		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Selects their Skin", null, null, false);
		#end

		Mods.loadTopMod();
		WeekData.setDirectoryFromWeek();
		
		if (!reloadedState) {
			for (v in [FlxG.sound.music, FreeplayState.vocals, FreeplayState.opponentVocals]) {
				if (v == null)
					continue;

				v.pause();
			}

			prevConBPM = Conductor.bpm;
			prevConBPMChanges = Conductor.bpmChangeMap;
			prevConTime = Conductor.songPosition;

			// if (musicIntro != null)
			// 	musicIntro.stop();
			if (music != null)
				music.stop();

			music = FlxG.sound.play(Paths.music('stayFunky'), 1, true);
			music.persist = true;
			FlxG.sound.list.add(music);

			// if (!introPlayed) {
			//  music.pause();
			//
			// 	musicIntro = FlxG.sound.play(Paths.music('stayFunky-intro'), 1, false);
			// 	musicIntro.onComplete = () -> {
			// 		introPlayed = true;
			// 		music.play();
			// 	}
			// 	musicIntro.persist = true;
			// 	FlxG.sound.list.add(musicIntro);
			// }

			Conductor.bpm = 90;
			Conductor.bpmChangeMap = [];
			Conductor.songPosition = 0;
		}

		FlxG.cameras.add(characterCamera = new FlxCamera(), false);
		FlxG.cameras.add(hud = new FlxCamera(), false);
		CustomFadeTransition.nextCamera = hud;
		characterCamera.bgColor.alpha = 0;
		hud.bgColor.alpha = 0;
		characterCamera.zoom = 0.8;

		camFollow = new FlxObject(FlxG.width / 2, FlxG.height / 2 - 200, 1, 1);
		
		camera.follow(camFollow, LOCKON, 0.05);
		characterCamera.follow(camFollow, LOCKON, 0.05);
		camera.snapToTarget();
		characterCamera.snapToTarget();

		camFollow.setPosition(FlxG.width / 2, FlxG.height / 2);

		blackRectangle = new FlxSprite();
		blackRectangle.makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		blackRectangle.cameras = [hud];

		bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.color = 0xff303030;
		bg.setGraphicSize(Std.int(bg.width * 1.1));
		bg.screenCenter();
		bg.antialiasing = ClientPrefs.data.antialiasing;
		add(bg);

		if (!ClientPrefs.data.lowQuality) {
			var stageBg = new FlxSprite(0, -220).loadGraphic(Paths.image('charSelect/charSelectBG'));
			stageBg.setGraphicSize(Std.int(stageBg.width * 1.1));
			stageBg.updateHitbox();
			stageBg.antialiasing = ClientPrefs.data.antialiasing;
			stageBg.screenCenter(X);
			stageBg.scrollFactor.set(0.5, 0.5);
			add(stageBg);

			stageCrowd = new FlxAnimate(0, 240);
			Paths.loadAnimateAtlas(stageCrowd, 'charSelect/crowd');
			stageCrowd.antialiasing = ClientPrefs.data.antialiasing;
			stageCrowd.anim.addBySymbol('beat', 'crowd', 24, true);
			stageCrowd.anim.play('beat');
			stageCrowd.scrollFactor.set(0.7, 0.7);
			add(stageCrowd);

			var stage = new FlxSprite(0, 390);
			stage.antialiasing = ClientPrefs.data.antialiasing;
			stage.frames = Paths.getSparrowAtlas('charSelect/charSelectStage');
			stage.animation.addByPrefix('idle', "stage full instance 1", 24);
			stage.animation.play('idle');
			stage.updateHitbox();
			stage.screenCenter(X);
			stage.scrollFactor.set(0.9, 0.9);
			add(stage);

			var swageLight1 = new FlxSprite(200, 280).loadGraphic(Paths.image('charSelect/charLight'));
			swageLight1.antialiasing = ClientPrefs.data.antialiasing;
			swageLight1.scrollFactor.set(0.75, 0.75);
			add(swageLight1);

			var swageLight2 = new FlxSprite(700, 280).loadGraphic(Paths.image('charSelect/charLight'));
			swageLight2.antialiasing = ClientPrefs.data.antialiasing;
			swageLight2.scrollFactor.set(0.75, 0.75);
			add(swageLight2);

			var stageCurtain = new FlxSprite(0, 0).loadGraphic(Paths.image('charSelect/curtains'));
			stageCurtain.setGraphicSize(Std.int(stageCurtain.width * 1.05));
			stageCurtain.updateHitbox();
			stageCurtain.antialiasing = ClientPrefs.data.antialiasing;
			stageCurtain.screenCenter(XY);
			stageCurtain.scrollFactor.set(0.95, 0.1);
			add(stageCurtain);

			stageSpeakers = new FlxAnimate(-80, 440);
			Paths.loadAnimateAtlas(stageSpeakers, 'charSelect/charSelectSpeakers');
			stageSpeakers.antialiasing = ClientPrefs.data.antialiasing;
			stageSpeakers.anim.addBySymbol('beat', 'Speakers ALL', 24, true);
			stageSpeakers.anim.play('beat');
			stageSpeakers.scrollFactor.set(0.95, 0.95);
			add(stageSpeakers);

			defaultGirlfriend = new FlxAnimate(-80, 440);
			Paths.loadAnimateAtlas(defaultGirlfriend, 'charSelect/gfChill');
			defaultGirlfriend.antialiasing = ClientPrefs.data.antialiasing;
			defaultGirlfriend.anim.addBySymbol('beat', 'GIRLFRIEND CS', 24, true);
			defaultGirlfriend.anim.play('beat');
			defaultGirlfriend.scrollFactor.set(0.95, 0.95);
			add(defaultGirlfriend);
		}

        var i = 0;

		var oldModDir = Mods.currentModDirectory;

		// var defaultName = !flipped ? "default" : "default-player";
		// characterList.set(defaultName, new Character(0, 0, defaultName, flipped));
		// charactersMod.set(defaultName, null);
		// charactersName.set(i, defaultName);
        // i++;

		var hardList = [];

		for (name in [null].concat(Mods.parseList().enabled)) {
			var characters:String;
			if (name == null) {
				Mods.loadTopMod();
				characters = 'assets/characters/';
			}
			else {
				Mods.currentModDirectory = name;
				characters = Paths.mods(name + '/characters/');
			}
			if (FileSystem.exists(characters)) {
				for (file in Paths.readDirectory(characters)) {
					var path = Path.join([characters, file]);
					if (!sys.FileSystem.isDirectory(path) && file.endsWith('.json')) {
						var character:String = file.substr(0, file.length - 5);
						if (!flipped ? character.endsWith("-player") : !character.endsWith("-player")) {
                            continue;
                        }

						if (!hardList.contains(character) && FileSystem.exists(Path.join([characters, (!flipped ? character + "-player" : character.substring(0, character.length - "-player".length)) + ".json"]))) {
							if (name == null)
								hardList.push(character);

							//characterList.set(character, new Character(0, 0, character, flipped));
							charactersMod.set(character, name);
							charactersName.push(character);

							//characterList.get(character).updateHitbox();

							if (curCharacter == -1 && isEquiped(name, !flipped ? character + "-player" : character.substring(0, character.length - "-player".length))) {
								curCharacter = i;
							}

							i++;
                        }
                    }
                }
            }
        }
		charactersLength = i;

		Mods.currentModDirectory = oldModDir;

        character = new FlxTypedGroup<Character>();
		character.cameras = [characterCamera];
        add(character);

		staticSound = FlxG.sound.play(Paths.sound('static loop'), 1, true, false);
		staticSound.stop();
		staticSound.persist = false;
		FlxG.sound.list.add(staticSound);

		staticMan = new FlxSprite();
		staticMan.antialiasing = ClientPrefs.data.antialiasing;
		staticMan.frames = Paths.getSparrowAtlas('randomChill');
		staticMan.animation.addByPrefix('idle', "LOCKED MAN instance 1", 24);
		staticMan.animation.play('idle');
		staticMan.flipX = !flipped;
		staticMan.updateHitbox();
		staticMan.screenCenter(XY);
		staticMan.y += 50;
		add(staticMan);

		var barUp = new FlxSprite();
		barUp.makeGraphic(FlxG.width, 100, FlxColor.BLACK);
		barUp.cameras = [hud];
		add(barUp);

		var barDown = new FlxSprite();
		barDown.makeGraphic(FlxG.width, 100, FlxColor.BLACK);
		barDown.y = FlxG.height - barDown.height;
		barDown.cameras = [hud];
		add(barDown);

		title = new Alphabet(0, 0, "BOYFRIEND", true);
		title.cameras = [hud];
		title.y = barUp.height / 2 - title.height / 2;
		title.x = FlxG.width / 2 - title.width / 2;
		add(title);

		arrowLeft = new Alphabet(0, 0, "<", true);
		arrowLeft.cameras = [hud];
		arrowLeft.y = FlxG.height / 2 - arrowLeft.height / 2;
		arrowLeft.x = alX = 100;
		add(arrowLeft);

		arrowRight = new Alphabet(0, 0, ">", true);
		arrowRight.cameras = [hud];
		arrowRight.y = FlxG.height / 2 - arrowRight.height / 2;
		arrowRight.x = arX = FlxG.width - arrowRight.width - 100;
		add(arrowRight);

		charSelect = new FlxText(0, 0, FlxG.width);
		charSelect.text = 'Press $accept to select!';
		charSelect.setFormat("VCR OSD Mono", 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		charSelect.y = barDown.y + barDown.height / 2 - charSelect.height / 2;
		charSelect.alpha = 0.8;
		charSelect.cameras = [hud];
		add(charSelect);

		final gofuckurself:String = (controls.mobileC) ? "Use Arrow Keys while pressing X to move!" : "Use Note keybinds while pressing SHIFT to move!";

		var swagText = new FlxText(0, charSelect.y + charSelect.height + 5, FlxG.width);
		swagText.text = gofuckurself;
		swagText.setFormat("VCR OSD Mono", 18, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		swagText.alpha = 0.8;
		swagText.cameras = [hud];
		add(swagText);

		final tab:String = (controls.mobileC) ? "C" : "TAB";
		final eight:String = (controls.mobileC) ? "D" : "8";
		final ctrl:String = (controls.mobileC) ? "V" : "CTRL";
		var tip1 = new FlxText(20, 0, FlxG.width, '$tab - Flip skin\n$eight - Edit skin\n$ctrl - Open the Character List');
		tip1.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		tip1.y = charSelect.y - 10;
		tip1.alpha = 0.5;
		tip1.cameras = [hud];
		add(tip1);

		var f1:String = (controls.mobileC) ? "Y" : "F1";
		var f2:String = (controls.mobileC) ? "Z" : "F2";
		var tip2 = new FlxText(-20, 0, FlxG.width, '$f1 for Help!\n$f2 to Browse Verified Skins');
		tip2.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		tip2.y = tip1.y;
		tip2.alpha = tip1.alpha;
		tip2.cameras = [hud];
		add(tip2);

		setCharacter(0);

		super.create();
		
		CustomFadeTransition.nextCamera = hud; // wat

		addTouchPad('LEFT_FULL', 'A_B_C_D_V_X_Y_Z');
		addTouchPadCamera();

		GameClient.send("status", "Selects their skin");
    }

    var acceptSound:FlxSound;
	var stopUpdates:Bool = false;
	var leftHoldTime:Float = 0;
	var rightHoldTime:Float = 0;
	var leavingState:Bool = false;
	var skipStaticDestroy:Bool = false;

    override function update(elapsed) {
        super.update(elapsed);

		arrowLeft.x = FlxMath.lerp(arrowLeft.x, alX, elapsed * 10);
		arrowRight.x = FlxMath.lerp(arrowRight.x, arX, elapsed * 10);

		if (controls.UI_LEFT)
			leftHoldTime += elapsed;
		else
			leftHoldTime = 0;

		if (controls.UI_RIGHT)
			rightHoldTime += elapsed;
		else
			rightHoldTime = 0;

		camFollow.setPosition(FlxG.width / 2, FlxG.height / 2);

		if (stopUpdates) {
			camFollow.y += !ClientPrefs.data.lowQuality ? 600 : 200;
			return;
		}

		if (music != null && music.playing) {
			Conductor.songPosition = music.time;
		}

        if (touchPad.buttonX.pressed || FlxG.keys.pressed.SHIFT) {
			if (character.members[0] != null) {
				if (controls.NOTE_UP) {
					character.members[0].playAnim("singUP");
				}
				if (controls.NOTE_DOWN) {
					character.members[0].playAnim("singDOWN");
				}
				if (controls.NOTE_LEFT) {
					character.members[0].playAnim("singLEFT");
				}
				if (controls.NOTE_RIGHT) {
					character.members[0].playAnim("singRIGHT");
				}
				if (controls.TAUNT) {
					character.members[0].playAnim("taunt");
				}
			}
        }
        else {
			if (controls.UI_LEFT_P) {
				setCharacter(-1);
			}
			else if (controls.UI_RIGHT_P) {
				setCharacter(1);
			}
        }

		if (touchPad.buttonV.justPressed || FlxG.keys.justPressed.CONTROL) {
			if (selectTimer != null)
				selectTimer.active = false;

			touchPad.visible = false;

			var daCopy = charactersName.copy();
			daCopy[0] = "Default";
			openSubState(new online.substates.SoFunkinSubstate(daCopy, curCharacter, i -> {
				if (selectTimer != null)
					selectTimer.active = true;
				setCharacter(i - curCharacter);
				return true;
			}, (i, leText) -> {
				Mods.currentModDirectory = charactersMod.get(charactersName[i]);
				var charaData:CharacterFile = Character.getCharacterFile(charactersName[i]);
				var iconName = charaData?.healthicon;
				if (iconName != null) {
					var icon = new HealthIcon(iconName, false);
					icon.sprTracker = leText;
					icon.scrollFactor.set(1, 1);
					Mods.loadTopMod();
					return icon;
				}
				return null;
			}));
		}

		if (!FlxG.keys.pressed.SHIFT && controls.ACCEPT) {
			var charName = charactersName[curCharacter];
			if (charName.endsWith("-player"))
				charName = charName.substring(0, charName.length - "-player".length);
			
			if (charName.endsWith("-pixel"))
				charName = charName.substring(0, charName.length - "-pixel".length);

			if (charName == "default")
				ClientPrefs.data.modSkin = null;
            else
				ClientPrefs.data.modSkin = [charactersMod.get(charactersName[curCharacter]), charName];
            ClientPrefs.saveSettings();
            
			if (isEquiped(charactersMod.get(charactersName[curCharacter]), charName)) {
				charSelect.text = 'Selected!';
				charSelect.alpha = 1;
			}
			else {
				charSelect.text = 'Press $accept to select!';
				charSelect.alpha = 0.8;
			}
			if (acceptSound != null)
				acceptSound.stop();

			acceptSound = FlxG.sound.play(Paths.sound('CS_confirm'), 0.8);

			if (character.members[0] != null)
				character.members[0].playAnim("hey", true);
        }

		if (controls.BACK || (!FlxG.keys.pressed.SHIFT && controls.ACCEPT)) {
			switchState(() -> Type.createInstance(backClass, []));
		}

		if (touchPad.buttonD.justPressed || FlxG.keys.justPressed.EIGHT) {
			Mods.currentModDirectory = charactersMod.get(charactersName[curCharacter]);
			switchState(() -> new CharacterEditorState(charactersName[curCharacter], false, true));
		}

		if (touchPad.buttonC.justPressed || FlxG.keys.justPressed.TAB) {
			flipped = !flipped;
			skipStaticDestroy = true;
			LoadingState.loadAndSwitchState(new SkinsState());
		}

		if (touchPad.buttonY.justPressed || FlxG.keys.justPressed.F1) {
			RequestSubstate.requestURL("https://github.com/Snirozu/Funkin-Psych-Online/wiki#skins", true);
		}

		if (touchPad.buttonZ.justPressed || FlxG.keys.justPressed.F2) {
			switchState(() -> new DownloaderState('collection:110039'));
		}

		if (character.members[0] != null) {
			switch (character.members[0].animation.curAnim.name) {
				case 'singRIGHT':
					camFollow.x += 20;
				case 'singLEFT':
					camFollow.x -= 20;
				case 'singUP':
					camFollow.y -= 20;
				case 'singDOWN':
					camFollow.y += 20;
			}
		}
    }

	function switchState(switchFunction:flixel.util.typeLimit.NextState) {
		stopUpdates = true;
		camera.follow(camFollow, LOCKON, 0.01);
		characterCamera.follow(camFollow, LOCKON, 0.01);

		FlxG.sound.play(Paths.sound('cancelMenu'));
		if (GameClient.isConnected()) {
			if (ClientPrefs.data.modSkin != null && ClientPrefs.data.modSkin.length >= 2) {
				GameClient.send("setSkin", [
					ClientPrefs.data.modSkin[0],
					ClientPrefs.data.modSkin[1],
					OnlineMods.getModURL(ClientPrefs.data.modSkin[0])
				]);
			}
			else {
				GameClient.send("setSkin", null);
			}
		}

		FlxTween.tween(blackRectangle, {alpha: 1}, 0.5, {ease: FlxEase.quadInOut});
		blackRectangle.alpha = 0;
		add(blackRectangle);

		//var funkySound = music.playing ? music : musicIntro;
		music.fadeOut(0.5, 0, t -> {
			//musicIntro.stop();
			music.stop();

			for (v in [FlxG.sound.music, FreeplayState.vocals, FreeplayState.opponentVocals]) {
				if (v == null)
					continue;

				v.play();
				v.fadeIn(0.5, 0, 1);
			}

			Conductor.bpm = prevConBPM;
			Conductor.bpmChangeMap = prevConBPMChanges;
			Conductor.songPosition = prevConTime;

			FlxG.switchState(switchFunction);
		});
	}

	override function openSubState(SubState:FlxSubState) {
		SubState.cameras = [hud];
		persistentUpdate = false;

		super.openSubState(SubState);
	}

	override function closeSubState() {
		persistentUpdate = true;
		super.closeSubState();
		if (touchPad != null)
			removeTouchPad();
		addTouchPad('LEFT_FULL', 'A_B_C_D_V_X_Y_Z');
		addTouchPadCamera();
	}

	override function destroy() {
		super.destroy();

		if (skipStaticDestroy)
			return;

		// if (musicIntro != null)
		// 	musicIntro.stop();
		if (music != null)
			music.stop();
	}

    function setCharacter(difference:Int, ?beatHold:Bool = false) {
		var prevCharacter = curCharacter;

		curCharacter += difference;

		if (curCharacter >= charactersLength) {
			curCharacter = beatHold ? 0 : charactersLength - 1;
		}
		else if (curCharacter < 0) {
			curCharacter = beatHold ? charactersLength - 1 : 0;
		}

		if (difference != 0 && curCharacter == prevCharacter) {
			return;
		}

		if (persistentUpdate) {
			if (difference > 0) {
				arrowRight.x += 40;
			}
			if (difference < 0) {
				arrowLeft.x -= 40;
			}
			if (difference != 0) {
				FlxG.sound.play(Paths.sound('CS_select'), 0.6);
			}
		}

		arrowLeft.visible = curCharacter > 0;
		arrowRight.visible = curCharacter < charactersLength - 1;

		if (character.members[0] != null) {
			character.members[0].destroy();
		}
		character.clear();

		staticSound.play(true);
		staticMan.visible = true;

		if (charactersName[curCharacter] != null) {
			var curCharName = charactersName[curCharacter];

			if (selectTimer != null)
				selectTimer.cancel();

			selectTimer = new FlxTimer().start(1, t -> {
				var curCharName = charactersName[curCharacter]; // re-define it lol

				if (character.members[0] != null) {
					character.members[0].destroy();
				}
				character.clear();

				staticSound.stop();
				staticMan.visible = false;

				// character.add(characterList.get(curCharName));

				Mods.currentModDirectory = charactersMod.get(curCharName);

				var daCharacter = new Character(0, 0, curCharName, flipped);
				daCharacter.scrollFactor.set(1.2, 1.2);
				daCharacter.graphic.bitmap.disposeImage();
				character.add(daCharacter);

				character.members[0].x = 420 + character.members[0].positionArray[0];
				character.members[0].y = -100 + character.members[0].positionArray[1];

				var hca = character.members[0].healthColorArray;
				tweenColor(FlxColor.fromRGB(hca[0], hca[1], hca[2]));
			});

			curCharName = !flipped ? curCharName : curCharName.substring(0, curCharName.length - "-player".length);

			title.text = curCharName == "default" ? "BOYFRIEND" : curCharName.replace('-', ' ');
			title.x = FlxG.width / 2 - title.width / 2;

			if (isEquiped(charactersMod.get(curCharName), curCharName)) {
				charSelect.text = 'Selected!';
				charSelect.alpha = 1;
			}
            else {
				charSelect.text = 'Press $accept to select!';
				charSelect.alpha = 0.8;
            }

			tweenColor(FlxColor.fromRGB(150, 150, 150));
        }
    }

	var colorTween:FlxTween;
	function tweenColor(color:FlxColor) {
		if (colorTween != null) {
			colorTween.cancel();
		}
		colorTween = FlxTween.color(bg, 1, bg.color, color, {
			onComplete: function(twn:FlxTween) {
				colorTween = null;
			}
		});
	}

    function isEquiped(mod:String, skin:String) {
		if (skin.endsWith("-player"))
			skin = skin.substring(0, skin.length - "-player".length);

		if (skin.endsWith("-pixel"))
			skin = skin.substring(0, skin.length - "-pixel".length);

		if (skin == "default" && ClientPrefs.data.modSkin == null) {
            return true;
        }

		return ClientPrefs.data.modSkin != null && ClientPrefs.data.modSkin.length >= 2
			&& mod == ClientPrefs.data.modSkin[0] && skin == ClientPrefs.data.modSkin[1];
    }

	override function beatHit() {
		super.beatHit();

		if (character.members[0] != null && character.members[0].animation.curAnim.finished)
			character.members[0].dance();

		if (staticMan.visible)
			staticMan.animation.play('idle');

		if (stageSpeakers != null)
			stageSpeakers.anim.play('beat');
	}

	override function stepHit() {
		super.stepHit();

		// thats how you do it ninjamuffin duh
		if (!FlxG.keys.pressed.SHIFT)
			if (leftHoldTime > 0.5) {
				setCharacter(-1, true);
			}
			else if (rightHoldTime > 0.5) {
				setCharacter(1, true);
			}
	}
}
