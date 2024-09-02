package boxup;

using Lambda;
using StringTools;
using boxup.TokenTools;

class Parser {
	final tokens:Array<Token>;
	var position:Int = 0;

	public function new(tokens) {
		this.tokens = tokens;
	}

	public function parse():Result<Node, BoxupError> {
		position = 0;
		var nodes:Array<Node> = [];

		while (!isAtEnd()) switch parseRoot(0) {
			case Ok(None):
			case Ok(Some(node)): nodes.push(node);
			case Error(error): return Error(error);
		}

		return Ok({
			type: Root,
			children: nodes,
			pos: {
				min: 0,
				max: position,
				file: tokens[0].pos.file
			}
		});
	}

	function parseRoot(indent:Int, isInline:Bool = false):Result<Maybe<Node>, BoxupError> {
		if (isAtEnd()) return Ok(None);
		if (isInline && isNewline(peek())) return Ok(None);
		if (match(TokNewline)) return parseRoot(0);
		if (match(TokWhitespace)) return parseRoot(indent + 1);
		if (match(TokCommentStart)) {
			ignoreComment();
			return parseRoot(indent, isInline);
		}
		if (match(TokOpenBracket)) return parseBlock(indent).map(node -> Some(node));
		if (checkProperty()) return parseProperty(() -> parseValue().map(v -> Some(v))).map(node -> Some(node));
		return parseParagraph(indent).map(node -> Some(node));
	}

	function parseBlock(indent:Int, isTag:Bool = false):Result<Node, BoxupError> {
		ignoreWhitespace();

		var type = identifier();
		var children:Array<Node> = [];
		var paramsIndex = 0;
		var paramsAllowed = true;

		if (type == null) {
			return Error(new BoxupError('Expected a block type', peek().pos));
		}

		ignoreWhitespace();

		while (!check(TokCloseBracket) && !isAtEnd()) {
			ignoreWhitespaceAndNewline();
			if (!checkProperty() && paramsAllowed) {
				switch parseParameter(paramsIndex++) {
					case Ok(value): children.push(value);
					case Error(error): return Error(error);
				}
			} else {
				paramsAllowed = false;
				switch parseProperty(() -> parseInlineValue().map(v -> Some(v))) {
					case Ok(value): children.push(value);
					case Error(error): return Error(error);
				}
			}
			ignoreWhitespaceAndNewline();
		}

		switch consume(TokCloseBracket) {
			case Ok(_):
			case Error(error): return Error(error);
		}

		var childIndent:Int = 0;
		inline function checkIndent() {
			var prev:Int = position;
			function cancel() {
				position = prev;
				return false;
			}

			if (isAtEnd()) return cancel();

			childIndent = findIndent();

			// Child blocks *must* be indented past the block header to be counted as children.
			if (childIndent > indent && check(TokOpenBracket)) {
				return true;
			}

			// All other nodes are children if they are at the same indent as the block header.
			if (childIndent >= indent && !check(TokOpenBracket)) {
				return true;
			}

			return cancel();
		}

		if (!isTag) {
			ignoreWhitespace();
			if (!isNewline(peek())) {
				switch parseRoot(indent, true) {
					case Error(e):
						return Error(e);
					case Ok(None):
					case Ok(Some(child)):
						children.push(child); // Allow children to follow on the same line
				}
			} else {
				while (checkIndent()) switch parseRoot(childIndent) {
					case Error(e):
						return Error(e);
					case Ok(None):
					case Ok(Some(child)):
						children.push(child);
				};
			}
		}

		return Ok({
			type: Block(type.value, isTag),
			children: children,
			pos: type.pos
		});
	}

	function parseTaggedBlock():Result<Node, BoxupError> {
		// Ensures we don't nest tags
		var tagged = readWhile(() -> !checkAny([TokCloseAngleBracket, TokOpenAngleBracket])).merge();

		switch consume(TokCloseAngleBracket) {
			case Ok(_):
			case Error(error): return Error(error);
		}

		switch consume(TokOpenBracket) {
			case Ok(_):
			case Error(error): return Error(error);
		}

		return parseBlock(0, true).map(node -> {
			node.children.push({
				type: Text,
				textContent: tagged.value,
				pos: tagged.pos
			});
			node;
		});
	}

