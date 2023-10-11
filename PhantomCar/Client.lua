
-- Brain Vars
local Destroyed = true
local Hunting = false

-- Entity Vars
local PhantomCar = nil
local Driver = nil
local Blip = nil

-- FX Vars
local FlamesFX = nil
local FlamesSoundId = nil

local function LoadModel(ModelHash)
    if not IsModelInCdimage(ModelHash) then
        return
    end

    RequestModel(ModelHash)
    while not HasModelLoaded(ModelHash) do
        Citizen.Wait(0)
    end

    return ModelHash
end

-- Custom GetTimeDifference
local function TimeDifference(Time)
    local Hour = GetClockHours()
    local Minute = GetClockMinutes()
    Hour = Hour == 0 and 12 or Hour

    local CurrentTime = ("%.2d%.2d"):format(Hour,Minute)
    return (CurrentTime - Time) == 0
end

local function GetBearing(A,B)
    return math.abs(math.fmod((math.atan2(A[1] - B[1],A[2] - B[2]) * (180 / math.pi)), 360) - 180)
end

local function ModifyVehicle(Vehicle) -- Should be TORNADO5
    NetworkFadeInEntity(Vehicle, true, false)

    -- Damage
    local Health = GetEntityMaxHealth(Vehicle) * 5
    SetEntityMaxHealth(Vehicle, Health)
    SetEntityHealth(Vehicle, Health, 0)
    SetEntityProofs(Vehicle, false, true, false, false, false, false, false, false)
    SetVehicleStrong(Vehicle, true)
    SetVehicleProvidesCover(Vehicle, false)
    SetVehicleHasStrongAxles(Vehicle, true)
    SetVehicleExplodesOnHighExplosionDamage(Vehicle, false)
    SetVehicleCanDeformWheels(Vehicle, false)
    SetVehicleHasUnbreakableLights(Vehicle, true)
    SetVehicleDisableTowing(Vehicle, true)
    SetVehicleCanBeVisiblyDamaged(Vehicle, false)
    SetVehicleRadioEnabled(Vehicle, false)

    SetVehicleTyresCanBurst(Vehicle, false)
    SetDriftTyresEnabled(Vehicle, false)
    SetVehicleDoorsLocked(Vehicle, 2)

    -- Colour
    SetVehicleExtra(Vehicle, 12, true)
    SetVehicleColours(Vehicle, 32, 32)
    SetVehicleExtraColours(Vehicle, 0, 156)
    SetVehicleInteriorColor(Vehicle, 1)
    SetVehicleDashboardColor(Vehicle, 132)
    SetVehicleRoofLivery(Vehicle, 0)
    SetVehicleLivery(Vehicle, 0)
    SetVehicleWindowTint(Vehicle, 3)
    SetVehicleWheelType(Vehicle, 8)
    SetVehicleTyreSmokeColor(Vehicle, 255, 255, 255)
    SetVehicleNeonLightsColour(Vehicle, 255, 255, 255)

    -- Visual
    SetVehicleNumberPlateText(Vehicle, "EAB__211")
    SetVehicleNumberPlateTextIndex(Vehicle, 1)
    SetVehicleMod(Vehicle, 23, 94, false)
    ToggleVehicleMod(Vehicle, 20, true)
    RemoveVehicleMod(Vehicle, 10)

    SetVehicleLights(Vehicle, 2)
    SetVehicleLightMultiplier(Vehicle, 15.0)
    SetVehicleHeadlightsColour(Vehicle, 8)

    -- Performance
    SetVehicleMod(Vehicle, 11, 3, false)
    SetVehicleMod(Vehicle, 12, 2, false)
    SetVehicleMod(Vehicle, 13, 2, false)
    ToggleVehicleMod(Vehicle, 18, true)
end

local function ModifyPed(Ped) -- Should be S_M_Y_ROBBER_01
    SetEntityAlpha(Ped, 0, false)
    SetEntityVisible(Ped, false, false)
    SetPedCombatAttributes(Ped, 3, false)
    SetEntityProofs(Ped, false, true, false, false, false, false, false, false)
    SetEntityInvincible(Ped, true)
    SetPedConfigFlag(Ped, 109, true)
    SetPedConfigFlag(Ped, 116, false)
    SetPedConfigFlag(Ped, 118, false)
    SetPedConfigFlag(Ped, 430, true)
    SetPedConfigFlag(Ped, 42, true)
    DisablePedPainAudio(Ped, true)
    SetPedCanBeTargetted(Ped, false)

    SetBlockingOfNonTemporaryEvents(Ped, true)
    SetDriverAbility(Ped, 1.0)
    SetDriverRacingModifier(Ped, 1.0)
    SetDriverAggressiveness(Ped, 1.0)
end

