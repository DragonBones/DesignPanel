var events;
(function (events) 
{

    
    var Event = (function () 
    {
        function Event(type, data) 
        {
            this.target = null;
            this.type = type;
            this.data = data;
        }
        return Event;
    })();
    events.Event = Event;


    var EventDispatcher = (function () 
    {
        function EventDispatcher() 
        {
        }

        EventDispatcher.prototype.hasEventListener = function (type) 
        {
            assert(type);

            if (this._listenersMap && this._listenersMap[type]) 
            {
                return true;
            }
            return false;
        };

        EventDispatcher.prototype.addEventListener = function (type, listener) 
        {
            assert(type && typeof listener === "function");

            if (!this._listenersMap) 
            {
                this._listenersMap = {};
            }

            var listeners = this._listenersMap[type];

            if (listeners) 
            {
                this.removeEventListener(type, listener);
            }

            if (listeners) 
            {
                listeners.push(listener);
            } 
            else 
            {
                this._listenersMap[type] = [listener];
            }
        };

        EventDispatcher.prototype.removeEventListener = function (type, listener) 
        {
            assert(type && typeof listener === "function");

            var listeners = this._listenersMap[type];
            if (listeners) 
            {
                for (var i = 0, l = listeners.length; i < l; i++) 
                {
                    if (listeners[i] == listener) 
                    {
                        if (l == 1) 
                        {
                            listeners.length = 0;
                            delete this._listenersMap[type];
                        } 
                        else 
                        {
                            listeners.splice(i, 1);
                        }
                    }
                }
            }
        };

        EventDispatcher.prototype.removeAllEventListeners = function (type) 
        {
            if (type) 
            {
                delete this._listenersMap[type];
            } 
            else 
            {
                this._listenersMap = null;
            }
        };

        EventDispatcher.prototype.dispatchEvent = function (event) 
        {
            assert(event);
            
            if (this._listenersMap)
            {
                var listeners = this._listenersMap[event.type];
                if (listeners) 
                {
                    event.target = this;
                    var listenersCopy = listeners.concat();
                    for (var i = 0, l = listenersCopy.length; i < l; i++) 
                    {
                        listenersCopy[i](event);
                    }
                }
            }
        };
        return EventDispatcher;
    })();
    events.EventDispatcher = EventDispatcher;

}
)(events || (events = {}));