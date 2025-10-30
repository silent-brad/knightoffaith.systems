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

#quote(block:true, lorem(50))

#link("/code-example.pdf")[Link to PDF of this page]
#link("/code-example.md")[Link to Markdown of this page]

== This is a code example.

```js
function add(a, b) {
  return a + b;
}
```

== And this is another code example.

```rs
fn add(a: i32, b: i32) -> i32 {
  a + b
}
```

== And some glorious Haskell code

```hs
add :: Int -> Int -> Int
add a b = a + b

myMap :: [a] -> (a -> b) -> [b]
myMap [] _ = []
myMap x:xs fn =
  fn x:myMap xs fn

fib :: Int -> Int
fib 0 = 0
fib 1 = 1
fib x = fib (x - 1) + fib (x - 2)
```

== More examples

=== Lua
```lua
function fib(num)
  if num < 2 then
    return 1
  else
    return fib(x - 1) + fib(x - 2)
  end
end
```

=== Elixir
```elixir
def fib(x) when x < 2
  return x
end
def fib(x) when x >= 2
  return fib(x - 1) + fib(x - 2)
end
```

=== Nim
```nim
func fib(x: Int): Int =
  case x
    of 0: 0
    of 1: 1
    else: fib(x - 1) + fib(x - 2)
```

=== Go
```go
func fib(x int) int {
  if x < 2 {
    return x
  } else {
    return fib(x - 1) + fib(x - 2)
  }
}
```

