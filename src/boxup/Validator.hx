package boxup;

interface Validator {
  public function validate(nodes:Array<Node>):Result<Array<Node>, CompileError>;
}
