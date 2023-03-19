package boxup.schema;

using boxup.schema.SchemaTools;

class SchemaAwareValidator implements Validator {
	final schemaCollection:SchemaCollection;

	public function new(schemaCollection) {
		this.schemaCollection = schemaCollection;
	}

	public function validate(nodes:Array<Node>):Result<Array<Node>, CompileError> {
		return nodes.findSchema().flatMap(id -> switch schemaCollection.get(id) {
			case null: Error(new CompileError(Fatal, 'No schema found', nodes[0].pos));
			case schema: Ok(schema);
		}).flatMap(schema -> schema.validate(nodes));
	}
}
