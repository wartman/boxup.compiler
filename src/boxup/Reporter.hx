package boxup;

interface Reporter {
	public function report(error:BoxupError, source:Source):Void;
}
