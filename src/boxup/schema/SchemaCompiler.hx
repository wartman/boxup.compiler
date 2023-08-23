package boxup.schema;

import boxup.loader.Loader;

using Lambda;

class SchemaCompiler {
	final reporter:Reporter;
	final loader:Loader;
	final generator:SchemaGenerator;
	final validator = new SchemaValidator();
	final collection = new SchemaCollection();

	public function new(reporter, loader) {
		this.reporter = reporter;
		this.loader = loader;
		this.generator = new SchemaGenerator(load);
	}

	/**
		Add a pre-compiled Schema for use when resolving IDs.
	**/
	public inline function addSchema(schema:Schema) {
		collection.add(schema);
		return schema;
	}

	/**
		Attempt to load a Schema using the given id. If an existing Schema
		is found in the cache it will not be re-compiled.

		Note that, unlike the normal Compiler class, the SchemaCompiler is
		entirely *sync*. This is to ensure it can be used inside macros
		if needed.
	**/
	public function load(id:String):Result<Schema, CompileError> {
		return switch collection.get(id) {
			case null:
				loader.loadSync(id).flatMap(source -> compile(source).flatMap(schema -> {
					if (schema.id == id) return Ok(schema);

					// It's annoying that we have to do this to find the right node,
					// but for right now...
					var nodes = new Parser(new Scanner(source).scan()).parse().or([]);
					var node = nodes.find(node -> node.type.equals(Block(Keyword.KSchema, false)));
					return Error(new CompileError(Fatal, 'Invalid id: expected $id but was ${schema.id}',
						'Make sure your `[schema id]` matches the file path it\'s located in.', {
							min: node?.pos?.min ?? 0,
							max: node?.pos?.max ?? 0,
							file: source.file
						}));
				}).mapError(e -> {
					// We need to report here to ensure we have the right Source.
					reporter.report(e, source);
					e;
				})).map(addSchema);
			case schema:
				Ok(schema);
		}
	}

	/**
		Compile a Source into a Schema.
	**/
	public function compile(source:Source):Result<Schema, CompileError> {
		var tokens = new Scanner(source).scan();
		var parser = new Parser(tokens);
		return parser.parse().flatMap(validator.validate).flatMap(generator.generate).mapError(e -> {
			reporter.report(e, source);
			e;
		});
	}
}
