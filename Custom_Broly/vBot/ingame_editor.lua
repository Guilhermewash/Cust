local chName = "Terminal"
local function log(msgColor,...)
  local mod = modules.game_console
  local ch = mod.getTab(chName)
  if not ch then
    mod.addTab(chName,false)
  end
  local msg = ""
  local args = {...}
  local appendSpace = #args > 1
  for i,v in ipairs(args) do
    msg = msg .. tostring(v)
    if appendSpace and i < #args then
      msg = msg .. ' , '
    end
  end
  mod.addTabText(msg,{speakType = 6, color = msgColor},ch)
end

function print(...)
  return log('#9dd1ce',...)
end

function warn(...)
  return log('#FFFF00',...)
end

function error(...)
  return log('#F55E5E',...)
end 

setDefaultTab("Main")
UI.Separator()
local btIn = UI.Button("In-Game Script Editor", function(newText)
  UI.MultilineEditorWindow(storage.ingame_hotkeys or "", {title="In-Game Macro/Script Editor", description="You can add your custom scripts here"}, function(text)
    storage.ingame_hotkeys = text
    reload()
  end)
end)
btIn:setImageColor('#2de0d7')
    
for _, scripts in pairs({storage.ingame_hotkeys}) do
  if type(scripts) == "string" and scripts:len() > 3 then
    UI.Separator()
    local label = UI.Label("In-Game Scripts:")
    label:setColor('#9dd1ce')
    label:setFont('verdana-11px-rounded')
    local status, result = pcall(function()
      assert(load(scripts, "ingame_editor"))()
    end)
    if not status then 
      error("Ingame editor error:\n" .. result)
    end
  end
end

UI.Separator()