package boxup;

import boxup.Node;

using StringTools;
using Lambda;
using boxup.TokenTools;

class Parser {
  // @todo: Rebuild this so that we don't throw errors?
  public static function parse(tokens):Result<Array<Node>> {
    return try {
      Ok(new Parser(tokens).parseTokens());
    } catch (e:Error) {
      Fail(e);
    }
  }

  final tokens:Array<Token>;
  var position:Int = 0;
  
  public function new(tokens) {
    this.tokens = tokens;
  }

  public function parseTokens():Array<Node> {
    position = 0;
    return [ while (!isAtEnd()) parseRoot(0) ].filter(n -> n != null);
  }

  function parseRoot(indent:Int, isInline:Bool = false) {
    if (isAtEnd()) return null;
    if (isInline && isNewline(peek())) return null;
    if (match(TokNewline)) return parseRoot(0);
    if (match(TokWhitespace)) return parseRoot(indent + 1);
    if (match(TokCommentStart)) {
      ignoreComment();
      return parseRoot(indent, isInline);
    }
    if (match(TokOpenBracket)) return parseBlock(indent);
    if (checkProperty()) return parseProperty(parseValue);
    return parseParagraph(indent);
  }

  function parseBlock(indent:Int, isTag:Bool = false):Node {
    ignoreWhitespace();

    var type = identifier();
    var children:Array<Node> = [];
    var paramsAllowed = true;
    // var paramPos = 0;
    var params:Array<NodeParam> = [];

    if (type == null) {
      throw error('Expected a block type', peek().pos);
    }

    ignoreWhitespace();

    while (!check(TokCloseBracket) && !isAtEnd()) {
      ignoreWhitespaceAndNewline();
      if (!checkProperty() && paramsAllowed) {
        params.push(parseParameter());
      } else {
        paramsAllowed = false;
        children.push(parseProperty(parseInlineValue));
      }
      ignoreWhitespaceAndNewline();
    }
    
    consume(TokCloseBracket);

    var childIndent:Int = 0;
    inline function checkIndent() {
      var prev:Int = position;
      if (!isAtEnd() && ((childIndent = findIndent()) > indent)) {
        return true;
      } else {
        position = prev;
        return false;
      }
    }

    if (!isTag) {
      ignoreWhitespace();
      if (!isNewline(peek())) {
        children.push(parseRoot(indent, true)); // Allow children to follow on the same line
      } else while (checkIndent()) switch parseRoot(childIndent) {
        case null:
        case child: children.push(child);
      };
    }

    var id = children.find(child -> child.id == Keyword.KId);

    return {
      type: Block(type.value, isTag),
      params: params,
      id: id != null ? id.children[0].textContent : null,
      children: children,
      pos: type.pos
    };
  }

  function parseParagraph(indent:Int):Node {
    var start = peek();
    var children:Array<Node> = [];

    do children.push(parseText(indent)) while (!isAtEnd() && !isNewline(peek()));

    return {
      type: Paragraph,
      children: children.filter(c -> c != null),
      pos: start.getMergedPos(previous())
    }
  }

  function parseDecoration(indent:Int, name:Builtin, delimiter:TokenType):Node {
    var start = peek();
    var children:Array<Node> = [];
    while (!check(delimiter) && !isAtEnd() && !isNewline(peek())) {
      children.push(parseText(indent));
    }
    consume(delimiter);
    return {
      type: Block(name, false),
      children: children,
      pos: start.getMergedPos(previous())
    }
  }
  
  function parseText(indent:Int):Node {
    return if (match(TokOpenAngleBracket)) {
      parseTaggedBlock();
    } else if (match(TokUnderline)) {
      parseDecoration(indent, BItalic, TokUnderline);
    } else if (match(TokStar)) {
      parseDecoration(indent, BBold, TokStar);
    } else if (match(TokRaw)) {
      parseDecoration(indent, BRaw, TokRaw);
    } else {
      parseTextPart(indent);
    }
  }

  function parseTextPart(indent:Int):Node {
    var read = () -> readWhile(() -> 
      !checkAny([ 
        TokOpenAngleBracket,
        TokStar,
        TokUnderline,
        TokRaw,
        TokNewline
      ])
    ).merge();
    var out = [ read() ];

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

    return {
      type: Text,
      textContent: tok.value,
      pos: tok.pos
    };
  }

