package states.stages.objects;

#if funkin.vis
import funkin.vis.dsp.SpectralAnalyzer;
#end

// note to everyone that's reading this, DON'T try to implement abot in this way because it will take a long time
class ABotSpeaker extends FlxSpriteGroup {
	final VIZ_MAX = 7; // ranges from viz1 to viz7

	public var bg:FlxSprite;
	public var vizSprites:Array<FlxSprite> = [];
	public var eyeBg:FlxSprite;
	public var eyes:FlxAnimate;
	public var darkSpeaker:FlxAnimate;
	public var speaker:FlxAnimate;

	#if funkin.vis
	var analyzer:SpectralAnalyzer;
	#end
	var volumes:Array<Float> = [];

	public var snd(default, set):FlxSound;

	function set_snd(changed:FlxSound) {
		snd = changed;
		#if funkin.vis
		initAnalyzer();
		#end
		return snd;
	}

	public var isPixel:Bool = false;

	public function new(x:Float = 0, y:Float = 0, ?addDarkSprite:Bool = false, ?isPixel:Bool = false) {
		this.isPixel = isPixel;
		super(x, y);

		var antialias = ClientPrefs.data.antialiasing && !isPixel;
		var speakerPos:Array<Float> = [];

		bg = new FlxSprite(90, 20).loadGraphic(Paths.image(
			!isPixel
			? 'abot/stereoBG'
			: 'abotPixel/aBotPixelBack'
		));
		if (isPixel)
			bg.setPosition(-71, -195);
		bg.antialiasing = antialias;
		if (isPixel) {
			bg.scale.set(6, 6);
			bg.updateHitbox();
		}
		add(bg);

		var VIZ_POS_X:Array<Float> = isPixel ? [0, 7 * 6, 8 * 6, 9 * 6, 10 * 6, 6 * 6, 7 * 6] : [0, 59, 56, 66, 54, 52, 51];
		var VIZ_POS_Y:Array<Float> = isPixel ? [0, -2 * 6, -1 * 6, 0, 0, 1 * 6, 2 * 6] : [0, -8, -3.5, -0.4, 0.5, 4.7, 7];

		var vizX:Float = 0;
		var vizY:Float = 0;
		var vizFrames = Paths.getSparrowAtlas(
			!isPixel 
			? 'abot/aBotViz'
			: 'abotPixel/aBotVizPixel'
		);
		for (i in 1...VIZ_MAX + 1) {
			volumes.push(0.0);
			vizX += VIZ_POS_X[i - 1];
			vizY += VIZ_POS_Y[i - 1];
			var viz:FlxSprite = new FlxSprite(vizX + 140, vizY + 74);
			if (isPixel)
				viz.setPosition(vizX - 11, vizY - 136);
			viz.frames = vizFrames;
			viz.animation.addByPrefix('VIZ', 'viz$i', 0);
			viz.animation.play('VIZ', true);
			viz.animation.curAnim.finish(); // make it go to the lowest point
			viz.antialiasing = antialias;
			vizSprites.push(viz);
			if (isPixel)
				viz.scale.set(6, 6);
			viz.updateHitbox();
			viz.centerOffsets();
			add(viz);
		}

		if (!isPixel) {
			eyeBg = new FlxSprite(-30, 215).makeGraphic(1, 1, FlxColor.WHITE);
			eyeBg.scale.set(160, 60);
			eyeBg.updateHitbox();
			eyeBg.antialiasing = antialias;
			add(eyeBg);

			eyes = new FlxAnimate(-10, 230);
			Paths.loadAnimateAtlas(eyes, 'abot/systemEyes');
			var timelineFramesByTwo:Int = Std.int(eyes.anim.getDefaultTimeline().frameCount / 2);
			eyes.anim.addByTimelineIndices('lookleft', eyes.anim.getDefaultTimeline(), [for (i in 0...timelineFramesByTwo) i], 24, false);
			eyes.anim.addByTimelineIndices('lookright', eyes.anim.getDefaultTimeline(), [for (i in 0...timelineFramesByTwo) timelineFramesByTwo + i], 24, false);
			eyes.anim.play('lookright', true);
			eyes.animation.finish();
			eyes.applyStageMatrix = false;
			eyes.antialiasing = antialias;
			add(eyes);
		}
		else {
			eyes = new FlxAnimate(-227, -131);
			eyes.frames = Paths.getSparrowAtlas('abotPixel/abotHead');
			eyes.animation.addByPrefix('lookleft', 'toleft', 24, false);
			eyes.animation.addByPrefix('lookright', 'toright', 24, false);
			eyes.animation.play('lookleft', true);
			eyes.antialiasing = antialias;
			eyes.scale.set(6, 6);
			eyes.updateHitbox();
			add(eyes);
		}

		if (addDarkSprite) {
			darkSpeaker = new FlxAnimate(-65, -10);
			Paths.loadAnimateAtlas(darkSpeaker, 'abot/dark/abotSystem');
			darkSpeaker.anim.addBySymbol('anim', 'Abot System', 24, false);
			darkSpeaker.anim.play('anim', true);
			darkSpeaker.animation.finish();
			darkSpeaker.antialiasing = antialias;
			add(darkSpeaker);
		}

		if (!isPixel) {
			speaker = new FlxAnimate(-65, -10);
			Paths.loadAnimateAtlas(speaker, 'abot/abotSystem');
			speaker.anim.addBySymbol('anim', 'Abot System', 24, false);
			speaker.anim.play('anim', true);
			speaker.animation.finish();
			speaker.antialiasing = antialias;
			add(speaker);
		}
		else {
			speaker = new FlxAnimate(-228, -226);
			speaker.frames = Paths.getSparrowAtlas('abotPixel/aBotPixel');
			speaker.animation.addByPrefix('idle', 'idle', 24, false);
			speaker.animation.play('idle', true);
			speaker.antialiasing = antialias;
			speaker.scale.set(6, 6);
			speaker.updateHitbox();
			add(speaker);
		}
	}

