package boxup.loader;

using sys.io.File;
using sys.FileSystem;
using haxe.io.Path;

class FileSystemLoader implements Loader {
	final root:String;

	public function new(root) {
		this.root = root;
	}

	public function loadSync(id:String):Result<Source, CompileError> {
		return getFileSync(id);
	}

	public function load(id:String):Task<Source, CompileError> {
		return getFileSync(id);
	}

	function getFileSync(id:String):Result<Source, CompileError> {
		var path = Path.join([root].concat(id.split('.'))).withExtension('box');
		var content = path.getContent();
		var source:Source = {file: path, content: content};
		return Ok(source);
	}
}
