setDefaultTab("Main")

-- securing storage namespace
local panelName = "extras"
if not storage[panelName] then
  storage[panelName] = {}
end
local settings = storage[panelName]

-- basic elements
extrasWindow = UI.createWindow('ExtrasWindow', rootWidget)
extrasWindow:hide()
extrasWindow.closeButton.onClick = function(widget)
  extrasWindow:hide()
end

extrasWindow.onGeometryChange = function(widget, old, new)
  if old.height == 0 then return end
  
  settings.height = new.height
end

extrasWindow:setHeight(550)

-- available options for dest param
local rightPanel = extrasWindow.content.right
local leftPanel = extrasWindow.content.left

-- objects made by Kondrah - taken from creature editor, minor changes to adapt
local addCheckBox = function(id, title, defaultValue, dest, tooltip)
  local widget = UI.createWidget('ExtrasCheckBox', dest)
  widget.onClick = function()
    widget:setOn(not widget:isOn())
    settings[id] = widget:isOn()
    if id == "checkPlayer" then
      local label = rootWidget.newHealer.targetSettings.vocations.title
      if not widget:isOn() then
        label:setColor("#d9321f")
        label:setTooltip("! WARNING ! \nTurn on check players in extras to use this feature!")
      else
          label:setColor("#dfdfdf")
          label:setTooltip("")
      end
    end
  end
  widget:setText(title)
  widget:setTooltip(tooltip)
  if settings[id] == nil then
    widget:setOn(defaultValue)
  else
    widget:setOn(settings[id])
  end
  settings[id] = widget:isOn()
end

local addTextEdit = function(id, title, defaultValue, dest, tooltip)
  local widget = UI.createWidget('ExtrasTextEdit', dest)
  widget.text:setText(title)
  widget.textEdit:setText(settings[id] or defaultValue or "")
  widget.text:setTooltip(tooltip)
  widget.textEdit.onTextChange = function(widget,text)
    settings[id] = text
  end
  settings[id] = settings[id] or defaultValue or ""
end

local addScrollBar = function(id, title, min, max, defaultValue, dest, tooltip)
  local widget = UI.createWidget('ExtrasScrollBar', dest)
  widget.text:setTooltip(tooltip)
  widget.scroll.onValueChange = function(scroll, value)
    widget.text:setText(title .. ": " .. value)
    if value == 0 then
      value = 1
    end
    settings[id] = value
  end
  widget.scroll:setRange(min, max)
  widget.scroll:setTooltip(tooltip)
  if max-min > 1000 then
    widget.scroll:setStep(100)
  elseif max-min > 100 then
    widget.scroll:setStep(10)
  end
  widget.scroll:setValue(settings[id] or defaultValue)
  widget.scroll.onValueChange(widget.scroll, widget.scroll:getValue())
end
UI.Separator()
UI.Button(" Configuracoes e scripts", function()
  extrasWindow:show()
  extrasWindow:raise()
  extrasWindow:focus()
end)
UI.Separator()

addCheckBox("title", "Mudar nome da Aba ", true, rightPanel, "Personalize o nome da janela OTCv8 de acordo com o personagem.")
if true then
  local vocText = ""

  if voc() == 1 or voc() < 500 then
      vocText = "- MESTRE"
  end

  macro(5000, function()
    if settings.title then
      if hppercent() > 0 then
          g_window.setTitle("Tibia - " .. name() .. " - " .. lvl() .. "lvl " .. vocText)
      else
          g_window.setTitle("Tibia - " .. name() .. " - DEAD")
      end
    else
      g_window.setTitle("Tibia - " .. name())
    end
  end) 
end

addCheckBox("bless", "Auto Bless", false, rightPanel, "Fala !bless ao entrar no game.")
if true then
local UIBlessing = setupUI([[
Panel
  width: 300
  height:300

  Label
    font: verdana-11px-rounded 
    id:Label
]], g_ui.getRootWidget())

local blesscommand = "!bless" -- qué decir para comprar una "bless"
local minutes = 1 -- tiempo después del cual hará un cierre de sesión si no hay "bless".
local money = "com a bless" -- mensaje si tienes el dinero
local notmoney = "dinheiro suficiente" -- mensaje si no tienes el dinero

