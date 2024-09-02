package boxup;

abstract DecoderCollection<T>(Array<Decoder<T>>) from Array<Decoder<T>> {
	public function new(decoders) {
		this = decoders;
	}

	public function decode(node:Node):Result<T, BoxupError> {
		for (decoder in this) {
			if (decoder.accepts(node)) return decoder.decode(node);
		}
		return Error(new BoxupError('Invalid node', 'Could not find an acceptable decoder', node.pos));
	}
}
