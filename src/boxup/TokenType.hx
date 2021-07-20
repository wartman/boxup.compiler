package boxup;

enum abstract TokenType(String) to String {
  var TokOpenBracket = '[';
  var TokCloseBracket = ']';
  var TokOpenAngleBracket = '<';
  var TokCloseAngleBracket = '>';
  var TokStar = '*';
  var TokUnderline = '_';
  var TokRaw = '`';
  var TokEquals = '=';
  var TokWhitespace = '<whitespace>';
  var TokIdentifier = '<identifier>';
  var TokText = '<text>';
  var TokNewline = '<newline>';
  var TokEof = '<eof>';
  var TokCommentStart = '[/';
  var TokCommentEnd = '/]';
  var TokSingleQuote = "'";
  var TokDoubleQuote = '"';
}
