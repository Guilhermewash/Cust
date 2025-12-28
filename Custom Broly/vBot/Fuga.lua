----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
scriptFuncs = {};
fugaSpellsWidgets = {};

scriptFuncs.readProfile = function(filePath, callback)
    if g_resources.fileExists(filePath) then
        local status, result = pcall(function()
            return json.decode(g_resources.readFileContents(filePath))
        end)
        if not status then
            return warn("Error: ".. result)
        end

        callback(result);
    end
end

scriptFuncs.saveProfile = function(configFile, content)
    local status, result = pcall(function()
        return json.encode(content, 2)
    end);

    if not status then
        return warn("Error:" .. result);
    end
    g_resources.writeFileContents(configFile, result);
end

storageProfiles = {
    fugaSpells = {},
}
MAIN_DIRECTORY = "/bot/" .. modules.game_bot.contentsPanel.config:getCurrentOption().text .. "/storage/"
STORAGE_DIRECTORY = "" .. MAIN_DIRECTORY .. g_game.getWorldName() .. '_FUGA.json';

if not g_resources.directoryExists(MAIN_DIRECTORY) then
    g_resources.makeDir(MAIN_DIRECTORY);
end

scriptFuncs.readProfile(STORAGE_DIRECTORY, function(result)
    storageProfiles = result;
    if (type(storageProfiles.fugaSpells) ~= 'table') then
        storageProfiles.fugaSpells = {};
    end
end);

scriptFuncs.reindexTable = function(t)
    if not t or type(t) ~= "table" then
        return
    end

    local i = 0
    for _, e in pairs(t) do
        i = i + 1
        e.index = i
    end
end

firstLetterUpper = function(str)
    return (str:gsub("(%a)([%w_']*)", function(first, rest)
        return first:upper() .. rest:lower()
    end))
end

storage['iconScripts'] = storage['iconScripts'] or {
    fugaMacro = false,
    showInfos = false,
}

local isOn = storage['iconScripts'];

function removeTable(tbl, index)
    table.remove(tbl, index)
end

storage.Attacking = storage.Attacking or {}

function getPlayersAttack()
    local count = 0
    for _ in pairs(storage.Attacking) do
        count = count + 1
    end
    return count
end

function calculatePercentage(var)
    local multiplier = getPlayersAttack(false);
    return var + (multiplier * 7)
end


function formatTime(seconds)
    if seconds < 60 then
        return seconds .. 's'
    else
        local minutes = math.floor(seconds / 60)
        local remainingSeconds = seconds % 60
        return string.format("%dm %02ds", minutes, remainingSeconds)
    end
end

formatRemainingTime = function(time)
    local remainingTime = (time - now) / 1000;
    local timeText = '';
    timeText = string.format("%.0f", (time - now) / 1000) .. "s";
    return timeText;
end

formatOsTime = function(time)
    local remainingTime = (time - os.time());
    local timeText = '';
    timeText = string.format("%.0f", (time - os.time())) .. "s";
    return timeText;
end

attachSpellWidgetCallbacks = function(widget, spellId, table)
    widget.onDragEnter = function(self, mousePos)
        if not modules.corelib.g_keyboard.isCtrlPressed() then
            return false
        end
        self:breakAnchors()
        self.movingReference = {
            x = mousePos.x - self:getX(),
            y = mousePos.y - self:getY()
        }
        return true
    end

    widget.onDragMove = function(self, mousePos, moved)
        local parentRect = self:getParent():getRect()
        local newX = math.min(math.max(parentRect.x, mousePos.x - self.movingReference.x),
            parentRect.x + parentRect.width - self:getWidth())
        local newY = math.min(math.max(parentRect.y - self:getParent():getMarginTop(),
            mousePos.y - self.movingReference.y), parentRect.y + parentRect.height - self:getHeight())
        self:move(newX, newY)
        if table[spellId] then
            table[spellId].widgetPos = {
                x = newX,
                y = newY
            }
            storageProfiles.keySpells = nil
            scriptFuncs.saveProfile(STORAGE_DIRECTORY, storageProfiles)
        end
        return true
    end

    widget.onDragLeave = function(self, pos)
        return true
    end
end



