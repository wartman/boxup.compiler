package boxup.schema;

import boxup.Node.NodeParam;
import haxe.ds.Map;
import boxup.Builtin;

using Lambda;

class Schema implements Validator {
	public static macro function create(expr) {
		return boxup.macro.SchemaBuilder.create(expr);
	}

	public final id:SchemaId;

	final blocks:Array<BlockDefinition>;
	final meta:Map<String, String>;

	public function new(id, blocks, meta) {
		this.id = id;
		this.blocks = blocks;
		this.meta = meta;
	}

	public function getBlocks() {
		return blocks;
	}

	public function getBlock(name:String) {
		return blocks.find(b -> b.name == name);
	}

	public function getAllMeta() {
		return meta;
	}

	public function getMeta(name:String, ?def:String) {
		return meta.exists(name) ? meta.get(name) : def;
	}

	public function merge(other:Schema) {
		var root = getBlock(BRoot);
		var otherRoot = other.getBlock(BRoot);

		for (child in otherRoot.children) {
			if (!root.children.exists(c -> c.name == child.name)) {
				root.children.push(child);
			}
		}

		for (block in other.blocks) switch block.name {
			case BRoot: // noop
			case name if (getBlock(name) == null):
				blocks.push(block);
			default:
		}
	}

	public function validate(nodes:Array<Node>):Result<Array<Node>, CompileError> {
		var file = nodes.length > 0 ? nodes[0].pos.file : '<unknown>';

		return getBlock(BRoot).validate({
			type: Block(BRoot, false),
			children: nodes,
			pos: {min: 0, max: 0, file: file}
		}, this).map(_ -> nodes);
	}
}

enum abstract BlockDefinitionType(String) from String to String {
	var BNormal = 'Normal';
	var BTag = 'Tag';
	var BParagraph = 'Paragraph';
	var BPropertyBag = 'PropertyBag';
	var BDynamicChildren = 'DynamicChildren';
}

@:structInit
class BlockDefinition {
	public final name:String;
	public final meta:Map<String, String> = [];
	public final type:BlockDefinitionType = BNormal;
	public final id:Null<IdDefinition> = null;
	public final parameters:Array<ParameterDefinition> = [];
	public final properties:Array<PropertyDefinition> = [];
	public final children:Array<ChildDefinition> = [];

	public var isParagraph(get, never):Bool;

	function get_isParagraph() return type == BParagraph;

	public var isTag(get, never):Bool;

	function get_isTag() return type == BTag;

	public function getMeta(name:String, ?def:String) {
		return meta.exists(name) ? meta.get(name) : def;
	}

	public function validate(node:Node, schema:Schema):Result<Node, CompileError> {
		var existingChildren:Array<String> = [];
		var existingProps:Array<String> = [];
		var existingParams:Array<Int> = [];

		function validateChild(type:String, isTag:Bool, child:Node):Result<Node, CompileError> {
			if (!children.exists(c -> c.name == type)) {
				return Error(new CompileError(Fatal, 'The block ${type} is an invalid child for ${name}', child.pos));
			}
			var childDef = children.find(c -> c.name == type);
			var blockDef = schema.getBlock(type);

			if (childDef == null) {
				return Error(new CompileError(Fatal, 'Child not allowed: ${type}', child.pos));
			} else if (blockDef == null) {
				return Error(new CompileError(Fatal, 'Unknown block type: ${type}', child.pos));
			} else if (existingChildren.contains(type) && childDef.multiple == false) {
				return Error(new CompileError(Fatal, 'Only one ${type} is allowed in ${name}', child.pos));
			}

			existingChildren.push(type);

			return blockDef.validate(child, schema);
		}

		function validateParam(param:NodeParam, pos:Int):Result<NodeParam, CompileError> {
			var paramDef = parameters.find(p -> p.pos == pos);

			if (paramDef == null) return Error(new CompileError(Fatal, 'Invalid parameter', param.pos));

			existingParams.push(paramDef.pos);

			return paramDef.validate(param);
		}

		function validateProp(prop:Node):Result<Node, CompileError> {
			if (prop.id == Keyword.KId) return Ok(prop);

			var propDef = properties.find(p -> p.name == prop.id);

			if (propDef == null) switch type {
				case BPropertyBag:
					if (existingProps.contains(prop.id)) {
						return Error(new CompileError(Fatal, 'Duplicate property ${prop.id}', prop.pos));
					}
					return Ok(prop);
				default:
					return Error(new CompileError(Fatal, 'Invalid property ${prop.id}', prop.pos));
			}

			if (existingProps.contains(propDef.name)) {
				return Error(new CompileError(Fatal, 'Duplicate property ${propDef.name}', prop.pos));
			}

			existingProps.push(propDef.name);

			return propDef.validate(prop);
		}

		if (id != null) {
			if (node.id == null && id.required) {
				return Error(new CompileError(Fatal, '${name} requires an id', node.pos));
			}
			if (node.id != null) switch id.validate(node.id, node.pos) {
				case Error(error): return Error(error);
				case Ok(_):
			}
		} else {
			if (node.id != null) {
				return Error(new CompileError(Fatal, '${name} cannot have an id', node.pos));
			}
		}

		if (type != BDynamicChildren) for (child in node.children) switch child.type {
			case Block(type, isTag):
				switch validateChild(type, isTag, child) {
					case Error(error): return Error(error);
					case Ok(_):
				}
			// case Parameter(pos): switch  validateParam(child, pos) {
			//   case Error(error): return Error(error);
			//   case Ok(_):
			// }
			case Property:
				switch validateProp(child) {
					case Error(error): return Error(error);
					case Ok(_):
				}
			case Paragraph:
				var para:BlockDefinition = null;
				for (def in children) {
					var b = schema.getBlock(def.name);
					if (b.isParagraph) {
						para = b;
						break;
					}
				}
				if (para == null) {
					return Error(new CompileError(Fatal, 'No Paragraphs are allowed here', child.pos));
				} else
					switch validateChild(para.name, para.isTag, child) {
						case Error(error): return Error(error);
						case Ok(_):
					}
			case Text if (!isTag && !isParagraph):
				return Error(new CompileError(Fatal, 'Invalid child', child.pos));
			case Text:
				// ?
		}

		for (i in 0...node.params.length) switch validateParam(node.params[i], i) {
			case Error(error): return Error(error);
			case Ok(_):
		}

		for (def in parameters) {
			if (!existingParams.contains(def.pos)) {
				var msg = if (def.meta.exists('schema.error')) {
					def.meta.get('schema.error') + ' at position ${def.pos}.';
				} else {
					'Requires a ${def.type} parameter at position ${def.pos}.';
				}
				return Error(new CompileError(Fatal, msg, node.pos));
			}
		}

		for (def in properties) {
			if (def.required && !existingProps.contains(def.name)) {
				return Error(new CompileError(Fatal, 'Requires property ${def.name}', node.pos));
			}
		}

		for (child in children) {
			if (child.required && !existingChildren.contains(child.name)) {
				return Error(new CompileError(Fatal, 'Requires a ${child.name} block', node.pos));
			}
		}

		return Ok(node);
	}
}

