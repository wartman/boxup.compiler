package boxup.schema;

class SchemaCompiler {
	final reporter:Reporter;
	final generator = new SchemaGenerator();
	final validator = new SchemaValidator();

	public function new(reporter) {
		this.reporter = reporter;
	}

	public function compile(source:Source):Result<Schema, CompileError> {
		var tokens = new Scanner(source).scan();
		var parser = new Parser(tokens);
		return parser.parse().flatMap(validator.validate).flatMap(generator.generate).mapError(e -> {
			reporter.report(e, source);
			e;
		});
	}
}