local spellEntry = [[
UIWidget
  background-color: alpha
  text-offset: 18 0
  focusable: true
  height: 16

  CheckBox
    id: enabled
    anchors.left: parent.left
    anchors.verticalCenter: parent.verticalCenter
    width: 15
    height: 15
    margin-top: 2
    margin-left: 3

  $focus:
    background-color: #00000055

  CheckBox
    id: showTimespell
    anchors.left: enabled.left
    anchors.verticalCenter: parent.verticalCenter
    width: 15
    height: 15
    margin-top: 2
    margin-left: 15

  $focus:
    background-color: #00000055

  Label
    id: textToSet
    anchors.left: showTimespell.left
    anchors.verticalCenter: parent.verticalCenter
    margin-left: 20

  Button
    id: remove
    !text: tr('x')
    anchors.right: parent.right
    margin-right: 15
    width: 15
    height: 15
    tooltip: Remove Spell
]]

local widgetConfig = [[
UIWidget
  background-color: black
  opacity: 0.8
  padding: 0 5
  focusable: true
  phantom: false
  draggable: true
  text-auto-resize: true
]]
  
fugaIcon = setupUI([[
Panel
  height: 40
  BotSwitch
    id: title
    anchors.top: parent.top
    anchors.left: parent.left
    text-align: center
    width: 130
    text: Fuga

  Button
    id: settings
    anchors.top: prev.top
    anchors.left: prev.right
    anchors.right: parent.right
    margin-left: 3
    height: 17
    text: Setup

  CheckBox
    id: showInfos
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: prev.bottom
    margin-top: 5
    text: Show Information
]])

fugaInterface = setupUI([[
MainWindow
  text: Fuga Panel
  size: 550 322

  Panel
    image-source: /images/ui/panel_flat
    anchors.top: parent.top
    anchors.right: sep2.left
    anchors.left: parent.left
    anchors.bottom: separator.top
    margin: 5 5 5 5
    image-border: 6
    padding: 3
    size: 320 235

  Panel
    image-source: /images/ui/panel_flat
    anchors.top: parent.top
    anchors.left: sep2.left
    anchors.right: parent.right
    anchors.bottom: separator.top
    margin: 5 5 5 5
    image-border: 6
    padding: 3
    size: 320 235


  TextList
    id: spellList
    anchors.left: parent.left
    anchors.top: parent.top
    padding: 1
    size: 240 215
    margin-top: 11
    margin-left: 11
    vertical-scrollbar: spellListScrollBar

  VerticalScrollBar
    id: spellListScrollBar
    anchors.top: spellList.top
    anchors.bottom: spellList.bottom
    anchors.right: spellList.right
    step: 14
    pixels-scroll: true

  Button
    id: moveUp
    anchors.bottom: parent.bottom
    anchors.horizontalCenter: parent.horizontalCenter
    margin-bottom: 40
    margin-left: 50
    text: Move Up
    size: 60 17
    font: cipsoftFont

  Button
    id: moveDown
    anchors.bottom: parent.bottom
    anchors.left: moveUp.left
    margin-bottom: 40
    margin-left: 65
    text: Move Down
    size: 60 17
    font: cipsoftFont

  VerticalSeparator
    id: sep2
    anchors.top: parent.top
    anchors.bottom: closeButton.top
    anchors.horizontalCenter: parent.horizontalCenter
    margin-left: 3
    margin-bottom: 5

  HorizontalSeparator
    id: separator
    anchors.right: parent.right
    anchors.left: parent.left
    anchors.bottom: closeButton.top
    margin-bottom: 5

  Label
    id: castSpellLabel
    anchors.left: castSpell.right
    anchors.top: parent.top
    text: Cast Spell
    margin-top: 19
    margin-left: 15

  TextEdit
    id: castSpell
    anchors.left: spellList.right
    anchors.top: parent.top
    margin-left: 34
    margin-top: 15
    width: 100

  Label
    id: orangeSpellLabel
    anchors.left: orangeSpell.right
    anchors.top: parent.top
    text: Orange Spell
    margin-top: 49
    margin-left: 15

  TextEdit
    id: orangeSpell
    anchors.left: spellList.right
    anchors.top: parent.top
    margin-top: 45
    margin-left: 34
    width: 100

  CheckBox
    id: sameSpell
    anchors.left: orangeSpellLabel.right
    anchors.top: parent.top
    margin-top: 49
    margin-left: 8
    tooltip: Same Spell

  Label
    id: onScreenLabel
    anchors.left: orangeSpell.right
    anchors.top: parent.top
    text: On Screen
    margin-top: 79
    margin-left: 15

  TextEdit
    id: onScreen
    anchors.left: spellList.right
    anchors.top: parent.top
    margin-left: 34
    margin-top: 75
    width: 100

  Label
    id: hppercentLabel
    anchors.left: hppercent.right
    anchors.top: parent.top
    margin-top: 105
    margin-left: 5
    text: HP para Fuga

  HorizontalScrollBar
    id: hppercent
    anchors.left: spellList.right
    margin-left: 20
    anchors.top: parent.top
    margin-top: 105
    width: 125
    minimum: 0
    maximum: 100
    step: 1

  Label
    id: mppercentLabel
    anchors.left: mppercent.right
    anchors.top: parent.top
    margin-top: 135
    margin-left: 5
    text: MP para Fuga

  HorizontalScrollBar
    id: mppercent
    anchors.left: spellList.right
    margin-left: 20
    anchors.top: parent.top
    margin-top: 135
    width: 125
    minimum: 0
    maximum: 100
    step: 1

  Label
    id: cooldownTotalLabel
    anchors.left: mppercent.right
    anchors.top: parent.top
    margin-top: 165
    margin-left: 5
    text: Total Cooldown

  HorizontalScrollBar
    id: cooldownTotal
    anchors.left: spellList.right
    margin-left: 20
    anchors.top: parent.top
    margin-top: 165
    width: 125
    minimum: 0
    maximum: 180
    step: 1

  Label
    id: cooldownActiveLabel
    anchors.left: hppercent.right
    anchors.top: parent.top
    margin-top: 195
    margin-left: 5
    text: Active Cooldown

  HorizontalScrollBar
    id: cooldownActive
    anchors.left: spellList.right
    margin-left: 20
    anchors.top: parent.top
    margin-top: 195
    width: 125
    minimum: 0
    maximum: 180
    step: 1

  Button
    id: insertSpell
    text: Insert Spell
    font: cipsoftFont
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    size: 60 21
    margin-bottom: 40
    margin-right: 20


  Button
    id: closeButton
    !text: tr('Close')
    font: cipsoftFont
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    size: 45 21
    margin-right: 5

]], g_ui.getRootWidget())
fugaInterface:hide();


