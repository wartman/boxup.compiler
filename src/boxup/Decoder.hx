package boxup;

interface Decoder<T> {
	public function accepts(node:Node):Bool;
	public function decode(node:Node):Result<T, BoxupError>;
}
