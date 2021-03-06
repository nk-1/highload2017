require('si_configReader')

local json = require('json')
local log = require('log')
local controller = {}

local function new()
    controller._repository = require('repository')

    return controller
end

local function isNumber(value)
    local result, _ = pcall(function() math.floor(value) end)
    return result
end

local function parseId(uri)
    return tonumber(string.split(string.split(uri, '/')[3], '?')[1])
end

local function getLocation(id)
    return controller._repository.getLocation(id);
end

local function saveLocation(locationJson)
    if locationJson.id == nil or not isNumber(locationJson.id) then
        return 400
    end
    for _, value in pairs(locationJson) do
        if value == nil then
            return 400
        end
    end
    return controller._repository.saveLocation(locationJson);
end

local function updateLocation(locationId, locationJson)
    for arg, value in pairs(locationJson) do
        if arg == 'id' then
            return 400
        end
        if value == nil then
            return 400
        end
    end
    if (locationJson.distance ~= nil and not isNumber(locationJson.distance)) then
        return 400
    end

    return controller._repository.updateLocation(locationId, locationJson);
end

local function getLocationAverage(locationId, fromDate, toDate, fromAge, toAge, gender)
    if (fromDate ~= nil and not isNumber(fromDate))
            or (toDate ~= nil and not isNumber(toDate))
            or (fromAge ~= nil and not isNumber(fromAge))
            or (toAge ~= nil and not isNumber(toAge))
            or (gender ~= nil and (type(gender) ~= 'string' or (gender ~= 'f' and gender ~= 'm'))) then
        return 400, {}
    end
    fromDate = tonumber(fromDate)
    toDate = tonumber(toDate)
    fromAge = tonumber(fromAge)
    toAge = tonumber(toAge)
    local status, avg = controller._repository.getLocationAverage(locationId, fromDate, toDate, fromAge, toAge, gender);
    local response = {}
    response.avg = avg
    return status, response
end

function locationEndpoint(req)
    local status = 200
    local response = {}
    if req.method == 'GET' then
        local locationId = parseId(req.uri)
        if string.match(req.uri, '/avg') then
            local s, r = getLocationAverage(locationId, req.args.fromDate, req.args.toDate, req.args.fromAge, req.args.toAge, req.args.gender)
            status = s
            response = r
        else
            response = getLocation(locationId)
            if not response then
                status = 404
            end
        end
    end
    if req.method == 'POST' then
        local parseStatus, jsonBody = pcall(function()
            return json.decode(req.body)
        end)
        if not parseStatus then
            return 400, response
        end
        if (string.match(req.uri, '/new')) then
            status = saveLocation(jsonBody)
        else
            local locationId = parseId(req.uri)
            status = updateLocation(locationId, jsonBody)
        end
    end

    return status, response
end

return {
    new = new
}