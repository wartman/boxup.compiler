package boxup.schema;

import haxe.ds.Map;
import boxup.schema.Schema;
import boxup.schema.SchemaId;

abstract SchemaCollection(Map<SchemaId, Schema>) {
	public function new(?collection:Array<Schema>) {
		this = [];
		if (collection != null) for (schema in collection) add(schema);
	}

	public inline function add(schema:Schema) {
		this.set(schema.id, schema);
	}

	public inline function get(id:SchemaId) {
		return this.get(id);
	}
}
