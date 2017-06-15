/*globals describe, unused , it, expect, beforeEach, angular, mock, module, $controller, document, window, mockController, spyOn, _ */

describe('pinEditorController', function () {
  'use strict';

  var controller, scope;

  beforeEach(function () {
    var mocked_controller = mockController('PinEditorController');
    controller = mocked_controller.controller;
    scope = mocked_controller.scope;
    scope.pins = [{name: "pin1", company_id: 1, definition: {employees: ["a@b.com", "b@c.com"], conditions: [{param: "qualifications", oper: "not in", vals: [1, 3, 4]},
      {param: "position", oper: "not in", vals: [8, 11, 14]}]}}];
    scope.available_opers = ['in', 'not in'];
    scope.selected = -1;
    scope.available_filters = {"position": [{name: "manager",  value: 1}, {name: "CEO",  value: 2}], "location": [{name: "haifa",  value: 4}, {name: "telaviv",  value: 2}] };
    scope.employees = [{"email": "a@b.com"}, {"email": "gil@bli.com"}, {"email": "gil@asa.com"}, {"email": "gil@sds.com"}];
  });
  it("should be a valid controller", function () {
    expect(controller).toBeDefined();
  });

  describe('left sidebar behavior', function () {

    it("sets clicked pin to selected", function () {
      scope.onClickPinTitle(scope.pins[0]);
      expect(JSON.stringify(scope.pins[0])).toEqual(JSON.stringify(scope.selected));
    });


  });
  describe('helper functions', function () {

    beforeEach(function () {
      scope.selected = scope.pins[0];
    });
    it("does a pin contain an employee", function () {

      expect(scope.doesPinContainEmployee(scope.selected, scope.employees[0])).toEqual(true);
      expect(scope.doesPinContainEmployee(scope.selected,  scope.employees[1])).toEqual(false);
    });

  });
  describe('deleting and adding conds', function () {

    beforeEach(function () {
      scope.selected = scope.pins[0];

    });
    it("deletes a cond from a pin that has conds", function () {
      var condToDelete = scope.selected.definition.conditions[0];
      var sizeBeforeDelete = scope.selected.definition.conditions.length;
      scope.onClickDelFilter(scope.selected, condToDelete);
      var sizeAfterDelete = scope.selected.definition.conditions.length;
      expect(sizeBeforeDelete).not.toEqual(sizeAfterDelete);
    });

  });

  describe('deleting and adding employees', function () {
    beforeEach(function () {
      scope.selected = scope.pins[0];
    });
    it("deletes an employee that exists in pin ", function () {
      var sizeBeforeDelete = scope.selected.definition.employees.length;
      scope.onClickPinEmployee(scope.selected, scope.employees[0]);
      var sizeAfterDelete = scope.selected.definition.employees.length;
      expect(sizeBeforeDelete).not.toEqual(sizeAfterDelete);
    });
    it("adds an employee that dosn't exist in pin ", function () {
      var sizeBeforeDelete = scope.selected.definition.employees.length;
      scope.onClickPinEmployee(scope.selected, scope.employees[2]);
      var sizeAfterDelete = scope.selected.definition.employees.length;
      expect(sizeBeforeDelete).not.toEqual(sizeAfterDelete);
    });
  });
});