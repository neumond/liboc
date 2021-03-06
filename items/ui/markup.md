Markup module works with very simplified HTML.

### Limitations

1. Module contains no parsing code. You have to supply tokens (usually separate words) as array of strings.
    ```lua
    local m = require("ui.markup")
    local text = m.Div(
        m.Div("Lorem", m.Span("ipsum"):class("em"), "dolor", "sit", "amet"),
        m.Div("consectetur", "adipiscing", "elit.")
    )
    local styles = {
        m.Selector({"em"}, {color=0xFF0000})
    }
    local commands = m.markupToGpuCommands(text, {}, styles, 50)
    m.execGpuCommands(gpu, commands)
    ```
1. Styles can be applied only to element classes. You can't use generic `div`, `span`, `*` selectors. You can't use ID selectors as well.
1. The only supported complex selector is class nesting.
    ```lua
    local styles = {
        m.Selector({"main", "content", "infoblock"}, {...})
    }
    ```
    In CSS this would mean `.main .content .infoblock`.
    You can't use other types of selectors like `.main.content`,
    `.main > .content`, `.main + .content`, etc.
1. Only one class per element. To apply several classes use nested elements.
    ```lua
    local text = m.Div(
        m.Div(
            ...
        ):class("content")
    ):class("quote")
    ```
1. Selector specificity isn't calculated at all. Only selector order matter: later overrides ealier.
    ```lua
    local text = m.Span(
        "Lorem",
        m.Span("ipsum"):class("em"),
        "dolor"
    ):class("quote")

    local styles = {
        m.Selector({"quote", "em"}, {color=0xFFFFFF}),
        m.Selector({"quote"}, {color=0xFF0000})
    }
    ```
    Even though first selector is more specific, second overrides it
    and whole text rendered as red. To fix just reorder selectors:
    ```lua
    local styles = {
        m.Selector({"quote"}, {color=0xFF0000}),
        m.Selector({"quote", "em"}, {color=0xFFFFFF})
    }
    ```
1. Currently there are only general block element and general inline element. You must avoid placing blocks inside inlines (as in real HTML), no internal checking done for that case.
1. You have to manually glue tokens together if you want to apply styles to parts of words.
    ```lua
    local text = m.Span(
        "consectetur",
        "adip", m.Glue, m.Span("isc"):class("h"), m.Glue, "ing",
        "elit."
    )
    ```
    `adipiscing` wouldn't be broken into three words.

### Styles

| Name | Meaning | Possible values | Applied to |
| --- | --- | --- | --- |
| `color` | Text color | Hexadecimal 24 bit number | block, inline |
| `background` | Background color | Hexadecimal 24 bit number | block, inline |
| `align` | Text alignment | `left`, `center`, `right` | block |
| `fill` | Filler character | | block |
| `fillcolor` | Color of filler characters | Hexadecimal 24 bit number | block |

### Making horizontal rules

Full line filled with character:

```lua
local hr = m.Div(""):class("hr1")
local s = m.Selector({"hr1"}, {fill="─"})
```

Centered piece of text:

```lua
local hr = m.Div("* * *"):class("hr2")
local s = m.Selector({"hr2"}, {align="center"})
```

### Interactive elements

Interactive elements can't intersect. You _can_ create nested
clickable elements, but if you hover inner element, outer becomes unhovered.

#### Inlines

Inline elements can be clickable
(hover coloring, active coloring, onClick callback function),
but can't change _lengths_ of their tokens.
E.g. you can implement checkboxes by replacing first character of inline element.

```lua
local element = m.Span("[ ]", "Checkbox")
local token = element:getToken(1)

token:getText()
token:setText("[*]")
token:setText("[ ]")

-- but you can't change length!
-- this throws an error
token:setText(1, "[]")
```

It is possible to change colors of tokens:

```lua
token:getInitialColor()
token:getColor()
token:setColor(0xFF0000)

token:getInitialBackground()
token:getBackground()
token:setBackground(0xFF00FF)
```

And even refill spacings:

```lua
local space = element:getSpace(1)
space:getInitialColor()
space:getColor()
space:setColor(0xFF0000)

space:getInitialBackground()
space:getBackground()
space:setBackground(0xFF00FF)

space:getInitialFilling()
space:getFilling()
space:setFilling(".")
```

#### Blocks

Block elements can be clickable as well, but can be extended into custom
controls. Clickable interface works exactly as inline. Additionally you
can change padding/border colors of whole block.

Custom controls _can't_ contain markup. Instead they
implement render method,
implement calcHeight method (when width of markup changes),
receive keyboard events (when active),
mouse events (over this element),
focus/unfocus events
via methods-callbacks.
