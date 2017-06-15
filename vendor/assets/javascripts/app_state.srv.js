/*globals angular, _, window */
angular.module('state_router', []);

angular.module('state_router').factory('StateService', function ($location, $rootScope) {
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
    // $location.search(state);
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
  };

  service.view = function () {
    return _.cloneDeep(state);
  };

  // $rootScope.$on('$locationChangeStart', function () {
  //   var new_state = $location.search();
  //   if (angular.equals(state, new_state)) { return; }
  //   // TODO isValidState is always false. need to serialize validators too.
  //   // if (!service.isValidState(new_state)) { throw [JSON.stringify(new_state), "is an invalid state"].join(' '); }
  //   state = $location.search();
  // });

  return service;
});