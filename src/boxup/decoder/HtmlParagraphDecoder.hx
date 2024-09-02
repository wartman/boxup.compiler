package boxup.decoder;

class HtmlParagraphDecoder implements Decoder<String> {
	public static function instance() {
		static var decoder = null;
		if (decoder == null) decoder = new HtmlParagraphDecoder();
		return decoder;
	}

	public function new() {}

	public function accepts(node:Node):Bool {
		return node.type.equals(Paragraph);
	}

	public function decode(node:Node):Result<String, BoxupError> {
		if (!accepts(node)) {
			return Error(new BoxupError('Invalid node', 'Could not decode node', node.pos));
		}

		var out = '';
		for (child in node.children) switch child.type {
			case Text:
				out += child.textContent;
			case Paragraph:
				switch decode(child) {
					case Ok(value): out += value;
					case Error(error): return Error(error);
				}
			case Block(_, _) if (HtmlDecoder.instance().accepts(child)):
				out += switch HtmlDecoder.instance().decode(child) {
					case Ok(value): value;
					case Error(error): return Error(error);
				}
			default:
				return Error(new BoxupError('Invalid node', 'Could not decode node', child.pos));
		}
		return Ok('<p>' + out + '</p>');
	}
}