fugaIcon.title:setOn(isOn.fugaMacro);
fugaIcon.title.onClick = function(widget)
    isOn.fugaMacro = not isOn.fugaMacro;
    widget:setOn(isOn.fugaMacro);
    scriptFuncs.saveProfile(STORAGE_DIRECTORY, storageProfiles);
end

fugaIcon.settings.onClick = function(widget)
    if not fugaInterface:isVisible() then
        fugaInterface:show();
        fugaInterface:raise();
        fugaInterface:focus();
    else
        fugaInterface:hide();
        scriptFuncs.saveProfile(STORAGE_DIRECTORY, storageProfiles);
    end
end

fugaInterface.closeButton.onClick = function(widget)
    fugaInterface:hide();
    scriptFuncs.saveProfile(STORAGE_DIRECTORY, storageProfiles);
end

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

fugaInterface.hppercent:setText('0%')
fugaInterface.hppercent.onValueChange = function(widget, value)
    widget:setText(value .. '%')
end

fugaInterface.mppercent:setText('0%')
fugaInterface.mppercent.onValueChange = function(widget, value)
    widget:setText(value .. '%')
end

fugaInterface.cooldownTotal:setText('0s')
fugaInterface.cooldownTotal.onValueChange = function(widget, value)
    local formattedTime = formatTime(value)
    widget:setText(value .. 's')
    -- widget:setText(formattedTime)
end

fugaInterface.cooldownActive:setText('0s')
fugaInterface.cooldownActive.onValueChange = function(widget, value)
    local formattedTime = formatTime(value)
    widget:setText(value .. 's')
    -- widget:setText(formattedTime)
end

fugaIcon.showInfos:setChecked(isOn.showInfos)
fugaIcon.showInfos.onClick = function(widget)
    isOn.showInfos = not isOn.showInfos
    widget:setChecked(isOn.showInfos)
end

