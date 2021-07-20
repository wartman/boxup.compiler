package boxup;

import haxe.ds.Option;

interface Validator {
  public function validate(nodes:Array<Node>):Option<Error>;
}
