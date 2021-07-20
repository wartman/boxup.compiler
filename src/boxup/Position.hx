package boxup;

@:structInit
class Position {
  public inline static function unknown():Position {
    return {
      min: 0,
      max: 0,
      file: '<unknown>'
    };
  }

  public final min:Int;
  public final max:Int;
  public final file:String;
}
