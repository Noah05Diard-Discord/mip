local root = "https://raw.githubusercontent.com/Noah05Diard-Discord/mip/refs/heads/main/src/"

local components = {
    "client/browser.lua",
    "client/sandbox.lua",
    "client/mipProtocol.lua",
    "dns/dns-sys.lua",
    "server/server.lua"
}

local programs = {
    server = {
        entry = "server/server.lua",
        5
    },
    client = {
        entry = "client/browser.lua",
        1,
        2,
        3
    },
    dns = {
        entry = "dns/dns-sys.lua",
        4
    }
}

write("Would you want to install manually? y/N")
local ans = read()

if ans:lower() == "y" then
    for i,a in ipairs(components) do
        print(i,"|",a)
    end
    write("Type number of choice")
    local choice = tonumber(read())
    if not components[choice] then error("Choice out of range",0) end
    local req = http.get(root..components[choice])
    local all = req.readAll()
    req.close()
    write("Type path: ")
    local path = read()
    local f = fs.open(path,"w")
    f.write(all)
    f.close()
else
    for i,a in pairs(programs) do
        print(i)
    end
    write("What program? ")
    local program = programs[read()]
    if not program then error("Unknown program",1)  end
    for i,a in ipairs(program) do
        if type(a) == "number" then
            local req = http.get(root..components[a])
            local all = req.readAll()
            req.close()
            local f = fs.open(components[a],"w")
            f.write(all)
            f.close()
        end
    end
end