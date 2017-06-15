/*globals describe, it, expect, beforeEach, angular, mock, module, inject, unused */

describe('employeeWidgetFactoryService,', function () {
  'use strict';

  var service, res;

  var employee_list = ['a', 'b', 'c', 'd', 5, 4, 5, 4];
  var num_to_display, first_index, last_index, display_list;

  /*var fillSharedSpecData = function (data_obj) {
    var i;
    var values = [];
    for (i = 0; i < delta_titles.length; i++) {
      values[i] = [delta_titles[i], delta_org_vals[i], delta_in_vals[i]];
    }
    data_obj.values = values;
  };
*/
  beforeEach(angular.mock.module('workships.services'));

  beforeEach(inject(function (employeeWidgetFactoryService) {
    service = employeeWidgetFactoryService;
  }));

  describe('functionality', function () {
    it('should be defined', function () {
      expect(service).toBeDefined();
      expect(service.initDisplayList).toBeDefined();
    });
  });

  describe('initDisplayList', function () {

    it('should return last = 8 in current input ', function () {
      res = service.initDisplayList(employee_list);
      expect(res.last).toBe(8);
    });

    it('should return first_index = 0  when init the list', function () {
      res = service.initDisplayList(employee_list);
      expect(res.first).toBe(0);
    });

    it('should return display_list = employee_list when init and size < 10 ', function () {
      res = service.initDisplayList(employee_list);
      expect(res).toEqual({first: 0, last: 8});
    });

    it('should return display_list != employee_list when init and size >10 ', function () {
      employee_list = ['1', 2, 3, 4, 5, 6, 7, 8, 23, 45, 67, 45, 'g', 'h'];
      res = service.initDisplayList(employee_list);
      expect(res).toEqual({first: 0, last: 10});
    });

  });

  describe('getThePreviousEmployees', function () {
    beforeEach(function () {
      employee_list = ['1', 2, 3, 4, 5, 6, 7, 8, 23, 45, 67, 45, 'g', 'h'];
      first_index = 8;
      last_index = 14;
      num_to_display = 5;
      display_list = null;
    });
    it('should return list with the first employee is num 3', function () {
      res = service.getThePreviousEmployees(display_list, employee_list, first_index, last_index, num_to_display);
      expect(res.first).toBe(0);
    });

    it('should return list with 10  employee', function () {
      employee_list = ['1', 2, 3, 4, 5, 6, 7, 8];
      first_index = 2;
      last_index = 8;
      res = service.getThePreviousEmployees(display_list, employee_list, first_index, last_index, num_to_display);
      expect(res.last).toBe(10);
    });
  });

  describe('getTheEndEmployeesList', function () {
    beforeEach(function () {
      employee_list = ['1', 2, 3, 4, 5, 6, 7, 8, 23, 45, 67, 45, 'g', 'h'];
      num_to_display = 5;
    });
    it('should return list with the last number is 14 ', function () {
      res = service.getTheEndEmployeesList(employee_list, num_to_display);
      expect(res.last).toBe(14);
    });

    it('should return list with 5 employee', function () {
      employee_list = ['1', 2, 3, 4, 5, 6, 7, 8];
      res = service.getTheEndEmployeesList(employee_list, num_to_display);
      expect(res).toEqual({first: 3, last: 8});
    });
  });

  describe('getToBeginEmployeesList', function () {
    var list;
    beforeEach(function () {
      list = ['1', 2, 3, 4, 5, 6, 7, 8, 23, 45, 67, 45, 'g', 'h'];
    });
    it('', function () {
      res = service.getToBeginEmployeesList(list);
      expect(res).toEqual({first: 0, last: 10});
    });

  });
});
