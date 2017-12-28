local utils = require("utils")
local SimpleInlineControl = require("ui.baseControls").SimpleInlineControl


local ClickableControl = utils.makeClass(SimpleInlineControl)


function ClickableControl:onClick()
    error("Not implemented")
end


function ClickableControl:onFocus()
    local hlColor = 0xFF8000
    for i=1,self:getTokenCount() do
        local token
        token = self:getToken(i)
        token:setBackground(hlColor)
        token = self:getSpaceBeforeToken(i)
        if token ~= nil then token:setBackground(hlColor) end
    end
end


function ClickableControl:onBlur()
    for i=1,self:getTokenCount() do
        local token
        token = self:getToken(i)
        token:setBackground(token:getInitialBackground())
        token = self:getSpaceBeforeToken(i)
        if token ~= nil then token:setBackground(token:getInitialBackground()) end
    end
end


function ClickableControl:onTouch(x, y, button, playerName)
    -- TODO: only left button
    self:onClick()
    return true
end


function ClickableControl:onKeyDown(char, code, playerName)
    if code == 28 then self:onClick() end
    return false
end


-- Link


local Link = utils.makeClass(ClickableControl, function(self, super, callback, ...)
    super(...)
    self.callback = callback
end)


function Link:onClick()
    self.callback()
end


-- CheckBox


local CheckBox = utils.makeClass(ClickableControl, function(self, super, ...)
    self.checked = false
    super(self.states[self.checked], ...)
end)


CheckBox.states = {[false]="☐", [true]="☑"}


function CheckBox:isChecked()
    return self.checked
end


function CheckBox:setChecked(value)
    self.checked = value
    self:getToken(1):setText(self.states[self.checked])
end


function CheckBox:onClick()
    self:setChecked(not self.checked)
end


-- RadioButton


local RadioButton = utils.makeClass(ClickableControl, function(self, super, radioGroup, ...)
    self.selected = false
    super(self.states[self.selected], ...)
    self.radioGroup = radioGroup
    self.radioId = radioGroup:register(self)
end)


RadioButton.states = {[false]="○", [true]="◉"}


function RadioButton:isSelected()
    return self.selected
end


function RadioButton:setSelected(value)
    if value == self.selected then return end
    self.selected = value
    self:getToken(1):setText(self.states[true])
    if value then
        self.radioGroup:onSelect(self.radioId)
    else
        self.radioGroup:onDeselect(self.radioId)
    end
end


function RadioButton:onClick()
    self:setSelected(true)
end


function RadioButton:getId()
    return self.radioId
end


-- RadioGroup


local RadioGroup = utils.makeClass(function(self)
    self.id = 0
    self.buttons = {}
    self.selected = nil
end)


function RadioGroup:register(radioButton)
    self.id = self.id + 1
    self.buttons[self.id] = radioButton
    return self.id
end


function RadioGroup:onSelect(id)
    if id == self.selected then return end
    self.buttons[self.selected]:setSelected(false)
    self.selected = id
end


function RadioGroup:onDeselect(id)
    if id ~= self.selected then return end
    self.selected = nil
end


return {
    Link=Link,
    CheckBox=CheckBox,
    RadioButton=RadioButton,
    RadioGroup=RadioGroup
}
