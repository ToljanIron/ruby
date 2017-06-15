/*globals _, describe, unused , it, expect, beforeEach, angular, mock, module, $controller, document, inject, window, mockController */

describe('directoryController,', function () {
  'use strict';

  var controller, scope, module;

  beforeEach(function () {
    var mocked_controller = mockController('directoryController');
    controller = mocked_controller.controller;
    scope = mocked_controller.scope;
    module = mocked_controller.module;
  });
  unused(module);
  unused(scope);
  it("should be a valid module", function () {
    expect(controller).toBeDefined();
  });
  describe('createListToBar', function () {
    it('should get empty arr if employee empty ', function () {
      var arg = {attribute_list: null, number_of_emp: null };
      var expcted = 0;
      var res = controller.createListToBar(arg.attribute_list, arg.number_of_emp);
      expect(res.length).toBe(expcted);
    });

    it('should get 2 attribute 1 with 20% and the anhoter with 80% ', function () {
      var attribute_list = { 'male': [ 45, 55], 'female': [1, 4, 6, 8, 3, 23, 45, 55]};
      var arg = {attribute_list: attribute_list, number_of_emp: 10 };
      var expcted = [20, 80];
      var res = controller.createListToBar(arg.attribute_list, arg.number_of_emp);
      expect(res[0].size).toBe(expcted[0]);
      expect(res[1].size).toBe(expcted[1]);
    });
  });

  describe('getAttrIndex', function () {
    it('should get empty arr ([]) if attr is null ', function () {
      var emp = null;
      var arg = {attribute_list: null, emp: emp };
      var res = controller.getAttrIndex(arg.attribute_list, arg.emp);
      expect(res).toBe(undefined);
    });

    it('should get attr index 1  ', function () {
      var attribute_list = [{ employees_id: [ 45, 55]}, { employees_id: [1, 4, 6, 8, 3, 23, 45, 55]}];
      var emp = { id: 4};
      var arg = {attribute_list: attribute_list, emp: emp };
      var expcted = 1;
      var res = controller.getAttrIndex(arg.attribute_list, arg.emp);
      expect(res).toBe(expcted);
    });
  });


  describe('getPreviewsEmployee', function () {
    it('should get scope.prev_employee to be 3 when the index is 0 ', function () {
      scope.employees_list = [{id: 2}, {id: 10}, {id : 3}, {id : 5}];
      var index = 0;
      controller.getPreviewsEmployee(index);
      expect(scope.prev_employee).toBe(scope.employees_list[3]);
    });
    it('should get scope.prev_employee to be 2 when the index is 3 ', function () {
      scope.employees_list = [{id: 2}, {id: 10}, {id : 3}, {id : 5}];
      var index = 3;
      controller.getPreviewsEmployee(index);
      expect(scope.prev_employee).toBe(scope.employees_list[2]);
    });
  });

  describe('getNextEmployee', function () {
    it('should get scope.next_employee to be 0 when the index is 3 ', function () {
      scope.employees_list = [{id: 2}, {id: 10}, {id : 3}, {id : 5}];
      var index = 3;
      controller.getNextEmployee(index);
      expect(scope.next_employee).toBe(scope.employees_list[0]);
    });
    it('should get scope.next_employee to be 1 when the index is 0 ', function () {
      scope.employees_list = [{id: 2}, {id: 10}, {id : 3}, {id : 5}];
      var index = 0;
      controller.getNextEmployee(index);
      expect(scope.next_employee).toBe(scope.employees_list[1]);
    });
  });

});