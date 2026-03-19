package boxup.tools;

class OptionTools {
	public static function map<T, R>(option:Option<T>, transform:(value:T) -> R):Option<R> {
		return switch option {
			case Some(v): Some(transform(v));
			case None: None;
		}
	}
}
