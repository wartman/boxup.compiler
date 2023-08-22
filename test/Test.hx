import boxup.loader.FileSystemLoader;
import haxe.Json;
import boxup.schema.*;
import boxup.generator.JsonGenerator;
import boxup.reporter.VisualReporter;
import boxup.Compiler;
import boxup.Source;

using haxe.io.Path;

function main() {
	load();
}

function load() {
	var loader = new FileSystemLoader(Path.join([Sys.getCwd(), 'test/schema']));
	var reporter = new VisualReporter();
	var validator = new SchemaLoadingValidator(new SchemaCompiler(reporter, loader));
	var compiler = new Compiler(new JsonGenerator(), validator, reporter);
	var source:Source = {
		file: 'foo.box',
		content: '
[use root]

YAMS and stuff.
[header "foo bar bin" 1 type=foo]
How is things?

[tester]
  foo = bar

And _this <works>[link href="https://www.foo.bar"]_ too!
'
	};

	compiler.compile(source).handle(result -> {
		result.mapError(_ -> {
			Sys.println('Compile failed');
			Sys.exit(1);
		}).map(value -> {
			trace(Json.stringify(value, '  '));
			Sys.print('Compile succeeded');
			Sys.exit(0);
		});
	});
}

function noLoad() {
	// Note: `Schema.create` is a macro that builds a schema from a given
	// string. It will be validated and will display errors right in your
	// editor.
	var schema = Schema.create('
  [schema test]

  [/ A "group" is a kind of mixin. Right now it\'s just for children. /]
  [group content]
    [child paragraph]
    [child header]
    [child tester]

  [root]
    [extend content]

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
');

	var reporter = new VisualReporter();
	var validator = new SchemaPreLoadedValidator(new SchemaCollection([schema]));
	// var validator = new NullValidator();
	var compiler = new Compiler(new JsonGenerator(), validator, reporter);
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

	compiler.compile(source).handle(result -> {
		result.mapError(_ -> {
			Sys.println('Compile failed');
			Sys.exit(1);
		}).map(value -> {
			trace(Json.stringify(value, '  '));
			Sys.print('Compile succeeded');
			Sys.exit(0);
		});
	});
}
