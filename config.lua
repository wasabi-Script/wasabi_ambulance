-----------------For support, scripts, and more----------------
--------------- https://discord.gg/wasabiscripts  -------------
---------------------------------------------------------------
local seconds, minutes = 1000, 60000
Config = {}
--------------------------------------------------------------
-- TO MODIFY NOTIFICATIONS TO YOUR OWN CUSTOM NOTIFICATIONS:--
---------- Navigate to client/client.lua line ~96 ------------
--------------------------------------------------------------
Config.gksPhoneDistress = true -- If you use GKS Phone and want to use it for distress signals(If set to true, the default distress will be disabled regardless)
Config.customCarlock = false -- If you use wasabi_carlock(Or want to add your own key system to client/client.lua line ~579)
Config.MythicHospital = false -- If you use that old injury script by mythic. (Added per request to reset injuries on respawn)

Config.jobMenu = 'F6' -- Default job menu key
Config.billingSystem = true -- Current options: 'esx' (For esx_billing) / 'okok' (For okokBilling) (Easy to add more in editable client - SET TO false IF UNDESIRED) or of course false to disable
Config.skinScript = true -- Current options: 'esx' (For esx_skin) / 'appearance' (For wasabi-fivem-appearance) or of course false to disable

Config.RespawnTimer = 1 * minutes -- Time before optional respawn
Config.BleedoutTimer = 20 * minutes -- Time before it forces respawn

Config.removeItemsOnDeath = true -- Remove items on death?
Config.Inventory = 'ox' -- Options include: 'ox' - (ox_inventory) / 'mf' - (mf-inventory) / 'qs' (qs-inventory) / 'other' (whatever else) // This only really matters if using Config.removeItemsOnDeath

Config.AntiCombatLog = { -- When enabled will kill player who logged out while dead
    enabled = true, -- enabled?
    notification = {
        enabled = true, -- enabled notify of wrong-doings??
        title = 'Logged While Dead',
        desc = 'You last left dead and now have returned dead'
    }
}

Config.RespawnPoint = { -- Where player respawns if bleeds out
    coords = vec3(324.15, -583.14, 44.20), -- This defaults pillbox
    heading = 332.22
}

Config.EMSItems = {
    revive = {
        item = 'defib', -- Item used for reviving
        remove = false -- Remove item when using?
    },
    heal = {
        item = 'medikit', -- Item used for healing
        duration = 5 * seconds, -- Time to use
        remove = true -- Remove item when using?
    },
    sedate = {
        item = 'sedative', -- Item used to sedate players temporarily
        duration = 8 * seconds, -- Time sedative effects last
        remove = true -- Remove item when using?
    },
    medbag = 'medbag', -- Medbag item name used for getting supplies to treat patient
    stretcher = 'stretcher' -- Item used for stretcher
}

Config.ReviveRewards = {
    enabled = true, -- Enable cash rewards for reviving
    no_injury = 4000, -- If above enabled, how much reward for fully treated patient with no injury in diagnosis
    burned = 3000,  -- How much if player is burned and revived without being treated
    beat = 2500, -- So on, so forth
    stabbed = 2000,
    shot = 1500,
}

Config.ReviveHealth = { -- How much health to deduct for those revived without proper treatment
    shot = 60, -- Ex. If player is shot and revived without having the gunshots treated; they will respond with 60 health removed
    stabbed = 50,
    beat = 40,
    burned = 20
}

Config.TreatmentTime = 9 * seconds -- Time to perform treatment

Config.TreatmentItems = {
    shot = 'tweezers',
    stabbed = 'suturekit',
    beat = 'icepack',
    burned = 'burncream'
}

