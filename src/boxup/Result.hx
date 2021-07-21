package boxup;

import haxe.ds.Option;

@:using(boxup.Result.ResultTools)
enum Result<T> {
  Ok(?data:T);
  Fail(error:Error);
}

class ResultTools {
  public inline static function otherwise<T>(result:Result<T>, value:T):Result<T> {
    return switch result {
      case Ok(_): result;
      case Fail(_): Ok(value);
    }
  }

  public inline static function sure<T>(result:Result<T>):T {
    return switch result {
      case Ok(data): data;
      case Fail(error): throw error;
    }
  }

  public inline static function map<T, R>(result:Result<T>, transform:(data:T)->Result<R>):Result<R> {
    return switch result {
      case Ok(data): transform(data);
      case Fail(error): Fail(error);
    }
  }

  public inline static function mapValue<T, R>(result:Result<T>, transform:(data:T)->R):Result<R> {
    return switch result {
      case Ok(data): Ok(transform(data));
      case Fail(error): Fail(error);
    }
  }

  public inline static function mapError<T>(result:Result<T>, transform:(errors:Error)->Error):Result<T> {
    return switch result {
      case Ok(data): Ok(data);
      case Fail(error): Fail(transform(error));
    }
  }

  public inline static function handleValue<T>(result:Result<T>, handle:(value:T)->Void):Result<T> {
    switch result {
      case Ok(value): handle(value);
      case Fail(_): // noop
    }
    return result;
  }

  public inline static function handleError<T>(result:Result<T>, handle:(err:Error)->Void):Result<T> {
    switch result {
      case Ok(_): // noop
      case Fail(error): handle(error);
    }
    return result;
  }

  public inline static function asOption<T>(result:Result<T>):Option<T> {
    return switch result {
      case Ok(data): Some(data);
      case Fail(_): None;
    }
  }
}
