local configName = modules.game_bot.contentsPanel.config:getCurrentOption().text
local configFiles = g_resources.listDirectoryFiles("/bot/" .. configName .. "/vBot", true, false)
for i, file in ipairs(configFiles) do
  local ext = file:split(".")
  if ext[#ext]:lower() == "ui" or ext[#ext]:lower() == "otui" then
    g_ui.importStyle(file)
  end
end
local function loadScript(name)
  return dofile("/vBot/" .. name .. ".lua")
end
local luaFiles = {
  "main",  
  "tools",
  "vlib",
  "extras",
  "playerlist", 
  "new_cavebot_lib",
  "Hud_timer",
  "alarms",
  "zAutoBuff",
  "combo",
  "Fuga",
  "zFightBack",
  "z_Auto-Party",
  "cave_target_settings",
  "cavebot", 
  "follow player",
  "Follow_Attack",
  "spy_level",  
  "ingame_editor",
  "npc_talk",
  "PZ-TIME",
}

for i, file in ipairs(luaFiles) do
  loadScript(file)
end

setDefaultTab("Main")
local label = UI.Label("Main:")
label:setColor('#9dd1ce')
label:setFont('verdana-11px-rounded')
UI.Separator()
local interface = modules.game_interface
local leftPanel = interface:getLeftPanel()
leftPanel:setWidth(210)

local frags = 0
local unequip = false
local m = macro(50, "AntReD", function() end)

function safeExit()
    CaveBot.setOff()
    TargetBot.setOff()
    g_game.cancelAttackAndFollow()
    g_game.cancelAttackAndFollow()
    g_game.cancelAttackAndFollow()
    modules.game_interface.forceExit()
end

onTextMessage(function(mode, text)
    if not m.isOn() then return end
    if not text:find("Warning! The murder of") then return end
    frags = frags + 1
    if killsToRs() < 2 or frags > 1 then
        schedule(100, function()
            safeExit()
        end)
    end
end)

BugMap = {};
local consoleTextEdit = g_ui.getRootWidget():recursiveGetChildById('consoleTextEdit');
local availableKeys = {
  ['W'] = { 0, -5, 0 },
  ['S'] = { 0, 5, 2 },
  ['A'] = { -5, 0, 3 },
  ['D'] = { 5, 0, 1 },
  ['C'] = { 5, 5 },
  ['Z'] = { -5, 5 },
  ['Q'] = { -5, -5 },
  ['E'] = { 5, -5 }
};
BugMap.macro = macro(1, "BugMap", function() 
  BugMap.logic();
end)
function BugMap.logic()
  if (modules.game_console:isChatEnabled() or modules.corelib.g_keyboard.isCtrlPressed()) then return; end
  local playerPos = pos();
  local tile;
  local dir;
  for key, value in pairs(availableKeys) do
    if (modules.corelib.g_keyboard.isKeyPressed(key)) then
      playerPos.x = playerPos.x + value[1];
      playerPos.y = playerPos.y + value[2];
      tile = g_map.getTile(playerPos);
      dir = value[3];
      break;
    end
  end
  if (dir) then
    g_game.walk(dir, false);
  end  
  if (not tile) then return end;
  g_game.use(tile:getTopUseThing());
end
BugMapICONIcon = addIcon("Bug Map", {item =3079, text = "Bug Map"}, function(mapisOn, mapisOn)
  BugMap.macro.setOn(mapisOn)
end)


local configName = modules.game_bot.contentsPanel.config:getCurrentOption().text
local pathBot = "/bot/" .. configName .. "/"

local widgetArrow = setupUI([[
UIWidget
  height: 64
  width: 64
  anchors.centerIn: parent
  visible: false
]], modules.game_interface.getMapPanel())

if not storage["exiva/senseAdvanced"] then
  storage["exiva/senseAdvanced"] = {
    Spell = "sense",
    LastTargetKey = "t",
    LastSenseKey = "v",
    LastSensedPlayer = nil
  }
end

local config = storage["exiva/senseAdvanced"]

local positions = {
    west = {marginLeft = -80, marginTop = 0, rotation = 270},
    east = {marginLeft = 80, marginTop = 0, rotation = 90},
    north = {marginLeft = 0, marginTop = -80, rotation = 0},
    south = {marginLeft = 0, marginTop = 80, rotation = 180},
    ["north-west"] = {marginLeft = -80, marginTop = -80, rotation = 315},
    ["north-east"] = {marginLeft = 80, marginTop = -80, rotation = 45},
    ["south-west"] = {marginLeft = -80, marginTop = 80, rotation = 225},
    ["south-east"] = {marginLeft = 80, marginTop = 80, rotation = 135}
}

local function showArrow(direction)
    local pos = positions[direction]
    if pos then
        widgetArrow:setVisible(true)
        widgetArrow:setRotation(pos.rotation)
        widgetArrow:setMarginLeft(pos.marginLeft)
        widgetArrow:setMarginTop(pos.marginTop)
        widgetArrow:show()
        if evento and type(evento) == "number" then
            removeEvent(evento)
        end
        modules.corelib.g_effects.fadeIn(widgetArrow)
        evento = modules.corelib.scheduleEvent(function ()
            modules.corelib.g_effects.fadeOut(widgetArrow)
            evento = nil
        end, 1800)
    end
end

onTextMessage(function(mode, text)
    if mode == 20 then
        local player = text:match('^(.-) is very .- to the [a-z-]+%.')
        if player then
            config.LastSensedPlayer = player:trim()
        end
        showArrow(text:match("is .- to the ([a-z-]+)%.") or text:match("is to the ([a-z-]+)%."))
    end
end)

onKeyPress(function(keys)
  if (modules.game_console:isChatEnabled() or modules.corelib.g_keyboard.isCtrlPressed()) then return; end

    keys = keys:lower()

    if keys == config.LastTargetKey:lower() then
        if Player and type(Player) == "string" then
            say(config.Spell .. ' "' .. Player .. '"')
            config.LastSensedPlayer = Player
        else
            modules.game_textmessage.displayGameMessage("Não há último destino armazenado.")
        end
    elseif keys == config.LastSenseKey:lower() then
        if config.LastSensedPlayer and type(config.LastSensedPlayer) == "string" then
            say(config.Spell .. ' "' .. config.LastSensedPlayer .. '"')
        else
            modules.game_textmessage.displayGameMessage("Não há nenhum último Sense/Exiva armazenado.")
        end
    end
end)

macro(1500, "Sense target", function()
    if Player and type(Player) == "string" then
        local targetVisible = false
        for _, spectator in ipairs(getSpectators()) do
            if spectator:getName() == Player then
                targetVisible = true
                break
            end
        end
        if not targetVisible then
            say(config.Spell .. ' "' .. Player .. '"')
            config.LastSensedPlayer = Player
        end
    end
end)

macro(1, function()
    if g_game.isAttacking() and g_game.getAttackingCreature():isPlayer() then
        Player = g_game.getAttackingCreature():getName()
        config.LastSensedPlayer = Player
    end
end)

macro(1, 'Sense', 'F12', function()
    if config.Spell and config.LastSensedPlayer and type(config.LastSensedPlayer) == "string" then
        local locatePlayer = getPlayerByName(config.LastSensedPlayer)
        if not (locatePlayer and locatePlayer:getPosition().z == player:getPosition().z and getDistanceBetween(pos(), locatePlayer:getPosition()) <= 8) then
            say(config.Spell .. ' "' .. config.LastSensedPlayer .. '"')
            delay(3000)
        end
    end
end)

if not g_resources.fileExists(pathBot .. "/arrow.png") then
    HTTP.get("https://i.imgur.com/UCpAD89.png", function(data, err)
        if not err then
            g_resources.writeFileContents(pathBot .. "/arrow.png", data)
            widgetArrow:setImageSource(pathBot .. "/arrow.png")
        end
    end)
else
    widgetArrow:setImageSource(pathBot .. "/arrow.png")
end
macro(5 * 60 * 1000, function()
  modules.game_bot.save()
end)