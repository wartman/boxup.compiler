package boxup.loader;

using Lambda;

class StaticLoader implements Loader {
	final sources:Array<Source>;

	public function new(sources) {
		this.sources = sources;
	}

	public function loadSync(id:String):Result<Source, CompileError> {
		return switch sources.find(source -> source.file == id) {
			case null: Error(new CompileError(Fatal, 'No source exists with the id $id'));
			case source: Ok(source);
		}
	}

	public function load(id:String):Task<Source, CompileError> {
		return loadSync(id);
	}
}
