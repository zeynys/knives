--- @param player Player
function LoadKnivesPlayerData(player)
    if player:IsFakeClient() then return end
    if not db:IsConnected() then return end

    db:QueryParams("select * from knives where steamid = '@steamid' limit 1", { steamid = player:GetSteamID() },
        function(err, result)
            if #err > 0 then
                return print("ERROR: " .. err)
            end

            if #result == 0 then
                player:SetVar("knives.t", "")
                player:SetVar("knives.ct", "")
                player:SetVar("knives.data", "{}")
            else
                player:SetVar("knives.t", result[1].t)
                player:SetVar("knives.ct", result[1].ct)
                player:SetVar("knives.data", result[1].knives_data)
            end
        end)
end

--- @param player Player
function GetPlayerKnives(player)
    return {
        t = (player:GetVar("knives.t") or ""),
        ct = (player:GetVar("knives.ct") or ""),
        data = (json.decode(player:GetVar("knives.data") or "{}") or {})
    }
end

--- @param player Player
--- @param team "t"|"ct"
--- @param knifeidx string
function UpdatePlayerKnives(player, team, knifeidx)
    if player:IsFakeClient() then return end
    if not db:IsConnected() then return end
    if team ~= "t" and team ~= "ct" then return end

    player:SetVar("knives." .. team, knifeidx)

    local params = {
        steamid = player:GetSteamID(),
        t = "",
        ct = "",
    }

    db:QueryParams(
        "insert ignore into knives (steamid, t, ct, knives_data) values ('@steamid', '@t', '@ct', '{}')",
        params
    )

    params = {
        steamid = player:GetSteamID(),
        team = team,
        knifeidx = knifeidx
    }

    db:QueryParams("update knives set `@team` = '@knifeidx' where `steamid` = '@steamid' limit 1", params)
end

--- @param player Player
--- @param knifeidx string
--- @param field "seed"|"wear"|"nametag"
--- @param value number|string
function UpdatePlayerKnivesData(player, knifeidx, field, value)
    if player:IsFakeClient() then return end
    if not db:IsConnected() then return end

    if not player:GetVar("knives.data") then
        player:SetVar("knives.data", "{}")
    end

    local knivesData = json.decode(player:GetVar("knives.data") or "{}") or {}
    if not knivesData[knifeidx] then
        math.randomseed(math.floor(server:GetTickCount()))
        knivesData[knifeidx] = {
            wear = 0.0,
            seed = math.random(0, 1000),
            nametag = ""
        }
    end

    if knivesData[knifeidx][field] then
        knivesData[knifeidx][field] = value
    end

    player:SetVar("knives.data", json.encode(knivesData))

    db:QueryParams(
        "insert ignore into knives (steamid, t, ct, knives_data) values ('@steamid', '', '', '{}')",
        { steamid = player:GetSteamID() }
    )

    db:QueryParams("update knives set knives_data = '@knivesdata' where steamid = '@steamid' limit 1",
        { knivesdata = json.encode(knivesData), steamid = player:GetSteamID() })
end

--- @param weapon CBasePlayerWeapon
--- @param paint_index number
--- @param seed number
--- @param wear number
--- @param nametag string
function GiveWeaponSkin(weapon, paint_index, seed, wear, nametag)
    weapon.Parent.FallbackPaintKit = paint_index
    weapon.Parent.FallbackSeed = seed
    weapon.Parent.FallbackWear = wear
    if nametag ~= "" then weapon.Parent.AttributeManager.Item.CustomName = nametag end

    weapon.Parent.AttributeManager.Item.NetworkedDynamicAttributes:SetOrAddAttributeValueByName(
        "set item texture prefab", paint_index + 0.0)
    weapon.Parent.AttributeManager.Item.NetworkedDynamicAttributes:SetOrAddAttributeValueByName(
        "set item texture seed", seed + 0.0)
    weapon.Parent.AttributeManager.Item.NetworkedDynamicAttributes:SetOrAddAttributeValueByName(
        "set item texture wear", wear)

    weapon.Parent.AttributeManager.Item.AttributeList:SetOrAddAttributeValueByName(
        "set item texture prefab", paint_index + 0.0)
    weapon.Parent.AttributeManager.Item.AttributeList:SetOrAddAttributeValueByName(
        "set item texture seed", seed + 0.0)
    weapon.Parent.AttributeManager.Item.AttributeList:SetOrAddAttributeValueByName(
        "set item texture wear", wear)
end

--- @param player Player
function UpdatePlayerKnife(player)
    if not player:CBaseEntity():IsValid() then return end
    if player:CBaseEntity().TeamNum ~= Team.CT and player:CBaseEntity().TeamNum ~= Team.T then return end

    local knifeTeam = (player:CBaseEntity().TeamNum == Team.T and "_t" or "")
    local team = (player:CBaseEntity().TeamNum == Team.T and "t" or "ct")

    if player:IsFakeClient() then
        return NextTick(function()
            player:GetWeaponManager():GiveWeapon("weapon_knife" .. knifeTeam)
        end)
    end

    local weapons = player:GetWeaponManager():GetWeapons()
    for i = 1, #weapons do
        --- @type Weapon
        local weapon = weapons[i]
        if weapon:CCSWeaponBaseVData().GearSlot == gear_slot_t.GEAR_SLOT_KNIFE then
            weapon:Remove()
            break
        end
    end

    local knives = GetPlayerKnives(player)
    if knives[team] ~= "" then
        NextTick(function()
            player:GetWeaponManager():GiveWeapon(KnifeWeaponIdx[knives[team]].weaponid)
        end)
    else
        NextTick(function()
            player:GetWeaponManager():GiveWeapon("weapon_knife" .. knifeTeam)
        end)
    end
end
