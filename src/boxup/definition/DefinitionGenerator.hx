package boxup.definition;

import haxe.ds.Map;
import boxup.Builtin;
import boxup.definition.Definition;

using Lambda;
using haxe.io.Path;

class DefinitionGenerator implements Generator<Definition> {
  static final defaultParagraphChildren:Array<ChildDefinition> = [
    { name: BItalic },
    { name: BBold },
    { name: BRaw }
  ];

  static final defaultBlocks:Array<BlockDefinition> = [
    {
      name: BItalic,
      type: BTag
    },
    {
      name: BBold,
      type: BTag
    },
    {
      name: BRaw,
      type: BTag
    }
  ];

  public function new() {}

  public function generate(nodes:Array<Node>):Definition {
    var blocks:Array<BlockDefinition> = [].concat(defaultBlocks);
    var meta:Map<String, String> = [];
    var id:DefinitionId = switch nodes[0].pos.file.withoutDirectory().split('.') {
      case [name, 'd', 'box'] | [name, 'box']: name;
      default: '<unknown>';
    }

    for (node in nodes) switch node.type {
      case Block('definition', false):
        if (node.id != null) id = node.id;
        var metas = node.children.filter(c -> c.type.equals(Block('meta', false)));
        for (m in metas) {
          var suffix = m.id;
          for (child in m.children.filter(c -> c.type.equals(Property))) {
            meta.set(suffix != null ? '${suffix}.${child.id}' : child.id, child.textContent);
          }
        }
        // todo: handle imports
      case Block('root', false):
        blocks.push({
          name: BRoot,
          children: generateChildren(node)
        });
      case Block('block', false):
        var type:BlockDefinitionType = node.getProperty('type', BlockDefinitionType.BNormal);
        var id = node.children.find(n -> n.type.equals(Block('id', false)));
        blocks.push({
          name: node.id,
          id: id != null
            ? {
              required: id.getProperty('required', 'false') == 'true',
              type: id.getProperty('type', ValueType.VString)
            }
            : null,
          type: type,
          meta: generateMeta(node),
          properties: generateProperties(node),
          children: switch type {
            case BParagraph:
              defaultParagraphChildren.concat(generateChildren(node));
            default:
              generateChildren(node);
          }
        });
      default:
    }

    return new Definition(id, blocks, meta);
  }

  function generateProperties(node:Node) {
    return node.children
      .filter(n -> n.type.equals(Block('property', false)))
      .map(n -> {
        var allowed = n.children.filter(n -> n.type.equals(Block('option', false)));
        ({
          name: n.id,
          required: n.getProperty('required', 'false') == 'true',
          type: n.getProperty('type', 'String'),
          allowedValues: allowed.length > 0
            ? allowed.map(n -> n.id)
            : []
        }:PropertyDefinition);
      });
  }

  function generateMeta(node:Node) {
    var meta:Map<String, String> = [];
    for (n in node.children.filter(n -> n.type.equals(Block('meta', false)))) {
      var suffix = n.id;
      for (child in n.children.filter(n -> n.type.equals(Property))) {
        meta.set(suffix != null ? '${suffix}.${child.id}' : child.id, child.textContent);    
      }
    }
    return meta;
  }

  function generateChildren(node:Node) {
    return node.children
      .filter(n -> n.type.equals(Block('child', false)))
      .map(n -> ({
        name: n.id,
        required: n.getProperty('required', 'false') == 'true',
        multiple: n.getProperty('multiple', 'true') == 'true'
      }:ChildDefinition)); 
  }
}
