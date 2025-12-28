setDefaultTab("Tools")
a = function(name)
    if type(name) ~= 'string' then
        name = name:getName()
    end
    return table.find(storage.playerList.friendList, name, true)
end

enemy = macro(300, 'Enemy', function()
    local possibleTarget = false

    for _, creature in ipairs(getSpectators(posz())) do
        local specHP = creature:getHealthPercent()
        if creature:isPlayer() and specHP and specHP > 0 then
            if not isFriend(creature) and creature:getEmblem() ~= 1 then
                if creature:canShoot(9) then
                    if not possibleTarget or possibleTargetHP > specHP or (possibleTargetHP == specHP and possibleTarget:getId() < creature:getId()) then
                        possibleTarget = creature
                        possibleTargetHP = possibleTarget:getHealthPercent()
                    end
                end
            end
        end
    end
    if possibleTarget and g_game.getAttackingCreature() ~= possibleTarget then
        g_game.attack(possibleTarget)
    end
end)
enemyIcon = addIcon("enemy", {item = 134 , text = "enemy"}, enemy)

isEnemy = function(name)
    if type(name) ~= 'string' then
        name = name:getName()
    end
    name = name:trim()

    local pl = storage.playerList
    if not pl then return false end

    local enemyList = pl.enemyList or {}
    local blackList = pl.blackList or {}

    if #enemyList == 0 and #blackList == 0 then
        return false
    end

    return table.find(enemyList, name, true)
        or table.find(blackList, name, true)
end

addSeparator()

Attackenemy = macro(200, 'Attack Enemy-List', function()
    local pos = pos()
    local actualTarget
    for _, creature in ipairs(getSpectators(pos)) do
        local specHp = creature:getHealthPercent()
        local specPos = creature:getPosition()
        if creature:isPlayer() and specHp and specHp > 0 then
            if isEnemy(creature) then
                if creature:canShoot() then
                    if not actualTarget or actualTargetHp > specHp or (actualTargetHp == specHp and getDistanceBetween(pos, actualTargetPos) > getDistanceBetween(specPos, pos)) then
                        actualTarget, actualTargetPos, actualTargetHp = creature, specPos, specHp
                    end
                end
            end
        end
    end
    if actualTarget and g_game.getAttackingCreature() ~= actualTarget then
        g_game.attack(actualTarget)
    end
end)
AttackenemyIcon = addIcon("Attackenemy", {item =12977 , text = "Attack\n enemy"}, Attackenemy)

UI.Separator()
Panels.AttackLeaderTarget(batTab)  
UI.Separator()
UI.Label("Combo:")
UI.Separator()
chaseIcon = macro(250, "Chase", function()
    if g_game.isAttacking() then
          g_game.setChaseMode(1)
    end
  end)

  local targetID = nil
  
  -- escape when attacking will reset hold target
  onKeyPress(function(keys)
      if keys == "Escape" and targetID then
          targetID = nil
      end
  end)
  onTextMessage(function(mode, text)
    if text ~= "You may not attack a person while you are in a protection zone." then
        return
    end
    targetID = nil
    g_game.cancelAttack()
end)

chaseIcon = addIcon ("Chase", {item = 12793, text ="Chase"}, chaseIcon)

AttackTarget = macro(100, "Attack Target", function()
      if target() and target():getPosition().z == posz() and not target():isNpc() then
          targetID = target():getId()
      elseif not target() then
          if not targetID then return end
            for i, spec in ipairs(getSpectators()) do
              local sameFloor = spec:getPosition().z == posz()
              local oldTarget = spec:getId() == targetID
              
              if sameFloor and oldTarget then
                  attack(spec)
              end
          end
      end
  end)
AttackTargetIcon = addIcon("Attack Target", {item =2028 , text = "Attack\n Target"}, AttackTarget)


