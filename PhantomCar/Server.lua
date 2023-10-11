RegisterCommand("spc", function(source, args)
    args[1] = args[1] or -1
    TriggerClientEvent("PC:Spawn", args[1])
end, true)

RegisterCommand("dpc", function(source, args)
    args[1] = args[1] or -1
    TriggerClientEvent("PC:Despawn", args[1])
end, true)
