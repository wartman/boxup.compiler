package boxup.schema;

import boxup.Builtin;

class SchemaTools {
  public static function findSchema(nodes:Array<Node>):Result<SchemaId> {
    for (node in nodes) switch node.type {
      case Block(BRoot, _): return findSchema(node.children);
      case Block(Keyword.KUse, _): return Ok(node.getParameter(0));
      default:
    }
    return Fail(new Error('No schema found', nodes[0].pos));
  }
}
