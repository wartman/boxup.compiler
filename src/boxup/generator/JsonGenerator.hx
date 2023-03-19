package boxup.generator;

class JsonGenerator implements Generator<Array<Dynamic>> {
	public function new() {}

	public function generate(nodes:Array<Node>):Future<Result<Array<Dynamic>, CompileError>> {
		return Future.immediate(Ok(nodes.map(node -> node.toJson())));
	}
}
