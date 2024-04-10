package boxup;

using Lambda;

enum NodeType {
	Block(type:String, ?isTag:Bool);
	Parameter(pos:Int);
	Property(name:String);
	Paragraph;
	Text;
}

@:structInit
class Node {
	public var type:NodeType;
	public var pos:Position;
	public var children:Array<Node> = [];
	public var textContent:Null<String> = null;

	public function getProperty(name:String, def:String = null):String {
		for (child in children) switch child.type {
			case Property(propertyName) if (propertyName == name):
				return child.getValue() ?? def;
			default:
		}
		return def;
	}

	public function getParameter(pos:Int, def:String = null):String {
		for (child in children) switch child.type {
			case Parameter(parameterPos) if (parameterPos == pos):
				return child.getValue() ?? def;
			default:
		}
		return def;
	}

	public function getValue():Null<String> {
		return children.find(child -> child.type.equals(Text))?.textContent;
	}

	public function toJson():Dynamic {
		return {
			type: switch type {
				case Block(type, _): 'Block';
				case Property(name): 'Property';
				case Parameter(pos): 'Parameter';
				case Paragraph: 'Paragraph';
				case Text: 'Text';
			},
			id: switch type {
				case Block(type, _): type;
				case Property(name): name;
				case Parameter(pos): Std.string(pos);
				case Paragraph: null;
				case Text: null;
			},
			textContent: textContent,
			children: children.map(c -> c.toJson())
		};
	}
}
