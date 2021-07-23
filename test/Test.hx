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
  [child paragraph]
  [child header]
  [child tester]

[block header]
  [id] required = true
  
[block paragraph]
  type = Paragraph
  [child link]

[block link]
  type = Tag
  [id]
    required = true

[block tester]
  [property foo]
    [option bar]
    [option foo]
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
      var compiler = new Compiler(new NullGenerator(), def, reporter);
      var source:Source = {
        file: 'foo.box',
        content: '
YAMS and stuff.
[header foo bar bin]
How is things?

[tester]
  foo = bar
  
  And this <works>[link https://www.foo.bar] too!
'
      };

      compiler.compile(source);
    })
    .handleError(_ -> {
      Sys.println('Compile failed');
      Sys.exit(1);
    })
    .handleValue(_ -> {
      Sys.print('Compile succeeded');
      Sys.exit(0);
    });
}
