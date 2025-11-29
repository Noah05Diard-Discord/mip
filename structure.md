structure a serialized lua table
```lua
{
  ["objs"] = {
    {
      ["type"] = "video",
      then the args
    },
  },
  ["style"] = {
    -- The style table of your website, is here how to define it
    [".className"] = {
      ["background"] = "blue",
      ["textColor"] = "white",
    }
    ["elementType"] = {
      ["background"] = "red",
      ["textColor"] = "white",
    }
    ["body"] = {
      -- To change the main page style so like applies to the page bg and default textColor, this is required
      ["background"] = "black",
      ["textColor"] = "white",
    }
  }
  ["title"] = "title",
  ["description"] = "desc",
  ["script"] = "lua script",
}
```