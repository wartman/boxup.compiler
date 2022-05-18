package boxup.schema;

using boxup.schema.SchemaTools;

class SchemaAwareValidator implements Validator {
  final schemaCollection:SchemaCollection;

  public function new(schemaCollection) {
    this.schemaCollection = schemaCollection;
  }

  public function validate(nodes:Array<Node>):Result<Array<Node>> {
    return nodes
      .findSchema()
      .map(id -> switch schemaCollection.get(id) {
        case null: Fail(new Error(Fatal, 'No schema found', nodes[0].pos));
        case schema: Ok(schema);
      })
      .map(schema -> schema.validate(nodes));
  }
}
