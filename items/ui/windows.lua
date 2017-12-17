local utils = require("utils")


--


local Surface = utils.makeClass(function(self)
    -- Represents constrained part of screen capable of outputting Elements
    -- Can scroll vertically over its contents
    self.element = nil
end)


function Surface:changeWidth()
end

--


local VSplitter = utils.makeClass(function(self)
end)


local HSplitter = utils.makeClass(function(self)
end)
