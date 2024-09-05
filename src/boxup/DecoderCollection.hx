package boxup;

class DecoderCollection<T> implements Decoder<T> {
	final decoders:Array<Decoder<T>>;

	public function new(decoders) {
		this.decoders = decoders;
	}

	public function accepts(node:Node):Bool {
		for (decoder in decoders) if (decoder.accepts(node)) return true;
		return false;
	}

	public function decode(node:Node):Result<T, BoxupError> {
		for (decoder in decoders) if (decoder.accepts(node)) return decoder.decode(node);
		return Error(new BoxupError('No decoder found', node.pos));
	}
}
