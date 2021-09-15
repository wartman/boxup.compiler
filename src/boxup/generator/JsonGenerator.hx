package boxup.generator;

class JsonGenerator implements Generator<Array<Dynamic>> {
  public function new() {}
  
  public function generate(nodes:Array<Node>):Result<Array<Dynamic>> {
    return Ok(nodes.map(node -> node.toJson()));
  }
}
