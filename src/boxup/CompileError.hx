package boxup;

enum ErrorType {
  Warning;
  Fatal;
}

class CompileError {
  public final type:ErrorType;
  public final pos:Position;
  public final message:String;
  public final detailedMessage:Null<String> = null;

  public function new(type, message, ?detailedMessage, ?pos) {
    this.type = type;
    this.message = message;
    this.detailedMessage = detailedMessage;
    this.pos = pos != null ? pos : Position.unknown();
  }

  public function toString() {
    return '${message} : ${pos.file} ${pos.min} ${pos.max}';
  }
}
