package boxup;

import boxup.reporter.NullReporter;
import boxup.validator.NullValidator;

class Compiler<T> {
	final generator:Generator<T>;
	final validator:Validator;
	final reporter:Reporter;

	public function new(generator, ?validator, ?reporter) {
		this.generator = generator;
		this.validator = validator == null ? new NullValidator() : validator;
		this.reporter = reporter == null ? new NullReporter() : reporter;
	}

	public function compile(source:Source):Future<Result<T, CompileError>> {
		var tokens = new Scanner(source).scan();
		var parser = new Parser(tokens);

		return new Future(activate -> {
			switch parser.parse().flatMap(validator.validate) {
				case Error(error):
					reporter.report(error, source);
					activate(Error(error));
				case Ok(nodes):
					generator.generate(source, nodes).handle(result -> {
						switch result {
							case Error(error): reporter.report(error, source);
							default:
						}
						activate(result);
					});
			}
		});
	}
}
