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

    // @todo: no idea why the +2 is needed here, but it works.
    // I'd really like to figure out why.
    var min = realPosition.min + error.pos.min + 2;
    var max = realPosition.min + error.pos.max + 2;

    var pos = Context.makePosition({
      min: min,
      max: max,
      file: realPosition.file
    });

    Context.error(error.message, pos);
  }
}
