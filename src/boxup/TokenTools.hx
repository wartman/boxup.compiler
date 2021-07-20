package boxup;

class TokenTools {
  public static function merge(tokens:Array<Token>):Token {
    tokens = tokens.filter(t -> t != null);
    if (tokens.length == 0) return null;
    if (tokens.length == 1) return tokens[0];
    return {
      type: TokText,
      value: tokens.map(t -> t.value).join(''),
      pos: getMergedPos(tokens[0], tokens[tokens.length - 1])
    };
  }

  public static function getMergedPos(a:Token, b:Token):Position {
    return {
      min: a.pos.min,
      max: b.pos.max,
      file: a.pos.file
    };
  }
}
