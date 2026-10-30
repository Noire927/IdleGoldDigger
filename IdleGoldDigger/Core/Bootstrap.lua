local addonName, addon = ...

-- Start the event system
addon.Events:Initialize()

-- Register slash commands
addon.Commands:Initialize()
