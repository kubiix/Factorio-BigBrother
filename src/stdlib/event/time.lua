--- Raise events for surfaces at certain time intervals.
-- This module uses the @{Event} module.
-- @module Time
-- @usage require('stdlib/event/time')
-- @see event.time.lua

require('stdlib/core')

local Time = {_module_name = "Time"}
setmetatable(Time, {__index = require('stdlib/core')})
require('stdlib/event/event')

local function init_time_globals()
    storage._surface_time = storage._surface_time or {}
end

-- All times are offset by 0.5
-- This is because both EvoGUI and MoWeather already apply that offset.
-- Following the precedent to remain consistent.
-- Actually, this little snippet is even borrowed from EvoGUI.
local get_day_time
if remote.interfaces.MoWeather then
    -- assume MoWeather's getdaytime is sane
    get_day_time = function (surface_name_or_index) return remote.call("MoWeather", "getdaytime", surface_name_or_index) end
else
    -- 0.5 is midnight; let's make days *start* at midnight instead.
    get_day_time = function (surface_name_or_index) return game.surfaces[surface_name_or_index].daytime + 0.5 end
end

--- @field midday Fires whenever it becomes midday/noon on a surface
Time.midday = script.generate_event_name()
--- @field midnight Fires whenever it becomes midnight on a surface
Time.midnight = script.generate_event_name()
--- @field sunrise Fires whenever the sunrises on a surface
Time.sunrise = script.generate_event_name()
--- @field sunset Fires whenever the sunsets on a surface
Time.sunset = script.generate_event_name()
--- @field hourly Fires every hour for a surface
Time.hourly = script.generate_event_name()
--- @field minutely Fires every minute for a surface
Time.minutely = script.generate_event_name()
--- @field daily Fires every day for a surface
Time.daily = script.generate_event_name()

local function time_ticker()
    for idx, surface in pairs(game.surfaces) do
        if not surface.freeze_daytime then
            local day_time = math.fmod(get_day_time(idx), 1)
            local day_time_minutes = math.floor(day_time * 1440) -- 24 * 60

            if day_time_minutes ~= storage._surface_time[idx] then
                storage._surface_time[idx] = day_time_minutes
                script.raise_event(Time.minutely, {surface = surface})

                if day_time_minutes % 60 == 0 then
                    script.raise_event(Time.hourly, {surface = surface})
                end

                if day_time_minutes == 0 then
                    script.raise_event(Time.daily, {surface = surface})
                    script.raise_event(Time.midnight, {surface = surface})
                end

                -- These are not 100% accurate but within 5-10 Nauvis minutes of the real thing.
                -- 105 (1:45AM) Brightness starts to increase
                -- 265 (4:25AM) Flashlight clicks off
                if day_time_minutes == 265 then
                    script.raise_event(Time.sunrise, {surface = surface})
                end

                if day_time_minutes == 720 then
                    script.raise_event(Time.midday, {surface = surface})
                end

                -- These are not 100% accurate but within 5-10 Nauvis minutes of the real thing.
                -- 1070 (5:50PM) Brightness starts to decrease
                -- 1160 (7:20PM) Flashlight clicks on
                if day_time_minutes == 1160 then
                    script.raise_event(Time.sunset, {surface = surface})
                end
            end
        end
    end
end
Event.register(defines.events.on_tick, time_ticker)

--- Get the current time of a given surface.
-- @function get_day_time
-- @tparam LuaSurface surface
-- @treturn double the current surface time such that 0.0 ⋜ surface time ⋜ 1.0
Time.get_day_time = get_day_time

-- When the mod is initialized the first time
Event.register(Event.core_events.init_and_config, init_time_globals)

Event.Time = Time
return Time
