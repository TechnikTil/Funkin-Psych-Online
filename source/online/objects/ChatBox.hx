package online.objects;

import online.util.ShitUtil;
import online.substates.RequestSubstate;
import flixel.math.FlxRect;
import openfl.events.KeyboardEvent;
import lime.system.Clipboard;

class ChatBox extends FlxTypedSpriteGroup<FlxSprite> {
	public static var instance:ChatBox;
	final accept:String = Controls.instance.mobileC ? "RETURN" : "ACCEPT";
	final tab:String = Controls.instance.mobileC ? "C" : "TAB";
	var prevMouseVisibility:Bool = false;
    public var focused(default, set):Bool = false;
	function set_focused(v) {
		if (v) {
			prevMouseVisibility = FlxG.mouse.visible;
			FlxG.mouse.visible = true;
			typeTextHint.text = "(Type something to input the message, " + accept + " to send)";
			typeBg.colorTransform.alphaOffset = 0;
			typeBg.scale.x = FlxG.width;
			ClientPrefs.toggleVolumeKeys(false);
		}
		else {
			FlxG.mouse.visible = prevMouseVisibility;
			typeTextHint.text = '(Press $tab to open chat!)';
			typeBg.colorTransform.alphaOffset = -100;
			typeBg.scale.x = Std.int(bg.width);
			ClientPrefs.toggleVolumeKeys(true);
		}
		typeBg.updateHitbox();
		targetAlpha = v ? 3 : 0;
		return focused = v;
	}
	var bg:FlxSprite;
	var chatGroup:FlxTypedSpriteGroup<ChatMessage> = new FlxTypedSpriteGroup<ChatMessage>();
	var typeBg:FlxSprite;
    public var typeText:InputText;
    var typeTextHint:FlxText; // i can call it a hint or tip whatever i want
	var targetAlpha:Float;
	var chatHeight:Float;
	var onCommand:(String, Array<String>) -> Bool;

	static var lastMessages:Array<Dynamic> = [];

	var initMessage:String = "See /help for the list of commands!";

	public static function addMessage(raw:Dynamic) {
		if (instance == null) {
			lastMessages.push(raw);
			return;
		}

		instance.targetAlpha = 5;

		var chat = new ChatMessage(instance.bg.width, ShitUtil.parseLog(raw));
		instance.chatGroup.insert(0, chat);

		if (instance.chatGroup.length >= 22) {
			instance.chatGroup.remove(instance.chatGroup.members[instance.chatGroup.length - 1], true);
		}
	}

	public static function clearLogs() {
		if (instance?.chatGroup != null)
			instance.chatGroup.clear();
		lastMessages = [];
	}

	public static function tryRegisterLogs() {
		if (GameClient.isConnected())
			GameClient.room.onMessage("log", function(message) {
				Waiter.put(() -> {
					addMessage(message);
					var sond = FlxG.sound.play(Paths.sound('scrollMenu'));
					sond.pitch = 1.5;
				});
			});
	}

	public function new(?camera:FlxCamera, ?onCommand:(command:String, args:Array<String>) -> Bool, ?chatHeight:Int = 400) {
		super();

		this.chatHeight = chatHeight;

		instance = this;

		scrollFactor.set(0, 0);
        
        bg = new FlxSprite();
		bg.makeGraphic(600, 1, FlxColor.BLACK);
		bg.scale.y = chatHeight;
		bg.updateHitbox();
		bg.alpha = 0.6;
        add(bg);

		typeTextHint = new FlxText(0, 0, bg.width, "(Type something to input the message, ACCEPT to send)");
		typeTextHint.setFormat("VCR OSD Mono", 16, FlxColor.WHITE);
		typeTextHint.alpha = 0.6;

		typeBg = new FlxSprite(0, bg.y + bg.height);
		typeBg.makeGraphic(1, Std.int(typeTextHint.height), FlxColor.BLACK);
		typeBg.scale.x = FlxG.width;
		typeBg.updateHitbox();
		add(typeBg);

		chatGroup = new FlxTypedSpriteGroup<ChatMessage>();
		addMessage(initMessage);
		for (msg in lastMessages) {
			addMessage(msg);
		}
		lastMessages = [];
		add(chatGroup);

		typeText = new InputText(0, 0, typeBg.width, text -> {
			if (StringTools.startsWith(text, "/")) {
				switch (text) {
					case "/help":
						ChatBox.addMessage("> Global Commands: /roll, /kick");

						if (onCommand != null)
							parseCommand(text);
					case "/roll":
						GameClient.send("command", ["roll"]);
					case "/kick":
						GameClient.send("command", ["kick"]);
					default:
						if (onCommand != null)
							parseCommand(text);
						else
							addMessage("Unknown command; try /help to see the command list!");
				}
			}
			else
				GameClient.send("chat", text);
			
			typeText.text = "";
			if (FlxG.state is PlayState)
				focused = false;
		});
		typeText.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);

