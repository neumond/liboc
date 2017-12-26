local borderMod = require("ui.borders")


local trackerConfig = {}
local copyMap = {}
local borderCopyMap = {}
do
    for _, side in ipairs({"Left", "Right", "Top", "Bottom"}) do
        for _, prop in ipairs({"margin", "padding", "border"}) do
            trackerConfig[prop .. side] = true
        end
        for _, prop in ipairs({"margin", "padding"}) do
            copyMap[prop .. side] = true
        end
        borderCopyMap["border" .. side] = true
    end
end


local function copyBoxStyles(styles)
    local box = {}
    for k, _ in pairs(copyMap) do
        box[k] = styles[k]
    end
    for k, _ in pairs(borderCopyMap) do
        box[k] = borderMod.getBorderWidth(styles[k])
    end
    return box
end


local function boxShrink(box)
    return (
          box.marginLeft
        + box.marginRight
        + box.borderLeft
        + box.borderRight
        + box.paddingLeft
        + box.paddingRight
    )
end


local function makeBox(styles, screenWidth)
    local box = copyBoxStyles(styles)
    box.contentWidth = screenWidth - boxShrink(box)
    box.borderChars = borderMod.getBorderFillChars(
        styles.borderTop, styles.borderRight,
        styles.borderBottom, styles.borderLeft)
    return box
end


return {
    makeBox=makeBox,
    trackerConfig=trackerConfig
}
