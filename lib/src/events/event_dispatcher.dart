// Copyright 2014 Federico Omoto
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

part of create_dart;

typedef EventListener(Event event, [dynamic data]);

/**
 * EventDispatcher provides methods for managing queues of event listeners and
 * dispatching events.
 *
 * You can either extend EventDispatcher or mix its methods into an existing
 * prototype or instance by using the EventDispatcher initialize method.
 * 
 * Together with the CreateJS Event class, EventDispatcher provides an extended
 * event model that is based on the DOM Level 2 event model, including
 * addEventListener, removeEventListener, and dispatchEvent. It supports
 * bubbling / capture, preventDefault, stopPropagation,
 * stopImmediatePropagation, and handleEvent.
 * 
 * EventDispatcher also exposes a on method, which makes it easier to create
 * scoped listeners, listeners that only run once, and listeners with associated
 * arbitrary data. The off method is merely an alias to removeEventListener.
 * 
 * Another addition to the DOM Level 2 model is the removeAllEventListeners
 * method, which can be used to listeners for all events, or listeners for a
 * specific event. The Event object also includes a remove method which removes
 * the active listener.
 *
 * ##Example
 * Add EventDispatcher capabilities to the "MyClass" class.
 *
 *      EventDispatcher.initialize(MyClass.prototype);
 *
 * Add an event (see addEventListener).
 *
 *      instance.addEventListener("eventName", handlerMethod);
 *      function handlerMethod(event) {
 *          console.log(event.target + " Was Clicked");
 *      }
 *
 * **Maintaining proper scope**
 * 
 * Scope (ie. "this") can be be a challenge with events. Using the on method to
 * subscribe to events simplifies this.
 *
 *      instance.addEventListener("click", function(event) {
 *          console.log(instance == this); // false, scope is ambiguous.
 *      });
 *      
 *      instance.on("click", function(event) {
 *          console.log(instance == this); // true, "on" uses dispatcher scope
 *                                         // by default.
 *      });
 * 
 * If you want to use addEventListener instead, you may want to use
 * function.bind() or a similar proxy to manage scope.
 */
class EventDispatcher {
  Map<String, Set<EventListener>> _listeners;
  Map<String, Set<EventListener>> _captureListeners;
  EventDispatcher _parent;

  EventDispatcher() {
    _listeners = new Map<String, Set<EventListener>>();
    _captureListeners = new Map<String, Set<EventListener>>();
  }

  /**
   * Adds the specified event listener. Note that adding multiple listeners to
   * the same function will result in multiple callbacks getting fired.
   *
   * ##Example
   *
   *      displayObject.addEventListener("click", handleClick);
   *      function handleClick(event) {
   *         // Click happened.
   *      }
   */
  EventListener addEventListener(String type, EventListener listener, [bool
      useCapture = false]) {
    Map<String, Set<EventListener>> listeners;
    listeners = useCapture ? _captureListeners : _listeners;

    if (listeners[type] == null) listeners[type] = new Set<EventListener>();

    listeners[type].add(listener);

    return listener;
  }

  /**
   * A shortcut method for using addEventListener that makes it easier to
   * specify an execution scope, have a listener only run once, associate
   * arbitrary data with the listener, and remove the listener.
   * 
   * This method works by creating an anonymous wrapper function and subscribing
   * it with addEventListener.
   * The created anonymous function is returned for use with
   * .removeEventListener (or .off).
   * 
   * ##Example
   * 
   *              var listener = myBtn.on("click", handleClick, null, false,
   *                  {count:3});
   *              function handleClick(evt, data) {
   *                      data.count -= 1;
   *                      console.log(this == myBtn); // true - scope defaults
   *                                                  // to the dispatcher
   *                      if (data.count == 0) {
   *                              alert("clicked 3 times!");
   *                              myBtn.off("click", listener);
   *                              // alternately: evt.remove();
   *                      }
   *              }
   */
  EventListener on(String type, EventListener listener, [bool once =
      false, Object data, bool useCapture = false]) {
    return addEventListener(type, (Event event, [Object data]) {
      listener(event, data);
      if (once) event.remove();
    }, useCapture);
  }

