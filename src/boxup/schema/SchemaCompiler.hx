package boxup.schema;

import boxup.loader.Loader;

class SchemaCompiler {
	final reporter:Reporter;
	final loader:Null<Loader>;
	final generator:SchemaGenerator;
	final collection = new SchemaCollection();
	final validator = new SchemaValidator();

	public function new(reporter, ?loader) {
		this.reporter = reporter;
		this.loader = loader;
		this.generator = new SchemaGenerator(loader != null ? load : null);
	}

	public function load(id:String):Result<Schema, CompileError> {
		if (loader == null) {
			return Error(new CompileError(Fatal, 'No loader found'));
		}
		return switch collection.get(id) {
			case null:
				loader.loadSync(id).flatMap(compile).map(schema -> {
					collection.add(schema);
					schema;
				});
			case schema:
				Ok(schema);
		}
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