	function parseParagraph(indent:Int):Result<Node, BoxupError> {
		var start = peek();
		var children:Array<Node> = [];

		do {
			switch parseText(indent) {
				case Ok(value): children.push(value);
				case Error(error): return Error(error);
			}
		} while (!isAtEnd() && !isNewline(peek()));

		return Ok({
			type: Paragraph,
			children: children.filter(c -> c != null),
			pos: start.getMergedPos(previous())
		});
	}

	function parseDecoration(indent:Int, name:Builtin, delimiter:TokenType):Result<Node, BoxupError> {
		var start = peek();
		var children:Array<Node> = [];

		while (!check(delimiter) && !isAtEnd() && !isNewline(peek())) {
			switch parseText(indent) {
				case Ok(child): children.push(child);
				case Error(e): return Error(e);
			}
		}

		switch consume(delimiter) {
			case Ok(_):
			case Error(error): return Error(error);
		}

		return Ok({
			type: Block(name, false),
			children: children,
			pos: start.getMergedPos(previous())
		});
	}

	function parseText(indent:Int):Result<Node, BoxupError> {
		if (match(TokOpenAngleBracket)) return parseTaggedBlock();
		if (match(TokUnderline)) return parseDecoration(indent, BItalic, TokUnderline);
		if (match(TokStar)) return parseDecoration(indent, BBold, TokStar);
		if (match(TokRaw)) return parseDecoration(indent, BRaw, TokRaw);
		return parseTextPart(indent);
	}

	function parseTextPart(indent:Int):Result<Node, BoxupError> {
		var read = () -> readWhile(() -> !checkAny([TokOpenAngleBracket, TokStar, TokUnderline, TokRaw, TokNewline])).merge();
		var out = [read()];

		function readNext() if (!isAtEnd()) {
			var pre = position;
			if (isNewline(peek())) {
				advance();
				if (findIndentWithoutNewline() >= indent) {
					// Bail if we see a block after a newline or discover a property.
					if (check(TokOpenBracket)) {
						position = pre;
					} else {
						var part = read();
						if (part == null || part.value.length == 0) {
							position = pre;
						} else {
							out.push({
								type: part.type,
								value: ' ' + part.value,
								pos: part.pos
							});
							readNext();
						}
					}
				} else {
					position = pre;
				}
			} else {
				position = pre;
			}
		}

		readNext();

		var tok = out.merge();

		return Ok({
			type: Text,
			textContent: tok.value,
			pos: tok.pos
		});
	}

	function parseParameter(index:Int):Result<Node, BoxupError> {
		var value = if (checkIdentifier()) {
			identifier();
		} else switch parseValue() {
			case Ok(value): value;
			case Error(e): return Error(e);
		}

		return Ok({
			type: Parameter(index),
			pos: value.pos,
			children: [
				{
					type: Text,
					textContent: value.value,
					pos: value.pos
				}
			]
		});
	}

	function parseProperty(value:() -> Result<Maybe<Token>, BoxupError>):Result<Node, BoxupError> {
		var id = identifier();
		if (id == null) {
			return Error(new BoxupError('Expected an identifier', peek().pos));
		}

		ignoreWhitespace();
		switch consume(TokEquals) {
			case Ok(_):
			case Error(error): return Error(error);
		}
		ignoreWhitespace();

		return switch value() {
			case Error(error):
				Error(error);
			case Ok(None):
				Error(new BoxupError('Expected a value', peek().pos));
			case Ok(Some(value)):
				Ok({
					type: Property(id.value),
					pos: id.pos,
					children: [
						{
							type: Text,
							textContent: value.value,
							pos: value.pos
						}
					]
				});
		}
	}

	function parseInlineValue():Result<Token, BoxupError> {
		if (match(TokSingleQuote)) return parseString(TokSingleQuote);
		if (match(TokDoubleQuote)) return parseString(TokDoubleQuote);
		return Ok(readWhile(checkIdentifier).merge());
	}

