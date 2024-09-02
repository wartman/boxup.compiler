package boxup.reporter;

class NullReporter implements Reporter {
	public function new() {}

	public function report(error:BoxupError, source:Source) {
		throw error;
	}
}
