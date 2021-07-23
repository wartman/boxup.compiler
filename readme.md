[boxup]
=======

Simple, structured markup.

About
-----

> Note: this is a rework of [the original Boxup](https://github.com/wartman/boxup), a project that quickly got out of scope and became far too complex. This refactor aims to keep things simpler.

Boxup is a markup language, designed for situations where Markdown doesn't provide enough structure but where something like XML would be too cumbersome. In addition, it has schemas built in to its compiler.

```boxup
[/ Comments look like this! /]

[article]
  title = Hello world!
  slug = hello_world

[section one]
  css = "
    width: 100%;
    background: blue;
  "

  [header Hey World!]

  Boxup is a very simple markup language based 
  around square brackets and indentation.

  It has *bold text*, _italic text_ and you 
  can <tag stuff>[example This is a tag!] too.
```

```boxup
[/ A possible schema for the above: /]

[schema example]

[root]
  [child article]
    required = true
  [child section]
  [child paragraph]

[block paragraph]
  type = Paragraph
  [child example]

[block example]
  type = Tag
  [id]
    required = true

[block article]
  [property title]
    required = true
  [property slug]

[block section]
  [id]
    required = true
  [property css]
  [child header]
  [child paragraph]

[block header]
  [id]
    required = true
```
