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
  [child article required = true]
  [child section]
  [child paragraph]

[block paragraph]
  [/ Properties do not need to be defined in the block header: /]
  type = Paragraph
  [child example]

[block example type=Tag]
  [property content]
    required = true

[block article]
  [property title required=true]
  [property slug]

[block section]
  [/ In addition to properties, you can define
   / "parameters" on your blocks. In Boxup, parameters
   / are *positional* rather than *named* properties,
   / which can be handy in some situations.
   /
   / Parameters *must* come before properties in a block header and 
   / they are space-delimited. 
   /
   / Also note that parameters are ALWAYS required (at least for now).
   /]
  [parameter type=String]
  [property css]
  [child header]
  [child paragraph]

[block header]
  [child paragraph required = true]
```
