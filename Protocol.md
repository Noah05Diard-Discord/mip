# MIP Protocol
# WARNING:
## Making your own browser is NOT recommended. Thanks!
Here is how you get a domain if it exists. Send this to PORT 80 on your modem (table)

```lua
{
    ["destination"] = "DNS",
    ["action"] = "get_domain",
    ["arg"] = "domain.tls",
    ["id"] = math.random(1000,9999), -- This is only so the DNS Server can reply to that ID so requests don't get mixed up!
}
```

Reply:
```lua
{
    ["destination"] = "CLIENT",
    ["id"] = <the id sent>,
    ["reply"] = {
        ["success"] = true / false,
        -- if true these are the things more
        ["pcId"] = <Server PC Id>,
    }
}
```

Get a website:
```lua
{
    ["destination"] = "SERVER",
    ["action"] = "get_page",
    ["pcid"] = <Server PC Id>,
    ["id"] = math.random(1000,9999),
    ["page"] = "page",
}
```

Reply:
```lua
{
    ["destination"] = "CLIENT",
    ["id"] = <the id sent>,
    ["reply"] = {
        ["success"] = true / false,
        -- if true these are the things more
        ["data"] = <the webpage>,
    }
}
```
but that is only get page!
so we need to add to have upload and download
```lua
{
    ["destination"] = "SERVER",
    ["action"] = "download",
    ["pcid"] = <Server PC Id>,
    ["id"] = math.random(1000,9999),
    ["file"] = "your filename",
}
```
Reply:
```lua
{
    ["destination"] = "CLIENT",
    ["id"] = <the id sent>,
    ["reply"] = {
        ["success"] = true / false,
        -- if true these are the things more
        ["data"] = <the file>,
    }
}
```

now uploading

```lua
{
    ["destination"] = "SERVER",
    ["action"] = "upload",
    ["pcid"] = <Server PC Id>,
    ["id"] = math.random(1000,9999),
    ["file"] = "your filename",
    ["data"] = "your file",
}
```
Reply:
```lua
{
    ["destination"] = "CLIENT",
    ["id"] = <the id sent>,
    ["reply"] = {
        ["success"] = true / false,
    }
}
```