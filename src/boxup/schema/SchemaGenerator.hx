package boxup.schema;

import haxe.ds.Map;
import boxup.Builtin;
import boxup.schema.Schema;

using Lambda;
using haxe.io.Path;

class SchemaGenerator implements Generator<Schema> {
  static final defaultParagraphChildren:Array<ChildDefinition> = [
    { name: BItalic },
    { name: BBold },
    { name: BRaw }
  ];

  static final defaultBlocks:Array<BlockDefinition> = [
    {
      name: Keyword.KUse,
      parameters: [
        { pos: 0, type: VString }
      ]
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

  public function new() {}

  public function generate(nodes:Array<Node>):Result<Schema> {
    var blocks:Array<BlockDefinition> = [].concat(defaultBlocks);
    var meta:Map<String, String> = [];
    var id:SchemaId = switch nodes[0].pos.file.withoutDirectory().split('.') {
      case [name, 'box']: name;
      default: '<unknown>';
    }

    try for (node in nodes) switch node.type {
      case Block(Keyword.KSchema, _):
        if (node.getParameter(0) != null) id = node.getParameter(0);
        meta = generateMeta(node);
      case Block('root', false):
        blocks.push({
          name: BRoot,
          children: generateChildren(node, nodes).concat([
            { name: Keyword.KUse, required: true, multiple: false }
          ])
        });
      case Block('block', false):
        var type:BlockDefinitionType = node.getProperty('type', BlockDefinitionType.BNormal);
        var id = node.children.find(n -> n.type.equals(Block('id', false)));
        blocks.push({
          name: node.getParameter(0),
          id: id != null
            ? {
              required: id.getProperty('required', 'false') == 'true',
              type: id.getProperty('type', ValueType.VString),
              parameter: Std.parseInt(id.getProperty('parameter', '0'))
            }
            : null,
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
    } catch (e:Error) {
      return Fail(e);
    }

    return Ok(new Schema(id, blocks, meta));
  }

  function generateParameters(node:Node) {
    var pos = 0;
    return node.children
      .filter(n -> n.type.equals(Block('parameter', false)))
      .map(n -> {
        var allowed = n.children.filter(n -> n.type.equals(Block('option', false)));
        ({
          pos: pos++,
          type: n.getProperty('type', 'String'),
          meta: generateMeta(n),
          allowedValues: allowed.length > 0
            ? allowed.map(n -> n.getProperty('value'))
            : []
        }:ParameterDefinition);
      });
  }

  function generateProperties(node:Node) {
    return node.children
      .filter(n -> n.type.equals(Block('property', false)))
      .map(n -> {
        var allowed = n.children.filter(n -> n.type.equals(Block('option', false)));
        ({
          name: n.getParameter(0),
          required: n.getProperty('required', 'false') == 'true',
          type: n.getProperty('type', 'String'),
          meta: generateMeta(n),
          allowedValues: allowed.length > 0
            ? allowed.map(n -> n.getProperty('value'))
            : []
        }:PropertyDefinition);
      });
  }

  function generateMeta(node:Node) {
    var meta:Map<String, String> = [];
    for (n in node.children.filter(n -> n.type.equals(Block('meta', false)))) {
      var suffix = n.getParameter(0);
      for (child in n.children.filter(n -> n.type.equals(Property))) {
        meta.set('${suffix}.${child.id}', child.children[0].textContent);    
      }
    }
    return meta;
  }

  function generateChildren(node:Node, root:Array<Node>) {
    var children = node.children
      .filter(n -> n.type.equals(Block('child', false)))
      .map(n -> ({
        name: n.getParameter(0),
        required: n.getProperty('required', 'false') == 'true',
        multiple: n.getProperty('multiple', 'true') == 'true'
      }:ChildDefinition));
    var extensions = node.children.filter(n -> n.type.equals(Block('extend', false)));
    for (reference in extensions) {
      var name = reference.getParameter(0);
      var target = root.find(node -> 
        node.type.equals(Block('group', false))
        && node.getParameter(0) == name
      );
      if (target == null) {
        throw new Error(Fatal, 'No group exists with the name "$name"', reference.params[0].pos);
      }
      children = children.concat(generateChildren(target, root));
    }
    return children;
  }
}
