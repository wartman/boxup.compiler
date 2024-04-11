package boxup;

import boxup.loader.Loader;
import boxup.loader.NullLoader;
import boxup.reporter.NullReporter;
import boxup.validator.NullValidator;

class Compiler<T> {
	final loader:Loader;
	final generator:Generator<T>;
	final validator:Validator;
	final reporter:Reporter;

	public function new(generator, ?validator, ?reporter, ?loader) {
		this.generator = generator;
		this.validator = validator ?? new NullValidator().as(Validator);
		this.reporter = reporter ?? new NullReporter().as(Reporter);
		this.loader = loader ?? new NullLoader().as(Loader);
	}

	public function load(id:String):Task<T, CompileError> {
		return loader.load(id).next(compile);
	}

	public function compile(source:Source):Task<T, CompileError> {
		var tokens = new Scanner(source).scan();
		var parser = new Parser(tokens);

		return new Future(activate -> {
			parser.parse().flatMap(validator.validate).inspect(nodes -> {
				generator.generate(source, nodes).handle(result -> {
					result.ifExtract(Error(error), reporter.report(error, source));
					activate(result);
				});
			}).inspectError(error -> {
				reporter.report(error, source);
				activate(Error(error));
			});
		});
	}
}
