package boxup.loader;

using Lambda;

class StaticLoader implements Loader {
	final sources:Array<Source>;

	public function new(sources) {
		this.sources = sources;
	}

	public function existsSync(id:String):Bool {
		return sources.exists(source -> source.file == id);
	}

	public function exists(id:String):Future<Bool> {
		return Future.immediate(existsSync(id));
	}

	public function loadSync(id:String):Result<Source, CompileError> {
		return switch sources.find(source -> source.file == id) {
			case null: Error(new CompileError('No source exists with the id $id'));
			case source: Ok(source);
		}
	}

	public function load(id:String):Task<Source, CompileError> {
		return loadSync(id);
	}
}
