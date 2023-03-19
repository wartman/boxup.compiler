package boxup;

interface Reporter {
  public function report(error:CompileError, source:Source):Void;
}
