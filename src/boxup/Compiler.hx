package boxup;

import boxup.reporter.NullReporter;
import boxup.validator.NullValidator;

class Compiler<T> {
  final generator:Generator<T>;
  final validator:Validator;
  final reporter:Reporter;

  public function new(generator, ?validator, ?reporter) {
    this.generator = generator;
    this.validator = validator == null 
      ? new NullValidator()
      : validator;
    this.reporter = reporter == null
      ? new NullReporter()
      : reporter;
  }

  public function compile(source:Source):Result<T> {
    return Scanner.scan(source)
      .map(Parser.parse)
      .map(validator.validate)
      .map(generator.generate)
      .handleError(e -> reporter.report(e, source));
  }
}
