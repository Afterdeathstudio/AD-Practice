fx_version 'cerulean'
game 'gta5'

lua54 'yes'

author 'AfterDeath'
description 'Coded by: TenTypeeek'
version '2.0.0'

shared_script {
    'config.lua'
}

client_scripts {
    '@ox_lib/init.lua',
    'client.lua'
}

dependencies {
    'ox_lib',
    'qtarget'
}