  /**
   * Removes the specified event listener.
   *
   * **Important Note:** that you must pass the exact function reference used
   * when the event was added. If a proxy function, or function closure is used
   * as the callback, the proxy/closure reference must be used - a new proxy or
   * closure will not work.
   *
   * ##Example
   *
   *      displayObject.removeEventListener("click", handleClick);
   */
  void removeEventListener(String type, EventListener listener, [bool useCapture
      = false]) {
    Map<String, Set<EventListener>> listeners;
    listeners = useCapture ? _captureListeners : _listeners;

    if (listeners[type] == null) return;

    Set<EventListener> set = listeners[type];

    if (set.contains(listener)) {
      if (set.length == 1) {
        listeners.remove(type);
      } else {
        set.remove(listener);
      }
    }
  }

  /**
   * A shortcut to the removeEventListener method, with the same parameters and
   * return value. This is a companion to the .on method.
   */
  void off(String type, EventListener listener, [bool useCapture = false]) {
    removeEventListener(type, listener, useCapture);
  }

  /**
   * Removes all listeners for the specified type, or all listeners of all types.
   *
   * ##Example
   *
   *      // Remove all listeners
   *      displayObject.removeAllEventListeners();
   *
   *      // Remove all click listeners
   *      displayObject.removeAllEventListeners("click");
   */
  void removeAllEventListeners([String type]) {
    if (type == null) {
      _listeners.clear();
      _captureListeners.clear();
    } else {
      _listeners.remove(type);
      _captureListeners.remove(type);
    }
  }

  /**
   * Dispatches the specified event to all listeners.
   *
   * ##Example
   *
   *      // Use a string event
   *      this.dispatchEvent("complete");
   *
   *      // Use an Event instance
   *      var event = new createjs.Event("progress");
   *      this.dispatchEvent(event);
   */
  bool dispatchEvent(Event event, [EventDispatcher target]) {
    // TODO: deprecated. Target param is deprecated, only use case is
    // MouseEvent/mousemove, remove.
    event._target = target == null ? this : target;

    if (!event.bubbles || _parent == null) {
      _dispatchEvent(event, 2);
    } else {
      EventDispatcher top = this;
      List<EventDispatcher> list = [top];

      while (top._parent != null) list.add(top = top._parent);

      // capture & atTarget
      for (int i = list.length - 1; i >= 0 && !event.propagationStopped; i--) {
        list[i]._dispatchEvent(event, 1 + (i == 0 ? 1 : 0));
      }

      // bubbling
      for (int i = 1; i < list.length && !event.propagationStopped; i++) {
        list[i]._dispatchEvent(event, 3);
      }
    }

    return event.defaultPrevented;
  }

  /**
   * Indicates whether there is at least one listener for the specified event
   * type.
   */
  bool hasEventListener(String type) => !!((_listeners.isNotEmpty &&
      _listeners[type] != null) || (_captureListeners.isNotEmpty &&
      _captureListeners[type] != null));

  /**
   * Indicates whether there is at least one listener for the specified event
   * type on this object or any of its ancestors (parent, parent's parent, etc).
   * A return value of true indicates that if a bubbling event of the specified
   * type is dispatched from this object, it will trigger at least one listener.
   * 
   * This is similar to [hasEventListener], but it searches the entire event
   * flow for a listener, not just this object.
   */
  bool willTrigger(String type) {
    EventDispatcher object = this;

    while (object != null) {
      if (object.hasEventListener(type)) return true;
      object = object._parent;
    }

    return false;
  }

  /// Returns a string representation of this object.
  @override
  String toString() => '[${runtimeType}]';

  void _dispatchEvent(Event event, int eventPhase) {
    Map<String, Set<EventListener>> listeners = eventPhase == 1 ?
        _captureListeners : _listeners;

    if (listeners.isEmpty || listeners[event.type] == null) return;

    List<EventListener> list = new List<EventListener>.from(
        listeners[event.type]);

    event._currentTarget = this;
    event._eventPhase = eventPhase;
    event._removed = false;

    // to avoid issues with items being removed or added during the dispatch
    for (int i = 0; i < list.length && !event.immediatePropagationStopped; i++)
        {
      EventListener listener = list[i];

      listener(event);

      if (event._removed) {
        off(event.type, listener, eventPhase == 1);
        event._removed = false;
      }
    }
  }
}
