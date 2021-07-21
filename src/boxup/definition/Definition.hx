package boxup.definition;

import haxe.ds.Option;
import haxe.ds.Map;
import boxup.Builtin;

using Lambda;

class Definition implements Validator {
  public final id:DefinitionId;
  final blocks:Array<BlockDefinition>;
  final meta:Map<String, String>;

  public function new(id, blocks, meta) {
    this.id = id;
    this.blocks = blocks;
    this.meta = meta;
  }

  public function getBlock(name:String) {
    return blocks.find(b -> b.name == name);
  }

  public function getMeta(name:String, ?def:String) {
    return meta.exists(name) ? meta.get(name) : def;
  }

  public function validate(nodes:Array<Node>):Result<Array<Node>> {
    var file = nodes.length > 0
      ? nodes[0].pos.file
      : '<unknown>';

    return getBlock(BRoot).validate({
      type: Block(BRoot, false),
      children: nodes,
      pos: { min: 0, max: 0, file: file }
    }, this).map(_ -> Ok(nodes));
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
  public final id:Null<IdDefintion> = null;
  public final properties:Array<PropertyDefinition> = [];
  public final children:Array<ChildDefinition> = [];
  
  public var isParagraph(get, never):Bool;
  function get_isParagraph() return type == BParagraph;

  public var isTag(get, never):Bool;
  function get_isTag() return type == BTag;

  public function getMeta(name:String, ?def:String) {
    return meta.exists(name) ? meta.get(name) : def;
  }

  public function validate(node:Node, definition:Definition):Result<Node> {
    var existingChildren:Array<String> = [];
    var existingProps:Array<String> = [];

    function validateChild(type:String, isTag:Bool, child:Node):Result<Node> {
      if (!children.exists(c -> c.name == type)) {
        return Fail(new Error('The block ${type} is an invalid child for ${name}', child.pos));
      }
      var childDef = children.find(c -> c.name == type);
      var blockDef = definition.getBlock(type);

      if (childDef == null) {
        return Fail(new Error('Child not allowed: ${type}', child.pos));
      } else if (blockDef == null) {
        return Fail(new Error('Unknown block type: ${type}', child.pos));
      } else if (existingChildren.contains(type) && childDef.multiple == false) {
        return Fail(new Error('Only one ${type} is allowed in ${name}', child.pos));
      }

      existingChildren.push(type);

      return blockDef.validate(child, definition);
    }

    function validateProp(prop:Node):Result<Node> {
      var propDef = properties.find(p -> p.name == prop.id);
      
      if (propDef == null) switch type {
        case BPropertyBag:
        default:
          return Fail(new Error('Invalid property ${prop.id}', prop.pos));
      }

      if (existingProps.contains(propDef.name)) {
        return Fail(new Error('Duplicate property', prop.pos));
      }

      existingProps.push(propDef.name);

      return propDef.validate(prop);
    }

    if (id != null) {
      if (node.id == null && id.required) {
        return Fail(new Error('${name} requires an id', node.pos));
      }
      if (node.id != null) switch id.validate(node.id, node.pos) {
        case Fail(error): return Fail(error);
        case Ok(_):
      }
    }

    for (child in node.children) switch child.type {
      case Block(type, isTag): switch validateChild(type, isTag, child) {
        case Fail(error): return Fail(error);
        case Ok(_):
      }
      case Property: switch validateProp(child) {
        case Fail(error): return Fail(error);
        case Ok(_):
      }
      case Paragraph:
        var para:BlockDefinition = null;
        for (def in children) {
          var b = definition.getBlock(def.name);
          if (b.isParagraph) {
            para = b;
            break;
          }
        }
        if (para == null) {
          return Fail(new Error('No Paragraphs are allowed here', child.pos));
        } else switch validateChild(para.name, para.isTag, child) {
          case Fail(error): return Fail(error);
          case Ok(_):
        }
      case Text if (!isTag && !isParagraph):
        return Fail(new Error('Invalid child', child.pos));
      case Text:
        // ?
    }
    
    for (def in properties) {
      if (def.required && !existingChildren.contains(def.name)) {
        return Fail(new Error('Requires property ${def.name}', node.pos));
      }
    }

    for (child in children) {
      if (child.required && !existingChildren.contains(child.name)) {
        return Fail(new Error('Requires a ${child.name} block', node.pos));
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

private function checkType(value:String, type:ValueType, pos:Position):Result<String> {
  return switch type {
    case VBool: switch value {
      case 'true' | 'false': Ok(value);
      default: Fail(new Error('Expected a Bool', pos));
    }
    case VString | VAny: Ok(value);
    case VInt: try { 
      @:keep Std.parseInt(value);
      Ok(value); 
    } catch (e) {
      Fail(new Error('Expected an Int', pos));
    }
    case VFloat: try { 
      @:keep Std.parseFloat(value);
      Ok(value); 
    } catch (e) {
      Fail(new Error('Expected an Float', pos));
    }
  }
}

@:structInit
class IdDefintion {
  public final required:Bool = false;
  public final type:ValueType = VString;

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
class PropertyDefinition {
  public final name:String;
  public final def:Null<String> = null;
  public final required:Bool = false;
  public final type:ValueType = VString;
  public final allowedValues:Array<String> = [];

  public function validate(prop:Node):Result<Node> {
    var child = prop.children.find(p -> switch p.type {
      case Text: true;
      default: false;
    });
    var value = child != null
      ? child.textContent
      : def;

    if (allowedValues.length > 0) {
      if (!allowedValues.contains(value)) {
        return Fail(new Error('Must be one of ${allowedValues.join(', ')}', child.pos));
      }
    }

    return checkType(value, type, child.pos)
      .map(_ -> Ok(prop));
  }
}
