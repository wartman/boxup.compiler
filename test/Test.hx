import boxup.Compiler;
import boxup.generator.JsonGenerator;
import boxup.loader.FileSystemLoader;
import boxup.reporter.VisualReporter;
import boxup.schema.*;
import haxe.Json;

using haxe.io.Path;

function main() {
	load();
}

function load() {
	var loader = new FileSystemLoader(Path.join([Sys.getCwd(), 'test']));
	var reporter = new VisualReporter();
	var validator = new SchemaAwareValidator(new SchemaCompiler(reporter, loader));
	var compiler = new Compiler(new JsonGenerator(), validator, reporter, loader);

	compiler.load('data.foo').handle(result -> {
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
