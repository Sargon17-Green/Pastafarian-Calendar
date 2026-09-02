local Catalog = {}

local VERSION = "1.0.0"
local LANGUAGE = "Kreyòl ayisyen"

local cutlets = {
    "bwonz",
    "rena",
    "ren",
    "Lagach",
    "panse",
    "kat pati sou nèf",
    "Palgourach",
    "jon",
    "grap",
    "eskòpyon",
    "sann",
    "ble",
    "rivyè",
    "ri",
    "Akad",
    "kòn",
    "krich vid"
}

local months = {
    "ajil",
    "grenad",
    "koud",
    "jalouzi",
    "Eridou",
    "pat dan",
    "twa pati sou senk",
    "Karchoumab",
    "tig",
    "eten",
    "bwouya",
    "lansan",
    "fizo",
    "kòt",
    "kawoub",
    "Ourouk",
    "wont",
    "chamo",
    "kwiv",
    "pi",
    "jòn ze",
    "zetwal",
    "siwo myèl",
    "larat",
    "kalkè",
    "lajwa",
    "fig",
    "Niniv",
    "krapo",
    "goudwon",
    "bouji",
    "pòt fèmen",
    "wowoli",
    "dèyè kou",
    "ajan",
    "flè lis",
    "tanpèt",
    "bourik",
    "farin",
    "regrè",
    "Babilòn",
    "lang",
    "len",
    "sèl",
    "pwa",
    "banza",
    "sab"
}

local function assert_index(index, upper, label)
    assert(type(index) == "number" and math.type(index) == "integer", label .. " mande yon endis antye")
    assert(index >= 1 and index <= upper, label .. " endis la andeyò limit")
end

function Catalog.version()
    return VERSION
end

function Catalog.language()
    return LANGUAGE
end

function Catalog.cutletCount()
    return #cutlets
end

function Catalog.monthCount()
    return #months
end

function Catalog.cutlet(index)
    assert_index(index, #cutlets, "Katalòg kotlèt")
    return cutlets[index]
end

function Catalog.month(index)
    assert_index(index, #months, "Katalòg mwa")
    return months[index]
end

function Catalog.cutletEntry(index)
    return {canonicalIndex = index, sourceString = Catalog.cutlet(index)}
end

function Catalog.monthEntry(index)
    return {canonicalIndex = index, sourceString = Catalog.month(index)}
end

function Catalog.iterCutlets()
    local i = 0
    return function()
        i = i + 1
        if i <= #cutlets then
            return i, Catalog.cutletEntry(i)
        end
    end
end

function Catalog.iterMonths()
    local i = 0
    return function()
        i = i + 1
        if i <= #months then
            return i, Catalog.monthEntry(i)
        end
    end
end

return setmetatable(Catalog, {
    __newindex = function()
        error("SourceLanguageCatalog la jele depi Stage 1")
    end,
    __metatable = false
})
