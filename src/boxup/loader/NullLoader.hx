package boxup.loader;

class NullLoader implements Loader {
	public function new() {}

	public function loadSync(id:String):Result<Source, CompileError> {
		return Error(new CompileError(Fatal, 'No loader found; cannot load $id'));
	}

	public function load(id:String):Task<Source, CompileError> {
		return Task.reject(new CompileError(Fatal, 'No loader found; cannot load $id'));
	}
}
