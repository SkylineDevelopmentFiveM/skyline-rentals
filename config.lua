Config = {}

Config.NPC = {
    model = 's_m_m_highsec_01',
    coords = vec3(195.86, -846.78, 30.85),
    heading = 163.61
}

-- Interaction mode: 'ox_target', 'qb-target', or 'textui'
Config.Interaction = {
    mode = 'textui',
    key = 38 -- E (only used when mode = 'textui')
}

-- TextUI settings (only used when mode = 'textui')
Config.TextUI = {
    position = 'right-center' -- options include: 'left-center', 'right-center', 'top-center', 'bottom-center'
}

Config.Target = {
    label = 'Rent a Vehicle',
    icon = 'fa-solid fa-car',
    distance = 2.0
}

Config.Menu = {
    title = 'Vehicle Rental'
}

Config.Payment = {
    item = 'money'
}

Config.PlatePrefix = 'RENTAL'

Config.Vehicles = {
    {
        label = 'BMX',
        model = 'bmx',
        price = 200,
        spawn = { coords = vec3(200.39, -844.61, 30.62), heading = 250.5 }
    },
    {
        label = 'Faggio',
        model = 'faggio',
        price = 500,
        spawn = { coords = vec3(200.39, -844.61, 30.62), heading = 250.5 }
    }
}

Config.GiveKeys = function(vehicle)
end
