--- SexboundCommand
local SexboundCommand = {}
local SexboundCommand_mt = {
    __index = SexboundCommand
}

function SexboundCommand:new(options)
    return setmetatable({
        requiresAuth = options.requiresAuth or false,
        description = options.description or "",
        usage = options.usage or "",
        handler = options.handler
    }, SexboundCommand_mt)
end

--- SexboundCommands
local SexboundCommands = {}
local SexboundCommands_mt = {
    __index = SexboundCommands
}

function SexboundCommands.new()
    local self = setmetatable({
        _commands = {},
        _config = root.assetJson('/sexbound.config'),
        _changelog = root.assetJson('/sexbound-changelog.json'),
        _credits = root.assetJson('/sexbound-credits.json')
        --_supporters = root.assetJson('/sexbound-supporters.json')
    }, SexboundCommands_mt)

    self:defineCommands()

    return self
end

function SexboundCommands:checkIsAuthorized(connectionId, requiresAuth)
    if requiresAuth == false then
        return
    end
    return CommandProcessor.adminCheck(connectionId, "run this command")
end

function SexboundCommands:convertNameToLowerCase(name)
    return string.lower(name)
end

function SexboundCommands:convertArgsToLowerCase(args)
    for i, arg in ipairs(args) do
        args[i] = string.lower(arg or "")
    end

    return args
end

function SexboundCommands:tryHandlingCommand(name, id, args)
    name = self:convertNameToLowerCase(name)

    if name ~= "sexbound" and name ~= "sxb" then
        return
    end

    args = self:convertArgsToLowerCase(args)

    local action = args[1] or ""
    if action == "" then
        return "^white;Sexbound exists!^reset;"
    end

    if self._commands[action] ~= nil then
        local auth = self:checkIsAuthorized(id, self._commands[action].requiresAuth)
        if (type(auth) == "string") then
            return auth
        end
        return self._commands[action]:handler(self, args)
    else
        return "^white;Command not recognized!^reset;"
    end
end

function SexboundCommands:defineCommands()
    self:defineChangelogCommand()
    --self:defineBackersCommand()
    self:defineCreditsCommand()
    self:defineDonateCommand()
    self:definePluginsCommand()
    self:defineSpeciesCommand()
    self:defineVersionCommand()
    self:defineUpdatesCommand()
    self:defineHelpCommand()
end

function SexboundCommands:defineBackersCommand()
    self._commands['backers'] = SexboundCommand:new({
        description = 'OUTPUTS A LIST OF SUPPORTERS.',
        handler = self.handleBackersAction
    })
end

function SexboundCommands:handleBackersAction(commands, args)
    local separator = "^orange;  ^reset;"
    local message = "\n^red;:: SEXBOUND SUPPORTERS ::^reset;\n\n"
    for _, supporter in ipairs(commands._supporters) do
        message = message .. separator .. "^white;" .. supporter.name .. "^reset;"
    end
    message = message .. separator
    return message
end

function SexboundCommands:defineChangelogCommand()
    self._commands['changelog'] = SexboundCommand:new({
        description = 'OUTPUTS CHANGELOG FOR THE CURRENT VERSION.',
        handler = self.handleChangelogAction
    })
end

function SexboundCommands:handleChangelogAction(commands, args)
    local version = commands._config.version
    local versionStripped = string.gsub(version, "_?h%d+$", "")
    local versionBase = string.gsub(version, "(%d%.%d)_.+", "%1")
    local message = "\n^red;:: SEXBOUND CHANGELOG v" .. version .. " ::^reset;\n\n"
    local changes = commands._changelog[version] or commands._changelog[versionStripped] or commands._changelog[versionBase] or {}

    for _, change in ipairs(changes) do
        message = message .. " => ^white;" .. change .. "^reset;\n"
    end

    return message
end

function SexboundCommands:defineCreditsCommand()
    self._commands['credits'] = SexboundCommand:new({
        description = 'OUTPUTS A LIST OF CREDITS.',
        handler = self.handleCreditsAction
    })
end

