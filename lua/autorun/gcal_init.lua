if SERVER then
    AddCSLuaFile("gcal/gcal_lerp.lua")
    AddCSLuaFile("gcal/gcal_core.lua")
    AddCSLuaFile("gcal/gcal_compat.lua")
    AddCSLuaFile("gcal/gcal_legs.lua")
    AddCSLuaFile("gcal/gcal_base_anims.lua")
    AddCSLuaFile("gcal/gcal_menu.lua")
    AddCSLuaFile("gcal/gcal_debug_menu.lua")
    AddCSLuaFile("autorun/client/gcal_menu_autorun.lua")
end

if CLIENT then
    GCAL = GCAL or {}
    GCAL.ConflictingWorkshopAddons = GCAL.ConflictingWorkshopAddons or {
        ["2155366756"] = "VManip (Base)",
        ["3262499127"] = "Chen's VManip Patch",
        ["3080114310"] = "VManip (Base) Remix 2024",
        ["3039950711"] = "VManip (Fix_and_function)",
        ["3425927104"] = "Vmanip Base with knockdown",
        ["2844472642"] = "Vmanip +",
        ["3714993549"] = "Vmanip (Lite)",
        ["2861839844"] = "NikNaks"
        -- ["1234567890"] = "Example Addon"
    }

    function GCAL:RegisterConflictingWorkshopAddon(workshopID, label)
        workshopID = tostring(workshopID or "")
        if workshopID == "" then return end

        self.ConflictingWorkshopAddons[workshopID] = label or ("Workshop addon " .. workshopID)
    end

    local function GetMountedConflictingWorkshopAddons()
        local found = {}

        for _, addon in ipairs(engine.GetAddons()) do
            local workshopID = tostring(addon.wsid or "")
            local label = GCAL.ConflictingWorkshopAddons[workshopID]

            if label and addon.mounted then
                found[#found + 1] = {
                    id = workshopID,
                    label = label,
                    display = label .. " [" .. workshopID .. "]"
                }
            end
        end

        table.sort(found, function(a, b)
            return a.display < b.display
        end)
        return found
    end

    local function ShowConflictPopup(hasLegacyFile, mountedConflicts)
        local lines = {
            "Conflicting addons were detected.",
            "Please disable them to prevent conflicts.",
            "GCAL won't work with those properly.",
            "If you post a bug/issue with any of these addons on, you'll get laughed at and/or ignored. So please disable them before using GCAL.",
        }

        if hasLegacyFile then
            lines[#lines + 1] = ""
            lines[#lines + 1] = "Legacy VManip files were also detected."
        end

        if #mountedConflicts > 0 then
            lines[#lines + 1] = ""
            lines[#lines + 1] = "Mounted Workshop conflicts:"

            for _, addon in ipairs(mountedConflicts) do
                lines[#lines + 1] = " - " .. addon.display
            end
        end

        surface.PlaySound("buttons/button10.wav")

        local dim = vgui.Create("DPanel")
        dim:SetSize(ScrW(), ScrH())
        dim:MakePopup()
        dim:SetKeyboardInputEnabled(false)
        dim:SetMouseInputEnabled(false)
        function dim:Paint(w, h)
            draw.RoundedBox(0, 0, 0, w, h, Color(0, 0, 0, 165))
        end

        local frame = vgui.Create("DFrame")
        frame:SetTitle("")
        frame:SetSize(math.min(ScrW() - 80, 760), math.min(ScrH() - 70, 680))
        frame:Center()
        frame:MakePopup()
        frame:SetSizable(false)
        frame:SetDraggable(true)
        frame.StartTime = SysTime()
        if IsValid(frame.btnMinim) then
            frame.btnMinim:SetVisible(false)
            frame.btnMinim:SetEnabled(false)
        end
        if IsValid(frame.btnMaxim) then
            frame.btnMaxim:SetVisible(false)
            frame.btnMaxim:SetEnabled(false)
        end
        frame.OnClose = function()
            if IsValid(dim) then
                dim:Remove()
            end
        end

        function frame:Paint(w, h)
            Derma_DrawBackgroundBlur(self, self.StartTime)
            draw.RoundedBox(8, 0, 0, w, h, Color(22, 22, 28, 245))
            draw.RoundedBoxEx(8, 0, 0, w, 68, Color(150, 34, 34, 255), true, true, false, false)
            draw.SimpleText("GCAL Conflict Warning", "DermaLarge", 18, 12, Color(255, 245, 245), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            draw.SimpleText("Conflicting addons can break arm rendering and legacy compatibility.", "Trebuchet18", 18, 40, Color(255, 220, 220), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            surface.SetDrawColor(255, 120, 120, 40)
            surface.DrawOutlinedRect(0, 0, w, h, 1)
        end

        local content = vgui.Create("DScrollPanel", frame)
        content:Dock(FILL)
        content:DockMargin(14, 80, 14, 104)

        local y = 0
        for _, line in ipairs(lines) do
            local label = content:Add("DLabel")
            label:Dock(TOP)
            label:DockMargin(8, y == 0 and 0 or 0, 8, line == "" and 10 or 4)
            label:SetWrap(true)
            label:SetAutoStretchVertical(true)
            label:SetFont("Trebuchet18")
            label:SetTextColor(Color(236, 242, 255))
            label:SetText(line == "" and " " or line)
            y = y + 1
        end

        local workshopButton = vgui.Create("DButton", frame)
        workshopButton:Dock(BOTTOM)
        workshopButton:DockMargin(14, 0, 14, 8)
        workshopButton:SetTall(38)
        workshopButton:SetText("Open Subscribed Addons")
        workshopButton:SetFont("Trebuchet18")
        workshopButton.DoClick = function()
            local ply = LocalPlayer()
            local steamID64 = IsValid(ply) and ply:SteamID64() or ""
            if steamID64 == "" then
                gui.OpenURL("https://steamcommunity.com/workshop/browse/?appid=4000")
                return
            end

            gui.OpenURL("https://steamcommunity.com/profiles/" .. steamID64 .. "/myworkshopfiles?appid=4000&browsefilter=mysubscriptions")
        end

        local closeButton = vgui.Create("DButton", frame)
        closeButton:Dock(BOTTOM)
        closeButton:DockMargin(14, 0, 14, 14)
        closeButton:SetTall(38)
        closeButton:SetText("I know what I am doing, close this warning.")
        closeButton:SetFont("Trebuchet18")
        closeButton.DoClick = function()
            frame:Close()
        end
    end

    include("gcal/gcal_lerp.lua")
    include("gcal/gcal_core.lua")
    include("gcal/gcal_menu.lua")
    include("gcal/gcal_compat.lua")
    include("gcal/gcal_legs.lua")
    include("gcal/gcal_base_anims.lua")
    include("gcal/gcal_debug_menu.lua")
    
    print("GCAL (Client) Initialized! :3")

    -- Conflict Detection Notice
    timer.Simple(1, function()
        local mountedConflicts = GetMountedConflictingWorkshopAddons()
        local hasLegacyFile = file.Exists("autorun/client/cl_vmanip.lua", "LUA")

        if hasLegacyFile or #mountedConflicts > 0 then
            local msg = "!!! GCAL WARNING: Conflicting Workshop addons detected! !!!"
            local msg2 = "Please disable the conflicting Workshop addons to prevent animation conflicts and performance issues. GCAL is a complete replacement! :3"
            
            MsgC(Color(255, 0, 0), msg .. "\n")
            MsgC(Color(255, 255, 255), msg2 .. "\n")

            if #mountedConflicts > 0 then
                local displays = {}
                for _, addon in ipairs(mountedConflicts) do
                    displays[#displays + 1] = addon.display
                end
                MsgC(Color(255, 176, 93), "[GCAL] Conflicting mounted Workshop addons: " .. table.concat(displays, ", ") .. "\n")
            end

            ShowConflictPopup(hasLegacyFile, mountedConflicts)
        end
    end)
end

if SERVER then
    util.AddNetworkString("GCAL_Play")
    util.AddNetworkString("GCAL_Stop")
    
    -- Backward compatibility networking
    util.AddNetworkString("VManip_SimplePlay")
    util.AddNetworkString("VManip_StopHold")

    include("gcal/gcal_lerp.lua")
    include("gcal/gcal_core.lua")
    include("gcal/gcal_compat.lua")
    include("gcal/gcal_base_anims.lua")
    
    print("GCAL (Server) Initialized! :3")

    concommand.Add("gcal_menu_open", function(ply)
        if IsValid(ply) then
            ply:ConCommand("gcal_menu_open")
        else
            print("GCAL menu is clientside. Run gcal_menu_open from a player console.")
        end
    end)
end
