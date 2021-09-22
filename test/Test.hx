import boxup.schema.SchemaCollection;
import boxup.schema.SchemaAwareValidator;
import haxe.Json;
import boxup.generator.JsonGenerator;
import boxup.generator.NullGenerator;
import boxup.schema.SchemaGenerator;
import boxup.schema.SchemaValidator;
import boxup.reporter.VisualReporter;
import boxup.Compiler;
import boxup.Source;

function main() {
  var source:Source = {
    file: 'test.box',
    content: '
[schema test]

[root]
  [child id = paragraph]
  [child id = header]
  [child id = tester]

[block id = header]
  [id required = true]
  
[block id = paragraph]
  type = Paragraph
  [child id = link]

[block id = link]
  type = Tag
  [property id = href required = true]

[block id = tester]
  [property id = foo]
    [option value = bar]
    [option value = foo]
  [child id = paragraph]
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
[header id = "foo bar bin"]
How is things?

[tester]
  foo = bar
  
  And _this <works>[link "https://www.foo.bar"]_ too!
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
