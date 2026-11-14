local FileBrowser = {}

include("util.lua")(FileBrowser)
include("skin.lua")(FileBrowser)
include("settings.lua")(FileBrowser)
include("node.lua")(FileBrowser)
include("rootfolder.lua")(FileBrowser)
include("userprompt.lua")(FileBrowser)
include("tree.lua")(FileBrowser)
include("browser.lua")(FileBrowser)
include("panel.lua")(FileBrowser)

return FileBrowser