enum abstract ValueType(String) to String from String {
	final VAny = 'Any';
	final VString = 'String';
	final VInt = 'Int';
	final VFloat = 'Float';
	final VBool = 'Bool';
}

private function checkType(value:String, type:ValueType, pos:Position):Result<String, CompileError> {
	return switch type {
		case VBool: switch value {
				case 'true' | 'false': Ok(value);
				default: Error(new CompileError(Fatal, 'Expected a Bool', pos));
			}
		case VString:
			Ok(value);
		// if (isAlpha(value.charAt(0))) {
		//   Ok(value);
		// } else {
		//   Error(new CompileError(Fatal, 'Expected a string', pos));
		// }
		case VAny:
			Ok(value);
		case VInt:
			for (i in 0...value.length) if (!isDigit(value.charAt(i))) {
				return Error(new CompileError(Fatal, 'Expected an Int', pos));
			}
			Ok(value);
		case VFloat: try {
				@:keep Std.parseFloat(value);
				Ok(value);
			} catch (e) {
				Error(new CompileError(Fatal, 'Expected a Float', pos));
			}
	}
}

function isDigit(c:String):Bool {
	return c >= '0' && c <= '9';
}

function isAlpha(c:String):Bool {
	return (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z');
}

@:structInit
class IdDefinition {
	public final required:Bool = false;
	public final type:ValueType = VString;
	public final parameter:Int = 0;

	public function validate(value, pos) {
		return checkType(value, type, pos);
	}
}

@:structInit
class ChildDefinition {
	public final name:String;
	public final required:Bool = false;
	public final multiple:Bool = true;
}

@:structInit
class ParameterDefinition {
	public final pos:Int;
	public final def:Null<String> = null;
	public final type:ValueType = VString;
	public final allowedValues:Array<String> = [];
	public final meta:Map<String, String> = [];

	public function validate(param:NodeParam):Result<NodeParam, CompileError> {
		// var child = param.children.find(p -> switch p.type {
		//   case Text: true;
		//   default: false;
		// });

		var value = param.value != null ? param.value : def;

		if (allowedValues.length > 0) {
			if (!allowedValues.contains(value)) {
				return Error(new CompileError(Fatal, 'Must be one of ${allowedValues.join(', ')}', param.pos));
			}
		}

		return checkType(value, type, param.pos).map(_ -> param);
	}
}

@:structInit
class PropertyDefinition {
	public final name:String;
	public final def:Null<String> = null;
	public final required:Bool = false;
	public final type:ValueType = VString;
	public final allowedValues:Array<String> = [];
	public final meta:Map<String, String> = [];

	public function validate(prop:Node):Result<Node, CompileError> {
		var child = prop.children.find(p -> switch p.type {
			case Text: true;
			default: false;
		});
		var value = child != null ? child.textContent : def;

		if (allowedValues.length > 0) {
			if (!allowedValues.contains(value)) {
				return Error(new CompileError(Fatal, 'Must be one of ${allowedValues.join(', ')}', child.pos));
			}
		}

		return checkType(value, type, child.pos).map(_ -> prop);
	}
}