local function SpawnPhantomCar()
    if not Destroyed then return end

    local PlayerPed = PlayerPedId()
    local Position = GetEntityCoords(PlayerPed)

    local Success, NodePosition = GetNthClosestVehicleNode(Position[1], Position[2], Position[3], 20)
    if not Success then SpawnPhantomCar() return end

    Destroyed = false
    PhantomCar = CreateVehicle(LoadModel("TORNADO5"), NodePosition, GetBearing(NodePosition,Position), true, false)
    Driver = CreatePedInsideVehicle(PhantomCar, 26, LoadModel("S_M_Y_ROBBER_01"), -1, true, false)
    Hunting = IsPedSittingInAnyVehicle(PlayerPed)

    ModifyVehicle(PhantomCar)
    Citizen.Wait(500)
    ModifyPed(Driver)

    Blip = AddBlipForEntity(PhantomCar)
    SetBlipAsShortRange(Blip, true)
    SetBlipScale(Blip, 0.5)

    BeginTextCommandSetBlipName("STRING")
    AddTextComponentSubstringPlayerName("Phantom Car")
    EndTextCommandSetBlipName(Blip)

    SetModelAsNoLongerNeeded("TORNADO5")
    SetModelAsNoLongerNeeded("S_M_Y_ROBBER_01")

    RequestScriptAudioBank("DLC_TUNER/DLC_Tuner_Phantom_Car", false, -1)
    PlaySoundFromEntity(-1, "Spawn_In_Game", PhantomCar, "DLC_Tuner_Halloween_Phantom_Car_Sounds", false, false)
    TriggerMusicEvent("H21_PC_START_MUSIC")
end

local function TakeNetwork(Entity)
    --[[while not NetworkHasControlOfEntity(Entity) do
        NetworkRequestControlOfEntity(Entity)
        Citizen.Wait(250)
    end]]

    SetEntityAsMissionEntity(Entity,true,true)
end

local function DespawnPhantomCar()
    if Destroyed then return end

    NetworkFadeOutEntity(PhantomCar,false,true)
    PlaySoundFromEntity(-1, "Despawn_In_Game", PhantomCar, "DLC_Tuner_Halloween_Phantom_Car_Sounds", false, false)
    TriggerMusicEvent("H21_PC_STOP_MUSIC")

    TakeNetwork(Driver)
    TakeNetwork(PhantomCar)

    Citizen.Wait(1000)

    RemoveBlip(Blip) Blip = nil
    DeletePed(Driver) Driver = nil
    DeleteVehicle(PhantomCar) PhantomCar = nil

    Citizen.Wait(5000)
    Destroyed = true
end

Citizen.CreateThread(function()
    RequestScriptAudioBank("DLC_TUNER/DLC_Tuner_Phantom_Car", false, -1)
    RequestNamedPtfxAsset("scr_tn_phantom")

    while true do
        if not HasNamedPtfxAssetLoaded("scr_tn_phantom") then
            RequestNamedPtfxAsset("scr_tn_phantom")
        end

        Citizen.Wait(5000)
    end
end)

Citizen.CreateThread(function()
    while true do
        if PhantomCar and not Destroyed then
            local PlayerPed = PlayerPedId()

            if GetVehicleEngineHealth(PhantomCar) <= 0 then
                DespawnPhantomCar()
            end

            if IsEntityDead(PlayerPed) then
                DespawnPhantomCar()
            end

            SetVehicleCheatPowerIncrease(PhantomCar, 2.0)
            if not IsPedSittingInAnyVehicle(PlayerPed) and not Hunting then
                Hunting = true
                FlamesSoundId = GetSoundId()
                UseParticleFxAsset("scr_tn_phantom")
                PlaySoundFrontend(-1, "Spawn_FE", "DLC_Tuner_Halloween_Phantom_Car_Sounds", false)
                FlamesFX = StartParticleFxLoopedOnEntity("scr_tn_phantom_flames", PhantomCar, 0.0, 0.0, 0.0, 0.0, 0.0, 180.0, 1.0, false, true, false)
                PlaySoundFromEntity(FlamesSoundId, "Flames_Loop", PhantomCar, "DLC_Tuner_Halloween_Phantom_Car_Sounds", false, false)

                ToggleVehicleMod(PhantomCar, 22, true)
                TaskVehicleFollow(Driver, PhantomCar, PlayerPed, 30.0, 4981260, 0)
            elseif IsPedSittingInAnyVehicle(PlayerPed) and Hunting then
                Hunting = false
                StopSound(FlamesSoundId)
                ReleaseSoundId(FlamesSoundId)
                StopParticleFxLooped(FlamesFX, true)

                ToggleVehicleMod(PhantomCar, 22, false)
                TaskVehicleFollow(Driver, PhantomCar, PlayerPed, 120.0, 786956, 20)
            end
        end

        Citizen.Wait(0)
    end
end)

Citizen.CreateThread(function()
    while true do Citizen.Wait(2000)
        if TimeDifference("2100") then
            SpawnPhantomCar()
        end
        if TimeDifference("0500") then
            DespawnPhantomCar()
        end
    end
end)

AddEventHandler("gameEventTriggered", function(Name, Args)
    if Name == "CEventNetworkEntityDamage" and Driver then
        if Args[2] == Driver and Hunting then
            if not IsEntityOnFire(Args[1]) then
                StartEntityFire(Args[1])
            end
            if Args[6] == 1 then
                StopEntityFire(Args[1])
            end
        end
    end
end)

RegisterNetEvent("PC:Spawn")
AddEventHandler("PC:Spawn", function()
    SpawnPhantomCar()
end)

RegisterNetEvent("PC:Despawn")
AddEventHandler("PC:Despawn", function()
    DespawnPhantomCar()
end)

TriggerEvent("chat:addSuggestion", "/spc", "Spawn Phantom Car", {{ name = "playerid", help = "Player Server ID" }})
TriggerEvent("chat:addSuggestion", "/dpc", "Despawn Phantom Car", {{ name = "playerid", help = "Player Server ID" }})
