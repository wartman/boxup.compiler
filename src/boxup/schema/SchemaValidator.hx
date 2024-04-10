package boxup.schema;

import boxup.schema.Schema;
import boxup.Builtin;

class SchemaValidator implements Validator {
	static final schema = new Schema('@schema', [
		{
			name: BRoot,
			children: [
				{name: 'root', required: true, multiple: false},
				{name: 'schema', required: true, multiple: false},
				{name: 'group'},
				{name: 'block'}
			]
		},
		{
			name: 'schema',
			parameters: [{pos: 0, type: VString}],
			children: [{name: 'use', required: false, multiple: true}]
		},
		{
			name: 'use',
			parameters: [{pos: 0, type: VString}]
		},
		{
			name: 'root',
			children: [{name: 'child'}, {name: 'extend'}, {name: 'meta'}]
		},
		{
			name: 'group',
			parameters: [{pos: 0, type: VString}],
			children: [{name: 'child'}]
		},
		{
			name: 'extend',
			parameters: [{pos: 0, type: VString}]
		},
		{
			name: 'block',
			parameters: [{pos: 0, type: VString}],
			properties: [
				{
					name: 'type',
					type: VString,
					required: false,
					allowedValues: [
						BlockDefinitionType.BTag,
						BlockDefinitionType.BNormal,
						BlockDefinitionType.BParagraph,
						BlockDefinitionType.BPropertyBag,
						BlockDefinitionType.BDynamicChildren
					]
				}
			],
			children: [
				{name: 'id', multiple: false},
				{name: 'extend'},
				{name: 'child'},
				{name: 'parameter'},
				{name: 'property'},
				{name: 'meta'}
			]
		},
		{
			name: 'child',
			parameters: [{name: 'name', pos: 0, type: VString}],
			properties: [
				{name: 'required', type: VBool, required: false},
				{
					name: 'multiple',
					type: VBool,
					def: 'false',
					required: false
				}
			]
		},
		{
			name: 'parameter',
			parameters: [{name: 'name', pos: 0, type: VString}],
			properties: [
				{
					name: 'type',
					type: VString,
					required: false,
					def: ValueType.VString,
					allowedValues: [
						ValueType.VString,
						ValueType.VAny,
						ValueType.VInt,
						ValueType.VFloat,
						ValueType.VBool
					]
				},
				{name: 'default', type: VAny, required: false}
			],
			children: [{name: 'meta'}, {name: 'option'}]
		},
		{
			name: 'property',
			parameters: [{pos: 0, type: VString}],
			properties: [
				{
					name: 'type',
					type: VString,
					required: false,
					def: ValueType.VString,
					allowedValues: [
						ValueType.VString,
						ValueType.VAny,
						ValueType.VInt,
						ValueType.VFloat,
						ValueType.VBool
					]
				},
				{name: 'required', type: VBool, required: false},
				{name: 'default', type: VAny, required: false}
			],
			children: [{name: 'meta'}, {name: 'option'}]
		},
		{
			name: 'option',
			properties: [{name: 'value', required: true}]
		},
		{
			name: 'meta',
			parameters: [{pos: 0, type: VString}],
			type: BPropertyBag
		}
	], []);

	public function new() {}

	public function validate(nodes:Array<Node>):Result<Array<Node>, CompileError> {
		return schema.validate(nodes);
	}
}
