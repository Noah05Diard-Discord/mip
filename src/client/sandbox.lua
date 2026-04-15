local sandbox = {}

sandbox.apis = {}

function sandbox.registerApi(name,api)
    sandbox.apis[name] = api
end

function sandbox.makeEnv()
    local env = {
        type = type,
        string = string,
        table = table,
        math = math,
        tostring = tostring,
        tonumber = tonumber,
        load = load,
        coroutine = coroutine,
        pairs = pairs,
        pcall = pcall,
        ipairs = ipairs,
        colors = colors,
        keys = keys
    }

    for k,v in pairs(sandbox.apis) do
        env[k] = v
    end

    return env
end

function sandbox.load(str,name)
    local func,err = load(str,name,nil,sandbox.makeEnv())

    if not func then
        error(err)
    end

    return func
end

return sandbox