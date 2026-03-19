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

	public function decode(node:Node):Either<String, BoxupError> {
		if (!accepts(node)) {
			return Right(new BoxupError('Invalid node', 'Could not decode node', node.pos));
		}

		var out = '';
		for (child in node.children) switch child.type {
			case Text:
				out += child.textContent;
			case Paragraph:
				switch decode(child) {
					case Left(value): out += value;
					case Right(error): return Right(error);
				}
			case Block(_, _) if (HtmlDecoder.instance().accepts(child)):
				out += switch HtmlDecoder.instance().decode(child) {
					case Left(value): value;
					case Right(error): return Right(error);
				}
			default:
				return Right(new BoxupError('Invalid node', 'Could not decode node', child.pos));
		}
		return Left('<p>' + out + '</p>');
	}
}
