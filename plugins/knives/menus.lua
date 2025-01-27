commands:Register("knife", function(playerid, args, argc, silent, prefix)
    if playerid == -1 then return end
    local player = GetPlayer(playerid)
    if not player then return end

    local menuOptions = {}
    local registeredCategories = {}

    for i = 1, #KnivesData do
        local category = KnivesData[i].name:split("|")[1]:trim()
        if not registeredCategories[category] then
            registeredCategories[category] = true
            table.insert(menuOptions, { category, "sw_selectcategory_knife \"" .. category .. "\"" })
        end
    end

    local menuid = "knife_menu_" .. GetTime()
    menus:RegisterTemporary(menuid, FetchTranslation("knives.menu.title"),
        config:Fetch("knives.color"), menuOptions)

    player:HideMenu()
    player:ShowMenu(menuid)
end)

commands:Register("selectcategory_knife", function(playerid, args, argc, silent, prefix)
    if playerid == -1 then return end
    local player = GetPlayer(playerid)
    if not player then return end
    if argc ~= 1 then return end

    local menuOptions = {}
    local knifeCategory = args[1]

    for i = 1, #KnivesData do
        if KnivesData[i].name:find("|") then
            local category = KnivesData[i].name:split("|")[1]:trim()
            if category == knifeCategory then
                local name = KnivesData[i].name:split("|")[2]:trim()
                table.insert(menuOptions, { name, "sw_selectknife \"" .. KnivesData[i].id .. "\"" })
            end
        end
    end

    local menuid = "select_knife_menu_" .. GetTime()
    menus:RegisterTemporary(menuid, knifeCategory, config:Fetch("knives.color"), menuOptions)

    player:HideMenu()
    player:ShowMenu(menuid)
end)

commands:Register("selectknife", function(playerid, args, argc, silent, prefix)
    if playerid == -1 then return end
    local player = GetPlayer(playerid)
    if not player then return end
    if argc ~= 1 then return end

    local knifeid = args[1]
    if not KnifeWeaponIdx[knifeid] then return end

    local menuid = "select_knife_menu_" .. GetTime()
    menus:RegisterTemporary(menuid, KnifeWeaponIdx[knifeid].name, config:Fetch("knives.color"), {
        { FetchTranslation("knives.menu.equipfor"),   "sw_knife_equipfor \"" .. knifeid .. "\"" },
        { FetchTranslation("knives.menu.setseed"),    "sw_knife_setseedfor \"" .. knifeid .. "\"" },
        { FetchTranslation("knives.menu.setwear"),    "sw_knife_setwearfor \"" .. knifeid .. "\"" },
        { FetchTranslation("knives.menu.setnametag"), "sw_knife_setnametag \"" .. knifeid .. "\" menu" },
        { FetchTranslation("core.menu.back"),         "sw_selectcategory_knives \"" .. KnifeWeaponIdx[knifeid].name:split("|")[1]:trim() .. "\"" }
    })

    player:HideMenu()
    player:ShowMenu(menuid)
end)

commands:Register("knife_equipfor", function(playerid, args, argc, silent, prefix)
    if playerid == -1 then return end
    local player = GetPlayer(playerid)
    if not player then return end
    if argc ~= 1 then return end

    local knifeid = args[1]
    if not KnifeWeaponIdx[knifeid] then return end

    local data = GetPlayerKnives(player)

    local menuid = "equipfor_knife_menu_" .. GetTime()
    menus:RegisterTemporary(menuid, KnifeWeaponIdx[knifeid].name .. " - " .. FetchTranslation("knives.menu.equip"),
        config:Fetch("knives.color"), {
            { "[" .. (data.ct == knifeid and "✔️" or "❌") .. "] " .. FetchTranslation("knives.menu.ct"), "sw_knife_equip \"" .. knifeid .. "\" ct" },
            { "[" .. (data.t == knifeid and "✔️" or "❌") .. "] " .. FetchTranslation("knives.menu.t"), "sw_knife_equip \"" .. knifeid .. "\" t" },
            { FetchTranslation("core.menu.back"), "sw_selectknife \"" .. knifeid .. "\"" }
        })

    player:HideMenu()
    player:ShowMenu(menuid)
end)

commands:Register("knife_equip", function(playerid, args, argc, silent, prefix)
    if playerid == -1 then return end
    local player = GetPlayer(playerid)
    if not player then return end
    if argc ~= 2 then return end

    local knifeid = args[1]
    if not KnifeWeaponIdx[knifeid] then return end

    local team = args[2]
    if team ~= "t" and team ~= "ct" then return end

    local data = GetPlayerKnives(player)
    local equipped = (data[team] == knifeid)

    if equipped then
        UpdatePlayerKnives(player, team, "")
        ReplyToCommand(playerid, config:Fetch("knives.prefix"),
            FetchTranslation("knives.unequip"):gsub("{NAME}", KnifeWeaponIdx[knifeid].name):gsub("{TEAM}",
                FetchTranslation("knives.menu." .. team)))
    else
        UpdatePlayerKnives(player, team, knifeid)
        ReplyToCommand(playerid, config:Fetch("knives.prefix"),
            FetchTranslation("knives.equip"):gsub("{NAME}", KnifeWeaponIdx[knifeid].name):gsub("{TEAM}",
                FetchTranslation("knives.menu." .. team)))
    end

    UpdatePlayerKnife(player)

    player:ExecuteCommand("sw_knife_equipfor \"" .. knifeid .. "\"")
end)

