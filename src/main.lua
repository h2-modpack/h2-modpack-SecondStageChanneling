-- =============================================================================
-- BOILERPLATE (do not modify)
-- =============================================================================

local mods = rom.mods
mods['SGG_Modding-ENVY'].auto()

---@diagnostic disable: lowercase-global
rom = rom
_PLUGIN = _PLUGIN
game = rom.game
modutil = mods['SGG_Modding-ModUtil']
chalk = mods['SGG_Modding-Chalk']
reload = mods['SGG_Modding-ReLoad']

config = chalk.auto('config.lua')
public.config = config

local NIL = {}
local backups = {}

local function backup(tbl, key)
    if not backups[tbl] then backups[tbl] = {} end
    if backups[tbl][key] == nil then
        local v = tbl[key]
        backups[tbl][key] = v == nil and NIL or (type(v) == "table" and DeepCopyTable(v) or v)
    end
end

local function restore()
    for tbl, keys in pairs(backups) do
        for key, v in pairs(keys) do
            tbl[key] = v == NIL and nil or (type(v) == "table" and DeepCopyTable(v) or v)
        end
    end
end

local function isEnabled()
    return config.Enabled
end

-- =============================================================================
-- UTILITIES
-- =============================================================================

local function DeepCompare(a, b)
    if a == b then return true end
    if type(a) ~= type(b) then return false end
    if type(a) ~= "table" then return false end
    for key, value in pairs(a) do
        if not DeepCompare(value, b[key]) then return false end
    end
    for key in pairs(b) do
        if a[key] == nil then return false end
    end
    return true
end

local function ListContainsEquivalent(list, template)
    if type(list) ~= "table" then return false end
    for _, entry in ipairs(list) do
        if DeepCompare(entry, template) then return true end
    end
    return false
end

-- =============================================================================
-- MODULE DEFINITION
-- =============================================================================

public.definition = {
    id       = "SecondStageChannelingFix",
    name     = "Remove Second Channeling",
    category = "BugFixes",
    group    = "Boons & Hammers",
    tooltip  = "Removes 2nd stage channel of Glorious Disaster/Giga Moonburst, baking bonus into stage 1.",
    default  = true,
}

-- =============================================================================
-- MODULE LOGIC
-- =============================================================================

local function PatchGloriousDisaster()
    if TraitData == nil or TraitData.ApolloSecondStageCastBoon == nil then return end

    local extraManaCost = 30
    local baseWait = 0.8
    local baseCost = 15

    TraitData.ApolloSecondStageCastBoon.ReportedDifference = extraManaCost
    TraitData.ApolloSecondStageCastBoon.WeaponDataOverrideTraitRequirement = "ApolloExCastBoon"
    TraitData.ApolloSecondStageCastBoon.ChargeStageModifiers = nil

    TraitData.ApolloSecondStageCastBoon.WeaponDataOverride = {
        WeaponCastArm = {
            ManaCost = 0,
            OnChargeFunctionNames = { "DoWeaponCharge" },
            ChargeWeaponData = {
                OnStageReachedFunctionName = "CastChargeStage",
                EmptyChargeFunctionName = "EmptyCastCharge",
                OnNoManaForceRelease = "NoManaCastSecondStageForceRelease"
            },
            ChargeWeaponStages = {
                { ManaCost = baseCost + extraManaCost, Wait = baseWait },
                { RequiredTraitName = "ApolloExCastBoon", ManaCost = baseCost + extraManaCost, Wait = 0, ForceRelease = true, ResetIndicator = true }
            }
        },
        WeaponCast = {
            ChargeWeaponStages = {
                { ManaCost = baseCost + extraManaCost, Wait = baseWait, ChannelSlowEventOnStart = true },
                { RequiredTraitName = "ApolloExCastBoon", ManaCost = baseCost + extraManaCost, Wait = 0, ForceRelease = true, ResetIndicator = true, SuperCharge = true }
            }
        },
        WeaponCastProjectileHades = {
            ChargeWeaponStages = {
                { ManaCost = baseCost + extraManaCost, Wait = baseWait, ChannelSlowEventOnStart = true },
                { RequiredTraitName = "ApolloExCastBoon", ManaCost = baseCost + extraManaCost, Wait = 0, ForceRelease = true, ResetIndicator = true, SuperCharge = true }
            }
        },
        WeaponAnywhereCast = {
            ChargeWeaponStages = {
                { ManaCost = baseCost + extraManaCost, Wait = baseWait, ChannelSlowEventOnStart = true },
                { RequiredTraitName = "ApolloExCastBoon", ManaCost = baseCost + extraManaCost, Wait = 0, ForceRelease = true, ResetIndicator = true, SuperCharge = true }
            }
        },
        WeaponCastProjectile = {
            ChargeWeaponStages = {
                { ManaCost = baseCost + extraManaCost, Wait = baseWait, ChannelSlowEventOnStart = true },
                { RequiredTraitName = "ApolloExCastBoon", ManaCost = baseCost + extraManaCost, Wait = 0, ForceRelease = true, ResetIndicator = true, SuperCharge = true }
            }
        },
        WeaponCastLob = {
            ChargeWeaponStages = {
                { ManaCost = baseCost + extraManaCost, Wait = baseWait, ChannelSlowEventOnStart = true },
                { RequiredTraitName = "ApolloExCastBoon", ManaCost = baseCost + extraManaCost, Wait = 0, ForceRelease = true, ResetIndicator = true, SuperCharge = true }
            }
        }
    }

    TraitData.ApolloSecondStageCastBoon.PropertyChanges = TraitData.ApolloSecondStageCastBoon.PropertyChanges or {}
    local propertyList = TraitData.ApolloSecondStageCastBoon.PropertyChanges

    local forceRelease = {
        TraitName = "ApolloExCastBoon",
        WeaponName = "WeaponCastArm",
        WeaponProperty = "ForceMaxChargeRelease",
        ChangeValue = false,
    }
    local chargeTime = {
        TraitName = "ApolloExCastBoon",
        WeaponName = "WeaponCastArm",
        WeaponProperty = "ChargeTime",
        ChangeValue = baseWait,
    }

    if not ListContainsEquivalent(propertyList, forceRelease) then
        table.insert(propertyList, forceRelease)
    end
    if not ListContainsEquivalent(propertyList, chargeTime) then
        table.insert(propertyList, chargeTime)
    end