	#if funkin.vis
	var levels:Array<Bar>;
	var levelMax:Int = 0;
	var prevBeat:Float = 0;

	override function update(elapsed:Float):Void {
		super.update(elapsed);

		var curBeat = Math.floor(Conductor.getBeat(Conductor.songPosition));
		if (prevBeat != curBeat && curBeat % Math.round(PlayState.instance.gfSpeed * PlayState.instance.gf.danceEveryNumBeats) == 0) {
			actualBeatHit();
			prevBeat = curBeat;
		}

		if (analyzer == null)
			return;

		levels = analyzer.getLevels(levels);
		var oldLevelMax = levelMax;
		levelMax = 0;
		for (i in 0...Std.int(Math.min(vizSprites.length, levels.length))) {
			var animFrame:Int = Math.round(levels[i].value * 5);
			animFrame = Std.int(Math.abs(FlxMath.bound(animFrame, 0, 5) - 5)); // shitty dumbass flip, cuz dave got da shit backwards lol!

			vizSprites[i].animation.curAnim.curFrame = animFrame;
			levelMax = Std.int(Math.max(levelMax, 5 - animFrame));
		}

		if (levelMax >= 4) {
			// trace(levelMax);
			if (oldLevelMax <= levelMax && (levelMax >= 5 || getCurSpeakerFrame() >= 3))
				bumpSpeaker();
		}
	}
	#end

	public function actualBeatHit() {
		if (!isPixel) return;
		speaker.animation.play('idle', true);
	}

	public function bumpSpeaker() {
		if(isPixel) return;

		if (speaker != null)
			speaker.anim.play('anim', true);
		if (darkSpeaker != null) {
			darkSpeaker.anim.play('anim', true);
		}
	}

	#if funkin.vis
	public function initAnalyzer() {
		@:privateAccess
		analyzer = new SpectralAnalyzer(snd._channel.__audioSource, VIZ_MAX, 0.1, 40);
    	// A-Bot tuning...
		analyzer.minDb = -65;
		analyzer.maxDb = -25;
		analyzer.maxFreq = 22000;
		// we use a very low minFreq since some songs use low low subbass like a boss
		analyzer.minFreq = 10;

		#if sys
		// On native it uses FFT stuff that isn't as optimized as the direct browser stuff we use on HTML5
		// So we want to manually change it!
		analyzer.fftN = 256;
		#end

		// analyzer.maxDb = -35;
		// analyzer.fftN = 2048;
	}
	#end

	var lookingAtRight:Bool = true;

	public function lookLeft() {
		if (lookingAtRight) {
			eyes.animation.play('lookleft', true);
		}
		lookingAtRight = false;
	}

	public function lookRight() {
		if (!lookingAtRight) {
			eyes.animation.play('lookright', true);
		}
		lookingAtRight = true;
	}

	public function finishEyes() {
		eyes.animation.finish();
	}

	function getCurSpeakerFrame() {
		return speaker.animation.curAnim.curFrame;
	}
}