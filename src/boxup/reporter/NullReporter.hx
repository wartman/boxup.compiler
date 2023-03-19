package boxup.reporter;

class NullReporter implements Reporter {
	public function new() {}

	public function report(error:CompileError, source:Source) {
		throw error;
	}
}
