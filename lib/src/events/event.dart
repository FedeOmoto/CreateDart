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

typedef EventListener(Event event, [Object data]);

/**
 * Contains properties and methods shared by all events for use with
 * EventDispatcher.
 * 
 * Note that Event objects are often reused, so you should never rely on an
 * event object's state outside of the call stack it was received in.
 */
class Event {
  /// The type of event.
  final String type;

  /// Indicates whether the event will bubble through the display list.
  final bool bubbles;

  /**
   * Indicates whether the default behaviour of this event can be cancelled via
   * [preventDefault]. This is set via the Event constructor.
   */
  final bool cancelable;

  EventDispatcher _target;
  EventDispatcher _currentTarget;
  int _eventPhase = 0;
  int _timeStamp;
  bool _defaultPrevented = false;
  bool _propagationStopped = false;
  bool _immediatePropagationStopped = false;
  bool _removed = false;

  /// The object that generated an event.
  EventDispatcher get target => _target;

  /**
   * The current target that a bubbling event is being dispatched from. For
   * non-bubbling events, this will always be the same as target. For example,
   * if childObj.parent = parentObj, and a bubbling event is generated from
   * childObj, then a listener on parentObj would receive the event with
   * target=childObj (the original target) and currentTarget=parentObj (where
   * the listener was added).
   */
  EventDispatcher get currentTarget => _currentTarget;

  /**
   * For bubbling events, this indicates the current event phase:
   * 
   * 1. Capture phase: starting from the top parent to the target.
   * 
   * 1. At target phase: currently being dispatched from the target.
   * 
   * 1. Bubbling phase: from the target to the top parent.
   */
  int get eventPhase => _eventPhase;

  /// The epoch time at which this event was created.
  int get timeStamp => _timeStamp;

  /// Indicates if [preventDefault] has been called on this event.
  bool get defaultPrevented => _defaultPrevented;

  /**
   * Indicates if [stopPropagation] or [stopImmediatePropagation] has been
   * called on this event.
   */
  bool get propagationStopped => _propagationStopped;

  /// Indicates if [stopImmediatePropagation] has been called on this event.
  bool get immediatePropagationStopped => _immediatePropagationStopped;

  /// Indicates if [remove] has been called on this event.
  bool get removed => _removed;

  Event(String type, [bool bubbles = false, bool cancelable = false])
      : type = type,
        bubbles = bubbles,
        cancelable = cancelable,
        _timeStamp = new DateTime.now().millisecondsSinceEpoch;

  /// Sets [defaultPrevented] to true. Mirrors the DOM event standard.
  void preventDefault() {
    _defaultPrevented = true;
  }

  /// Sets [propagationStopped] to true. Mirrors the DOM event standard.
  void stopPropagation() {
    _propagationStopped = true;
  }

  /**
   * Sets [propagationStopped] and [immediatePropagationStopped] to true.
   * Mirrors the DOM event standard.
   */
  void stopImmediatePropagation() {
    _immediatePropagationStopped = _propagationStopped = true;
  }

  /**
   * Causes the active listener to be removed via
   * [EventDispatcher.removeEventListener];
   * 
   *              myBtn.addEventListener("click", function(evt) {
   *                      // do stuff...
   *                      evt.remove(); // removes this listener.
   *              });
   */
  void remove() {
    _removed = true;
  }

  /// Returns a clone of the Event instance.
  Event clone() {
    return new Event(type, bubbles, cancelable);
  }

  /**
   * Provides a chainable shortcut method for setting a number of properties on
   * the instance.
   */
  Event set() {
    // TODO
    return this;
  }

  /// Returns a string representation of this object.
  @override
  String toString() => '[${runtimeType.toString()} (type=$type)]';
}
