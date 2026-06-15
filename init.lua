--!optimize 2

-- hashing (feds), decrypting module scripts (feds)

if not (getgenv and getgenv()) then
    error("getgenv is missing")
end

local Modules = {
    ["reanimate.lua"] = ""
}
local Methods = {}

--local decryptionkey = ""
--local scriptHashes = {
--    
--}

local getgenv = getgenv
local getfenv = getfenv
local shared = shared
local _G = _G

local setmetatable = setmetatable

local next = next
local type = type
local loadstring = loadstring
local require = require
local pcall = pcall

local _error = error

local debug = debug
local debug_info = debug.info
local debug_getinfo = debug.getinfo

local table_insert = table.insert

local string_format = string.format

local tostring = tostring

--local HashLibrary = loadstring(game:HttpGet("https://pastebin.com/raw/RZQ3cj4T"))()

--for ScriptName, Hash in next, scriptHashes do
--
--end

local workspace = workspace
local __workspace = workspace
local __game = __workspace.Parent

local _HAT = (getgenv and getgenv()) or _G or (getfenv and getfenv()) or shared
_HAT.__activethreadname = _HAT.__activethreadname or "init.lua"

local trace_error = "\n--%s--\n\n%s:%d: %s\nstack traceback:\n=[%s] in function '%s'\n=%s:%d in proto\n\n--%s--\n"
local error = function(message: string): ()
    local s, l, n = debug_info(2, "sln")
    local m = message or "null"
    local closure = p and p.what or "Lua"
    local err = string_format(trace_error, _HAT.__activethreadname, s, l, m, closure, "error", s, l, _HAT.__activethreadname)

    _error(err)
end
local assert = function(__object: any, message: string?): any
    if type(__object) == "string" then
        local __variable = _HAT[__object]
        if __variable ~= nil then return __variable end
    else
        if __object ~= nil and __object ~= false then
            return __object
        end
    end

    local name = type(__object) == "string" and __object or "?"
    local m = message or "null"
    local s, l, n = debug_info(2, "sln")
    local p = debug_getinfo(2)
    local closure = p and p.what or "Lua"
    local err = string_format(trace_error, _HAT.__activethreadname, s, l, m, closure, name, s, l, _HAT.__activethreadname)
    
    _error(err)
    return nil
end

local finder
local cached

finder, cached = loadstring(game:HttpGet("https://pastebin.com/raw/ibf4Cv7a"))()

finder({
	cloneref = 'string.find(...,"clone",nil,true) and string.find(...,"ref",nil,true)',
    setclipboard = 'string.find(..., "set",nil,true) and string.find(...,"clipboard",nil,true)',
    request = 'string.find(...,"req",nil,true) and string.find(...,"uest",nil,true)',
    readfile = 'string.find(...,"read",nil,true) and string.find(...,"file",nil,true)',
    writefile = 'string.find(...,"write",nil,true) and string.find(...,"file",nil,true)',
    isfile = 'string.find(...,"is",nil,true) and string.find(...,"file",nil,true)',
    makefolder = 'string.find(...,"make",nil,true) and string.find(...,"folder",nil,true)',
    isfolder = 'string.find(...,"is",nil,true) and string.find(...,"folder",nil,true)',
    base64encode = 'local a={...}local b=a[1]local function c(a,b)return string.find(a,b,nil,true)end;return c(b,"encode")and(c(b,"base64")or c(string.lower(tostring(a[2])),"base64"))',
    newcclosure = 'string.find(...,"new",nil,true) and string.find(...,"cclosure",nil,true)',
    sethiddenproperty = 'string.find(...,"set,nil,true) and string.find(...,"hidden",nil,true) and string.find(...,"prop",nil,true)',
    gethiddenproperty = 'string.find(...,"get",nil,true) and string.find(...,"h",nil,true) and string.find(...,"prop",nil,true) and string.sub(...,#...) ~= "s"',
	gethui = 'string.find(...,"get",nil,true) and string.find(...,"h",nil,true) and string.find(...,"ui",nil,true)',
	getcon = 'string.find(...,"get",nil,true) and (string.find(...,"conn",nil,true) or string.find(...,"sig",nil,true)) and string.sub(...,#(...))=="s"',
	getnilinstances = 'string.find(...,"nil",nil,true) and string.find(...,"get",nil,true) and string.sub(...,#...) == "s"', -- ! Could match some unwanted stuff
	getscriptbytecode = 'string.find(...,"get",nil,true) and string.find(...,"script",nil,true) and string.find(...,"bytecode",nil,true)', --  or string.find(...,"dump",nil,true) and string.find(...,"string",nil,true) due to Fluxus (dumpstring returns a function)
	hash = 'local a={...}local b=a[1]local function c(a,b)return string.find(a,b,nil,true)end;return c(b,"hash")and c(string.lower(tostring(a[2])),"crypt")',
	protectgui = 'string.find(...,"protect",nil,true) and string.find(...,"ui",nil,true) and not string.find(...,"un",nil,true)',
	setthreadidentity = 'string.find(...,"identity",nil,true) and string.find(...,"set",nil,true)',
    setsimulationradius = 'string.find(...,"set",nil,true) and string.find(...,"simulation",nil,true)'
}, true, 10) 

