package online.mods;

import haxe.io.Error;
import haxe.CallStack;
import haxe.io.Path;
import online.substates.RequestSubstate;
import sys.io.File;
import sys.io.FileOutput;
import haxe.io.Bytes;
import sys.net.Host;
import sys.net.Socket;
import online.mods.GameBanana.GBMod;
import sys.FileSystem;
// import haxe.Int64; note to self use float instead of int64

using StringTools;

//TODO move to HTTPClient class (im lazy im lazy)
class Downloader {
	var socket:Socket;
	var file:FileOutput;
	var id:String;
	var fileName:String;
	var gbMod:GBMod;
	public var originURL:String;

	var downloadPath:String;
	static var downloadDir:String = #if mobile StorageUtil.getStorageDirectory(true) + "downloads/" #else openfl.filesystem.File.applicationDirectory.nativePath + "/downloads/" #end;

	var alert:DownloadAlert;

	static var downloading:Array<String> = [];
	public static var downloaders:Array<Downloader> = [];

	var onFinished:(String, Downloader)->Void;
	public var cancelRequested(default, null):Bool = false;
	public var isConnected:Bool = false;
	public var isDownloading:Bool = false;
	public var isInstalling:Bool = false;

	public var contentLength:Float = 0;
	public var gotContent:Float = 0;
	
	public function new(fileName:String, id:String, url:String, onFinished:(fileName:String, downloader:Downloader) -> Void, ?mod:GBMod, ?headers:Map<String, String>, ?ogURL:String) {
		this.fileName = FileUtils.formatFile(fileName);
		id = FileUtils.formatFile(id);
		if (downloading.contains(id)) {
			// Waiter.put(() -> {
			// 	Alert.alert('Downloading failed!', 'Download ' + id + " is already being downloaded!");
			// });
			return;
		}
		if (downloading.length >= 6) {
			Waiter.put(() -> {
				Alert.alert('Downloading failed!', 'Too many files are downloading right now! (Max 6)');
			});
			return;
		}
		this.onFinished = onFinished;
		this.originURL = ogURL ?? url;
		this.gbMod = mod;
		if (gbMod != null) {
			ChatBox.addMessage("Starting the download of " + gbMod.name + " from: " + originURL);
		}
		else if (ChatBox.instance != null) {
			ChatBox.addMessage("Starting the download of a mod from: " + originURL);
		}
		this.id = id;
		downloaders.push(this);
		downloading.push(id);
		alert = new DownloadAlert(this.originURL);
		checkCreateDlDir();
		downloadPath = Path.normalize(downloadDir + id + ".dwl");

		Thread.run(() -> {
			try {
				startDownload(url, headers);
			}
			catch (exc) {
				if (!cancelRequested) {
					trace(id + ': ' + exc + "\n\n" + CallStack.toString(exc.stack));
					Waiter.put(() -> {
						Alert.alert('Uncaught Download Error!', id + ': ' + ShitUtil.readableError(exc) + "\n\n" + CallStack.toString(exc.stack));
					});
				}
				doCancel();
			}
		});
	}

	static var allowedMediaTypes:Array<String> = [
		"application/zip",
		"application/zip-compressed",
		"application/x-zip-compressed",
		"application/x-zip",
		"application/x-tar",
		"application/gzip",
		"application/x-gtar",
		"application/octet-stream", // unknown files
		#if RAR_SUPPORTED
		"application/vnd.rar",
		"application/x-rar-compressed",
		"application/x-rar",
		#end
	];

	public static function isMediaTypeAllowed(file:String) {
		file = file.trim();
		for (item in allowedMediaTypes) {
			if (file == item)
				return true;
		}
		return false;
	}

