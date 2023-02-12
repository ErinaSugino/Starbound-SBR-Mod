--- Sexbound.Compatibility Class Module.
-- @classmod Sexbound.Compatibility
-- @author Locuturus
-- @license GNU General Public License v3.0
Sexbound.Compatibility = {}
Sexbound.Compatibility_mt = {
    __index = Sexbound.Compatibility
}

--- Instantiates a new instance of Compatibility.
-- @param parent
function Sexbound.Compatibility.new(parent)
    local self = setmetatable({
        _parent = parent
    }, Sexbound.Compatibility_mt)

    self._, self._major, self._minor, self._patch, self._isOld = Sexbound.Util.parseVersion(self._parent:getConfig().version)
    self._isCompatible = self:_checkIsCompatible()

    return self
end

--- Returns whether or not the mod is compatible based on its requiredVersion
function Sexbound.Compatibility:_checkIsCompatible()
    local _requiredVersion = self:getParent():getRequiredVersion()

    -- Return true when requiredVersion option is nil, empty, or '*'
    if type(_requiredVersion) ~= 'string' or _requiredVersion == '*' then
        return true
    end

    local _range, _major, _minor, _patch, _isOld = Sexbound.Util.parseVersion(_requiredVersion)

    -- Use range to determine if the current version is compatible with the mod
    if type(_range) ~= "string" or #_range == 0 then
        --return self._major == _major and self._minor == _minor and self._patch == _patch
        return self._isInstalledSexboundVersionRequiredVersion(_major, _minor, _patch, _isOld)
    elseif _range == ">=" then
        return self:_isInstalledSexboundVersionGreaterThanOrEqualToRequiredVersion(_major, _minor, _patch, _isOld)
    elseif _range == ">" then
        return self:_isInstalledSexboundVersionGreaterThanRequiredVersion(_major, _minor, _patch, _isOld)
    elseif _range == "<=" then
        return self:_isInstalledSexboundVersionLessThanOrEqualToRequiredVersion(_major, _minor, _patch, _isOld)
    elseif _range == "<" then
        return self:_isInstalledSexboundVersionLessThanRequiredVersion(_major, _minor, _patch, _isOld)
    end

    return false
end

function Sexbound.Compatibility:_isInstalledSexboundVersionRequiredVersion(major, minor, patch, old)
    if old ~= self._isOld then return false end
    if self._isOld then
        return self._major == major and self._minor == minor and self._patch == patch
    else
        return self._major == major and self._minor == minor
    end
end

function Sexbound.Compatibility:_isInstalledSexboundVersionGreaterThanRequiredVersion(major, minor, patch, old)
    if self._isOld ~= old then return not self._isOld end -- Greater => new > old => not is old on difference
    if self._isOld and self._major == major and self._minor == minor and self._patch > patch then
        -- Patch only matters with old versions
        return true
    end
    if self._major == major and self._minor > minor then
        return true
    end
    if self._major > major then
        return true
    end

    return false
end

function Sexbound.Compatibility:_isInstalledSexboundVersionGreaterThanOrEqualToRequiredVersion(major, minor, patch, old)
    sb.logInfo("Trying to compare "..tostring(major)..">="..tostring(self._major)..", "..tostring(minor)..">="..tostring(self._minor)..","..tostring(patch)..">="..tostring(self._patch)..", "..tostring(old).."<="..tostring(self._isOld))
    if self._isOld ~= old then return not self._isOld end -- Greater => new > old => not is old on difference
    if self._isOld and self._major == major and self._minor == minor and self._patch >= patch then
        -- Patch only matters with old versions
        return true
    end
    if self._major == major and self._minor >= minor then
        return true
    end
    if self._major >= major then
        return true
    end

    return false
end

function Sexbound.Compatibility:_isInstalledSexboundVersionLessThanRequiredVersion(major, minor, patch)
    if self._isOld ~= old then return self._isOld end -- Lesser => new < old => is old on difference
    if self._isOld and self._major == major and self._minor == minor and self._patch < patch then
        -- Patch only matters with old versions
        return true
    end
    if self._major == major and self._minor < minor then
        return true
    end
    if self._major < major then
        return true
    end

    return false
end

function Sexbound.Compatibility:_isInstalledSexboundVersionLessThanOrEqualToRequiredVersion(major, minor, patch)
    if self._isOld ~= old then return self._isOld end -- Lesser => new < old => is old on difference
    if self._isOld and self._major == major and self._minor == minor and self._patch <= patch then
        -- Patch only matters with old versions
        return true
    end
    if self._major == major and self._minor <= minor then
        return true
    end
    if self._major <= major then
        return true
    end

    return false
end

function Sexbound.Compatibility:incompatibleVersion()
    Sexbound.Util.broadcastRadioMessage(
        "Sexbound:Compatibility",
        false,
        self:_buildIncompatibleVersionMessage()
    )
end

function Sexbound.Compatibility:_buildIncompatibleVersionMessage()
    local _modLink = self._parent:getModLink()
    local _modName = self._parent:getModName()
    local _version = self._parent:getVersion()
    local _message = "WARNING: <modName> is not compatible with Sexbound V<version>!"
    _message = util.replaceTag(_message, 'modName', '^red;' .. _modName .. '^reset;');
    _message = util.replaceTag(_message, 'version', _version)
    if type(_modLink) == 'string' then
        _message = _message .. " Download the latest version of this mod: <modLink>"
        _message = util.replaceTag(_message, 'modLink', '^green;' .. _modLink .. '^reset;')
    else
        _message = _message .. " Please check if a compatible version of this mod has been released."
    end
    return _message
end

function Sexbound.Compatibility:getParent()
    return self._parent
end

function Sexbound.Compatibility:isCompatible()
    return self._isCompatible
end
