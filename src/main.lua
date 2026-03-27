local mods = rom.mods
mods['SGG_Modding-ENVY'].auto()

---@diagnostic disable: lowercase-global
rom = rom
_PLUGIN = _PLUGIN
game = rom.game
modutil = mods['SGG_Modding-ModUtil']
chalk = mods['SGG_Modding-Chalk']
reload = mods['SGG_Modding-ReLoad']
local lib = mods['adamant-ModpackLib']

config = chalk.auto('config.lua')
public.config = config

local backup, revert = lib.createBackupSystem()

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
    category = "Bug Fixes",
    group    = "Boons & Hammers",
    tooltip  = "Removes 2nd stage channel of Glorious Disaster/Giga Moonburst, baking bonus into stage 1.",
    default  = true,
    dataMutation = true,
    modpack = "h2-modpack",
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

local function registerHooks()
    modutil.mod.Path.Wrap("CheckAxeCastArm", function(baseFunc, triggerArgs, args)
        if not lib.isEnabled(config, public.definition.modpack) then return baseFunc(triggerArgs, args) end
        if HeroHasTrait("ApolloExCastBoon") and HeroHasTrait("ApolloSecondStageCastBoon") then
            SessionMapState.SuperchargeCast = true
        end
        baseFunc(triggerArgs, args)
    end)
end

-- =============================================================================
-- Wiring
-- =============================================================================

public.definition.apply = apply
public.definition.revert = revert

local loader = reload.auto_single()

modutil.once_loaded.game(function()
    loader.load(function()
        import_as_fallback(rom.game)
        registerHooks()
        if lib.isEnabled(config, public.definition.modpack) then apply() end
        if public.definition.dataMutation and not lib.isCoordinated(public.definition.modpack) then
            SetupRunData()
        end
    end)
end)

local uiCallback = lib.standaloneUI(public.definition, config, apply, revert)
rom.gui.add_to_menu_bar(uiCallback)
