/*globals angular, _*/

angular.module('workships.services').factory('FilterFactoryService',
  function () {
    'use strict';
    var filter_factory = {};
    filter_factory.create = function () {
      var fm = {};
      var filter = {};
      var filter_group_ids = {
        list: []
      };
      var filter_employee_ids = {
        list: []
      };

      function updateFilter(attr, range_name, val) {
        if (!filter) {
          filter = {};
        }
        if (!filter[attr]) {
          filter[attr] = {};
        }
        if (!filter[attr][range_name]) {
          filter[attr][range_name] = {};
        }
        filter[attr][range_name] = val;
        // graphService.setFilter(filter, filter_group_ids.list, filter_employee_ids.list);
      }

      function getOnlyTrueKeys(obj) {
        var res = [];
        var keys = Object.keys(obj);
        _.each(keys, function (k) {
          if (k === 'from') {
            if (obj.from !== 0 || obj.to !== 10) {
              res[0] = obj.from;
              res[1] = obj.to;
            }
          } else if (k !== 'to' && obj[k]) {
            res.push(k);
          }

        });
        return res;
      }

      fm.mockFilter = function (obj) {
        filter = obj;
      };

      fm.mockFilterGroupIds = function (arr) {
        filter_group_ids.list =  arr;
      };

      fm.removeFilterGroupIds = function () {
        filter_group_ids.list.splice(0, filter_group_ids.list.length);
        // graphService.setFilter(filter, filter_group_ids.list, filter_employee_ids.list);
      };

      fm.getFilter = function () {
        return filter;
      };

      fm.add = function (attr, range_name) {
        updateFilter(attr, range_name, true);
      };

      fm.remove = function (attr, range_name) {
        updateFilter(attr, range_name, false);
      };

      fm.getFiltered = function () {
        var res = {};
        var keys;
        var attrs = _.keys(filter);
        _.each(attrs, function (a) {
          keys = getOnlyTrueKeys(filter[a]);
          if (keys.length) {
            res[a] = keys;
          }
        });
        return res;
      };

      fm.setEmployeesNumber = function (number) {
        fm.employee_number = number;
      };

      fm.getEmployeesNumber = function () {
        return fm.employee_number;
      };

      fm.getFilterGroupIds = function () {
        return filter_group_ids.list;
      };

      fm.getFilterEmployeeIds = function () {
        return filter_employee_ids.list;
      };


      fm.init = function (attrs) {
        _.each(Object.keys(attrs), function (key) {
          _.each(attrs[key], function (range_name) {
            switch (range_name) {
            case 'from':
              updateFilter(key, range_name, 0);
              break;
            case 'to':
              updateFilter(key, range_name, 10);
              break;
            default:
              updateFilter(key, range_name, false);
            }
          });
        });
      };
      return fm;
    };
    return filter_factory;
  });
