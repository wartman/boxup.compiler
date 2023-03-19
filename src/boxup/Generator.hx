package boxup;

interface Generator<T> {
	public function generate(nodes:Array<Node>):Future<Result<T, CompileError>>;
}
