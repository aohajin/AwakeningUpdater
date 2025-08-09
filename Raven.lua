local _, AUP = ...

do
    local Raven = {}
    Raven.__index = Raven

    local function safecall(fn, ...)
        return xpcall(fn, geterrorhandler(), ...)
    end

    -- allowed: 可选，限制允许的事件名集合（如 {EVENT=true}）
    function Raven.new(allowed)
        return setmetatable({ _handlers = {}, _allowed = allowed }, Raven)
    end

    -- 订阅：返回取消订阅函数 off()
    function Raven:on(event, fn)
        assert(type(event) == "string", "event must be a string")
        assert(type(fn) == "function", "handler must be a function")
        if self._allowed and not self._allowed[event] then
            error(("event '%s' not allowed"):format(event))
        end

        local list = self._handlers[event]
        if not list then
            list = {}
            self._handlers[event] = list
        end
        list[#list + 1] = fn

        local function off()
            local L = self._handlers[event]
            if not L then return end
            for i = #L, 1, -1 do
                if L[i] == fn then
                    table.remove(L, i)
                    break
                end
            end
            if #L == 0 then self._handlers[event] = nil end
        end
        return off
    end

    -- 一次性订阅
    function Raven:once(event, fn)
        local off
        off = self:on(event, function(...)
            off()
            fn(...)
        end)
        return off
    end

    -- 主动取消订阅
    function Raven:off(event, fn)
        local L = self._handlers[event]
        if not L then return end
        for i = #L, 1, -1 do
            if L[i] == fn then table.remove(L, i) end
        end
        if #L == 0 then self._handlers[event] = nil end
    end

    -- 派发事件
    function Raven:emit(event, ...)
        local list = self._handlers[event]
        if not list then return end
        local snapshot = {}
        for i = 1, #list do snapshot[i] = list[i] end
        for i = 1, #snapshot do
            safecall(snapshot[i], ...)
        end
    end

    -- 清空某事件或全部事件
    function Raven:clear(event)
        if event then
            self._handlers[event] = nil
        else
            self._handlers = {}
        end
    end

    -- 初始化一个全局 Raven 实例（可限制事件名）
    AUP.Raven = Raven.new({
        DATA_UPDATED = true,
    })
end
