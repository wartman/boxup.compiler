package boxup.reporter;

class NullReporter implements Reporter {
  public function new() {}

  public function report(error:Error, source:Source) {
    throw error;
  }
}