fugaInterface.sameSpell:setChecked(true);
fugaInterface.orangeSpell:setEnabled(false);
fugaInterface.sameSpell.onCheckChange = function(widget, checked)
    if checked then
        fugaInterface.orangeSpell:setEnabled(false)
    else
        fugaInterface.orangeSpell:setEnabled(true)
        fugaInterface.orangeSpell:setText(fugaInterface.castSpell:getText())
    end
end

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

function refreshFugaList(list, table)
    if table then
        for i, child in pairs(list.spellList:getChildren()) do
            child:destroy();
        end
        for _, widget in pairs(fugaSpellsWidgets) do
            widget:destroy();
        end
        for index, entry in ipairs(table) do
            local label = setupUI(spellEntry, list.spellList)
            local newWidget = setupUI(widgetConfig, g_ui.getRootWidget())
            newWidget:setText(firstLetterUpper(entry.spellCast))
            attachSpellWidgetCallbacks(newWidget, entry.index, storageProfiles.fugaSpells)

            if not entry.widgetPos then
                entry.widgetPos = {
                    x = 0,
                    y = 50
                }
            end
            if entry.enableTimeSpell then
                newWidget:show();
            else
                newWidget:hide();
            end
            newWidget:setPosition(entry.widgetPos)
            fugaSpellsWidgets[entry.index] = newWidget;
            label.onDoubleClick = function(widget)
                local spellTable = entry;
                list.castSpell:setText(spellTable.spellCast);
                list.orangeSpell:setText(spellTable.orangeSpell);
                list.onScreen:setText(spellTable.onScreen);
                list.hppercent:setValue(spellTable.selfHealth);
                list.mppercent:setValue(spellTable.selfMana);
                list.cooldownTotal:setValue(spellTable.cooldownTotal);
                list.cooldownActive:setValue(spellTable.cooldownActive);
                for i, v in ipairs(storageProfiles.fugaSpells) do
                    if v == entry then
                        removeTable(storageProfiles.fugaSpells, i)
                    end
                end
                scriptFuncs.reindexTable(table);
                newWidget:destroy();
                label:destroy();
            end
            label.enabled:setChecked(entry.enabled);
            label.enabled:setTooltip(not entry.enabled and 'Enable Spell' or 'Disable Spell');
            label.enabled.onClick = function(widget)
                entry.enabled = not entry.enabled;
                label.enabled:setChecked(entry.enabled);
                label.enabled:setTooltip(not entry.enabled and 'Enable Spell' or 'Disable Spell');
                scriptFuncs.saveProfile(STORAGE_DIRECTORY, storageProfiles);
            end
            label.showTimespell:setChecked(entry.enableTimeSpell)
            label.showTimespell:setTooltip(not entry.enableTimeSpell and 'Enable Time Spell' or 'Disable Time Spell');
            label.showTimespell.onClick = function(widget)
                entry.enableTimeSpell = not entry.enableTimeSpell;
                label.showTimespell:setChecked(entry.enableTimeSpell);
                label.showTimespell:setTooltip(not entry.enableTimeSpell and 'Enable Time Spell' or 'Disable Time Spell');
                if entry.enableTimeSpell then
                    newWidget:show();
                else
                    newWidget:hide();
                end
                scriptFuncs.saveProfile(STORAGE_DIRECTORY, storageProfiles);
            end
            label.remove.onClick = function(widget)
                for i, v in ipairs(storageProfiles.fugaSpells) do
                    if v == entry then
                        removeTable(storageProfiles.fugaSpells, i)
                    end
                end
                scriptFuncs.reindexTable(table);
                newWidget:destroy();
                label:destroy();
            end
            label.onClick = function(widget)
                fugaInterface.moveDown:show();
                fugaInterface.moveUp:show();
            end
            label.textToSet:setText(firstLetterUpper(entry.spellCast));
            label:setTooltip('Orange Message: ' .. entry.orangeSpell .. ' | On Screen: ' .. entry.onScreen ..
                                 ' | Total Cooldown: ' .. entry.cooldownTotal .. 's | Active Cooldown: ' ..
                                 entry.cooldownActive .. 's | Hppercent: ' .. entry.selfHealth .. 's | Mppercent: ' .. entry.selfMana)
        end
    end
end

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