function SexboundCommands:handleCreditsAction(commands, args)
    local separator = "^orange;  ^reset;"
    local message = "\n^red;:: SEXBOUND CREDITS ::^reset;\n\n"
    for _, credit in ipairs(commands._credits) do
        message = message .. separator .. "^white;" .. credit.name .. " - " .. credit.role .. "^reset;"
    end
    message = message .. separator
    return message
end

function SexboundCommands:defineDonateCommand()
    self._commands['donate'] = SexboundCommand:new({
        description = 'SPECIFIES HOW YOU CAN DONATE.',
        handler = self.handleDonateAction
    })
end

function SexboundCommands:handleDonateAction(commands, args)
    local message = "^white;If you enjoy my work you can consider leaving a tiny donation as a thanks: ^reset;\n"
    message = message .. " => ^orange;https://ko-fi.com/erinasugino^reset;"
    return message
end

function SexboundCommands:defineHelpCommand()
    self._commands['help'] = SexboundCommand:new({
        description = 'OUTPUTS A LIST OF COMMAND ACTIONS.',
        handler = self.handleHelpAction
    })
end

function SexboundCommands:handleHelpAction(commands, args)
    local message = "\n^red;:: SEXBOUND CLI ACTIONS ::^reset;\n\n"

    for commandName, command in pairs(commands._commands) do
        message = message .. " => ^blue;" .. commandName .. "^white; - " .. command.description .. "^reset;\n"
    end

    return message
end

function SexboundCommands:definePluginsCommand()
    self._commands['plugins'] = SexboundCommand:new({
        description = 'OUTPUTS A LIST OF INSTALLED PLUGINS.',
        handler = self.handlePluginsAction
    })
end

function SexboundCommands:formatPluginEnabled(plugin)
    if plugin.enable == true then
        return "^green;ENABLED^reset;"
    end

    return "^red;DISABLED^reset;"
end

function SexboundCommands:handlePluginsAction(commands, args)
    local plugins = commands._config.actor.plugins
    local message = "\n^red;:: SEXBOUND INSTALLED PLUGINS ::^reset;\n\n"

    for pluginName, plugin in pairs(plugins) do
        message = message .. " => ^white;" .. pluginName .. " [ " .. commands:formatPluginEnabled(plugin) ..
                      " ] ^reset;\n"
    end

    return message
end

function SexboundCommands:defineSpeciesCommand()
    self._commands['species'] = SexboundCommand:new({
        description = 'OUTPUTS A LIST OF SUPPORTED SPECIES.',
        handler = self.handleSpeciesAction
    })
end

function SexboundCommands:handleSpeciesAction(commands, args)
    local message = "\n^red;:: SEXBOUND SUPPORTED SPECIES ::^reset;\n\n"

    for _, species in ipairs(commands._config.sex.supportedPlayerSpecies) do
        message = message .. " => ^white;" .. species .. "^reset;\n"
    end

    return message
end

function SexboundCommands:defineUpdatesCommand()
    self._commands['updates'] = SexboundCommand:new({
        description = 'OUTPUTS THE UPDATE LINK.',
        handler = self.handleUpdatesAction
    })
end

function SexboundCommands:handleUpdatesAction(commands, args)
    return "Update Link: ^blue;" .. commands._config.updateLink .. "^reset;"
end

function SexboundCommands:defineVersionCommand()
    self._commands['version'] = SexboundCommand:new({
        description = 'OUTPUTS THE INSTALLED VERSION NUMBER.',
        handler = self.handleVersionAction
    })
end

function SexboundCommands:handleVersionAction(commands, args)
    return "^white;Running Sexbound Reborn V" .. commands._config.version .. "^reset;"
end

--- LUA HOOKS

local sexbound_init_old = init
function init()
    if type(sexbound_init_old) == "function" then
        sexbound_init_old()
    end

    self.sexboundCommands = SexboundCommands.new()
end

local sexbound_command_old = command
function command(name, id, args)
    if type(sexbound_command_old) == "function" then
        return sexbound_command_old(name, id, args)
    end

    return self.sexboundCommands:tryHandlingCommand(name, id, args)
end