	function parseValue():Result<Token, BoxupError> {
		if (match(TokSingleQuote)) return parseString(TokSingleQuote);
		if (match(TokDoubleQuote)) return parseString(TokDoubleQuote);
		return Ok(readWhile(() -> !isNewline(peek())).merge());
	}

	function parseString(delimiter:TokenType):Result<Token, BoxupError> {
		var out = readWhile(() -> !check(delimiter)).merge();

		if (isAtEnd()) {
			return Error(new BoxupError('Unterminated string', out.pos));
		}

		return consume(delimiter).map(_ -> out);
	}

	function identifier():Token {
		return readWhile(checkIdentifier).merge();
	}

	function checkProperty():Bool {
		if (check(TokText)) {
			var prev = position;
			identifier();
			ignoreWhitespace();

			if (check(TokEquals)) {
				position = prev;
				return true;
			}

			position = prev;
		}
		return false;
	}

	function checkIdentifier() {
		return checkTokenValue(peek(), isAlphaNumeric) || check(TokUnderline) || check(TokDot) || check(TokDash);
	}

	function findIndentWithoutNewline() {
		var found = 0;
		while (!isAtEnd() && isWhitespace(peek())) {
			advance();
			found++;
		}
		return found;
	}

	function findIndent() {
		var found = findIndentWithoutNewline();
		if (!isAtEnd() && isNewline(peek())) {
			advance();
			return findIndent();
		}
		if (!isAtEnd() && check(TokCommentStart)) {
			ignoreComment();
			ignoreWhitespace();
			if (isNewline(peek())) {
				advance();
				return findIndent();
			}
		}
		return found;
	}

	function ignoreWhitespace() {
		while (!isAtEnd()) {
			// Not sure if its a great idea to treat comments as whitespace, but
			// hm.
			if (match(TokCommentStart))
				ignoreComment();
			else if (!isAtEnd() && isWhitespace(peek()))
				advance();
			else
				break;
		}
		// readWhile(() -> isWhitespace(peek()));
	}

	function ignoreWhitespaceAndNewline() {
		readWhile(() -> isWhitespace(peek()) || isNewline(peek()));
	}

	function ignoreComment() {
		// Todo: allow nesting.
		readWhile(() -> !check(TokCommentEnd));
		if (!isAtEnd()) consume(TokCommentEnd);
	}

	function isNewline(token:Token) {
		return token.type == TokNewline;
	}

	function isWhitespace(token:Token) {
		return token.type == TokWhitespace;
	}

	function isDigit(c:String):Bool {
		return c >= '0' && c <= '9';
	}

	function isUcAlpha(c:String):Bool {
		return (c >= 'A' && c <= 'Z');
	}

	function isAlpha(c:String):Bool {
		return (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z');
	}

	function isAlphaNumeric(c:String) {
		return isAlpha(c) || isDigit(c);
	}

	function checkTokenValueStarts(token:Token, comp:(c:String) -> Bool):Bool {
		if (token.value.length == 0) return false;
		return comp(token.value.charAt(0));
	}

	function checkTokenValue(token:Token, comp:(c:String) -> Bool):Bool {
		if (token.value.length == 0) return false;
		for (pos in 0...token.value.length) {
			if (!comp(token.value.charAt(pos))) return false;
		}
		return true;
	}

	inline function readWhile(compare:() -> Bool):Array<Token> {
		return [while (!isAtEnd() && compare()) advance()];
	}

	function match(type:TokenType) {
		if (check(type)) {
			advance();
			return true;
		}
		return false;
	}

	function consume(type:TokenType):Result<Nothing, BoxupError> {
		if (!match(type)) return Error(new BoxupError('Expected a ${type}', peek().pos));
		return Ok(Nothing);
	}

	inline function check(type:TokenType) {
		return peek().type == type;
	}

	function checkAny(types:Array<TokenType>) {
		for (type in types) {
			if (check(type)) return true;
		}
		return false;
	}

	inline function peek() {
		return tokens[position];
	}

	inline function previous() {
		return tokens[position - 1];
	}

	function advance() {
		if (!isAtEnd()) position++;
		return previous();
	}

	function isAtEnd() {
		return position >= tokens.length || peek().type == TokEof;
	}
}
