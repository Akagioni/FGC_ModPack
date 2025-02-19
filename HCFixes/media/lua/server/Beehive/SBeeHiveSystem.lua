---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by Robotex140.
--- Based on Zomboid RainCollectorBarrel
--- DateTime: 16-Jan-22 15:58
---

--***********************************************************
--**                    THE INDIE STONE                    **
--***********************************************************

if isClient() then return end

require "Map/SGlobalObjectSystem"

SBeehiveSystem = SGlobalObjectSystem:derive("SBeehiveSystem")

function SBeehiveSystem:new()
    local o = SGlobalObjectSystem.new(self, "Beehive")
    return o
end

function SBeehiveSystem:initSystem()
    SGlobalObjectSystem.initSystem(self)

    -- Specify GlobalObjectSystem fields that should be saved.
    self.system:setModDataKeys({})

    -- Specify GlobalObject fields that should be saved.
    self.system:setObjectModDataKeys({'exterior', 'honeyAmount', 'honeyMax', 'pollenAmount'})

    self:convertOldModData()
end

function SBeehiveSystem:newLuaObject(globalObject)
    print('creating new lua object for hive')
    return SBeehiveGlobalObject:new(self, globalObject)
end

function SBeehiveSystem:isValidIsoObject(isoObject)
    return instanceof(isoObject, "IsoThumpable") and isoObject:getName() == "beehive_global"
end

function SBeehiveSystem:convertOldModData()
    if self.system:loadedWorldVersion() ~= -1 then return end
end


local function OnClientCommand(module, command, player, args)
    if module ~= 'Beehive' then return end
	print('Beehive OnClientCommand received command '..command)
    if SBeehiveSystemCommands[command] then
        local argStr = ''
        for k,v in pairs(args) do argStr = argStr..' '..k..'='..v end
        SBeehiveSystem:noise('OnClientCommand '..module..' '..command..argStr)
        -- should be call SBeehiveSystem.instance:receiveCommand but for some reason doesnt work
        -- SBeehiveSystem.instance:receiveCommand(player, command, args)
        SBeehiveSystemCommands[command](player, args)
    end
end

Events.OnClientCommand.Add(OnClientCommand)

function SBeehiveSystem:makeHoney()
    -- print('called makeHoney')
    for i=1,self:getLuaObjectCount() do
        local luaObject = self:getLuaObjectByIndex(i)
        --print('found beehive at  '..luaObject.x..","..luaObject.y..","..luaObject.z)
        local isoObject = luaObject:getIsoObject()
     --   print(i..': honey Amount: '..luaObject.honeyAmount..' max: '..luaObject.honeyMax..' pollen Amount: '..luaObject.pollenAmount)
        if luaObject.honeyAmount < 0 and ZombRand(5) == 0 then
            luaObject.honeyAmount = 0
        end

        if luaObject.honeyAmount < luaObject.honeyMax then
            local square = luaObject:getSquare()
            if square then
                luaObject.exterior = square:isOutside()
            end
            if luaObject.exterior and (not isWinter()) and luaObject.honeyAmount >=0 then
                make_honey_amount = math.min(luaObject.honeyMax - luaObject.honeyAmount, luaObject.pollenAmount, 12)
                luaObject.honeyAmount = luaObject.honeyAmount + make_honey_amount
                luaObject.pollenAmount = luaObject.pollenAmount - make_honey_amount
                luaObject:syncAll()
                luaObject:changeSprite()
            end
        end
    end
end

function SBeehiveSystem:receiveCommand(playerObj, command, args)
    SBeehiveSystemCommands[command](playerObj, args)
end

SGlobalObjectSystem.RegisterSystemClass(SBeehiveSystem)

-- -- -- -- --

local noise = function(msg)
    SBeehiveSystem.instance:noise(msg)
end

-- every 10 minutes we check the hives
local function EveryTenMinutes()
    SBeehiveSystem.instance:makeHoney()
end

-- every 10 minutes event 
Events.EveryTenMinutes.Add(EveryTenMinutes)

