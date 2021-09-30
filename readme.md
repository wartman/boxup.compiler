[boxup]
=======

Simple, structured markup.

About
-----

> Note: this is a rework of [the original Boxup](https://github.com/wartman/boxup), a project that quickly got out of scope and became far too complex. This refactor aims to keep things simpler.

Boxup is a markup language, designed for situations where Markdown doesn't provide enough structure but where something like XML would be too cumbersome. In addition, it has schemas built in to its compiler.

```boxup
[/ Comments look like this! /]

[/ Boxup has a few special keywords -- `use` is one of them. 
 / It can be used to tell the compiler which schema to use (although
 / this is an implementation detail)
 /]
[use example]

[article]
  title = Hello world!
  slug = hello_world

[section one]
  css = "
    width: 100%;
    background: blue;
  "

  [header]
    Hey World!

  Boxup is a very simple markup language based 
  around square brackets and indentation.

  It has *bold text*, _italic text_ and you 
  can <tag stuff>[example content="This is a tag!"] too.
```

```boxup
[/ A possible schema for the above: /]

[/ The `schema` keyword optionally names the schema. /]
[schema example]

[root]
  [child id=article]
    required = true
  [child id=section]
  [child id=paragraph]

[block id=paragraph]
  type = Paragraph
  [child id=example]

[block id=example type=Tag]
  [property id=content]
    required = true

[block id=article]
  [/ In addition to properties, you can define
   / "parameters" on your blocks. In Boxup, parameters
   / are *positional* rather than *named* properties,
   / which can be handy in some situations.
   /
   / Parameters *must* come before properties in a block header and 
   / they are space-delimited. 
   /]
  [parameter pos=1 required = true]
  [property id=slug]

[block id=section]
  [id]
    required = true
  [property id=css]
  [child id=header]
  [child id=paragraph]

[block id=header]
  [child id=paragraph required = true]
```
