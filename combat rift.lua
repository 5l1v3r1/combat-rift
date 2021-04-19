local repl = game:GetService("ReplicatedStorage")
local workspace = game:GetService("Workspace")
local plr = game:GetService('Players').LocalPlayer
local run = game:GetService('RunService');run=run.RenderStepped or run.HeartBeat

-- services
local Server = require(repl.ClientController.Services.ServerServices)

local Enemies = require(repl.Modules.Storage.Enemies)
local Swords = require(repl.Modules.Storage.Swords)
local Regions = workspace.EnemySpawnRegions
local CharacterEvents = Server.Character.Events

-- remotes
local Sell = require(repl.ClientController.Services.TouchManager.TouchClasses.Sell)
Sell = Sell.TouchManager.Server.SellSkulls
local ActivateSword = CharacterEvents.ActivateSword

do -- loading tables 
    tbl = {}
    for i,v in pairs(Enemies) do
        local modtb = v
        modtb.Index = i
        
        tbl[v.Name] = modtb
    end
    Enemies = tbl
    
    tbl = {}
    for i,v in pairs(Swords) do
        tbl[v.Name] = v
    end
    Swords = tbl
end

local char = setmetatable({},{
    __index = function(self,v)
        return plr.Character and plr.Character[v] or nil
    end
})

local gamedata = {
    Sword = setmetatable({},{
        __index = function(self,arg)
            local sword
        
            for i,v in pairs(plr.Character:GetChildren()) do
               if Swords[v.Name] then
                   sword = v
               end
            end
            
            for i,v in pairs(Swords) do
                if v.Name == sword.Name then
                    return v[arg]
                end
            end
        end
    })
}

do -- functions
    function getEnemies()
        local tbl = {}
        for i,v in pairs(Regions:GetChildren()) do
            if tonumber(v.Name) and v:IsA('Folder') then
                for i,v in pairs(v:GetChildren()) do
                    local vhum = v:FindFirstChildOfClass('Humanoid')
                    local id = v:FindFirstChild('EnemyValue')
                    
                    if vhum and id then
                        for i,e in pairs(Enemies) do
                            if id.Value == e.Index then
                                v.Name = i
                            end
                        end
                        table.insert(tbl,v)
                    end
                end
            end
        end
        return tbl
    end
    
    function canBeat(v)
        local data = Enemies[v.Name]
        local vhum = v:FindFirstChildOfClass('Humanoid')
        
        if not (vhum and data and vhum.Health > 0) then return nil end
        
        local a1 = vhum.Health
        local a2 = gamedata.Sword.Damage
        local a3 = a1/a2
        
        local p1 = char.Humanoid.Health
        local p2 = data.Damage
        local p3 = p1/p2

        return a3 < p3
    end
    
    function findEnemie()
        local last
        
        for i,v in pairs(getEnemies()) do
            if last and canBeat(v) then
                last = v
            elseif canBeat(v) then
                last = v
            end
        end
        return last
    end
end

while wait() do
    local v = findEnemie()
    local vroot = v and v.PrimaryPart
    local vhum = vroot and v:FindFirstChildOfClass('Humanoid')
    local root = char.PrimaryPart
    local hum = char.Humanoid

    while run:wait() and vhum and hum and vroot and root and vhum.Health > 0 do
        hum:ChangeState(11)
        root.CFrame = vroot.CFrame*CFrame.new(0,0,4)
        root.CFrame = CFrame.new(root.Position, vroot.Position)
        ActivateSword()
    end
    
    if root then
        local sell = Workspace.BuildingMapStuff.Map.Map1.MapDecoration.Fountain.Sell
        
        hum:ChangeState(11)
        root.CFrame = sell.CFrame
        
        Sell(sell)
    end
end