  function parseTaggedBlock():Node {
    var tagged = readWhile(() -> 
      !checkAny([ TokCloseAngleBracket, TokOpenAngleBracket ]) // Ensures we don't nest tags
    ).merge();

    consume(TokCloseAngleBracket);
    consume(TokOpenBracket);

    var node = parseBlock(0, true);
    node.children.push({
      type: Text,
      textContent: tagged.value,
      pos: tagged.pos
    });
    return node;
  }

  function parseParameter():NodeParam {
    var value = if (checkIdentifier()) {
      identifier();
    } else {
      parseValue();
    }
    return {
      pos: value.pos,
      value: value.value
    };
    // return {
    //   type: Parameter(pos),
    //   id: '@$pos',
    //   pos: value.pos,
    //   children: [
    //     {
    //       type: Text,
    //       textContent: value.value,
    //       pos: value.pos
    //     }
    //   ]
    // };
  }

  function parseProperty(value:()->Null<Token>):Node {
    var id = identifier();
    if (id == null) {
      throw error('Expected an identifier', peek().pos);
    }
    ignoreWhitespace();
    consume(TokEquals);
    ignoreWhitespace();
    var value = value();
    if (value == null) {
      throw error('Expected a value', peek().pos);
    }
    // return {
    //   name: id.value,
    //   pos: id.getMergedPos(value),
    //   value: value.value
    // };
    return {
      type: Property,
      id: id.value,
      pos: id.pos,
      children: [
        {
          type: Text,
          textContent: value.value,
          pos: value.pos
        }
      ]
    }
  }

  function parseInlineValue():Null<Token> {
    return if (match(TokSingleQuote)) {
      parseString(TokSingleQuote);
    } else if (match(TokDoubleQuote)) {
      parseString(TokDoubleQuote);
    } else {
      readWhile(checkIdentifier).merge();
    } 
  }

  function parseValue():Null<Token> {
    return if (match(TokSingleQuote)) {
      parseString(TokSingleQuote);
    } else if (match(TokDoubleQuote)) {
      parseString(TokDoubleQuote);
    } else {
      readWhile(() -> !isNewline(peek())).merge();
    }
  }
  
  function parseString(delimiter:TokenType):Token{
    var out = readWhile(() -> !check(delimiter)).merge();
    
    if (isAtEnd()) {
      throw error('Unterminated string', out.pos);
    }

    consume(delimiter);
    return out;
  }

  function identifier() {
    return readWhile(checkIdentifier).merge();
  }

  function checkProperty() {
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
    return checkTokenValue(peek(), isAlphaNumeric)
      || check(TokUnderline)
      || checkTokenValue(peek(), c -> c == '-' || c == '.');
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

  function isKeyword(token:Token) {
    return token.value == Keyword.KSchema || token.value == Keyword.KUse;
  }
  
  function isDigit(c:String):Bool {
    return c >= '0' && c <= '9';
  }

  function isUcAlpha(c:String):Bool {
    return (c >= 'A' && c <= 'Z');
  }

  function isAlpha(c:String):Bool {
    return (c >= 'a' && c <= 'z') ||
           (c >= 'A' && c <= 'Z');
  }

  function isAlphaNumeric(c:String) {
    return isAlpha(c) || isDigit(c);
  }

  function checkTokenValueStarts(token:Token, comp:(c:String)->Bool):Bool {
    if (token.value.length == 0) return false;
    return comp(token.value.charAt(0));
  }

  function checkTokenValue(token:Token, comp:(c:String)->Bool):Bool {
    if (token.value.length == 0) return false;
    for (pos in 0...token.value.length) {
      if (!comp(token.value.charAt(pos))) return false;
    }
    return true;
  }

  inline function readWhile(compare:()->Bool):Array<Token> {
    return [ while (!isAtEnd() && compare()) advance() ];
  }

  inline function consume(type:TokenType) {
    if (!match(type)) throw error('Expected a ${type}', peek().pos);
  }

  function match(type:TokenType) {
    if (check(type)) {
      advance();
      return true;
    }
    return false;
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

  function error(msg:String, pos:Position) {
    return new Error(Fatal, msg, pos);
  }
}