Turn = {}
Turn.maxDistance = {x = 7, y = 7}
Turn.minDistance = 1
Turn.macro = macro(1, 'Virar para o alvo', function()
    local target = g_game.getAttackingCreature()
    if target then
        local targetPos = target:getPosition()
        if targetPos then
            local pos = pos()
            local targetDistance = {x = math.abs(pos.x - targetPos.x), y = math.abs(pos.y - targetPos.y)}
            if not (targetDistance.x > Turn.minDistance and targetDistance.y > Turn.minDistance) then
                if targetDistance.x <= Turn.maxDistance.x and targetDistance.y <= Turn.maxDistance.y then
                    local playerDir = player:getDirection()
                    if targetDistance.y >= targetDistance.x then
                        if targetPos.y > pos.y then
                            return playerDir ~= 2 and turn(2)
                        else
                            return playerDir ~= 0 and turn(0)
                        end
                    else
                        if targetPos.x > pos.x then
                            return playerDir ~= 1 and turn(1)
                        else
                            return playerDir ~= 3 and turn(3)
                        end
                    end
                end
            end
        end
    end
end)
UI.Separator()
UI.Label("Mystic")
UI.Separator()

mysticMacro = macro(1, "Mystic Kai & Def", function()
    local manaPercent = manapercent();
    local healthPercent = hppercent();
    local hasManaShield = hasManaShield();

    if (healthPercent < manaPercent - 15) then
        if (not hasManaShield) then
            cast_spell = "Mystic Defense";
            status = true;
        end
    elseif (hasManaShield) then
        if (healthPercent > manaPercent + 5 or healthPercent > 85) then
            cast_spell = "Mystic Kai";
            status = false;
        end
    end

    if (cast_spell ~= nil) then
        if (status == hasManaShield) then
            cast_spell = nil;
            return;
        end
        return say(cast_spell);
    end
end);
macro(1, 'Mystic/Heal', function()
    if pr and pr >= now then
        return
    end
    local hasManaShield = hasManaShield()
    local hpPercent = hppercent()
    local manaPercent = manapercent()
    if manaPercent < hpPercent - 15 and hasManaShield then
        return say('Mystic Kai')
    elseif (hpPercent < manaPercent - 15 or manaPercent >= 90) and not hasManaShield then
        return say('Mystic Defense')
    end
end)

macro(1, "Mystic Defense", function()
    if pr and pr >= now then
        return
    end
    if hppercent() <= 80 and manapercent() >= 80 and not hasManaShield() then
        say("mystic defense")
    elseif hppercent() >= 70 and hasManaShield() or hppercent() >= 70 and manapercent() <= 40 and hasManaShield() then
        say("mystic kai")
    end
end)
reiatsuFull = function()
    if not hasManaShield() then
        say("Mystic Defense")
    end
end


macro(100, "Mystic Defense Full", reiatsuFull);
UI.Separator()
UI.Label("Senzu/Regeneration")
UI.Separator()

local s = {}
SenzuHeal = macro(100, "Potion", function()
    local configSenzu = storage.potion:split(",");
    if (hppercent() <= tonumber(configSenzu[2]) or manapercent() <= tonumber(configSenzu[3])) and (not s.cdW or s.cdW <= now) then
        useWith(tonumber(configSenzu[1]), player)
    end
end)
onUseWith(function(pos, itemId, target, subType)
    local configSenzu = storage.potion:split(",");
    if itemId == tonumber(configSenzu[1]) then
        s.cdW = now + tonumber(configSenzu[4])
    end
end)
addTextEdit("Config Potion", storage.potion or "ID, HP, MP, CD", function(widget, text)
    if text and #text:split(",") < 4 then
        return warn("por favor, inserir os valores na ordem (ID, HP, MP, CD)")
    end
    storage.potion = text
end)
addIcon("Senzu Heal", {item = 3040, text = "Senzu\n Heal"}, SenzuHeal)

ComboHeal = macro(100, "Heal", function() if  (hppercent() <= 95) then say("Big Regeneration") end end)
addIcon("Heal", {item = 239, text = "Heal"},ComboHeal)
UI.Separator()
UI.Label("Utilitarios:")
UI.Separator()

Speed = macro(100, "Speed", function()
    if (not hasHaste() or isParalyzed()) then
        say("Super Speed")
    end
end);
powerdown = macro(300, "Powerdown", function() 
    if manapercent() > 30 then 
        say("Power down")
    end
end)
macro(250, "Powerdown/Pcave",  function()
    local specAmountPW = 0
     if not g_game.isAttacking() then
         return
     end
     for i,mob in ipairs(getSpectators()) do
         if (getDistanceBetween(player:getPosition(), mob:getPosition())  <= 3 and mob:isMonster())  then
             specAmountPW = specAmountPW + 1
         end
     end
     if (specAmountPW <= 2) and manapercent() > 70 then
        say("Power down")
     end
 end)