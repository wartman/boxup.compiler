package boxup;

using Lambda;

enum NodeType {
	Root;
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

	public function tryProperty(name:String):Either<String, BoxupError> {
		return switch getProperty(name, null) {
			case null: Right(new BoxupError('Property not found', 'The property $name does not exist', pos));
			case value: Left(value);
		}
	}

	public function getParameter(pos:Int, def:String = null):String {
		for (child in children) switch child.type {
			case Parameter(parameterPos) if (parameterPos == pos):
				return child.getValue() ?? def;
			default:
		}
		return def;
	}

	public function tryParameter(position:Int):Either<String, BoxupError> {
		return switch getParameter(position, null) {
			case null: Right(new BoxupError('Parameter not found', 'No parameter at position $position', pos));
			case value: Left(value);
		}
	}

	public function getValue():Null<String> {
		return children.find(child -> child.type.equals(Text))?.textContent;
	}

	public function tryValue():Either<String, BoxupError> {
		return switch getValue() {
			case null: Right(new BoxupError('No value found', pos));
			case value: Left(value);
		}
	}

	public function getBlock(name:String):Null<Node> {
		return children.find(node -> switch node.type {
			case Block(type, _) if (name == type): true;
			default: false;
		});
	}

	public function tryBlock(name:String):Either<Node, BoxupError> {
		return switch getBlock(name) {
			case null: Right(new BoxupError('Could not find block', 'A child block named $name does not exist', pos));
			case block: Left(block);
		}
	}

	public function getParagraph():Null<Node> {
		return children.find(node -> switch node.type {
			case Paragraph: true;
			default: false;
		});
	}

	public function tryParagraph():Either<Node, BoxupError> {
		return switch getParagraph() {
			case null: Right(new BoxupError('No Paragraph found', pos));
			case node: Left(node);
		}
	}

	public function toJson():Dynamic {
		return {
			type: switch type {
				case Root: 'Root';
				case Block(type, _): 'Block';
				case Property(name): 'Property';
				case Parameter(pos): 'Parameter';
				case Paragraph: 'Paragraph';
				case Text: 'Text';
			},
			id: switch type {
				case Root: null;
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
