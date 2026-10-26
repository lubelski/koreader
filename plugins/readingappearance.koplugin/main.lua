local BottomContainer = require("ui/widget/container/bottomcontainer")
local ButtonDialog = require("ui/widget/buttondialog")
local Device = require("device")
local Event = require("ui/event")
local Menu = require("ui/widget/menu")
local UIManager = require("ui/uimanager")
local WidgetContainer = require("ui/widget/container/widgetcontainer")
local _ = require("gettext")
local Screen = Device.screen

-- Preview only touches the renderer. ReaderFont/Configurable retain the committed
-- values, so an autosave during preview cannot persist the draft appearance.
local Appearance = WidgetContainer:extend{
    name = "readingappearance",
    is_doc_only = true,
}

local Sheet = ButtonDialog:extend{}
function Sheet:init()
    ButtonDialog.init(self)
    self[1] = BottomContainer:new{ dimen = Screen:getSize(), self.movable }
end
function Sheet:onCloseWidget()
    self.owner:finish(false)
    ButtonDialog.onCloseWidget(self)
end

function Appearance:init()
    self.ui.menu:registerToMainMenu(self)
end

function Appearance:addToMainMenu(items)
    items.reading_appearance = {
        text = _("Reading appearance (experimental)"),
        sorting_hint = "typeset",
        enabled_func = function() return not self.ui.document.info.has_pages end,
        callback = function()
            -- Let TouchMenu close before displaying our independent sheet.
            UIManager:nextTick(function() self:showSheet() end)
        end,
    }
end

function Appearance:render(values)
    self.ui.document:setFontFace(values.font)
    self.ui.document:setFontSize(Screen:scaleBySize(values.size))
    self.ui.document:setInterlineSpacePercent(values.spacing)
    self.ui:handleEvent(Event:new("UpdatePos"))
end

function Appearance:finish(apply)
    if not self.original then return end
    local values = apply and self.draft or self.original
    if apply then
        self.ui.font.font_face = values.font
        self.ui.font.configurable.font_size = values.size
        self.ui.font.configurable.line_spacing = values.spacing
    end
    self:render(values)
    self.original = nil
    self.draft = nil
    self.sheet = nil
end

function Appearance:refresh()
    self:render(self.draft)
    self.sheet:getButtonById("font"):setText(self.draft.font)
    self.sheet:getButtonById("size"):setText(tostring(self.draft.size))
    self.sheet:getButtonById("spacing"):setText(self.draft.spacing .. "%")
    UIManager:setDirty(self.sheet, "ui")
end

function Appearance:chooseFont()
    local items = {}
    local faces = require("document/credocument"):engineInit().getFontFaces()
    table.sort(faces)
    local picker
    for _, face in ipairs(faces) do
        table.insert(items, {
            text = face,
            callback = function()
                self.draft.font = face
                UIManager:close(picker)
                self.picker = nil
                self:refresh()
            end,
        })
    end
    picker = Menu:new{
        title = _("Font · This book"),
        width = math.floor(Screen:getWidth() * 0.85),
        height = math.floor(Screen:getHeight() * 0.55),
        item_table = items,
        close_callback = function() self.picker = nil end,
    }
    self.picker = picker
    UIManager:show(picker)
end

function Appearance:showSheet()
    if self.sheet or self.ui.document.info.has_pages then return end
    local font = self.ui.font
    self.original = {
        font = font.font_face,
        size = font.configurable.font_size,
        spacing = font.configurable.line_spacing,
    }
    self.draft = {
        font = self.original.font,
        size = self.original.size,
        spacing = self.original.spacing,
    }
    local function adjust(key, delta, min, max)
        self.draft[key] = math.max(min, math.min(max, self.draft[key] + delta))
        self:refresh()
    end
    local function close(apply)
        local sheet = self.sheet
        self:finish(apply)
        UIManager:close(sheet)
    end
    self.sheet = Sheet:new{
        owner = self,
        width = math.floor(Screen:getWidth() * 0.94),
        title = _("Reading appearance · This book\nLive preview — defaults are unchanged"),
        buttons = {
            {
                { text = _("Font"), enabled = false },
                { text = self.draft.font, id = "font", callback = function() self:chooseFont() end },
            },
            {
                { text = _("Size"), enabled = false },
                { text = "−", callback = function() adjust("size", -1, 12, 255) end },
                { text = tostring(self.draft.size), id = "size", enabled = false },
                { text = "+", callback = function() adjust("size", 1, 12, 255) end },
            },
            {
                { text = _("Spacing"), enabled = false },
                { text = "−", callback = function() adjust("spacing", -5, 50, 200) end },
                { text = self.draft.spacing .. "%", id = "spacing", enabled = false },
                { text = "+", callback = function() adjust("spacing", 5, 50, 200) end },
            },
            {
                { text = _("Cancel"), callback = function() close(false) end },
                { text = _("Apply to this book"), callback = function() close(true) end },
            },
        },
    }
    UIManager:show(self.sheet)
end

-- Treat interruptions like Cancel, never silently commit a preview.
function Appearance:onSuspend()
    if self.picker then
        UIManager:close(self.picker)
        self.picker = nil
    end
    if self.sheet then UIManager:close(self.sheet) end
end
Appearance.onCloseDocument = Appearance.onSuspend

return Appearance
