package boxup.loader;

interface Loader {
	public function existsSync(id:String):Bool;
	public function exists(id:String):Future<Bool>;
	public function loadSync(id:String):Result<Source, CompileError>;
	public function load(id:String):Task<Source, CompileError>;
}