commands:Register("knife_setseedfor", function(playerid, args, argc, silent, prefix)
    if playerid == -1 then return end
    local player = GetPlayer(playerid)
    if not player then return end
    if argc ~= 1 then return end

    local knifeid = args[1]
    if not KnifeWeaponIdx[knifeid] then return end

    local menuid = "select_seed_menu_" .. GetTime()
    menus:RegisterTemporary(menuid, KnifeWeaponIdx[knifeid].name, config:Fetch("knives.color"), {
        { FetchTranslation("knives.menu.random"), "sw_knife_setseed \"" .. knifeid .. "\" random" },
        { FetchTranslation("knives.menu.manual"), "sw_knife_setseed \"" .. knifeid .. "\" manual" },
        { FetchTranslation("core.menu.back"),     "sw_selectknife \"" .. knifeid .. "\"" }
    })

    player:HideMenu()
    player:ShowMenu(menuid)
end)

commands:Register("knife_setseed", function(playerid, args, argc, silent, prefix)
    if playerid == -1 then return end
    local player = GetPlayer(playerid)
    if not player then return end
    if argc < 2 then return end

    local knifeid = args[1]
    if not KnifeWeaponIdx[knifeid] then return end

    local mode = args[2]
    if mode == "manual" then
        local seed = tonumber(args[3] or 0)
        if args[3] and seed then
            if seed < 0 or seed > 1000 then
                return ReplyToCommand(playerid, config:Fetch("knives.prefix"),
                    FetchTranslation("knives.invalid"):gsub("{LIMIT}", "0-1000"):gsub("{CATEGORY}", "seed"))
            end

            player:SetVar("knives.manualseed", false)
            UpdatePlayerKnivesData(player, knifeid, "seed", seed)
            ReplyToCommand(playerid, config:Fetch("knives.prefix"),
                FetchTranslation("knives.update"):gsub("{CATEGORY}", "seed"):gsub("{VALUE}", seed))

            UpdatePlayerKnife(player)
            player:ExecuteCommand("sw_selectknife \"" .. knifeid .. "\"")
            if player:GetVar("knives.timerid") then
                StopTimer(player:GetVar("knives.timerid"))
                player:SetVar("knives.timerid", nil)
            end
        else
            player:SetVar("knives.manualseed", true)
            local timerid = SetTimer(4500, function()
                player:SendMsg(MessageType.Center,
                    FetchTranslation("knives.type_in_chat"):gsub("{COLOR}", config:Fetch("knives.color")):gsub(
                        "{CATEGORY}", "seed"):gsub("{LIMIT}", "0-1000"))
            end)
            player:SetVar("knives.knifeid", knifeid)
            player:SetVar("knives.timerid", timerid)
            player:HideMenu()
            player:SendMsg(MessageType.Center,
                FetchTranslation("knives.type_in_chat"):gsub("{COLOR}", config:Fetch("knives.color")):gsub(
                    "{CATEGORY}", "seed"):gsub("{LIMIT}", "0-1000"))
        end
    else
        math.randomseed(math.floor(server:GetTickCount()))
        local seed = math.random(0, 1000)

        UpdatePlayerKnivesData(player, knifeid, "seed", seed)

        UpdatePlayerKnife(player)
        ReplyToCommand(playerid, config:Fetch("knives.prefix"),
            FetchTranslation("knives.update"):gsub("{CATEGORY}", "seed"):gsub("{VALUE}", seed))
    end
end)

commands:Register("knife_setwearfor", function(playerid, args, argc, silent, prefix)
    if playerid == -1 then return end
    local player = GetPlayer(playerid)
    if not player then return end
    if argc ~= 1 then return end

    local knifeid = args[1]
    if not KnifeWeaponIdx[knifeid] then return end

    local menuid = "select_seed_menu_" .. GetTime()
    menus:RegisterTemporary(menuid, KnifeWeaponIdx[knifeid].name, config:Fetch("knives.color"), {
        { "Factory New",                          "sw_knife_setwear \"" .. knifeid .. "\" manual 0.0" },
        { "Minimal Wear",                         "sw_knife_setwear \"" .. knifeid .. "\" manual 0.08" },
        { "Field Tested",                         "sw_knife_setwear \"" .. knifeid .. "\" manual 0.16" },
        { "Well-Worn",                            "sw_knife_setwear \"" .. knifeid .. "\" manual 0.40" },
        { "Battle-Scared",                        "sw_knife_setwear \"" .. knifeid .. "\" manual 0.45" },
        { FetchTranslation("knives.menu.random"), "sw_knife_setwear \"" .. knifeid .. "\" random" },
        { FetchTranslation("knives.menu.manual"), "sw_knife_setwear \"" .. knifeid .. "\" manual" },
        { FetchTranslation("core.menu.back"),     "sw_selectknife \"" .. knifeid .. "\"" }
    })

    player:HideMenu()
    player:ShowMenu(menuid)
end)

