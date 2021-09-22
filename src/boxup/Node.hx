package boxup;

using Lambda;

enum NodeType {
  Meta(keyword:Keyword);
  Block(type:String, ?isTag:Bool);
  Property;
  Paragraph;
  Text;
}

@:structInit
class Node {
  public var type:NodeType;
  public var pos:Position;
  public var id:Null<String> = null;
  public var textContent:Null<String> = null;
  public var children:Array<Node> = [];

  public function getProperty(name:String, def:String = null):String {
    for (c in children) switch c.type {
      case Property if (c.id == name):
        var data = c.children.find(n -> n.type.equals(Text));
        return if (data != null && data.textContent != null)
          data.textContent;
        else
          def;
      default:
    }
    return def;
  }
  
  public function toJson():Dynamic {
    return {
      type: switch type {
        case Meta(keyword): '@Meta:$keyword';
        case Block(type, _): '@Block:$type';
        case Property: '@Property';
        case Paragraph: '@Paragraph';
        case Text: '@Text';
      },
      id: id,
      textContent: textContent,
      children: children.map(c -> c.toJson())
    };
  }
}
