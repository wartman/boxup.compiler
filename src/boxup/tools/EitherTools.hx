package boxup.tools;

class EitherTools {
	public static function mapLeft<T, R, E>(either:Either<T, E>, transform:(left:T) -> R):Either<R, E> {
		return switch either {
			case Left(v): Left(transform(v));
			case Right(v): Right(v);
		}
	}

	public static function mapRight<T, R, E>(either:Either<E, T>, transform:(right:T) -> R):Either<E, R> {
		return switch either {
			case Left(v): Left(v);
			case Right(v): Right(transform(v));
		}
	}
}
