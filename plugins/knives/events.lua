AddEventHandler("OnPluginStart", function(event)
    db = Database("knives")
    if not db:IsConnected() then return end

    db:QueryBuilder():Table("knives"):Create({
        steamid = "string|max:128|unique",
        t = "string|max:128",
        ct = "string|max:128",
        knives_data = "json|default:{}"
    }):Execute(function (err, result)
        if #err > 0 then
            print("ERROR: " .. err)
        end
    end)

    local jsonData = json.decode(files:Read(GetPluginPath(GetCurrentPluginName()) .. "/data/skins.json"))
    if not jsonData then return end

    for i = 1, #jsonData do
        if jsonData[i].category.id == "sfui_invpanel_filter_melee" then
            table.insert(KnivesData,
                {
                    id = jsonData[i].id,
                    paint_index = tonumber(jsonData[i].paint_index),
                    name = (jsonData[i].phase ~= nil and jsonData[i].name .. " (" .. jsonData[i].phase .. ")" or jsonData[i].name),
                    weaponid = jsonData[i].weapon.id
                })

            KnifeWeaponIdx[jsonData[i].id] = {
                paint_index = tonumber(jsonData[i].paint_index),
                name = (jsonData[i].phase ~= nil and jsonData[i].name .. " (" .. jsonData[i].phase .. ")" or jsonData[i].name),
                weaponid = jsonData[i].weapon.id
            }
        end
    end

    for i = 1, playermanager:GetPlayerCap() do
        local player = GetPlayer(i - 1)
        if player then
            LoadKnivesPlayerData(player)
        end
    end

    config:Create("knives", {
        prefix = "[{lime}Knives{default}]",
        color = "00B869",
    })
end)

AddEventHandler("OnPlayerConnectFull", function(event)
    local playerid = event:GetInt("userid")
    local player = GetPlayer(playerid)
    if not player then return end

    LoadKnivesPlayerData(player)
end)

AddEventHandler("OnClientChat", function(event, playerid, text, teamonly)
    local player = GetPlayer(playerid)
    if not player then return end

    if player:GetVar("knives.manualseed") == true then
        if tonumber(text) then
            player:ExecuteCommand("sw_knife_setseed \"" ..
                player:GetVar("knives.knifeid") .. "\" manual " .. text)

            event:SetReturn(false)
            return EventResult.Handled
        end
    elseif player:GetVar("knives.manualwear") == true then
        if tonumber(text) then
            player:ExecuteCommand("sw_knife_setwear \"" ..
                player:GetVar("knives.knifeid") .. "\" manual " .. text)

            event:SetReturn(false)
            return EventResult.Handled
        end
    elseif player:GetVar("knives.manualnametag") == true then
        player:ExecuteCommand("sw_knife_setnametag \"" ..
            player:GetVar("knives.knifeid") .. "\" \"" .. text .. "\"")

        event:SetReturn(false)
        return EventResult.Handled
    end

    return EventResult.Continue
end)

AddEventHandler("OnPlayerSpawn", function(event)
    local player = GetPlayer(event:GetInt("userid"))
    if not player then return end

    UpdatePlayerKnife(player)
end)

AddEventHandler("OnRoundStart", function(event)
    convar:Set("mp_t_default_melee", "")
    convar:Set("mp_ct_default_melee", "")
    convar:Set("mp_equipment_reset_rounds", "0")
end)

AddEventHandler("OnEntityCreated", function(event, entityptr)
    local designername = CEntityInstance(entityptr).Entity.DesignerName

    if designername == "weapon_knife" then
        NextTick(function()
            local ownerentity = CBaseEntity(entityptr).OwnerEntity
            if not ownerentity:IsValid() then return end
            local originalcontroller = CCSPlayerPawnBase(ownerentity:ToPtr()).OriginalController
            if not originalcontroller:IsValid() then return end
            local player = GetPlayer(originalcontroller.Parent:EntityIndex() - 1)
            if not player then return end
            if player:IsFakeClient() then return end
            if not player:CBaseEntity():IsValid() then return end

            local playerdata = GetPlayerKnives(player)
            local team = (player:CBaseEntity().TeamNum == Team.T and "t" or "ct")

            if playerdata[team] ~= "" then
                local knifeid = playerdata[team]

                local paint_index = KnifeWeaponIdx[knifeid].paint_index
                local seed = (playerdata.data[knifeid] or { seed = math.random(0, 1000) }).seed
                local wear = (playerdata.data[knifeid] or { wear = 0.0 }).wear
                local nametag = (playerdata.data[knifeid] or { nametag = "" }).nametag

                GiveWeaponSkin(CBasePlayerWeapon(entityptr), paint_index, seed, wear, nametag)
            end
        end)
    end
end)

AddEventHandler("OnItemPickup", function(event)
    local player = GetPlayer(event:GetInt("userid"))
    if not player then return end
    if player:IsFakeClient() then return end

    local weapons = player:GetWeaponManager():GetWeapons()

    for i = 1, #weapons do
        if CBaseEntity(weapons[i]:CBasePlayerWeapon():ToPtr()).Parent.Entity.DesignerName:find("knife") then
            if not player:CBaseEntity():IsValid() then return end

            local playerdata = GetPlayerKnives(player)
            local team = (player:CBaseEntity().TeamNum == Team.T and "t" or "ct")

            if playerdata[team] ~= "" then
                local knifeid = playerdata[team]

                local paint_index = KnifeWeaponIdx[knifeid].paint_index
                local seed = (playerdata.data[knifeid] or { seed = math.random(0, 1000) }).seed
                local wear = (playerdata.data[knifeid] or { wear = 0.0 }).wear
                local nametag = (playerdata.data[knifeid] or { nametag = "" }).nametag

                GiveWeaponSkin(weapons[i]:CBasePlayerWeapon(), paint_index, seed, wear, nametag)
            end
        end
    end
end)