fugaInterface.moveUp.onClick = function()
    local action = fugaInterface.spellList:getFocusedChild();
    if (not action) then
        return;
    end
    local index = fugaInterface.spellList:getChildIndex(action);
    if (index < 2) then
        return;
    end
    fugaInterface.spellList:moveChildToIndex(action, index - 1);
    fugaInterface.spellList:ensureChildVisible(action);
    storageProfiles.fugaSpells[index].index = index - 1;
    storageProfiles.fugaSpells[index - 1].index = index;
    table.sort(storageProfiles.fugaSpells, function(a, b)
        return a.index < b.index
    end)
    scriptFuncs.saveProfile(STORAGE_DIRECTORY, storageProfiles);
end

fugaInterface.moveDown.onClick = function()
    local action = fugaInterface.spellList:getFocusedChild()
    if not action then
        return;
    end
    local index = fugaInterface.spellList:getChildIndex(action)
    if index >= fugaInterface.spellList:getChildCount() then
        return
    end
    fugaInterface.spellList:moveChildToIndex(action, index + 1);
    fugaInterface.spellList:ensureChildVisible(action);
    storageProfiles.fugaSpells[index].index = index + 1;
    storageProfiles.fugaSpells[index + 1].index = index;
    table.sort(storageProfiles.fugaSpells, function(a, b)
        return a.index < b.index
    end)
    scriptFuncs.saveProfile(STORAGE_DIRECTORY, storageProfiles);
end

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

fugaInterface.insertSpell.onClick = function(widget)
    local spellName = fugaInterface.castSpell:getText():trim():lower();
    local orangeMsg = fugaInterface.orangeSpell:getText():trim():lower();
    local onScreen = fugaInterface.onScreen:getText();
    orangeMsg = (orangeMsg:len() == 0) and spellName or orangeMsg;
    local hppercent = fugaInterface.hppercent:getValue();
    local mppercent = fugaInterface.mppercent:getValue();
    local cooldownTotal = fugaInterface.cooldownTotal:getValue();
    local cooldownActive = fugaInterface.cooldownActive:getValue();

    if spellName:len() == 0 then
        return warn('Invalid Spell Name.');
    end
    if not fugaInterface.sameSpell:isChecked() and orangeMsg:len() == 0 then
        return warn('Invalid Orange Spell.')
    end
    if onScreen:len() == 0 then
        return warn('Invalid Text On Screen')
    end
    if hppercent == 0 then
        return warn('Invalid Hppercent.')
    end

    if cooldownTotal == 0 then
        return warn('Invalid Cooldown Total.')
    end

    local spellConfig = {
        index = #storageProfiles.fugaSpells + 1,
        spellCast = spellName,
        orangeSpell = orangeMsg,
        onScreen = onScreen,
        selfHealth = hppercent,
        selfMana = mppercent,
        cooldownActive = cooldownActive,
        cooldownTotal = cooldownTotal,
        enableTimeSpell = true,
        enabled = true
    }
    table.insert(storageProfiles.fugaSpells, spellConfig)
    refreshFugaList(fugaInterface, storageProfiles.fugaSpells)
    scriptFuncs.saveProfile(STORAGE_DIRECTORY, storageProfiles)

    fugaInterface.castSpell:clearText()
    fugaInterface.orangeSpell:clearText()
    fugaInterface.onScreen:clearText()
    fugaInterface.cooldownTotal:setValue(0)
    fugaInterface.cooldownActive:setValue(0)
    fugaInterface.hppercent:setValue(0)
end

refreshFugaList(fugaInterface, storageProfiles.fugaSpells);

storage.widgetPos = storage.widgetPos or {};
informationWidget = {};

local widgetNames = {'showText'}

for i, widgetName in ipairs(widgetNames) do
    informationWidget[widgetName] = setupUI(widgetConfig, g_ui.getRootWidget())
end

local function attachSpellWidgetCallbacks(key)
    informationWidget[key].onDragEnter = function(widget, mousePos)
        if not modules.corelib.g_keyboard.isCtrlPressed() then
            return false
        end
        widget:breakAnchors()
        widget.movingReference = {
            x = mousePos.x - widget:getX(),
            y = mousePos.y - widget:getY()
        }
        return true
    end

    informationWidget[key].onDragMove = function(widget, mousePos, moved)
        local parentRect = widget:getParent():getRect()
        local x = math.min(math.max(parentRect.x, mousePos.x - widget.movingReference.x),
            parentRect.x + parentRect.width - widget:getWidth())
        local y = math.min(math.max(parentRect.y - widget:getParent():getMarginTop(),
            mousePos.y - widget.movingReference.y), parentRect.y + parentRect.height - widget:getHeight())
        widget:move(x, y)
        return true
    end

    informationWidget[key].onDragLeave = function(widget, pos)
        storage.widgetPos[key] = {}
        storage.widgetPos[key].x = widget:getX();
        storage.widgetPos[key].y = widget:getY();
        return true
    end
