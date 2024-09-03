package boxup.decoder;

class HtmlDecoder implements Decoder<String> {
	public static function instance() {
		static var decoder = null;
		if (decoder == null) decoder = new HtmlDecoder();
		return decoder;
	}

	public function new() {}

	public function accepts(node:Node):Bool {
		return switch node.type {
			case Root: true;
			case Text: true;
			case Paragraph: true;
			case Block(Builtin.BBold, _) | Block(Builtin.BItalic, _) | Block(Builtin.BRaw): true;
			case Block(type, _) if (allowedHtmlTags.contains(type)): true;
			default: false;
		}
	}

	public function decode(node:Node):Result<String, BoxupError> {
		return switch node.type {
			case Root:
				var out = [];
				for (child in node.children) if (accepts(child)) switch decode(child) {
					case Ok(value): out.push(value);
					case Error(error): return Error(error);
				} else return Error(new BoxupError('Invalid node', 'Could not decode node', child.pos));
				Ok(out.join(''));
			case Text:
				Ok(node.textContent);
			case Paragraph:
				HtmlParagraphDecoder.instance().decode(node);
			case Block(Builtin.BBold, _):
				decode({
					type: Block('b'),
					pos: node.pos,
					children: node.children,
					textContent: node.textContent
				});
			case Block(Builtin.BItalic, _):
				decode({
					type: Block('i'),
					pos: node.pos,
					children: node.children,
					textContent: node.textContent
				});
			case Block(Builtin.BRaw, _):
				decode({
					type: Block('code'),
					pos: node.pos,
					children: node.children,
					textContent: node.textContent
				});
			case Block(type, _):
				var props = [];
				var children = [];

				for (child in node.children) switch child.type {
					case Parameter(0):
						props.push('class="${child.getValue()}"');
					case Property(name):
						props.push('$name="${child.getValue()}"');
					case _ if (accepts(child)):
						switch decode(child) {
							case Ok(html): children.push(html);
							case Error(error): return Error(error);
						}
					default:
						return Error(new BoxupError('Invalid node', 'Could not decode node', child.pos));
				}

				var open = props.length > 0 ? '<$type ${props.join(' ')}>' : '<$type>';
				Ok('$open${children.join('')}</$type>');
			default:
				return Error(new BoxupError('Invalid node', 'Could not decode node', node.pos));
		}
	}
}

private final allowedHtmlTags = [
	'div',
	'code',
	'aside',
	'article',
	'blockquote',
	'section',
	'header',
	'footer',
	'main',
	'nav',
	'table',
	'thead',
	'tbody',
	'tfoot',
	'tr',
	'td',
	'th',
	'h1',
	'h2',
	'h3',
	'h4',
	'h5',
	'h6',
	'strong',
	'em',
	'span',
	'a',
	'p',
	'ins',
	'del',
	'i',
	'b',
	'small',
	'menu',
	'ul',
	'ol',
	'li',
	'label',
	'button',
	'pre',
	'picture',
	'canvas',
	'audio',
	'video',
	'form',
	'fieldset',
	'legend',
	'select',
	'option',
	'dl',
	'dt',
	'dd',
	'details',
	'summary',
	'figure',
	'figcaption',
	'textarea',
	'br',
	'embed',
	'hr',
	'img',
	'input',
	'link',
	'meta',
	'param',
	'source',
	'track',
	'wbr',
];