end

local function ReplaceGigaMoonburst()
    OverwriteTableKeys(TraitData, {
        StaffSecondStageTrait = {
            InheritFrom = { "WeaponTrait", "StaffHammerTrait" },
            Icon = "Hammer_Staff_37",
            GameStateRequirements = {
                { Path = { "CurrentRun", "Hero", "Weapons" }, HasAll = { "WeaponStaffSwing" } },
            },
            RarityLevels = {
                Common = { Multiplier = 1.0 },
                Legendary = { Multiplier = 1.333 },
            },
            ManaCostModifiers = {
                WeaponNames = { "WeaponStaffBall" },
                ExcludeLinked = true,
                ExWeapons = true,
                ManaCostAdd = 30,
                ReportValues = { ReportedManaCost = "ManaCostAdd" }
            },
            AddOutgoingDamageModifiers = {
                ValidProjectiles = { "ProjectileStaffBallCharged" },
                ValidWeaponMultiplier = { BaseValue = 4.0, SourceIsMultiplier = true },
                ReportValues = { ReportedWeaponMultiplier = "ValidWeaponMultiplier" },
            },
            PropertyChanges = {
                {
                    WeaponName = "WeaponStaffBall",
                    ProjectileName = "ProjectileStaffBallCharged",
                    ProjectileProperties = { DamageRadius = 550, BlastSpeed = 2500 },
                },
            },
            ExtractValues = {
                { Key = "ReportedManaCost", ExtractAs = "ManaCost" },
                { Key = "ReportedWeaponMultiplier", ExtractAs = "DamageIncrease", Format = "PercentDelta" },
            }
        }
    })
end

local function apply()
    backup(TraitData, "ApolloSecondStageCastBoon")
    backup(TraitData, "StaffSecondStageTrait")
    PatchGloriousDisaster()
    ReplaceGigaMoonburst()
end

local function disable()
    restore()
end

local function registerHooks()
    modutil.mod.Path.Wrap("CheckAxeCastArm", function(baseFunc, triggerArgs, args)
        if not isEnabled() then return baseFunc(triggerArgs, args) end
        if HeroHasTrait("ApolloExCastBoon") and HeroHasTrait("ApolloSecondStageCastBoon") then
            SessionMapState.SuperchargeCast = true
        end
        baseFunc(triggerArgs, args)
    end)
end

-- =============================================================================
-- PUBLIC API (do not modify)
-- =============================================================================

public.definition.enable = function()
    apply()
end

public.definition.disable = function()
    disable()
end

-- =============================================================================
-- LIFECYCLE (do not modify)
-- =============================================================================

local loader = reload.auto_single()

modutil.once_loaded.game(function()
    loader.load(function()
        import_as_fallback(rom.game)
        registerHooks()
        if config.Enabled then apply() end
    end)
end)
-- =============================================================================
-- STANDALONE UI (do not modify)
-- =============================================================================
-- When adamant-core is NOT installed, renders a minimal ImGui toggle.
-- When adamant-core IS installed, the core handles UI — this is skipped.

rom.gui.add_to_menu_bar(function()
    if mods['adamant-Core'] then return end
    if rom.ImGui.BeginMenu("adamant") then
        local val, chg = rom.ImGui.Checkbox(public.definition.name, config.Enabled)
        if chg then
            config.Enabled = val
            if val then apply() else disable() end
        end
        if rom.ImGui.IsItemHovered() and public.definition.tooltip ~= "" then
            rom.ImGui.SetTooltip(public.definition.tooltip)
        end
        rom.ImGui.EndMenu()
    end
end)
