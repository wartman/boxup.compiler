package boxup.generator;

class NullGenerator implements Generator<Dynamic> {
  public function new() {}
  
  public function generate(nodes:Array<Node>):Result<Dynamic> {
    return return Ok(nodes);
  }
}
