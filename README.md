# Polytoria Luau Module Loader
*A simple Luau module loader system for the Polytoria game engine.*
___
## Use Case
- If you need to initialize and start scripts in a sequential order predefined before runtime.
- Achieving a "single-script" architecture to keep your code well-organized and modular.
- Splitting up large systems into smaller modules to improve the cleanliness and ease-of-use of a game's code.

___
## Features
- A parameter to make sure the Client only starts running once the Server code is done initializing and started.
- Load the Client/Server through one function on the module.
- Add an IntValue called "ModuleLoaderPriority" to a ModuleScript and set its value (lower = first in the order, higher = further down the order) to sequentially load scripts.
- Add a BoolValue called "ModuleLoaderIgnore" to a ModuleScript to make it not run (good for debugging.)
- Method to check if the server or client is loaded from an external script.

___
## Install

### Necessary Instances
1. Add a **ModuleScript** into **ScriptService** called "ModuleLoader"
2. Add a **ServerScript** into **ScriptService** called "InitServer"
3. Add a **ClientScript** into **ScriptService** called "InitClient"
4. Create a **Folder** called "Server" inside **ServerHidden** - this is for your SERVER-only ModuleScripts
5. Create a **Folder** called "Client" inside **ScriptService** - this is for your CLIENT-only ModuleScripts

In the end, your world structure could look like this:
```
ScriptService
├─ ModuleLoader (ModuleScript)
├─ InitServer (ServerScript)
├─ InitClient (ClientScript)
└─ Client (Folder)

ServerHidden
└─ Server (Folder)
```


### Set up the ModuleLoader script
Paste the code from the ModuleLoader.luau file from this GitHub repository into the ModuleLoader script which you should've created earlier and then save.

### Set up the SERVER Init script
Paste the following code into the InitServer script you should've created earlier and then save.
```lua
local serverFolder = ServerHidden:WaitChild("Server")
local ModuleLoader = require(ScriptService:WaitChild("ModuleLoader"))
ModuleLoader.Load({
	["DEBUG"] = "SERVER",
	["target"] = serverFolder,
	["maxSearchDepth"] = 2,
	["logModulesLoaded"] = true,
	["logIgnoredModules"] = true,
})
```

### Set up the CLIENT Init script
Paste the following code into the InitServer script you should've created earliert and then save.
```lua
local clientFolder = ScriptService:WaitChild("Client")
local ModuleLoader = require(ScriptService:WaitChild("ModuleLoader"))
ModuleLoader.Load({
	["DEBUG"] = "CLIENT",
	["target"] = script.Parent:WaitChild("Client"),
	["maxSearchDepth"] = 2,
	["waitForServer"] = true, -- It is advisible to set this to true.
	["logModulesLoaded"] = true,
	["logIgnoredModules"] = true,
})
```
___
## Usage
Once installed, you can freely create ModuleScripts inside the respective Server and Client folders. You can further divide them up into descendant folders to group together scripts of similar function. Each script within one of the module loader's Server/Client folders can have two optional functions; "init" and "start." If you parent a ModuleScript into one of the loader's folders without these functions, it will still try to require() it, however; no functions will be called inside of the script. 

### Template ModuleScript
```lua
local module = {}

function module.init()
    -- This function always runs before the start function in any other script. Good for setting up specific instances in the scene.
end

function module.start()
	-- This function will run after the init functions of all other scripts further down the order have ran. Designed for code that runs after setup.
end

return module
```

___

This project is created by @BoolValue on Polytoria and is free and open source software under the MIT License.