		typeTextHint.y = typeBg.y;
		typeText.y = typeBg.y;

		add(typeTextHint);
		add(typeText);

		cameras = [camera];
		this.onCommand = onCommand;

		tryRegisterLogs();

		focused = false; // initial update

		y = FlxG.height - height;
    }

	override function destroy() {
		for (msg in chatGroup) {
			if (msg.text != initMessage)
				lastMessages.push(msg.text);
		}

		if(focused)
			ClientPrefs.toggleVolumeKeys(true);

		super.destroy();

		instance = null;
	}

    override function update(elapsed) {
		if (focused || alpha > 0) {
			if (FlxG.keys.justPressed.ESCAPE #if android || FlxG.android.justReleased.BACK #end) {
				focused = false;
			}

			var i = -1;
			while (++i < chatGroup.length) {
				var msg = chatGroup.members[i];

				if (i == 0) {
					msg.y = typeBg.y - msg.height;
				}
				else if (chatGroup.members[i - 1] != null) {
					msg.y = chatGroup.members[i - 1].y - msg.height;
				}

				msg.alpha = 0.8;
				if (msg != null && FlxG.mouse.visible && FlxG.mouse.overlaps(msg, camera)) {
					msg.alpha = 1;
					if (FlxG.mouse.justPressed && msg.link != null) {
						focused = false;
						RequestSubstate.requestURL(msg.link);
					}
				}
				if (!focused) {
					msg.alpha = i == 0 ? 1 : 0;
				}

				if (msg.alpha > targetAlpha) {
					msg.alpha = targetAlpha;
				}

				var newClipRect = msg.clipRect ?? new FlxRect();
				newClipRect.height = bg.height;
				newClipRect.width = bg.width;
				newClipRect.y = bg.y - msg.y;
				msg.clipRect = newClipRect;
			}

			if (!focused) {
				bg.y = typeBg.y - bg.height;
				bg.scale.y = chatGroup.members[0].height;
				bg.updateHitbox();
				typeBg.alpha = 0.7;
				if (typeBg.alpha > targetAlpha) {
					typeBg.alpha = targetAlpha;
				}
			}
			else {
				bg.y = y;
				bg.scale.y = chatHeight;
				bg.updateHitbox();
			}
		}

		if (bg.alpha > 0.6)
			bg.alpha = 0.6;
		if (typeTextHint.alpha > 0.6)
			typeTextHint.alpha = 0.6;

        super.update(elapsed);

		if ((MusicBeatState.getState().touchPad.buttonC != null && MusicBeatState.getState().touchPad.buttonC.justPressed) || FlxG.keys.justPressed.TAB) {
			focused = !focused;
			#if !android FlxG.stage.window.textInputEnabled = focused; #end
		}

		typeTextHint.visible = focused ? (typeText.text.length <= 0) : true;

		if (!focused && targetAlpha > 0.)
			targetAlpha -= elapsed;

		alpha = targetAlpha;

		typeText.hasFocus = focused;
    }

	function parseCommand(text:String) {
		var splitText:Array<String> = text.split(" ");
		var command = splitText.shift().substr(1);
		if (!onCommand(command, splitText)) {
			if (command != "help") {
				addMessage("Unknown command; try /help to see the command list!");
				return;
			}
		}
	}
}

class ChatMessage extends FlxText {
	public var link:String = null;

	public function new(fieldWidth:Float = 0, msg:LogData) {
		super(0, 0, fieldWidth, msg.content);
		setFormat("VCR OSD Mono", 16, msg.hue != null ? FlxColor.fromHSL(msg.hue, 1.0, 0.8) : FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);

		var _split = msg.content.split("");
		var i = -1;
		var str = "";
		var formatBeg = null;
		var formatEnd = null;
		while (++i < msg.content.length) {
			if (this.link == null && str.startsWith("https://")) {
				if (_split[i].trim() == "") {
					this.link = str;
					formatEnd = i;
				}
				else if (i == msg.content.length - 1) {
					this.link = str + _split[i].trim();
					formatEnd = i + 1;
				}
			}

			str += _split[i];

			if (this.link == null && str.endsWith("https://")) {
				str = "https://";
				formatBeg = i - 7;
			}
		}

		if (link != null)
			addFormat(new FlxTextFormat(FlxColor.CYAN), formatBeg, formatEnd);
	}
}
