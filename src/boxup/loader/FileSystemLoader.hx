package boxup.loader;

using sys.io.File;
using sys.FileSystem;
using haxe.io.Path;

class FileSystemLoader implements Loader {
	final root:String;

	public function new(root) {
		this.root = root;
	}

	public function existsSync(id:String):Bool {
		return fileExistsSync(id);
	}

	public function exists(id:String):Future<Bool> {
		return Future.immediate(fileExistsSync(id));
	}

	public function loadSync(id:String):Result<Source, CompileError> {
		return getFileSync(id);
	}

	public function load(id:String):Task<Source, CompileError> {
		return getFileSync(id);
	}

	function getPath(id:String) {
		return Path.join([root].concat(id.split('.'))).withExtension('box');
	}

	function fileExistsSync(id:String):Bool {
		var path = getPath(id);
		return path.exists();
	}

	function getFileSync(id:String):Result<Source, CompileError> {
		var path = getPath(id);
		var content = try path.getContent() catch (e) {
			return Error(new CompileError('Source not found: $id', e.message));
		}
		var source:Source = {file: path, content: content};
		return Ok(source);
	}
}
