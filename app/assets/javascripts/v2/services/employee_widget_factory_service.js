/*globals angular , unused */
angular.module('workships.services').factory('employeeWidgetFactoryService', function () {
  'use strict';

  var factory = {};

  var updateIndexOfDisplayListWhenNextSelected = function (emp_list, first_index, last_index, num_of_emp_to_display) {
    var new_list = {};
    if ((first_index + num_of_emp_to_display) < emp_list.length) {
      first_index += num_of_emp_to_display;
      last_index += num_of_emp_to_display;
    }
    new_list.first = first_index;
    new_list.last = last_index;
    return new_list;
  };

  var updateIndexOfDisplayListWhenBeforeSelected = function (emp_list, first_index, last_index, num_of_emp_to_display) {
    unused(emp_list);
    var new_list = {};
    if ((first_index - num_of_emp_to_display) >= 0) {
      first_index -= num_of_emp_to_display;
      if (last_index - first_index >= 10) {
        last_index -= num_of_emp_to_display;
      }
    } else {
      first_index = 0;
      last_index = 10;
    }
    new_list.first = first_index;
    new_list.last = last_index;
    return new_list;
  };

  factory.initDisplayList = function (employee_list) {
    var res = {};
    var size = Math.min(10, employee_list.length);
    res.first = 0;
    res.last = size;
    return res;
  };

  factory.getThePreviousEmployees = function (list, first_index, last_index, num_to_display) {
    var new_list = updateIndexOfDisplayListWhenBeforeSelected(list, first_index, last_index, num_to_display);
    return new_list;
  };

  factory.getTheNextEmployee = function (list, first_index, last_index, num_to_display) {
    var new_list = updateIndexOfDisplayListWhenNextSelected(list, first_index, last_index, num_to_display);
    return new_list;
  };

  factory.getTheEndEmployeesList = function (list, num_to_display) {
    var new_list = {};
    new_list.last = list.length;
    new_list.first = Math.max(list.length - num_to_display, 0);
    return new_list;
  };

  factory.getToBeginEmployeesList = function (list) {
    var new_list = {};
    var size = Math.min(10, list.length);
    new_list.first = 0;
    new_list.last = size;
    return new_list;
  };

  factory.displayTwoDigitsAfterDecimal = function (num) {
    num = parseFloat(num, 10);
    return parseFloat(Math.round(num * 100) / 100).toFixed(2);
  };

  return factory;
});
