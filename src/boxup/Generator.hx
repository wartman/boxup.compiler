package boxup;

interface Generator<T> {
	public function generate(source:Source, nodes:Array<Node>):Future<Result<T, CompileError>>;
}
