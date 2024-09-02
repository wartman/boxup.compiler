package boxup;

import haxe.Exception;

class BoxupError extends Exception {
	public final pos:Position;
	public final detailedMessage:Null<String>;

	public function new(message, ?detailedMessage, ?pos) {
		super(message);
		this.detailedMessage = detailedMessage;
		this.pos = pos != null ? pos : Position.unknown();
	}

	override function toString() {
		return '${super.toString()} : ${pos.file} ${pos.min} ${pos.max}';
	}
}
