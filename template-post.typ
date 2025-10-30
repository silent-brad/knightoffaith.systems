#set text(font: "Athelas")
#show heading.where(level: 1): set text(font: "Apple Chancery")

#show raw: set text(font: "Fira Code")
#show raw.where(block: true): set text(1em / 0.8)
#set raw(theme: "rose-pine-moon.tmTheme")
#show raw: it => block(
  fill: rgb("#232136"),
  inset: 8pt,
  radius: 5pt,
  text(fill: rgb("#a2aabc"), it)
)

#show quote.where(block: true): block.with(stroke: (left:2pt + gray, rest: none))

= Code Example

//#quote(block:true, lorem(50))

//#link("/code-example.pdf")[Link to PDF of this page]
//#link("/code-example.md")[Link to Markdown of this page]

