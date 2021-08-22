package boxup.schema;

import boxup.Builtin;
import boxup.Keyword;

class SchemaTools {
  public static function findSchema(nodes:Array<Node>):Result<SchemaId> {
    for (node in nodes) switch node.type {
      case Block(BRoot, _): return findSchema(node.children);
      case Block(KUse, _): return Ok(node.id);
      default:
    }
    return Fail(new Error('No schema found', nodes[0].pos));
  }
}
