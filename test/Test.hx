import haxe.Json;
import boxup.generator.NullGenerator;
import boxup.definition.DefinitionGenerator;
import boxup.definition.DefinitionValidator;
import boxup.reporter.VisualReporter;
import boxup.Compiler;
import boxup.Source;

function main() {
  var source:Source = {
    file: 'test.box',
    content: '
[definition test]

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
  var reporter = new VisualReporter(str -> trace(str));
  var compiler = new Compiler(
    reporter,
    new DefinitionGenerator(),
    new DefinitionValidator()
  );
  switch compiler.compile(source) {
    case Some(def):
      var compiler = new Compiler(reporter, new NullGenerator(), def);
      switch compiler.compile({
        file: 'foo.box',
        content: '
YAMS and stuff.
[header foo]
How is things?

[tester]
  foo = bar
  
  And this <works>[link https://www.foo.bar] too!
'
      }) {
        case Some(nodes): trace(Json.stringify(nodes, '  '));
        default: trace('error encountered');
      }
    case None: trace('Error encountered');
  }
}
