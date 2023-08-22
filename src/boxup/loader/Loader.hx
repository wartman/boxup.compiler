package boxup.loader;

interface Loader {
	public function loadSync(id:String):Result<Source, CompileError>;
	public function load(id:String):Task<Source, CompileError>;
}
