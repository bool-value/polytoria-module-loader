--[[
		@BoolValue on Polytoria
		2026/07/19
		"ModuleLoader"
		https://github.com/bool-value/polytoria-module-loader
		
		-----------
		
		MIT License

		Copyright (c) 2026 bool-value

		Permission is hereby granted, free of charge, to any person obtaining a copy
		of this software and associated documentation files (the "Software"), to deal
		in the Software without restriction, including without limitation the rights
		to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
		copies of the Software, and to permit persons to whom the Software is
		furnished to do so, subject to the following conditions:

		The above copyright notice and this permission notice shall be included in all
		copies or substantial portions of the Software.

		THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
		IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
		FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
		AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
		LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
		OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
		SOFTWARE.
		
		URL: https://github.com/bool-value/polytoria-module-loader/blob/main/LICENSE
]]

local public = {}
local private = {}

----------------------------------------------------------------

local DEFAULTS = {
	MAX_SEARCH_DEPTH = 100,
	PRIORITY_LIMIT = 10_000,
}
local HIERARCHY_INDICATOR = "Folder"
local INIT_FUNCTION = "init"
local START_FUNCTION = "start"

----------------------------------------------------------------

-- self-explanatory
function private.chkIsServer()
	return _SERVER
end

-- formatting mainly
function private.log(text: string, category: string?)
	local domain = private.chkIsServer() and "SERVER" or "CLIENT"
	if category then
		print(`ModuleLoader.{domain}::{category} -> {text}`)
	else
		print(`ModuleLoader.{domain} -> {text}`)
	end
end

-- order scripts by priority IntValue if found
function private.orderDomain(parentFolder: Folder, order: {any}, currentDepth: number)
	for idx, module: ModuleScript? in pairs(parentFolder:GetChildren()) do
		-- is a module
		if module:IsA("ModuleScript") then
			local ivModuleLoaderPriority: IntValue? = module:FindChild("ModuleLoaderPriority")
			local value: number = ivModuleLoaderPriority and ivModuleLoaderPriority.Value or private.unorderedIndex
			if order[value] == nil then order[value] = {} end
			table.insert(order[value], module)
		
		-- assume the dev uses folders for module hierarchy
		elseif module:IsA(HIERARCHY_INDICATOR) then
			if currentDepth >= private.maxSearchDepth then continue end
			order = private.orderDomain(module, order, currentDepth + 1)
			
		end
	end
	return order
end

-- initialize all modules
function private.initDomain(initFunctions)
	for idx, initFunc in pairs(initFunctions) do
		local isSuccess, issue = pcall(initFunc[2])
		if isSuccess and private.logModulesLoaded then
			private.log(`[+] Initialized module {initFunc[1]}`)
		elseif not isSuccess then
			private.log(`[!] Error initializing module {initFunc[1]}: {issue}`)
		end
	end
end

-- start all modules
function private.startDomain(startFunctions)
	for idx, startFunc in pairs(startFunctions) do
		local isSuccess, issue = pcall(startFunc[2])
		if isSuccess and private.logModulesLoaded then
			private.log(`[+] Started module {startFunc[1]}`)
		elseif not isSuccess then
			private.log(`[!] Error starting module {startFunc[1]}: {issue}`)
		end
	end
end

-- the actual loader part
function private.executeDomain(domFolder: Folder)
	local modules = private.orderDomain(domFolder, {}, 1)
	local initFunctions = {} :: {() -> ()}
	local startFunctions = {} :: {() -> ()}
	for rank, entries in pairs(modules) do
		for idx, entry in pairs(entries) do
			-- catch the module if it doesn't return any value
			local moduleReturn = nil
			local requireIsSuccess, requireIssue = pcall(function() 
				moduleReturn = require(entry) 
			end)
			if not requireIsSuccess then
				warn(`[!] Module "{entry.Name}" failed to require() with error: {requireIssue}`, "executeDomain")
				continue
			end
			-- ignore/lockout mechanism
			if entry:FindChild("ModuleLoaderIgnore") ~= nil then
				if private.logIgnoredModules then
					private.log(`[-] Ignored module {entry.Name} due to ModuleLoaderIgnore prescence.`)
				end
				continue
			end
			-- in case they dont understand how this works fully and miss out both optional functions
			if moduleReturn[INIT_FUNCTION] ~= nil then 
				table.insert(initFunctions, {entry.Name, moduleReturn[INIT_FUNCTION]})
			end
			if moduleReturn[START_FUNCTION] ~= nil then 
				table.insert(startFunctions, {entry.Name, moduleReturn[START_FUNCTION]})
			end
		end
	end
	
	private.initDomain(initFunctions)
	private.startDomain(startFunctions)
end

----------------------------------------------------------------

function public.load(params)
	local IS_SERVER = private.chkIsServer()
	local DBG_STRING: string = params.DEBUG
	local DOMAIN = IS_SERVER and "SERVER" or "CLIENT"
	
	-- needs to wait for the server to start ONLY if the param is set to true
	if params.waitForServer then repeat wait() until ScriptService:FindChild("ModuleLoaderIsLoaded") ~= nil end
	
	private.target = params.target 
	if private.target == nil then private.log(`[!] No target Folder found for init.`) return end
	private.priorityLimit = DEFAULTS.PRIORITY_LIMIT
	private.unorderedIndex = private.priorityLimit + 1
	private.maxSearchDepth = params.maxSearchDepth or DEFAULTS.MAX_SEARCH_DEPTH
	private.logModulesLoaded = params.logModulesLoaded or true
	private.logIgnoredModules = params.logIgnoredModules or true
	private.startTime = os.clock()

	print(`[*] BEGUN LOADING {DOMAIN} [*]`)
	
	private.executeDomain(private.target)
	if IS_SERVER then
		local ModuleLoaderIsLoaded: BoolValue = Instance.New("BoolValue")
		ModuleLoaderIsLoaded.Name = "ModuleLoaderIsLoaded"
		ModuleLoaderIsLoaded.Value = true
		ModuleLoaderIsLoaded.Parent = ScriptService
	end
	
	local endTime = os.clock()
	local timeDiff = endTime - private.startTime
	print(`[*] FINISHED LOADING {DOMAIN} IN {timeDiff} SECONDS [*]`)
	
	local domainLoadedBoolValue = Instance.New("BoolValue") :: BoolValue
	domainLoadedBoolValue.Name = `{DOMAIN}_IsLoaded`
	domainLoadedBoolValue.Value = true
	domainLoadedBoolValue.Parent = script
end

-- self-explanatory
function public.chkIsServerLoaded()
	return script:FindChild("SERVER_IsLoaded") and true or false
end

-- self-explanatory
function public.chkIsClientLoaded()
	if private.chkIsServer() then return end -- not a possibility (yet)
	return script:FindChild("CLIENT_IsLoaded") and true or false
end

----------------------------------------------------------------

return {
	Load = public.load,
	CheckIsServerLoaded = public.chkIsServerLoaded,
	CheckIsClientLoaded = public.chkIsClientLoaded
}