	private function startDownload(url:String, ?requestHeaders:Map<String, String>) {
		isConnected = true;

		var urlFormat = URLScraper.getURLFormat(url);
		var headers:String = "";
		headers += '\nHost: ${urlFormat.domain}' + (urlFormat.port != 80 && urlFormat.port != 443 ? ':${urlFormat.port}' : '');
		headers += '\nUser-Agent: haxe';
		if (requestHeaders != null) {
			for (key => value in requestHeaders) {
				headers += '\n$key: $value';
			}
		}

		socket = !urlFormat.isSSL ? new Socket() : new sys.ssl.Socket();
		socket.setTimeout(5);
		socket.setBlocking(true);

		var tries = 0;
		while (!cancelRequested) {
			tries++;

			alert.newStatus = "Connecting to the server..";
			try {
				socket.connect(new Host(urlFormat.domain), urlFormat.port);

				if (ClientPrefs.isDebug())
					Sys.println("DHX: Connected to HTTP 1.1 socket!");

				socket.write('GET ${urlFormat.path} HTTP/1.1${headers}\n\n');

				var httpStatus:String = null;
				httpStatus = socket.input.readLine();
				httpStatus = httpStatus.substr(httpStatus.indexOf(" ")).ltrim();

				if (httpStatus == null || httpStatus.startsWith("4") || httpStatus.startsWith("5")) {
					alert.newStatus = 'Server Error: $httpStatus (Retry #$tries)...';
					continue;
				}

				if (ClientPrefs.isDebug())
					Sys.println("DHX: Got response headers!");
				break;
			}
			catch (exc) {
				alert.newStatus = 'Failed to connect! (Retry #${tries})\n${exc.message}';

				if (tries >= 10) {
					trace(id + ': ' + exc + "\n\n" + CallStack.toString(exc.stack));
					Waiter.put(() -> {
						Alert.alert('Couldn\'t connect to the server after multiple tries!',
							'${urlFormat.domain + urlFormat.path}'
							+ ': '
							+ ShitUtil.readableError(exc) + "\n\n" + CallStack.toString(exc.stack));
					});
					cancelRequested = true;
					break;
				}

				if (ClientPrefs.isDebug())
					Sys.println("DHX: Retrying...");
				Sys.sleep(5);
			}
		}

		if (cancelRequested) {
			doCancel();
			return;
		}

		alert.newStatus = "Reading server response headers...";
		var gotHeaders:Map<String, String> = new Map<String, String>();
		while (!cancelRequested) {
			var readLine:String = socket.input.readLine();
			if (readLine.trim() == "") {
				break;
			}
			var splitHeader = readLine.split(": ");
			gotHeaders.set(splitHeader[0].toLowerCase(), splitHeader[1]);
		}

		alert.newStatus = "Parsing server response headers...";

		if (ClientPrefs.isDebug())
			Sys.println("DHX: Parsed response headers!");

		if (cancelRequested) {
			doCancel();
			return;
		}

		if (gotHeaders.exists("location")) {
			Sys.println('Redirecting from $url to ${gotHeaders.get("location")}');
			startDownload(gotHeaders.get("location"), requestHeaders);
			return;
		}

		if (gotHeaders.exists("content-length")) {
			contentLength = Std.parseFloat(gotHeaders.get("content-length"));
			if (ClientPrefs.isDebug())
				Sys.println("DHX: Response size: " + contentLength);
		}

		if (!isMediaTypeAllowed(gotHeaders.get("content-type"))) {
			if (!cancelRequested) {
				Waiter.put(() -> {
					Alert.alert('Downloading failed!', gotHeaders.get("content-type") + " may be invalid or unsupported file type!");
					RequestSubstate.requestURL(originURL, "The following mod needs to be installed from this source", true);
				});
			}
			doCancel();
			return;
		}

		if (ClientPrefs.isDebug())
			Sys.println("DHX: Transfer-Encoding type: " + gotHeaders.get("transfer-encoding"));

		try {
			file = File.append(downloadPath, true);
		}
		catch (exc) {
			file = null;
			if (!cancelRequested) {
				Waiter.put(() -> {
					Alert.alert('Downloading failed!', exc.toString());
				});
			}
			doCancel();
			return;
		}

		if (ClientPrefs.isDebug())
			Sys.println("DHX: Starting the download!");
		
		var buffer:Bytes = Bytes.alloc(1024);
		var _bytesWritten:Int = 1;
		var _lastLine = '';

		isDownloading = true;
		if (contentLength > 0) {
			while (gotContent < contentLength && !cancelRequested) {
				try {
					_bytesWritten = socket.input.readBytes(buffer, 0, buffer.length);
					file.writeBytes(buffer, 0, _bytesWritten);
					gotContent += _bytesWritten;
				}
				catch (e:Dynamic) {
					if (Std.string(e).toLowerCase() == "eof" || e == Error.Blocked) {
						// Eof and Blocked will be ignored
						continue;
					}
					throw e;
				}
			}
		}
		else {
			//while (_bytesWritten > 0) {
			while (_lastLine != '0') {
				try {
					_bytesWritten = Std.parseInt('0x' + (_lastLine = socket.input.readLine()));
					file.writeBytes(socket.input.read(_bytesWritten), 0, _bytesWritten);
					gotContent += _bytesWritten;
				}
				catch (e:Dynamic) {
					if (Std.string(e).toLowerCase() == "eof" || e == Error.Blocked) {
						// Eof and Blocked will be ignored
						continue;
					}
					throw e;
				}
			}
		}
		isDownloading = false;
		isConnected = false;

		doCancel(!cancelRequested);
	}

	public static function checkCreateDlDir() {
		if (!FileSystem.exists(downloadDir)) {
			FileSystem.createDirectory(downloadDir);
		}
	}

	public static function checkDeleteDlDir() {
		if (FileSystem.exists(downloadDir)) {
			FileUtils.removeFiles(downloadDir);
		}
	}

	public function tryRenameFile():String {
		if (FileSystem.exists(downloadPath)) {
			if (FileSystem.exists(downloadDir + fileName))
				FileSystem.deleteFile(downloadDir + fileName);
			FileSystem.rename(downloadPath, downloadDir + fileName);
		}
		return downloadDir + fileName;
	}

	function deleteTempFile() {
		if (FileSystem.exists(downloadPath)) {
			FileSystem.deleteFile(downloadPath);
		}
	}

	public function cancel() {
		if (isConnected) {
			cancelRequested = true;
			return;
		}

		doCancel();
	}

	function doCancel(?callOnFinished:Bool = false) {
		Sys.println('Download $id stopped!');
		try {
			if (socket != null)
				socket.close();
			socket = null;
			if (file != null)
				file.close();
		}
		catch (exc) {}
		if (callOnFinished) {
			isInstalling = true;
			onFinished(downloadPath, this);
		}
		downloading.remove(id);
		downloaders.remove(this);
		if (alert != null)
			alert.destroy();
		alert = null;
		try {
			if (!FlxG.keys.pressed.F2)
				deleteTempFile();
		}
		catch (exc) {
		}
	}

	public static function cancelAll() {
		Sys.println("Cancelling " + downloaders.length + " downloads...");
		for (downloader in downloaders) {
			if (downloader != null)
				downloader.cancel();
		}
	}

	static function isNumber(char:Int) {
		return char >= 48 && char <= 57; // 0-9
	}

	static function isLetter(char:Int) {
		return (char >= 65 && char <= 90) || /* A-Z */ (char >= 97 && char <= 122); // a-z
	}
}