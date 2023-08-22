package boxup.schema;

using boxup.schema.SchemaTools;

class SchemaLoadingValidator implements Validator {
	final compiler:SchemaCompiler;

	public function new(compiler) {
		this.compiler = compiler;
	}

	public function validate(nodes:Array<Node>):Result<Array<Node>, CompileError> {
		return nodes.findSchema().flatMap(compiler.load).flatMap(schema -> schema.validate(nodes));
	}
}
