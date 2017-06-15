/*globals angular, _, window */
angular.module('StateRouter', []);

/******************** StateKeeper ************************/

angular.module('StateRouter').factory('StateKeeper', function () {
  'use strict';
  var service = {};
  var SAVED_STATES = {};
  var VALID_VAR_RGX = /[a-zA-Z_][a-zA-Z0-9_]*/;

  if (window.karma_running) {
    service.SAVED_STATES = SAVED_STATES;
  }

  service.save = function (key, state) {
    if (!VALID_VAR_RGX.test(key)) { throw ["Cannot save state for by name", key].join(' '); }
    SAVED_STATES[key] = _.cloneDeep(state);
  };

  service.load = function (key) {
    if (!VALID_VAR_RGX.test(key)) { throw ["Cannot load by name", key].join(' '); }
    return _.cloneDeep(SAVED_STATES[key]);
  };

  return service;
});

/******************** RouterService ************************/

angular.module('StateRouter').factory('RouterService', function ($location) {
  'use strict';
  var service = {};

  service.setRoute = function (state) {
    $location.search(state);
  };

  service.getRoute = function () {
    return $location.search();
  };

  return service;
});

/******************** StateService ************************/

angular.module('StateRouter').factory('StateService', function ($rootScope, StateKeeper, RouterService) {
  'use strict';

  var state = {};
  var service = {};
  var VALIDATORS = {};
  var VALID_VAR_RGX = /[a-zA-Z_][a-zA-Z0-9_]*/;

  if (window.karma_running) {
    service.mockState = function (new_state) {
      state = new_state;
    };
    service.VALIDATORS = VALIDATORS;
  }

  function T() { return true; }

  function invalid_def(def) {
    if (!def) { return true; }
    if (!def.name) { return true; }
    if (!VALID_VAR_RGX.test(def.name)) { return true; }
    return false;
  }

  function valid_validator(v) {
    return typeof v === "function";
  }

  function already_defined(key) {
    return _.includes(_.keys(state), key);
  }

  function merge(obj, change_set) {
    var keys = Object.keys(change_set);
    keys.forEach(function (k) {
      if (typeof change_set[k] === 'object') {
        merge(obj[k], change_set[k]);
      } else {
        obj[k] = change_set[k];
      }
    });
  }

  $rootScope.$on('$locationChangeStart', function () {
    var new_state = RouterService.getRoute();
    if (angular.equals(state, new_state)) { return; }
    if (!service.isValidState(new_state)) { throw [JSON.stringify(new_state), "is an invalid state"].join(' '); }
    state = new_state;
  });

  service.defineState = function (def) {
    if (invalid_def(def)) {throw [JSON.stringify(def), "is an invalid state definition"].join(' '); }
    if (already_defined(def.name)) {throw [def.name, "was already defined"].join(' '); }
    if (def.validator && !valid_validator(def.validator)) {throw [JSON.stringify(def), "Invalid validator"].join(' '); }
    VALIDATORS[def.name] = def.validator || T;
    state[def.name] = undefined;
  };

  service.isValidState = function (s) {
    var validators_results = _.map(_.keys(s), function (k) {
      if (!VALIDATORS[k]) { return false; }
      return VALIDATORS[k](s[k]);
    });
    return _.isEqual(_.uniq(validators_results), [true]);
  };

  service.set = function (key_and_value) {
    var key = key_and_value.name;
    var val = key_and_value.value;
    if (!VALIDATORS[key](val)) {throw [JSON.stringify(val), "is an invalid value for", key].join(' '); }
    state[key] =  val;
    RouterService.setRoute(state);
  };

  service.get = function (key) {
    return _.cloneDeep(state[key]);
  };

  service.change = function (change_set) {
    var new_state = _.cloneDeep(state);
    merge(new_state, change_set);
    if (!service.isValidState(new_state)) {
      throw [JSON.stringify(change_set), "led to invalid state"].join(' ');
    }
    state = new_state;
    RouterService.setRoute(state);
  };

  service.view = function () {
    return _.cloneDeep(state);
  };

  service.save = function (key) {
    StateKeeper.save(key, state);
  };

  service.load = function (key) {
    var loaded_stated = StateKeeper.load(key);
    if (!service.isValidState(loaded_stated)) {
      throw [key, "has loaded an invalid state", JSON.stringify(loaded_stated)].join(' ');
    }
    state = loaded_stated;
    RouterService.setRoute(state);
  };

  return service;
});