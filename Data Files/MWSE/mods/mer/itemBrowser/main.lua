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
        message = "Item Browser",
        subheading = "Select Object Type:",
        buttons = buttons,
        doesCancel = true,
    }
end

---@param e keyDownEventData
local function onKeyDown(e)
    if tes3ui.menuMode() then return end
    if not config.mcm.enabled then return end
    if Util.isKeyPressed(e, config.mcm.hotKey) then
        showMenu()
    end
end

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

---@param recipes CraftingFrameworkRecipeData
---@param obj tes3object|tes3armor|tes3clothing|tes3misc|tes3light|tes3weapon|tes3book|tes3probe|tes3lockpick
---@return boolean #Returns true if this object can be added to the recipe list.
local function canAddObject(obj)
    if category.slots then
        if not category.slots[obj.slot] then
            return false
        end
    end
    if category.requiredFields then
        for k, v in pairs(category.requiredFields) do
            if obj[k] ~= v then
                return false
            end
        end
    end
    if category.enchanted ~= nil then
        if obj.enchantment and (category.enchanted == false) then
            return false
        end
        if (not obj.enchantment) and (category.enchanted == true) then
            return false
        end
    end
    if obj.name == "" then return false end
    return true
end

---@param obj tes3object|tes3armor|tes3clothing|tes3misc|tes3light|tes3weapon|tes3book|tes3probe|tes3lockpick
---@return CraftingFrameworkRecipeData
local function createObjectRecipe(obj)
    return {
        id = "itemBrowser:" .. obj.id,
        craftableId = obj.id,
        category = obj.sourceMod,
        soundId = "Item Misc Up",
        description = getDescription(obj),
        persist = false,
    }
end

local function createMenuForCategory(recipes, category)
    return CraftingFramework.MenuActivator:new{
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

local menusAlreadyRegistered --only register once
local function registerMenus()
    logger:debug("Registering Item Menus")
    if not menusAlreadyRegistered then
        menusAlreadyRegistered = true
        for _, category in pairs(config.static.categories) do
            logger:debug("Category: %s", category.name)
            local recipes = {}
            local count = 0
            for objectType, _ in pairs(category.objectTypes) do
                for obj in tes3.iterateObjects(objectType) do
                    if canAddObject(obj) then
                        local recipe = createObjectRecipe(obj)
                        table.insert(recipes, recipe)
                        count = count + 1
                    end
                end
            end
            logger:debug("Total %s registered: %d", category.name, count)
            createMenuForCategory(recipes, category)
        end
    end
end


---@param e initializedEventData
local function onInitialised(e)
    --Event for triggering recipes when enabling for the first time from MCM
    event.register("ItemBrowser:RegisterMenus", registerMenus)
    --Menu Hotkey event
    event.register(tes3.event.keyDown, onKeyDown)
    if config.mcm.enabled then
        registerMenus()
    else
        logger:debug("Mod disabled, skipping recipe registration.")
    end
    logger:info("Initialised: %s", Util.getVersion())
end
event.register(tes3.event.initialized, onInitialised)


