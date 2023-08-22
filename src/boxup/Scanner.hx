package boxup;

class Scanner {
	final source:Source;
	var position:Int = 0;
	var start:Int = 0;

	public function new(source) {
		this.source = source;
	}

	public function scan():Array<Token> {
		position = 0;
		start = 0;
		return [while (!isAtEnd()) scanToken()].concat([
			({
				type: TokEof,
				value: '',
				pos: {
					min: position,
					max: position,
					file: source.file
				}
			} : Token)
		]);
	}

	function scanToken():Token {
		start = position;
		var r = advance();
		return switch r {
			case ' ': createToken(TokWhitespace);
			case '\r' if (match('\n')): createToken(TokNewline, '\r\n');
			case '\n': createToken(TokNewline);
			// Todo: should probably limit escape sequences
			case '\\': createToken(TokText, advance());
			case '[' if (match('/')): createToken(TokCommentStart, '[/');
			case '/' if (match(']')): createToken(TokCommentEnd, '/]');
			case '[': createToken(TokOpenBracket);
			case ']': createToken(TokCloseBracket);
			case '<': createToken(TokOpenAngleBracket);
			case '>': createToken(TokCloseAngleBracket);
			case '=': createToken(TokEquals);
			case '_': createToken(TokUnderline);
			case '*': createToken(TokStar);
			case '`': createToken(TokRaw);
			case '"': createToken(TokDoubleQuote);
			case "'": createToken(TokSingleQuote);
			case '.': createToken(TokDot);
			case '-': createToken(TokDash);
			case r:
				{
					type: TokText,
					value: r + readWhile(() -> isAlphaNumeric(peek())),
					pos: {
						min: start,
						max: position,
						file: source.file
					}
				};
		}
	}

	function createToken(type:TokenType, ?value:String):Token {
		return {
			type: type,
			value: value == null ? previous() : value,
			pos: {
				file: source.file,
				min: start,
				max: position
			}
		};
	}

	function match(value:String) {
		if (check(value)) {
			position = position + value.length;
			return true;
		}
		return false;
	}

	function check(value:String) {
		var found = source.content.substr(position, value.length);
		return found == value;
	}

	function peek() {
		return source.content.charAt(position);
	}

	function advance() {
		if (!isAtEnd()) position++;
		return previous();
	}

	function previous() {
		return source.content.charAt(position - 1);
	}

	function isDigit(c:String):Bool {
		return c >= '0' && c <= '9';
	}

	function isAlpha(c:String):Bool {
		return (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z');
	}

	function isAlphaNumeric(c:String) {
		return isAlpha(c) || isDigit(c);
	}

	function readWhile(compare:() -> Bool):String {
		var out = [while (!isAtEnd() && compare()) advance()];
		return out.join('');
	}

	function isAtEnd() {
		return position >= source.content.length;
	}
}
