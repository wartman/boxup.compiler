package boxup.validator;

class NullValidator implements Validator {
  public function new() {}

  public function validate(nodes:Array<Node>):Result<Array<Node>> {
    return Ok(nodes);
  }
}
