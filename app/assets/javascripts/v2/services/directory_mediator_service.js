/*globals angular*/
angular.module('workships.services').factory('directoryMediator', function (FilterFactoryService) {
  'use strict';
  var selected = {};
  var first_time = true;
  var filter_init = false;
  selected.filter = FilterFactoryService.create();
  selected.init = function (id) {
    selected.type = 'group';
    selected.id = id;
    selected.selected_tab = 1;
    selected.view_in_list = false;
    first_time = false;

  };
  selected.setSelected = function (id, type) {
    selected.type = type;
    selected.id = id;
  };
  selected.setEmplyeeId = function (id) {
    selected.show_employee_card = true;
    selected.employee_id = id;
  };

  selected.inFirstTime = function () {
    return first_time;
  };

  selected.isFilterInit = function () {
    return filter_init;
  };

  selected.initFilter = function () {
    filter_init = true;
  };

  selected.setGroupByIndex = function (index) {
    selected.group_by_index = index;
  };
  selected.getGroupByIndex = function () {
    return selected.group_by_index;
  };
  selected.getMeasureByIndex = function () {
    return selected.measure_by_index;
  };
  selected.setMeasureByIndex = function (index) {
    selected.measure_by_index = index;
  };
  selected.is_group_toogle_on = {
    'is': false,
    'exist': true,
    'previous_state': -1,
    'on': false
  };
  selected.selected_tab_new = null;
  return selected;
});
