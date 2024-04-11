package boxup.loader;

class NullLoader implements Loader {
	public function new() {}

	public function existsSync(id:String):Bool {
		return false;
	}

	public function exists(id:String):Future<Bool> {
		return Future.immediate(false);
	}

	public function loadSync(id:String):Result<Source, CompileError> {
		return Error(new CompileError('No loader found; cannot load $id'));
	}

	public function load(id:String):Task<Source, CompileError> {
		return Task.reject(new CompileError('No loader found; cannot load $id'));
	}
}