end

for key, value in pairs(informationWidget) do
    attachSpellWidgetCallbacks(key)
    informationWidget[key]:setPosition(storage.widgetPos[key] or {0, 50})
end

local toShow = informationWidget['showText'];

macro(10, function()
    if isOn.showInfos then
        for _, value in ipairs(storageProfiles.fugaSpells) do
            if value.selfHealth then
                toShow:show()
                toShow:setText('Inimigos: ' .. getPlayersAttack(false) .. ' | Porcentagem: ' ..
                                   calculatePercentage(value.selfHealth) .. ' | Vida: ' .. player:getHealthPercent().. ' | Mana: ' .. manapercent())
                return;
            end
        end
    else
        toShow:hide();
    end
end);

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
macro(10, function()
    if not (fugaSpellsWidgets and storageProfiles.fugaSpells) then
        return;
    end

    for index, spellConfig in ipairs(storageProfiles.fugaSpells) do
        local widget = fugaSpellsWidgets[spellConfig.index];
        if widget then
            local textToSet = firstLetterUpper(spellConfig.onScreen)
            local color = 'green'
            if spellConfig.activeCooldown and spellConfig.activeCooldown > os.time() then
                textToSet = textToSet .. ' | ' .. formatOsTime(spellConfig.activeCooldown)
                color = 'blue'
                storage.fugabateu = true
            elseif spellConfig.totalCooldown and spellConfig.totalCooldown > os.time() then
                textToSet = textToSet .. ' | ' .. formatOsTime(spellConfig.totalCooldown)
                color = 'red'
            else
                textToSet = textToSet .. ' | OK!'
            end
            widget:setText(textToSet)
            widget:setColor(color)
        end
    end
end);

forceSay = function(spell)
    if type(spell) ~= "table" then
        for i = 0, 4 do
            return say(spell)
        end
    end

    for i = 0, 4 do
        return say(spell.spellCast or spell.text)
    end
end

macro(1, function()
    if not fugaIcon.title:isOn() then return end
    if isInPz() then return end

    local hpPercent = hppercent()
    local mpPercent = manapercent()
    local pressed = modules.corelib.g_keyboard.isKeyPressed("f11")
    local time = os.time()

    for _, spell in ipairs(storageProfiles.fugaSpells) do
        if spell.enabled then
            local hpTrigger = hpPercent <= calculatePercentage(spell.selfHealth)
            local mpTrigger = mpPercent <= spell.selfMana

            if (pressed or (hpTrigger and mpTrigger) or hpTrigger) and (not spell.totalCooldown or spell.totalCooldown <= time)
            then
                return forceSay(spell)
            end

        end
    end
end)

onTalk(function(name, level, mode, text, channelId, pos)
    if name ~= player:getName() then
        return
    end

    text = text:lower()
    local time = os.time()
    for _, spell in ipairs(storageProfiles.fugaSpells) do
        if spell.enabled and spell.orangeSpell and text == spell.orangeSpell then

            spell.activeCooldown = (spell.cooldownActive and spell.cooldownActive > 0)
                and (time + spell.cooldownActive)
                or nil

            spell.totalCooldown = (spell.cooldownTotal and spell.cooldownTotal > 0)
                and (time + spell.cooldownTotal)
                or nil
            return
        end
    end
end)

macro(200, function()
    for name, expire in pairs(storage.Attacking) do
        if expire < now then
            storage.Attacking[name] = nil
        end
    end
end)

onTextMessage(function(mode, text)
    text = text:lower()
    if not text:find("attack by") then return end

    for _, p in ipairs(getSpectators(posz())) do
        if p:isPlayer() and text:find(p:getName():lower()) then
            storage.Attacking[p:getName()] = now + 1000 -- 1s
            break
        end
    end
end)