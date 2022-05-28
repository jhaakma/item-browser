local Util = require("mer.itemBrowser.util")
local config = require("mer.itemBrowser.config")
local logger = Util.createLogger("main")
local mcm = require("mer.itemBrowser.mcm")

local CraftingFramework = include("CraftingFramework")
if not CraftingFramework then
    logger:error("CraftingFramework not installed! Go here to download: https://www.nexusmods.com/morrowind/mods/51009")
    return
end

local function showMenu()
    local buttons = {}
    for _, v in ipairs(config.static.categories) do
        table.insert(buttons, {
            text = v.name,
            callback = function()
                timer.delayOneFrame(function()
                    event.trigger("ItemBrowserActivate:" .. v.name)
                end)
            end
        })
    end
    Util.messageBox{
        message = "Select Object Type:",
        buttons = buttons,
        doesCancel = true
    }
end

---@param e keyDownEventData
local function onKeyDown(e)
    if tes3ui.menuMode() then return end
    if Util.isKeyPressed(e, config.mcm.hotKey) then
        showMenu()
    end
end
event.register(tes3.event.keyDown, onKeyDown)


---@param object tes3object|tes3armor|tes3clothing|tes3misc|tes3light|tes3weapon|tes3book|tes3probe|tes3lockpick
local function getDescription(object)
    local description = ""
    description = description .. string.format("ID: %s\n\n", object.id)
    description = description .. string.format("Source Mod: %s\n\n", object.sourceMod)
    if object.armorRating then
        description = description .. string.format("Armor Rating: %d\n", object.armorRating)
    end
    if object.slashMax then
        description = description .. string.format("Slash: %d - %d\n", object.slashMin, object.slashMax)
    end
    if object.thrustMax then
        description = description .. string.format("Thrust: %d - %d\n", object.thrustMin, object.thrustMax)
    end
    if object.chopMax then
        description = description .. string.format("Chop: %d - %d\n", object.chopMin, object.chopMax)
    end
    if object.speed then
        description = description .. string.format("Speed: %d\n", object.speed)
    end
    if object.enchantCapacity then
        description = description .. string.format("Enchant Capacity: %d\n", object.enchantCapacity)
    end
    description = description .. string.format("Weight: %.2f   Value: %d", object.weight, object.value)
    return description
end

---@param e initializedEventData
local function onInitialised(e)
    logger:debug("Registering Item Browser Menu")

    local function addRecipe(recipes, obj)
        local recipe = {
            id = "itemBrowser:" .. obj.id,
            craftableId = obj.id,
            category = obj.sourceMod,
            soundId = "Item Misc Up",
            description = getDescription(obj),
            persist = false,
        }
        table.insert(recipes, recipe)
    end

    for _, category in pairs(config.static.categories) do
        logger:debug("Category: %s", category.name)
        local recipes = {}
        local count = 0
        for objectType, _ in pairs(category.objectTypes) do
            for obj in tes3.iterateObjects(objectType) do
                local invalid = false
                if category.slots then
                    if not category.slots[obj.slot] then
                        invalid = true
                    end
                end
                if category.requiredFields then
                    for k, v in pairs(category.requiredFields) do
                        if obj[k] ~= v then
                            invalid = true
                        end
                    end
                end
                if obj.name == "" then invalid = true end
                if not invalid then
                    count = count + 1
                    addRecipe(recipes, obj)
                end
            end
        end
        logger:debug("Total %s: %d", category.name, count)
        CraftingFramework.MenuActivator:new{
            name = "Item Browser: " .. category.name,
            id = "ItemBrowserActivate:" .. category.name,
            type = "event",
            recipes = recipes,
            defaultSort = "name",
            defaultFilter = "all",
            defaultShowCategories = true,
            closeCallback = showMenu,
        }
    end
end
event.register(tes3.event.initialized, onInitialised)