function CheckStand()
local time = minutes*60*1000
    if standTime() > time then
    modules.game_interface.tryLogout(false)
    end
end
storage.bless = false
macro(100, function()
  if settings.bless and not storage.bless then
    say(blesscommand)
    delay(1000)
    UIBlessing.Label:setText("Bless: None")
    UIBlessing.Label:setColor("red")
CheckStand()
    else
    UIBlessing.Label:setText("Bless: True")
    UIBlessing.Label:setColor("green")
  end 
end)

onTextMessage(function(mode, text)
  if not settings.bless then return end
    
  if text:lower():find(notmoney) then
    storage.bless = false
  end
  if text:lower():find(money) then
    storage.bless = true
  end
end)

UIBlessing.Label:setPosition({x = 205, y = 450})
end
function staminaItems(parent)
  if not parent then
    parent = panel
  end
  local panelName = "staminaItemsUser"
  local ui = setupUI([[
Panel
  height: 65
  margin-top: 2

  SmallBotSwitch
    id: title
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: parent.top
    text-align: center

  HorizontalScrollBar
    id: scroll1
    anchors.left: parent.left
    anchors.right: parent.horizontalCenter
    anchors.top: title.bottom
    margin-right: 2
    margin-top: 2
    minimum: 0
    maximum: 42
    step: 1
    
  HorizontalScrollBar
    id: scroll2
    anchors.left: parent.horizontalCenter
    anchors.right: parent.right
    anchors.top: prev.top
    margin-left: 2
    minimum: 0
    maximum: 42
    step: 1    

  ItemsRow
    id: items
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: prev.bottom
  ]], parent)
  ui:setId(panelName)

  if not storage[panelName] then
    storage[panelName] = {
      min = 25,
      max = 40,
    }
  end

  local updateText = function()
    ui.title:setText("" .. storage[panelName].min .. " <= stamina >= " .. storage[panelName].max .. "")  
  end
 
  ui.scroll1.onValueChange = function(scroll, value)
    storage[panelName].min = value
    updateText()
  end
  ui.scroll2.onValueChange = function(scroll, value)
    storage[panelName].max = value
    updateText()
  end
 
  ui.scroll1:setValue(storage[panelName].min)
  ui.scroll2:setValue(storage[panelName].max)
 
  ui.title:setOn(storage[panelName].enabled)
  ui.title.onClick = function(widget)
    storage[panelName].enabled = not storage[panelName].enabled
    widget:setOn(storage[panelName].enabled)
  end
 
  if type(storage[panelName].items) ~= 'table' then
    storage[panelName].items = { 11588 }
  end
 
  for i=1,5 do
    ui.items:getChildByIndex(i).onItemChange = function(widget)
      storage[panelName].items[i] = widget:getItemId()
    end
    ui.items:getChildByIndex(i):setItemId(storage[panelName].items[i])    
  end
 
  macro(500, function()
    if not storage[panelName].enabled or stamina() / 60 < storage[panelName].min or stamina() / 60 > storage[panelName].max then
      return
    end
    local candidates = {}
    for i, item in pairs(storage[panelName].items) do
      if item >= 100 then
        table.insert(candidates, item)
      end
    end
    if #candidates == 0 then
      return
    end    
    use(candidates[math.random(1, #candidates)])
  end)
end
staminaItems(leftPanel)
UI.Separator(leftPanel)
local Keys = modules.corelib.g_keyboard.isKeyPressed
function getNearTiles(pos)
    if type(pos) ~= "table" then 
      storage[player:getName()] = {}
      storage[player:getName()][1] = {totalAtivo = 0, totalExhaust = 3000, exhaustTime = 0, activeTime = 0}
      pos = pos:getPosition() end

    local tiles = {}
    local dirs = {
        {-1, 1}, {0, 1}, {1, 1}, {-1, 0}, {1, 0}, {-1, -1}, {0, -1}, {1, -1}
    }
    for i = 1, #dirs do
        local tile = g_map.getTile({
            x = pos.x - dirs[i][1],
            y = pos.y - dirs[i][2],
            z = pos.z
        })
        if tile then table.insert(tiles, tile) end
    end

    return tiles
end

Stairs = {}
Stairs.Exclude = {}
Stairs.Click = {7047, 5102, 5111, 6207, 1948, 435, 7771, 5542, 8657, 6264, 1646, 1648, 1678, 5291, 1680, 6905, 6262, 1664, 13296, 1067, 13861, 11931, 1949, 6896, 6205, 5007, 8265, 1629, 1632, 5129, 6252, 6249, 7715, 7712, 7714, 7719, 6256, 1669, 1672, 5125, 5115, 5124, 17701, 17710, 1642, 6260, 5107, 4912, 6251, 5291, 1683, 1696, 1692, 5006, 2179, 5116, 11705, 30772, 30774, 6248, 5735, 5732, 5120, 23873, 5736, 6264, 5122, 30049, 30042, 7727, 12827, 12826, 1666, 7038, 7771,}
Stairs.postostring = function(pos)
    return pos.x .. ',' .. pos.y .. ',' .. pos.z
end

function Stairs.accurateDistance(c)
    if type(c) == 'userdata' then
        c = c:getPosition()
    end
    return math.abs(pos().x-c.x) + math.abs(pos().y-c.y)
end

Stairs.Check = {}

Stairs.checkTile = function(tile)
    if not tile then
        return false
  end
  
  local pos = Stairs.postostring(tile:getPosition())
  
    if Stairs.Check[pos] ~= nil then
        return Stairs.Check[pos]
  end
  
    if not tile:getTopUseThing() then
    Stairs.Check[pos] = false
        return false
    end
  
    for _, x in ipairs(tile:getItems()) do
        if table.find(Stairs.Click, x:getId()) then
            Stairs.Check[pos] = true
      return true
        elseif table.find(Stairs.Exclude, x:getId()) then
      Stairs.Check[pos] = false
      return false
    end
    end
  
    local cor = g_map.getMinimapColor(tile:getPosition())
    if cor >= 210 and cor <= 213 and not tile:isPathable() and tile:isWalkable() then
    Stairs.Check[pos] = true
        return true
  else
    Stairs.Check[pos] = false
        return false
    end
end


Stairs.checkAll = function()
  local tiles = {}
  for _, tile in ipairs(g_map.getTiles(posz())) do
    if Stairs.checkTile(tile) then
      table.insert(tiles, tile)
    end
  end
  if #tiles == 0 then return end
    table.sort(tiles, function(a, b)
        return Stairs.accurateDistance(a:getPosition()) < Stairs.accurateDistance(b:getPosition())
    end)
    for y, z in ipairs(tiles) do
        if findPath(z:getPosition(), pos(), 100, { ignoreCreatures = false, ignoreNonWalkable = false, ignoreNonPathable = false}) then
            return z
        end
    end
  return false
end


onPlayerPositionChange(function(newPos, oldPos)
  lastWalk = nil
end)

getItem = function(tile, id)
  for index, value in ipairs(tile:getItems()) do
    if value:getId() == id then
      return false
    end
  end
  return true
end

addCheckBox("escadd", "Auto Escada", true, leftPanel, "Suba e desca escadas precionando botao de atalho.")
if true then
end
macro(1000, function()
  if modules.game_console:isChatEnabled() then return end
    if Stairs.postostring(player:getPosition()) == Stairs.lastPosition then
        if Keys(storage.escadaid) and Stairs.See and settings.escadd then
      if lastWalk and lastWalk >= now then return end
      local pos = Stairs.See:getPosition()
      Stairs.distance = getDistanceBetween(player:getPosition(), pos)
            Stairs.See:setText('Escada\n' .. storage.escadaid, 'green')
            if Stairs.See:isWalkable() and not Stairs.See:isPathable() and not player:isServerWalking() and (not lastWalk or lastWalk < now) and autoWalk(pos, 1) then lastWalk = now + 500 return end
      if (Stairs.tryWalk and Stairs.tryWalk >= now) or Stairs.distance <= 3 then
        g_game.use(Stairs.See:getTopUseThing())
      else
        player:autoWalk(pos)
        Stairs.tryWalk = now + 1250
      end
        elseif Stairs.See and Stairs.See:getTopUseThing() and settings.escadd then
            Stairs.See:setText('Escada\n' .. storage.escadaid, 'red')
    end
        return
    end
    if Stairs.See and Stairs.See:getTopUseThing() then
        Stairs.See:setText('')
    end
    Stairs.See = Stairs.checkAll()
    Stairs.lastPosition = Stairs.postostring(player:getPosition())
  delay(100)
end)
local StairsClickContainer = UI.Container(function(widget, items)
  Stairs.Click = items
  end, true, leftPanel)
  StairsClickContainer:setHeight(37)
  StairsClickContainer:setItems(Stairs.Click)

UI.Separator(leftPanel)
UI.TextEdit("Space", function(widget, text)   
  storage.escadaid = text
end,leftPanel)
UI.Separator(leftPanel)

addCheckBox("Idlemode", "Idle Mode", false, rightPanel, "Reduz o consumo do cliente")
if true then

------------------------------------------------------
local secondsToIdle = 5
local activeFPS =  30
---------------------------------------------------------

local afkFPS = 0
function botPrintMessage(message)
modules.game_textmessage.displayGameMessage(message)
end

local function isSameMousePos(p1,p2)
return p1.x == p2.x and p1.y == p2.y
end

local function setAfk()
modules.client_options.setOption("backgroundFrameRate", afkFPS)
modules.game_interface.gameMapPanel:hide()
end

local function setActive()
modules.client_options.setOption("backgroundFrameRate", activeFPS)
modules.game_interface.gameMapPanel:show()
end

local lastMousePos = nil
local finalMousePos = nil
local idleCount = 0
local maxIdle = secondsToIdle * 4
macro(250, function()
local currentMousePos = g_window.getMousePosition()

  if finalMousePos then
  if isSameMousePos(finalMousePos,currentMousePos) then return end
  setActive()
  finalMousePos = nil
  end
  if lastMousePos and isSameMousePos(lastMousePos,currentMousePos) then
  idleCount = idleCount + 1
  else
  lastMousePos = currentMousePos
  idleCount = 0
  end

  if settings.Idlemode and idleCount == maxIdle then
  setAfk()
  finalMousePos = currentMousePos
  idleCount = 0
  end
end)
end
addCheckBox("limpartexto", "Esconder Msg", false, rightPanel, "Sem mensagens Laranja na tela.")
if true then
onStaticText(function(thing, text)
    if settings.limpartexto and not text:find('says:') then
        g_map.cleanTexts()
    end
end)
end

addCheckBox("esconderspr", "Esconder Sprites", false, rightPanel, "Esconder todos os efeitos do jogo.")
if true then
end
spr = macro(100, function() end)
onAddThing(function(tile, thing)
    if spr.isOff() then return end
    if thing:isEffect() and settings.esconderspr then
        thing:hide()
    end
end)


  addCheckBox("converte", "Converter Dinheiro", false, leftPanel, "Converte Dinheiro")
  if type(storage.moneyItems) ~= "table" then
    storage.moneyItems = {3031, 3035, 3043, 13924}
  end
  if true then
  macro(1000, function()
  if not storage.moneyItems[1] then return end
  local containers = g_game.getContainers()
  for index, container in pairs(containers) do
    if settings.converte and not container.lootContainer then -- ignore monster containers
      for i, item in ipairs(container:getItems()) do
        if item:getCount() == 100 or item:getCount() > 100 then
          for m, moneyId in ipairs(storage.moneyItems) do
            if item:getId() == moneyId.id then
              return g_game.use(item)            
            end
          end
        end
      end
    end
  end
  end)
  end
  local moneyContainer = UI.Container(function(widget, items)
  storage.moneyItems = items
  end, true, leftPanel)
  moneyContainer:setHeight(37)
  moneyContainer:setItems(storage.moneyItems)

addCheckBox("abrirbp", "Abrir Bag Principal", false, rightPanel, "Abrir Bag Principal")
if true then
macro(2500, function()
  bpItem = getBack()
  bp = getContainer(0)
  if settings.abrirbp and not bp and bpItem ~= nil then
      g_game.open(bpItem)
  end
end)
end