package boxup;

class Error {
  public final pos:Position;
  public final message:String;

  public function new(message, ?pos) {
    this.message = message;
    this.pos = pos != null ? pos : Position.unknown();
  }

  public function toString() {
    return '${message} : ${pos.file} ${pos.min} ${pos.max}';
  }
}
 