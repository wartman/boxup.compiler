package boxup;

using Lambda;
using StringTools;
using boxup.TokenTools;

class Parser {
	public static inline function fromSource(source) {
		return fromTokens(Scanner.fromSource(source).scan());
	}

	public static inline function fromTokens(tokens:Array<Token>) {
		return new Parser(tokens);
	}

	final tokens:Array<Token>;
	var position:Int = 0;

	public function new(tokens) {
		this.tokens = tokens;
	}

	public function parse():Either<Node, BoxupError> {
		position = 0;
		var nodes:Array<Node> = [];

		while (!isAtEnd()) switch parseRoot(0) {
			case Left(None):
			case Left(Some(node)): nodes.push(node);
			case Right(error): return Right(error);
		}

		return Left({
			type: Root,
			children: nodes,
			pos: {
				min: 0,
				max: position,
				file: tokens[0].pos.file
			}
		});
	}

	function parseRoot(indent:Int, isInline:Bool = false):Either<Option<Node>, BoxupError> {
		if (isAtEnd()) return Left(None);
		if (isInline && isNewline(peek())) return Left(None);
		if (match(TokNewline)) return parseRoot(0);
		if (match(TokWhitespace)) return parseRoot(indent + 1);
		if (match(TokCommentStart)) {
			ignoreComment();
			return parseRoot(indent, isInline);
		}
		if (match(TokOpenBracket)) return parseBlock(indent).mapLeft(node -> Some(node));
		if (checkProperty()) return parseProperty(() -> parseValue().mapLeft(v -> Some(v))).mapLeft(node -> Some(node));
		return parseParagraph(indent).mapLeft(node -> Some(node));
	}

	function parseBlock(indent:Int, isTag:Bool = false):Either<Node, BoxupError> {
		ignoreWhitespace();

		var type = identifier();
		var children:Array<Node> = [];
		var paramsIndex = 0;
		var paramsAllowed = true;

		if (type == null) {
			return Right(new BoxupError('Expected a block type', peek().pos));
		}

		ignoreWhitespace();

		while (!check(TokCloseBracket) && !isAtEnd()) {
			ignoreWhitespaceAndNewline();
			if (!checkProperty() && paramsAllowed) {
				switch parseParameter(paramsIndex++) {
					case Left(value): children.push(value);
					case Right(error): return Right(error);
				}
			} else {
				paramsAllowed = false;
				switch parseProperty(() -> parseInlineValue().mapLeft(v -> Some(v))) {
					case Left(value): children.push(value);
					case Right(error): return Right(error);
				}
			}
			ignoreWhitespaceAndNewline();
		}

		switch consume(TokCloseBracket) {
			case Left(_):
			case Right(error): return Right(error);
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
					case Right(e):
						return Right(e);
					case Left(None):
					case Left(Some(child)):
						children.push(child); // Allow children to follow on the same line
				}
			} else {
				while (checkIndent()) switch parseRoot(childIndent) {
					case Right(e):
						return Right(e);
					case Left(None):
					case Left(Some(child)):
						children.push(child);
				};
			}
		}

		return Left({
			type: Block(type.value, isTag),
			children: children,
			pos: type.pos
		});
	}

	function parseTaggedBlock():Either<Node, BoxupError> {
		// Ensures we don't nest tags
		var tagged = readWhile(() -> !checkAny([TokCloseAngleBracket, TokOpenAngleBracket])).merge();

		switch consume(TokCloseAngleBracket) {
			case Left(_):
			case Right(error): return Right(error);
		}

		switch consume(TokOpenBracket) {
			case Left(_):
			case Right(error): return Right(error);
		}

		return parseBlock(0, true).mapLeft(node -> {
			node.children.push({
				type: Text,
				textContent: tagged.value,
				pos: tagged.pos
			});
			node;
		});
	}

	function parseParagraph(indent:Int):Either<Node, BoxupError> {
		var start = peek();
		var children:Array<Node> = [];

		do {
			switch parseText(indent) {
				case Left(value): children.push(value);
				case Right(error): return Right(error);
			}
		} while (!isAtEnd() && !isNewline(peek()));

		return Left({
			type: Paragraph,
			children: children.filter(c -> c != null),
			pos: start.getMergedPos(previous())
		});
	}

	function parseDecoration(indent:Int, name:Builtin, delimiter:TokenType):Either<Node, BoxupError> {
		var start = peek();
		var children:Array<Node> = [];

		while (!check(delimiter) && !isAtEnd() && !isNewline(peek())) {
			switch parseText(indent) {
				case Left(child): children.push(child);
				case Right(e): return Right(e);
			}
		}

		switch consume(delimiter) {
			case Left(_):
			case Right(error): return Right(error);
		}

		return Left({
			type: Block(name, false),
			children: children,
			pos: start.getMergedPos(previous())
		});
	}

	function parseText(indent:Int):Either<Node, BoxupError> {
		if (match(TokOpenAngleBracket)) return parseTaggedBlock();
		if (match(TokUnderline)) return parseDecoration(indent, BItalic, TokUnderline);
		if (match(TokStar)) return parseDecoration(indent, BBold, TokStar);
		if (match(TokRaw)) return parseDecoration(indent, BRaw, TokRaw);
		return parseTextPart(indent);
	}

	function parseTextPart(indent:Int):Either<Node, BoxupError> {
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

		return Left({
			type: Text,
			textContent: tok.value,
			pos: tok.pos
		});
	}

	function parseParameter(index:Int):Either<Node, BoxupError> {
		var value = if (checkIdentifier()) {
			identifier();
		} else switch parseValue() {
			case Left(value): value;
			case Right(e): return Right(e);
		}

		return Left({
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

	function parseProperty(value:() -> Either<Option<Token>, BoxupError>):Either<Node, BoxupError> {
		var id = identifier();
		if (id == null) {
			return Right(new BoxupError('Expected an identifier', peek().pos));
		}

		ignoreWhitespace();
		switch consume(TokEquals) {
			case Left(_):
			case Right(error): return Right(error);
		}
		ignoreWhitespace();

		return switch value() {
			case Right(error):
				Right(error);
			case Left(None):
				Right(new BoxupError('Expected a value', peek().pos));
			case Left(Some(value)):
				Left({
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

	function parseInlineValue():Either<Token, BoxupError> {
		if (match(TokSingleQuote)) return parseString(TokSingleQuote);
		if (match(TokDoubleQuote)) return parseString(TokDoubleQuote);
		return Left(readWhile(checkIdentifier).merge());
	}

	function parseValue():Either<Token, BoxupError> {
		if (match(TokSingleQuote)) return parseString(TokSingleQuote);
		if (match(TokDoubleQuote)) return parseString(TokDoubleQuote);
		return Left(readWhile(() -> !isNewline(peek())).merge());
	}

	function parseString(delimiter:TokenType):Either<Token, BoxupError> {
		var out = readWhile(() -> !check(delimiter)).merge();

		if (isAtEnd()) {
			return Right(new BoxupError('Unterminated string', out.pos));
		}

		return consume(delimiter).mapLeft(_ -> out);
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

	function consume(type:TokenType):Either<TokenType, BoxupError> {
		if (!match(type)) return Right(new BoxupError('Expected a ${type}', peek().pos));
		return Left(type);
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
