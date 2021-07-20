package boxup;

import haxe.ds.Option;

class Compiler<T> {
  final reporter:Reporter;
  final generator:Generator<T>;
  final validator:Null<Validator>;

  public function new(reporter, generator, ?validator) {
    this.reporter = reporter;
    this.generator = generator;
    this.validator = validator;
  }

  public function compile(source:Source):Option<T> {
    return try {
      var scanner = new Scanner(source);
      var parser = new Parser(scanner.scan());
      var nodes = parser.parse();
      if (validator != null) switch validator.validate(nodes) {
        case Some(error):
          reporter.report(error, source);
          None;
        case None:
          Some(generator.generate(nodes));
      } else Some(generator.generate(nodes));
    } catch (e:Error) {
      reporter.report(e, source);
      None;
    }
  }
}
