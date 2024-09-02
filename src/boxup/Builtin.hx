package boxup;

// @todo: Consider a better way to handle this.
enum abstract Builtin(String) from String to String {
	var BItalic = '@italic';
	var BBold = '@bold';
	var BRaw = '@raw';
}
