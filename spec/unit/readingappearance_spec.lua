describe("Reading appearance preview", function()
    require("commonrequire")
    local UIManager = require("ui/uimanager")
    local Screen = require("device").screen
    local Appearance = dofile((os.getenv("APPEARANCE_PLUGIN_DIR") or "plugins/readingappearance.koplugin") .. "/main.lua")
    local plugin, rendered, font

    before_each(function()
        rendered = {}
        font = { font_face = "Original", configurable = { font_size = 22, line_spacing = 100 } }
        plugin = Appearance:new{
            ui = {
                font = font,
                menu = { registerToMainMenu = function() end },
                document = {
                    info = { has_pages = false },
                    setFontFace = function(_, value) rendered.font = value end,
                    setFontSize = function(_, value) rendered.size = value end,
                    setInterlineSpacePercent = function(_, value) rendered.spacing = value end,
                },
                handleEvent = function() end,
            },
        }
        plugin:showSheet()
    end)

    after_each(function()
        if plugin.sheet then UIManager:close(plugin.sheet) end
    end)

    it("previews without changing committed book settings", function()
        plugin.draft.font = "Preview"
        plugin.draft.size = 30
        plugin.draft.spacing = 125
        plugin:refresh()
        assert.equals("Preview", rendered.font)
        assert.equals(125, rendered.spacing)
        assert.equals("Original", font.font_face)
        assert.equals(22, font.configurable.font_size)
        assert.equals(100, font.configurable.line_spacing)
    end)

    it("cancels on dismissal and restores all three values", function()
        plugin.draft.font = "Preview"
        plugin.draft.size = 30
        plugin.draft.spacing = 125
        plugin:refresh()
        UIManager:close(plugin.sheet)
        assert.equals("Original", rendered.font)
        assert.equals(100, rendered.spacing)
        assert.equals(Screen:scaleBySize(22), rendered.size)
        assert.is_nil(plugin.original)
        assert.equals(22, font.configurable.font_size)
    end)

    it("commits only on Apply and does not roll back during close", function()
        plugin.draft.font = "Preview"
        plugin.draft.size = 30
        plugin.draft.spacing = 125
        plugin.sheet.buttons[4][2].callback()
        assert.equals("Preview", font.font_face)
        assert.equals(30, font.configurable.font_size)
        assert.equals(125, font.configurable.line_spacing)
        assert.equals("Preview", rendered.font)
    end)

    it("cancels on suspend", function()
        plugin.draft.size = 30
        plugin:refresh()
        plugin:onSuspend()
        assert.is_nil(plugin.sheet)
        assert.equals(22, font.configurable.font_size)
    end)

    it("cancels through the explicit Cancel button", function()
        plugin.draft.size = 30
        plugin:refresh()
        plugin.sheet.buttons[4][1].callback()
        assert.is_nil(plugin.sheet)
        assert.equals(Screen:scaleBySize(22), rendered.size)
    end)

    it("bounds size and spacing using the real adjustment callbacks", function()
        plugin.draft.size = 255
        plugin.sheet.buttons[2][4].callback()
        assert.equals(255, plugin.draft.size)
        plugin.draft.spacing = 50
        plugin.sheet.buttons[3][2].callback()
        assert.equals(50, plugin.draft.spacing)
    end)

    it("cancels when the document closes", function()
        plugin.draft.size = 30
        plugin:refresh()
        plugin:onCloseDocument()
        assert.is_nil(plugin.sheet)
        assert.equals(22, font.configurable.font_size)
    end)

    it("does not open for paginated documents", function()
        UIManager:close(plugin.sheet)
        plugin.ui.document.info.has_pages = true
        plugin:showSheet()
        assert.is_nil(plugin.sheet)
    end)
end)