--[[do
    local oldhashreference = cached.hash

    if oldhashreference then
        _HAT.oldhashreference = oldhashreference
        cached.hash = HashLibrary
    else
        cached.hash = HashLibrary
    end
end]]

for i, v in next, _HAT do
    if not v or type(v) == "nil" then
        return
    end

    table_insert(cached, v)
end

local function import(module)
    if cached[module] then
        return cached[module]
    end

    local name = tostring(module)
    return assert(module, string_format("Executor doesn't support '%s'", name))
end

local declare = function(globalname, global)
    return function()
        assert(global, tostring(global) .. " doesn't exist!", globalname)

        getfenv(0)[globalname] = global
        _HAT[globalname] = global
    end
end

declare("declare", declare)()
declare("error", error)()
declare("assert", assert)()
declare("import", import)()
declare("cached", cached)()
declare("game", setmetatable({}, {
    __index = function(self, key)
        if key == "GetService" or key == "service" or key == "FindService" then
            return function(self, service)
                local success, res = pcall(function()
                    return cached.cloneref(__game:GetService(service))
                end)

                if not success then
                    res = res or "Failed to get response"
                    return res
                end

                return res
            end
		end

        local val = __game[key]
        if type(val) == "function" then return function(self, ...) return val(__game, ...) end end return val
    end
}))()

_HAT.scriptproto = {
    Events = {},
    Cache = setmetatable({}, { __mode = "kv" }),
    Exit = function()
        for I, V in next, scriptproto.Events do
            V:Disconnect()
        end

        for I, V in next, scriptproto.Cache do
            V = nil
            I = nil
        end
    end
}

assert(game.HttpGet, "HttpGet Doesn't Exist For You're Environment")
assert((function()
    local cdn = "https://www.cloudflare.com/cdn-cgi/trace"
    local contents = game:HttpGet(cdn)

    return type(contents) == "string" and contents ~= ""
end)(), "CDN test failed. You're HttpRequest doesn't work")

local function download(path)
    if IsFile(path) then
        local contents = ReadFile(path)
        return contents
    end

    local unprocessed = game:HttpGet(path)
    assert(unprocessed, "(contents is nil)")
    assert(#unprocessed > 1, "(contents is empty)")

    return unprocessed
end

local IsFile = import("isfile")--cached.isfile
local WriteFile = import("writefile")--cached.writefile
local ReadFile = import("readfile")--cached.readfile
local MakeFolder = import("makefolder")--cached.makefolder
local IsFolder = import("isfolder")--cached.isfolder

local CanUseFiles = (IsFile and WriteFile and ReadFile) ~= nil
local CanUseFolders = (MakeFolder and IsFolder) ~= nil

if CanUseFiles then
    local function createFile(path, contents)
        if not IsFile(path) then
            WriteFile(path, contents)
        end
    end

    if CanUseFolders then
        local function createFolder(path)
            if not IsFolder(path) then
                MakeFolder(path)
            end
        end

        createFolder("server")
        createFolder("server/modules")
    end

    for ScriptName, Script in pairs(Methods) do
        local DownloadedModule = download(Script)
        
        if CanUseFolders then
            createFile("server/modules/" .. ScriptName, DownloadedModule)
        else
            createFile(ScriptName, DownloadedModule)
        end
    end
else
    local onlyWeb = true
    local downloaded = {}

    for ScriptName, Script in pairs(Modules) do
        local DownloadedModule = download(Script)

        downloaded[ScriptName] = DownloadedModule
    end

    declare("onlyWeb", onlyWeb)()
    declare("downloaded", downloaded)()
end

scriptproto.GetModule = function(modulename: string): string
    local module
    if onlyWeb then
        module = downloaded[modulename] or download(modulename)
    else
        if IsFile(modulename) then
            module = ReadFile(modulename)
        elseif IsFile("server/modules/" .. modulename) then
            module = ReadFile("server/modules/" .. modulename)
        end
    end
end

declare("download", download)()