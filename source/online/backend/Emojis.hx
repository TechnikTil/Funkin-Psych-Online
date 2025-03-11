package online.backend;

import haxe.Json;
import openfl.utils.Assets;

#if sys
import sys.io.File;
import sys.FileSystem;
#end

class Emojis
{
	public static var emojis:Map<String, String>;

	public static function initialize():Void
	{
		var path:String = Paths.json('emojis');
		var content:Null<String> = null;

		if(Assets.exists(path, TEXT))
			content = Assets.getText(path);

		#if sys
		if(FileSystem.exists(path) && content == null)
			content = File.getContent(path);
		#end

		if(content == null) {
			emojis = new Map<String, String>();
			return;
		}

		var json:Dynamic = Json.parse(content);
		emojis = cast ShitUtil.objToMap(json);
	}

	public static function format(content:String):EmojiFormatData
	{
		var formattedContent:String = '';
		var emojiPositions:Array<{
			start:Int,
			end:Int
		}> = [];

		var i:Int = 0;
		while(i < content.length)
		{
			var str:String = content.charAt(i);
			if(str == ':')
			{
				var nextI:Int = content.indexOf(':', i + 1);

				if(nextI != -1)
				{
					var emojiName:String = content.substring(i + 1, nextI);

					var emoji:Null<String> = emojis.get(emojiName);
					if(emoji != null)
					{
						i = nextI + 1;

						formattedContent += emoji;

						emojiPositions.push({
							start: formattedContent.length - emoji.length,
							end: formattedContent.length
						});

						continue;
					}
				}
			}

			formattedContent += str;
			i++;
		}

		return {
			content: formattedContent,
			emojiPositions: emojiPositions
		};
	}

	public static function formatText(content:String):String
	{
		return format(content).content;
	}
}

typedef EmojiFormatData =
{
	var content:String;
	var emojiPositions:Array<{
		start:Int,
		end:Int
	}>;
}