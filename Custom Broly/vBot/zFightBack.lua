local ignoreEmblems = {1,4} -- Guild Emblems (Allies)

local ui = setupUI([[
Panel
  height: 19

  BotSwitch
    id: title
    anchors.top: parent.top
    anchors.left: parent.left
    text-align: center
    width: 130
    !text: tr('Revide')
    font: verdana-11px-rounded

  Button
    id: edit
    anchors.top: prev.top
    anchors.left: prev.right
    anchors.right: parent.right
    margin-left: 3
    height: 17
    text: Setup
    font: verdana-11px-rounded
]])

local edit = setupUI([[
RevideBox < CheckBox
  font: verdana-11px-rounded
  margin-top: 5
  margin-left: 5
  anchors.top: prev.bottom
  anchors.left: parent.left
  anchors.right: parent.right
  color: lightGray

Panel
  height: 150

  RevideBox
    id: pauseTarget
    anchors.top: parent.top
    text: Pause TargetBot 
    !tooltip: tr('Pausar TargetBot enquanto luta.')

  RevideBox
    id: pauseCave
    text: Pause CaveBot 
    !tooltip: tr('Pausar CaveBot enquanto luta.')

  RevideBox
    id: battleativ
    text: Ativar battle 
    !tooltip: tr('Ativa o Battle.')
  
  RevideBox
    id: followTarget
    text: Follow Target 
    !tooltip: tr('Defina o modo Chase para seguir enquanto luta.')

  RevideBox
    id: ignoreGuild
    text: Atacar membros da Guild

  RevideBox
    id: attackAll
    text: Ataque todos com PK
    !tooltip: tr("Ataque todos os jogadores com PK, mesmo que eles não tenham atacado você.")

  BotTextEdit
    id: esc
    width: 83
    anchors.bottom: parent.bottom
    anchors.right: parent.right
    text: Escape
    color: red
    font: verdana-11px-rounded

  Label
    text: Cancel Attack:
    font: verdana-11px-rounded
    anchors.left: parent.left
    margin-left: 5
    anchors.verticalCenter: esc.verticalCenter
]])
edit:hide()

local showEdit = false
ui.edit.onClick = function(widget)
  showEdit = not showEdit
  if showEdit then
    edit:show()
  else
    edit:hide()
  end
end
-- End Basic UI

-- Storage
local st = "RevideFight"
storage[st] = storage[st] or {
  enabled = false,
  pauseTarget = true,
  battleativ= true,
  pauseCave = true,
  followTarget = true,
  ignoreGuild = false,
  attackAll = false,
  esc = "Escape",
}
local config = storage[st]

-- UI Functions
-- Main Button
ui.title:setOn(config.enabled)
ui.title.onClick = function(widget)
  config.enabled = not config.enabled
  widget:setOn(config.enabled)
end

-- Checkboxes
do
  edit.pauseTarget:setChecked(config.pauseTarget)
  edit.pauseTarget.onClick = function(widget)
    config.pauseTarget = not config.pauseTarget
    widget:setChecked(config.pauseTarget)
    widget:setImageColor(config.pauseTarget and "green" or "red")
  end
  edit.pauseTarget:setImageColor(config.pauseTarget and "green" or "red")
  
  edit.battleativ:setChecked(config.battleativ)
  edit.battleativ.onClick = function(widget)
    config.battleativ = not config.battleativ
    widget:setChecked(config.battleativ)
    widget:setImageColor(config.battleativ and "green" or "red")
  end
  edit.battleativ:setImageColor(config.battleativ and "green" or "red")

  edit.pauseCave:setChecked(config.pauseCave)
  edit.pauseCave.onClick = function(widget)
    config.pauseCave = not config.pauseCave
    widget:setChecked(config.pauseCave)
    widget:setImageColor(config.pauseCave and "green" or "red")
  end
  edit.pauseCave:setImageColor(config.pauseCave and "green" or "red")

  edit.followTarget:setChecked(config.followTarget)
  edit.followTarget.onClick = function(widget)
    config.followTarget = not config.followTarget
    widget:setChecked(config.followTarget)
    widget:setImageColor(config.followTarget and "green" or "red")
  end
  edit.followTarget:setImageColor(config.followTarget and "green" or "red")

  edit.ignoreGuild:setChecked(config.ignoreGuild)
  edit.ignoreGuild.onClick = function(widget)
    config.ignoreGuild = not config.ignoreGuild
    widget:setChecked(config.ignoreGuild)
    widget:setImageColor(config.ignoreGuild and "green" or "red")
  end
  edit.ignoreGuild:setImageColor(config.ignoreGuild and "green" or "red")

  edit.attackAll:setChecked(config.attackAll)
  edit.attackAll.onClick = function(widget)
    config.attackAll = not config.attackAll
    widget:setChecked(config.attackAll)
    widget:setImageColor(config.attackAll and "green" or "red")
  end
  edit.attackAll:setImageColor(config.attackAll and "green" or "red")
end

-- TextEdit
edit.esc:setText(config.esc)
edit.esc.onTextChange = function(widget, text)
  config.esc = text
end
edit.esc:setTooltip("Hotkey to cancel attack.")

-- End of setup.

local target = nil
local c = config

-- Main Loop
macro(250, function()
  if not c.enabled then return end
  if not target then
    if c.pausedTarget then
      c.pausedTarget = false
      TargetBot.setOn()
    end
    if c.pausedCave then
      c.pausedCave = false
      CaveBot.setOn()
    end
    if c.battleativD then
      c.battleativD = false
      delay(500)
      g_game.setSafeFight(true)
  end
    -- Search for attackers
    local creatures = getSpectators(false)
    for s, spec in ipairs(creatures) do
      if spec ~= player and spec:isPlayer() then
        if (c.attackAll and spec:getSkull() > 2) or spec:isTimedSquareVisible() then
          if spec:getShield() < 3 then
            if c.ignoreGuild or not table.find(ignoreEmblems, spec:getEmblem()) then
              target = spec:getName()
              break
            end
          end
        end
      end
    end
    return
  end

  local creature = getPlayerByName(target)
  if not creature then target = nil return end
  if c.pauseTargetBot then
    c.pausedTarget = true
    TargetBot.setOff()
  end
  if c.pauseTarget then
    c.pausedTarget = true
    TargetBot.setOff()
  end
  if c.pauseCave then 
    c.pausedCave = true
    CaveBot.setOff()
  end
  if c.battleativ and not pvpAtivado then
    c.battleativD = true
    delay(1000)
    g_game.setSafeFight(false)
end
  if c.followTarget then
    g_game.setChaseMode(1)
  end

  if g_game.isAttacking() then
    if g_game.getAttackingCreature():getName() ~= x then
      return
    end
  end
  g_game.attack(creature)
end)

onKeyDown(function(keys)
  if not c.enabled then return end
  if keys == config.esc then
    target = nil
  end
end)