import haxe.Json;
import boxup.schema.SchemaCollection;
import boxup.schema.SchemaAwareValidator;
import boxup.schema.SchemaGenerator;
import boxup.schema.SchemaValidator;
import boxup.generator.JsonGenerator;
import boxup.reporter.VisualReporter;
import boxup.Compiler;
import boxup.Source;

function main() {
  var source:Source = {
    file: 'test.box',
    content: '
[schema test]

[root]
  [child paragraph]
  [child header]
  [child tester]

[block header]
  [parameter]
    [meta schema error="Requires a title"]
  [parameter type = Int]
    [meta schema error="Requires a priority number"]
  [property type]
  
[block paragraph type=Paragraph]
  [child link]

[block link type=Tag]
  [property href required = true]

[block tester]
  [property foo]
    [option value = bar]
    [option value = foo]
  [child paragraph]
'
  };
  var reporter = new VisualReporter();
  var compiler = new Compiler(
    new SchemaGenerator(),
    new SchemaValidator(),
    reporter
  );
  compiler
    .compile(source)
    .map(def -> {
      var compiler = new Compiler(
        new JsonGenerator(), 
        new SchemaAwareValidator(new SchemaCollection([ def ])), 
        reporter);
      var source:Source = {
        file: 'foo.box',
        content: '
[use test]

YAMS and stuff.
[header "foo bar bin" 1 type=foo]
How is things?

[tester]
  foo = bar
  
  And _this <works>[link href="https://www.foo.bar"]_ too!
'
      };

      compiler.compile(source);
    })
    .handleError(_ -> {
      Sys.println('Compile failed');
      Sys.exit(1);
    })
    .handleValue(value -> {
      trace(Json.stringify(value, '  '));
      Sys.print('Compile succeeded');
      Sys.exit(0);
    });
}
