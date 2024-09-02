[boxup]
=======

Simple, structured markup.

About
-----

Boxup is a markup language, designed for situations where Markdown doesn't provide enough structure but where something like XML would be too cumbersome.

At a first glance, it can look very similar to TOML:

```boxup
[header]
config-one = Some value (no need for quotes!)
config-two = Some other value
```

...however it has many more features, including markdown-like syntax for paragraphs and nestable blocks, meaning it's useful as a more structured markup replacement:

```boxup
[/ Comments look like this! /]

[article]
title = Hello world!
slug = hello_world

[section one class="foo"]
css = "
  width: 100%;
  background: blue;
"

  [/ This block is indented, which means it's a child of the `section` node: /]
  [header]
  Hey World!

Boxup is a very simple markup language based 
around square brackets and indentation.

It has *bold text*, _italic text_ and you 
can <tag stuff>[example content="This is a tag!"] too.
```
