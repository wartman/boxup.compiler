package boxup.loader;

class CompositeLoader implements Loader {
	final loaders:Array<Loader>;

	public function new(loaders) {
		this.loaders = loaders;
	}

	public function existsSync(id:String):Bool {
		for (loader in loaders) if (loader.existsSync(id)) return true;
		return false;
	}

	public function exists(id:String):Future<Bool> {
		// @todo: we want a `Future.race(...)` or something.
		return Future.immediate(existsSync(id));
	}

	public function loadSync(id:String):Result<Source, CompileError> {
		for (loader in loaders) if (loader.existsSync(id)) return loader.loadSync(id);
		return Error(new CompileError('Source not found: $id'));
	}

	public function load(id:String):Task<Source, CompileError> {
		// @todo: we want a `Future.race(...)` or something so we're not
		// using `existsSync` here.
		for (loader in loaders) if (loader.existsSync(id)) return loader.load(id);
		return Task.reject(new CompileError('Source not found: $id'));
	}
}
