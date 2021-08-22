package boxup.schema;

import boxup.Builtin;
import boxup.Keyword;
import boxup.schema.SchemaId;

class SchemaAwareValidator implements Validator {
  final schemaCollection:SchemaCollection;

  public function new(schemaCollection) {
    this.schemaCollection = schemaCollection;
  }

  public function validate(nodes:Array<Node>):Result<Array<Node>> {
    var id = findSchema(nodes);

    if (id == null) return Ok(nodes);
    
    var schema = schemaCollection.get(id);
    
    if (schema == null) return Ok(nodes); // Throw error?

    return schema.validate(nodes);
  }

  function findSchema(nodes:Array<Node>):SchemaId {
    for (node in nodes) switch node.type {
      case Block(BRoot, _): return findSchema(node.children);
      case Block(KUse, _): return node.id;
      default:
    }
    return null;
  }
}
