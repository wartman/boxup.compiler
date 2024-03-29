package boxup.generator;

class NullGenerator implements Generator<Dynamic> {
	public function new() {}

	public function generate(source:Source, nodes:Array<Node>):Future<Result<Dynamic, CompileError>> {
		return Future.immediate(Ok(nodes));
	}
}
