package boxup;

interface Reporter {
  public function report(error:Error, source:Source):Void;
}