commands:Register("knife_setwear", function(playerid, args, argc, silent, prefix)
    if playerid == -1 then return end
    local player = GetPlayer(playerid)
    if not player then return end
    if argc < 2 then return end

    local knifeid = args[1]
    if not KnifeWeaponIdx[knifeid] then return end

    local mode = args[2]
    if mode == "manual" then
        local wear = tonumber(args[3] or 0.0)
        if args[3] and wear then
            if wear < 0.0 or wear > 1.0 then
                return ReplyToCommand(playerid, config:Fetch("knives.prefix"),
                    FetchTranslation("knives.invalid"):gsub("{LIMIT}", "0.0-1.0"):gsub("{CATEGORY}", "wear"))
            end

            player:SetVar("knives.manualwear", false)
            UpdatePlayerKnivesData(player, knifeid, "wear", wear)
            ReplyToCommand(playerid, config:Fetch("knives.prefix"),
                FetchTranslation("knives.update"):gsub("{CATEGORY}", "wear"):gsub("{VALUE}", wear))

            UpdatePlayerKnife(player)
            player:ExecuteCommand("sw_selectknife \"" .. knifeid .. "\"")

            if player:GetVar("knives.timerid") then
                StopTimer(player:GetVar("knives.timerid"))
                player:SetVar("knives.timerid", nil)
            end
        else
            player:SetVar("knives.manualwear", true)
            local timerid = SetTimer(4500, function()
                player:SendMsg(MessageType.Center,
                    FetchTranslation("knives.type_in_chat"):gsub("{COLOR}", config:Fetch("knives.color")):gsub(
                        "{CATEGORY}", "wear"):gsub("{LIMIT}", "0.0-1.0"))
            end)
            player:SetVar("knives.knifeid", knifeid)
            player:SetVar("knives.timerid", timerid)
            player:HideMenu()
            player:SendMsg(MessageType.Center,
                FetchTranslation("knives.type_in_chat"):gsub("{COLOR}", config:Fetch("knives.color")):gsub(
                    "{CATEGORY}", "wear"):gsub("{LIMIT}", "0.0-1.0"))
        end
    else
        math.randomseed(math.floor(server:GetTickCount()))
        local wear = math.random()

        UpdatePlayerKnivesData(player, knifeid, "wear", wear)

        UpdatePlayerKnife(player)

        ReplyToCommand(playerid, config:Fetch("knives.prefix"),
            FetchTranslation("knives.update"):gsub("{CATEGORY}", "wear"):gsub("{VALUE}", wear))
    end
end)

commands:Register("knife_setnametag", function(playerid, args, argc, silent, prefix)
    if playerid == -1 then return end
    local player = GetPlayer(playerid)
    if not player then return end
    if argc < 2 then return end

    local knifeid = args[1]
    if not KnifeWeaponIdx[knifeid] then return end

    local mode = args[2]
    if mode == "menu" then
        player:SetVar("knives.manualnametag", true)
        local timerid = SetTimer(4500, function()
            player:SendMsg(MessageType.Center,
                FetchTranslation("knives.type_in_chat"):gsub("{COLOR}", config:Fetch("knives.color")):gsub(
                    "{CATEGORY}", "nametag"):gsub("{LIMIT}", FetchTranslation("knives.clear")))
        end)
        player:SetVar("knives.knifeid", knifeid)
        player:SetVar("knives.timerid", timerid)
        player:HideMenu()
        player:SendMsg(MessageType.Center,
            FetchTranslation("knives.type_in_chat"):gsub("{COLOR}", config:Fetch("knives.color")):gsub(
                "{CATEGORY}", "nametag"):gsub("{LIMIT}", FetchTranslation("knives.clear")))
    else
        local input = args[2]
        if not player:GetVar("knives.manualnametag") then return end

        if input == "clear" then input = "" end

        player:SetVar("knives.manualnametag", false)
        UpdatePlayerKnivesData(player, knifeid, "nametag", input)
        ReplyToCommand(playerid, config:Fetch("knives.prefix"),
            FetchTranslation("knives.update"):gsub("{CATEGORY}", "nametag"):gsub("{VALUE}",
                input == "" and FetchTranslation("knives.none") or input))
        UpdatePlayerKnife(player)
        player:ExecuteCommand("sw_selectknife \"" .. knifeid .. "\"")

        if player:GetVar("knives.timerid") then
            StopTimer(player:GetVar("knives.timerid"))
            player:SetVar("knives.timerid", nil)
        end
    end
end)
