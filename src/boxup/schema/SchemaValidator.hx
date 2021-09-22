package boxup.schema;

import boxup.schema.Schema;
import boxup.Builtin;

class SchemaValidator implements Validator {
  static final schema = new Schema('@schema', [
    {
      name: BRoot,
      children: [
        { name: 'root', required: true, multiple: false },
        { name: 'block' }
      ]
    },

    {
      name: 'root',
      children: [
        { name: 'child' },
        { name: 'meta' }
      ]
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
        { name: 'multiple', type: VBool, def: 'false', required: false }
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
      properties: [
        { name: 'value', required: true }
      ]
    },

    {
      name: 'meta',
      id: { required: true },
      type: BPropertyBag
    }
  ], []);

  public function new() {}

  public function validate(nodes:Array<Node>):Result<Array<Node>> {
    return schema.validate(nodes);
  }
}