Config.Locations = {
    Pillbox = {

        Blip = {
            Enabled = true,
            Coords = vec3(324.15, -583.14, 44.20),
            Sprite = 61,
            Color = 2,
            Scale = 1.0,
            String = 'Pillbox Hospital'
        },

        BossMenu = {
            Enabled = true,
            Target = {
                label = 'Access Boss Menu',
                coords = vec3(335.59, -594.33, 43.21),
                heading = 269.85,
                width = 2.0,
                length = 1.0,
                minZ = 43.21-0.9,
                maxZ = 43.21+0.9
            }
        },

        CheckIn = { -- Hospital check-in
            Enabled = true, -- Enabled?
            Ped = 's_m_m_scientist_01', -- Check in ped
            Coords = vec3(308.58, -595.31, 43.28-0.9), -- Coords of ped
            Heading = 63.26, -- Heading of ped
            Cost = 3000, -- Cost of using hospital check-in. Set to false for free
            MaxOnDuty = 3, -- If this amount or less you can use, otherwise it will tell you that EMS is avaliable(Set to false to always enable check-in)
            PayAccount = 'bank', -- Account dead player pays from to check-in
            Label = '[E] - Check In'
        },

        Cloakroom = {
            Enabled = true, -- Set to false if you don't want to use (Compatible with esx_skin & wasabi fivem-appearance fork)
            Coords = vec3(300.6, -597.7, 42.1), -- Coords of cloakroom
            Label = '[E] - Change Clothes', -- String of text ui of cloakroom
            Range = 2.0, -- Range away from coords you can use.
            Uniforms = { -- Uniform choices
                ['Medic'] = { -- Name of outfit that will display in menu
                    male = { -- Male variation
                        ['tshirt_1'] = 15,  ['tshirt_2'] = 0,
                        ['torso_1'] = 5,   ['torso_2'] = 2,
                        ['arms'] = 5,
                        ['pants_1'] = 6,   ['pants_2'] = 1,
                        ['shoes_1'] = 16,   ['shoes_2'] = 7,
                        ['helmet_1'] = 44,  ['helmet_2'] = 7,
                    },
                    female = {
                        ['tshirt_1'] = 15,  ['tshirt_2'] = 0,
                        ['torso_1'] = 4,   ['torso_2'] = 14,
                        ['arms'] = 4,
                        ['pants_1'] = 25,   ['pants_2'] = 1,
                        ['shoes_1'] = 16,   ['shoes_2'] = 4,
                    }
                },
                ['Doctor'] = {
                    male = {
                        ['tshirt_1'] = 15,  ['tshirt_2'] = 0,
                        ['torso_1'] = 5,   ['torso_2'] = 2,
                        ['arms'] = 5,
                        ['pants_1'] = 6,   ['pants_2'] = 1,
                        ['shoes_1'] = 16,   ['shoes_2'] = 7,
                        ['helmet_1'] = 44,  ['helmet_2'] = 7,
                    },
                    female = {
                        ['tshirt_1'] = 15,  ['tshirt_2'] = 0,
                        ['torso_1'] = 4,   ['torso_2'] = 14,
                        ['arms'] = 4,
                        ['pants_1'] = 25,   ['pants_2'] = 1,
                        ['shoes_1'] = 16,   ['shoes_2'] = 4,
                    }
                },
            }
        },

        MedicalSupplies = { -- EMS Shop for supplies
            Enabled = true, -- If set to false, rest of this table do not matter
            Ped = 's_m_m_doctor_01', -- Ped to target
            Coords = vec3(306.63, -601.44, 43.28-0.95), -- Coords of ped/target
            Heading = 337.64, -- Heading of ped
            Supplies = { -- Supplies
                { item = 'medbag', label = 'Medical Bag', price = 1000 }, -- Pretty self explanatory, price may be set to 'false' to make free
                { item = 'medikit', label = 'First-Aid Kit', price = 150 },
            }
        },

        Vehicles = { -- Vehicle Garage
            Enabled = true, -- Enable? False if you have you're own way for medics to obtain vehicles.
            Zone = {
                coords = vec3(298.54, -606.79, 43.27), -- Area to prompt vehicle garage
                range = 5.5, -- Range it will prompt from coords above
                label = '[E] - Access Garage',
                return_label = '[E] - Return Vehicle'
            },
            Spawn = {
                land = {
                    coords = vec3(296.16, -607.67, 43.25),
                    heading = 68.43
                },
                air = {
                    coords = vec3(351.24, -587.67, 74.55),
                    heading =  289.29
                }
            },
            Options = {
                ['ambulance'] = { -- Car/Helicopter/Vehicle Spawn Code/Model Name
                    label = 'Ambulance',
                    category = 'land', -- Options are 'land' and 'air'
                },
                ['dodgeems'] = { -- Car/Helicopter/Vehicle Spawn Code/Model Name
                    label = 'Dodge Charger',
                    category = 'land', -- Options are 'land' and 'air'
                },
                ['polmav'] = { -- Car/Helicopter/Vehicle Spawn Code/Model Name
                    label = 'Maverick',
                    category = 'air', -- Options are 'land' and 'air'
                },
            }
        },
    }
}