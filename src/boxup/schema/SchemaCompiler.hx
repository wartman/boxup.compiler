package boxup.schema;

class SchemaCompiler extends Compiler<Schema> {
  public function new(reporter) {
    super(
      new SchemaGenerator(),
      new SchemaValidator(),
      reporter
    );
  }
}
