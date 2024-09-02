import boxup.*;
import boxup.decoder.HtmlDecoder;
import boxup.reporter.VisualReporter;

function main() {
	var content = '
[/ Comments look like this! /]

[section id=one]
class = "main-section"
styles = "width: 100%;background: blue;"

  [div class="one"]
    [header]
      class="section-header" 
      [h1] Boxup!
  Boxup is a very simple markup language based
  around square brackets and indentation.

  [header]
  Hey World!

    [div class="inner"]
    It has *bold text*, _italic text_ and you
    can <tag stuff>[a href="some/url"] too.
  
  [div class="two"]
  It is pretty flexible!
';

	// @todo: oops doesn't work
	var source:Source = {content: content, file: '<test>'};
	var reporter = new VisualReporter();
	var tokens = new Scanner(source).scan();

	new Parser(tokens).parse()
		.flatMap(HtmlDecoder.instance().decode)
		.inspect(html -> trace(html))
		.inspectError(error -> reporter.report(error, source));
}
