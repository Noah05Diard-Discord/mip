# List of elements:
- Video
```lua
{
    ["type"] = "video",
    ["fps"] = 2,
    ["frame"] = 1,
    ["title"] = "My Video",
    ["frames"] = {
        {
            ["nfp"]={},
            ["subtitles"]={}
        }
    },
    ["id"] = "", -- For scripting
    ["x"] = 1,
    ["y"] = 1,
}
```
- Picture
```lua
{
    ["type"] = "picture",
    ["nfp"] = {},
    ["id"] = "", -- For scripting
    ["x"] = 1,
    ["y"] = 1,
}
```
- Text
```lua
{
    ["type"] = "text",
    ["text"] = "Hello, World",
    ["class"] = "", -- For styling
    ["id"] = "",    -- For Scripting
    ["x"] = 1,
    ["y"] = 1,
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
    ["x"] = 1,
    ["y"] = 1,
}
```
- TextBox
```lua
{
    ["type"] = "textbox",
    ["placeholder"] = "Placeholder",
    ["text"] = "",
    ["class"] = "",
    ["id"] = "",
    ["x"] = 1,
    ["y"] = 1,
}
```
- PasswordBox
```lua
{
    ["type"] = "passbox",
    ["placeholder"] = "Placeholder",
    ["text"] = "",
    ["class"] = "",
    ["id"] = "",
    ["x"] = 1,
    ["y"] = 1,
}
```