package boxup.schema;

using boxup.schema.SchemaTools;

/**
	A Validator that can automatically find a schema id by searching for
	a `[use ...]` block, attempt to load it, and then attempt to validate
	the file.
**/
class SchemaAwareValidator implements Validator {
	final compiler:SchemaCompiler;

	public function new(compiler) {
		this.compiler = compiler;
	}

	public function validate(nodes:Array<Node>):Result<Array<Node>, CompileError> {
		return nodes.findSchema().flatMap(compiler.load).flatMap(schema -> schema.validate(nodes));
	}
}
