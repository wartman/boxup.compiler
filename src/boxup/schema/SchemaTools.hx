package boxup.schema;

import boxup.Builtin;

function findSchema(nodes:Array<Node>):Result<SchemaId, CompileError> {
	for (node in nodes) switch node.type {
		case Block(BRoot, _): return findSchema(node.children);
		case Block(Keyword.KUse, _): return Ok(node.getParameter(0));
		default:
	}
	return Error(new CompileError('No schema found', nodes[0].pos));
}
