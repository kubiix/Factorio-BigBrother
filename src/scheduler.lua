require 'stdlib/event/event'

Scheduler = {}

function Scheduler.add(key, func)
    if not storage.scheduled_tasks then
        storage.scheduled_tasks = {}
        Scheduler._setup()
    end
    if key then
        for _, task in pairs(storage.scheduled_tasks) do
            if task.key == key then
                return false
            end
        end
    end
    table.insert(storage.scheduled_tasks, { key = key, func = func })
    return true
end

function Scheduler._tick(event)
    local tasks = storage.scheduled_tasks
    if tasks then
        -- reset task queue, (don't set to nil, the event handler is still registered)
        storage.scheduled_tasks = {}
        -- execute queued tasks
        for _, task in pairs(tasks) do
            task.func(event)
        end
        -- tasks may have been added above, in the event loop, if not, disable scheduler
        if #storage.scheduled_tasks == 0 then
            storage.scheduled_tasks = nil
            Event.remove(defines.events.on_tick, event._handler)
        end
    end
end

function Scheduler._setup()
    if storage.scheduled_tasks then
        Event.register(defines.events.on_tick, Scheduler._tick)
    end
end

Event.register(Event.core_events.load, Scheduler._setup)
