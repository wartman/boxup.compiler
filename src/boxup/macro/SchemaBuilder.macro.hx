package boxup.macro;

import haxe.macro.Context;
import haxe.macro.Expr;
import boxup.schema.Schema;
import boxup.schema.SchemaCompiler;
import boxup.reporter.MacroReporter;

using haxe.macro.Tools;

function create(expr:Expr):Expr {
	var content = switch expr.expr {
		case EConst(CString(content, _)):
			content;
		default:
			Context.error('Expected a string', expr.pos);
			'';
	}
	var posInfo = expr.pos.getInfos();
	var source:Source = {
		file: posInfo.file,
		content: content
	};
	var reporter = new MacroReporter({
		min: posInfo.min,
		max: posInfo.max,
		file: posInfo.file
	});
	var compiler = new SchemaCompiler(reporter);
	return compiler.compile(source).map(schema -> {
		var out = generateSchema(schema);
		return macro $out;
	}).or(() -> macro null);
}

function generateSchema(schema:Schema):Expr {
	var id = schema.id;
	var blocks = schema.getBlocks();
	var meta = schema.getAllMeta();
	var blocksExpr:Array<Expr> = [];

	for (block in blocks) {
		blocksExpr.push(generateBlock(block));
	}

	return macro new boxup.schema.Schema($v{id}, [$a{blocksExpr}], []);
}

function generateBlock(block:BlockDefinition):Expr {
	return macro({
		name: $v{block.name},
		meta: ${generateMeta(block.meta)},
		type: $v{block.type},
		id: ${generateId(block.id)},
		parameters: ${generateParameters(block.parameters)},
		properties: ${generateProperties(block.properties)},
		children: ${generateChildren(block.children)}
	} : boxup.schema.Schema.BlockDefinition);
}

function generateId(id:Null<IdDefintion>) {
	if (id == null) return macro null;
	return macro({
		required: $v{id.required},
		type: $v{id.type},
		parameter: $v{id.parameter}
	} : boxup.schema.Schema.IdDefintion);
}

function generateMeta(metadata:Map<String, String>):Expr {
	var metas:Array<Expr> = [for (key => value in metadata) macro $v{key} => $v{value}];
	return macro [$a{metas}];
}

function generateStringArray(values:Array<String>) {
	var values = [for (value in values) macro $v{value}];
	return macro [$a{values}];
}

function generateParameters(parameters:Array<ParameterDefinition>) {
	var params = [for (param in parameters) generateParameter(param)];
	return macro [$a{params}];
}

function generateParameter(parameter:ParameterDefinition) {
	return macro({
		pos: $v{parameter.pos},
		def: $v{parameter.def},
		type: $v{parameter.type},
		allowedValues: ${generateStringArray(parameter.allowedValues)},
		meta: ${generateMeta(parameter.meta)}
	} : boxup.schema.Schema.ParameterDefinition);
}

function generateProperties(properties:Array<PropertyDefinition>) {
	var props = [for (prop in properties) generateProperty(prop)];
	return macro [$a{props}];
}

function generateProperty(property:PropertyDefinition) {
	return macro({
		name: $v{property.name},
		def: $v{property.def},
		required: $v{property.required},
		type: $v{property.type},
		allowedValues: ${generateStringArray(property.allowedValues)},
		meta: ${generateMeta(property.meta)}
	} : boxup.schema.Schema.PropertyDefinition);
}

function generateChildren(children:Array<ChildDefinition>) {
	var children = [for (child in children) generateChild(child)];
	return macro [$a{children}];
}

function generateChild(child:ChildDefinition) {
	return macro({
		name: $v{child.name},
		required: $v{child.required},
		multiple: $v{child.multiple}
	} : boxup.schema.Schema.ChildDefinition);
}
