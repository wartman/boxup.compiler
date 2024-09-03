import boxup.*;
import boxup.decoder.HtmlDecoder;
import boxup.reporter.VisualReporter;

function main() {
	var content = '
[/ Comments look like this! /]

[section main-section]
styles = "width: 100%;background: blue;"

  [div "one"]
    [header]
    class="section-header" 
      [h1] Boxup!
  Boxup is a very simple markup language based
  around square brackets and indentation.


    [div class="inner"]
    It has *bold text*, _italic text_ and you
    can <tag stuff>[a href="some/url"] too.
  
  [div two]
    [header]
      [h2] About
  It is pretty flexible!
';

	// @todo: oops doesn't work
	var source:Source = {content: content, file: '<test>'};
	var reporter = new VisualReporter();

	Parser.fromSource(source)
		.parse()
		.flatMap(HtmlDecoder.instance().decode)
		.inspect(html -> trace(html))
		.inspectError(error -> reporter.report(error, source));
}
