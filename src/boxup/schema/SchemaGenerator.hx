package boxup.schema;

import boxup.loader.Loader;
import haxe.ds.Map;
import boxup.Builtin;
import boxup.schema.Schema;

using Lambda;
using haxe.io.Path;

/**
	Generates a Schema.

	Note: This is *not* a valid boxup.Generator, as we need to use it in
	sync-only contexts (mainly macros).
**/
class SchemaGenerator {
	static final defaultParagraphChildren:Array<ChildDefinition> = [{name: BItalic}, {name: BBold}, {name: BRaw}];

	static final defaultBlocks:Array<BlockDefinition> = [
		{
			name: Keyword.KUse,
			parameters: [{name: 'name', pos: 0, type: VString}]
		},
		{
			name: BItalic,
			type: BDynamicChildren
		},
		{
			name: BBold,
			type: BDynamicChildren
		},
		{
			name: BRaw,
			type: BDynamicChildren
		}
	];

	final loadSource:(id:String) -> Result<Schema, CompileError>;

	public function new(loadSource) {
		this.loadSource = loadSource;
	}

	public function generate(nodes:Array<Node>):Result<Schema, CompileError> {
		var blocks:Array<BlockDefinition> = [].concat(defaultBlocks);
		var meta:Map<String, String> = [];
		var id:SchemaId = switch nodes[0].pos.file.withoutDirectory().split('.') {
			case [name, 'box']: name;
			default: '<unknown>';
		}

		for (node in nodes) switch node.type {
			case Block(Keyword.KSchema, _):
				if (node.getParameter(0) != null) id = node.getParameter(0);
				meta = generateMeta(node);
				switch generateUses(node) {
					case Ok(value):
						blocks = blocks.concat(value.filter(block -> block.name != BRoot));
					case Error(error):
						return Error(error);
				}
			case Block('root', false):
				blocks.push({
					name: BRoot,
					children: generateChildren(node, nodes).concat([{name: Keyword.KUse, required: true, multiple: false}])
				});
			case Block('block', false):
				var type:BlockDefinitionType = node.getProperty('type', BlockDefinitionType.BNormal);
				var id = node.children.find(n -> n.type.equals(Block('id', false)));
				blocks.push({
					name: node.getParameter(0),
					type: type,
					meta: generateMeta(node),
					parameters: generateParameters(node),
					properties: generateProperties(node),
					children: switch type {
						case BParagraph:
							defaultParagraphChildren.concat(generateChildren(node, nodes));
						default:
							generateChildren(node, nodes);
					}
				});
			default:
		}

		return Ok(new Schema(id, blocks, meta));
	}

	function generateParameters(node:Node) {
		var pos = 0;
		return node.children.filter(n -> n.type.equals(Block('parameter', false))).map(n -> {
			var allowed = n.children.filter(n -> n.type.equals(Block('option', false)));
			({
				pos: pos++,
				name: n.getParameter(0),
				type: n.getProperty('type', 'String'),
				meta: generateMeta(n),
				allowedValues: allowed.length > 0 ? allowed.map(n -> n.getProperty('value')) : []
			} : ParameterDefinition);
		});
	}

	function generateProperties(node:Node) {
		return node.children.filter(n -> n.type.equals(Block('property', false))).map(n -> {
			var allowed = n.children.filter(n -> n.type.equals(Block('option', false)));
			({
				name: n.getParameter(0),
				required: n.getProperty('required', 'false') == 'true',
				type: n.getProperty('type', 'String'),
				meta: generateMeta(n),
				allowedValues: allowed.length > 0 ? allowed.map(n -> n.getProperty('value')) : []
			} : PropertyDefinition);
		});
	}

	function generateMeta(node:Node) {
		var meta:Map<String, String> = [];
		for (n in node.children.filter(n -> n.type.equals(Block('meta', false)))) {
			var suffix = n.getParameter(0);
			for (child in n.children) switch child.type {
				case Property(name):
					meta.set('${suffix}.${name}', child.children[0].textContent);
				default:
			}
		}
		return meta;
	}

	function generateChildren(node:Node, root:Array<Node>) {
		var children = node.children.filter(n -> n.type.equals(Block('child', false))).map(n -> ({
			name: n.getParameter(0),
			required: n.getProperty('required', 'false') == 'true',
			multiple: n.getProperty('multiple', 'true') == 'true'
		} : ChildDefinition));
		var extensions = node.children.filter(n -> n.type.equals(Block('extend', false)));
		for (reference in extensions) {
			var name = reference.getParameter(0);
			var param = reference.children.find(node -> node.type.equals(Parameter(0)));
			var target = root.find(node -> node.type.equals(Block('group', false)) && node.getParameter(0) == name);
			if (target == null) {
				throw new CompileError('No group exists with the name "$name"', param?.pos);
			}
			children = children.concat(generateChildren(target, root));
		}
		return children;
	}

	function generateUses(node:Node):Result<Array<BlockDefinition>, CompileError> {
		var uses = node.children.filter(n -> n.type.equals(Block('use', false)));
		var results:Array<BlockDefinition> = [];
		for (node in uses) switch loadChildSchema(node.getParameter(0), node.pos) {
			case Ok(value): results = results.concat(value);
			case Error(error): return Error(error);
		}
		return Ok(results);
	}

	function loadChildSchema(id:String, pos:Position):Result<Array<BlockDefinition>, CompileError> {
		return loadSource(id).map(schema -> schema.getBlocks()).mapError(_ -> {
			new CompileError('Could not load $id', pos);
		});
	}
}
