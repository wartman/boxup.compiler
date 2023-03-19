package boxup.reporter;

import haxe.macro.Context;

class MacroReporter implements Reporter {
  final realPosition:Position;
  final externalReporter:Reporter;

  public function new(pos) {
    this.realPosition = pos;
    this.externalReporter = new VisualReporter(str -> {
      Context.error(str, Context.currentPos());
    });
  }

  public function report(error:Error, source:Source) {
    if (source.file != realPosition.file) {
      externalReporter.report(error, source);
      return;
    }

    var min = realPosition.min + error.pos.min + 1;
    var max = realPosition.min + error.pos.max + 1;

    var pos = Context.makePosition({
      min: min,
      max: max,
      file: realPosition.file
    });

    Context.error(error.message, pos);
  }
}
