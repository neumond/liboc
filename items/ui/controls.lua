local utils = require("utils")
local markupModule = require("ui.markup")


-- Control


local Control = utils.makeClass()


Control._isControl = true


-- returning false from following methods means
-- parent element/UI must process this event
-- returning true captures the event in this control


function Control:onKeyDown(char, code, playerName)
    return false
end


function Control:onKeyUp(char, code, playerName)
    return false
end


function Control:onTouch(x, y, button, playerName)
    return false
end


function Control:onDrag(x, y, button, playerName)
    return false
end


function Control:onDrop(x, y, button, playerName)
    return false
end


function Control:onScroll(x, y, direction, playerName)
    return false
end


function Control:isFocusable()
    return false
end


function Control:onFocus()
end


function Control:onBlur()
end


-- TokenControl


local TokenControl = utils.makeClass()


function TokenControl:getInitialText()
end


function TokenControl:getText()
end


function TokenControl:setText(text)
end


function TokenControl:getInitialColor()
end


function TokenControl:getColor()
end


function TokenControl:setColor(color)
end


function TokenControl:getInitialBackground()
end


function TokenControl:getBackground()
end


function TokenControl:setBackground(color)
end


-- SimpleInlineControl
-- can span across multiple lines, just like usual Span
-- have limited control over its tokens
-- without ability to change their length
-- suitable for checkboxes, radiobuttons, clickable links


local SimpleInlineControl = utils.makeClass(Control, markupModule.Span)


function SimpleInlineControl:getToken(n)
    -- returns TokenControl
end


function SimpleInlineControl:getTokenCount()
end


function SimpleInlineControl:getSpaceBeforeToken(n)
    -- returns TokenControl or nil
end


function SimpleInlineControl:getSpaceAfterToken(n)
    -- returns TokenControl or nil
end


-- RenderableControl
-- occupies contiguous block
-- has gpu proxy to render arbitrary contents


local RenderableControl = utils.makeClass(Control)


function RenderableControl:render(gpu, width, height)
    error("Not implemented")
end


-- InlineControl
-- full weight inline control
-- suitable for textual inputs, comboboxes, buttons
-- has fixed width and height of 1


InlineControl = utils.makeClass(RenderableControl, markupModule.Span, function(self, rcSuper, spanSuper, width)
    rcSuper()
    spanSuper(string.rep(" ", width))
    self.width = width
end)


-- BlockControl
-- can have any height
-- can be resized when width of parent layout changes


local BlockControl = utils.makeClass(RenderableControl, markupModule.Div)


function BlockControl:calcHeight(width)
    error("Not implemented")
end
