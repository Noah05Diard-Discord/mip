# List of elements:
- Video
```lua
{
    ["type"] = "video",
    ["fps"] = 2,
    ["title"] = "My Video",
    ["frames"] = {
        {
            ["nfp"]={},
            ["subtitles"]={}
        }
    },
    ["id"] = "" -- For scripting
}
```
- Text
```lua
{
    ["type"] = "text",
    ["text"] = "Hello, World",
    ["class"] = "", -- For styling
    ["id"] = "",    -- For Scripting
}
```
- Button
```lua
{
    ["type"] = "button",
    ["text"] = "button",
    ["web"] = "example.com",
    ["page"] = "index",
    ["class"] = "", -- For styling
    ["id"] = "", -- For Scripting
}
```
- TextBox
```lua
{
    ["type"] = "textbox",
    ["placeholder"] = "Placeholder",
    ["text"] = "",
    ["class"] = "",
    ["id"] = ""
}
```