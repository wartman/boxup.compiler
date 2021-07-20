package boxup.definition;

import boxup.definition.Definition.ValueType;
import boxup.definition.Definition.BlockDefinitionType;
import boxup.Builtin;
import haxe.ds.Option;

class DefinitionValidator implements Validator {
  static final definition = new Definition('d', [
    {
      name: BRoot,
      children: [
        { name: 'definition', required: true, multiple: false },
        { name: 'root', required: true, multiple: false },
        { name: 'block' }
      ]
    },

    {
      name: 'definition',
      id: { required: false },
      children: [
        { name: 'import' },
        { name: 'meta' }
      ]
    },

    {
      name: 'root',
      children: [
        { name: 'child' }
      ]
    },

    {
      name: 'import',
      id: { required: true }
    },

    {
      name: 'block',
      id: { required: true },
      properties: [
        { name: 'type', type: VString, required: false, allowedValues: [
          BlockDefinitionType.BTag,
          BlockDefinitionType.BNormal,
          BlockDefinitionType.BParagraph,
          BlockDefinitionType.BPropertyBag,
          BlockDefinitionType.BDynamicChildren
        ] }
      ],
      children: [
        { name: 'id', multiple: false },
        { name: 'child' },
        { name: 'property' },
        { name: 'meta' }
      ]
    },

    {
      name: 'id',
      properties: [
        { name: 'required', type: VBool, required: false },
        { name: 'type', type: VString, required: false, def: ValueType.VString, allowedValues: [
          ValueType.VString,
          ValueType.VAny,
          ValueType.VInt,
          ValueType.VFloat,
          ValueType.VBool
        ] }
      ]
    },

    {
      name: 'child',
      id: { required: true },
      properties: [
        { name: 'required', type: VBool, required: false },
        { name: 'multile', type: VBool, def: 'false', required: false }
      ]
    },

    {
      name: 'property',
      id: { required: true },
      properties: [
        { name: 'type', type: VString, required: false, def: ValueType.VString, allowedValues: [
          ValueType.VString,
          ValueType.VAny,
          ValueType.VInt,
          ValueType.VFloat,
          ValueType.VBool
        ] },
        { name: 'required', type: VBool, required: false },
        { name: 'default', type: VAny, required: false }
      ],
      children: [
        { name: 'option' }
      ]
    },

    {
      name: 'option',
      id: { required: true, type: VAny }
    },

    {
      name: 'meta',
      id: { required: true },
      type: BPropertyBag
    }
  ], []);

  public function new() {}

  public function validate(nodes:Array<Node>):Option<Error> {
    return definition.validate(nodes);
  }
}