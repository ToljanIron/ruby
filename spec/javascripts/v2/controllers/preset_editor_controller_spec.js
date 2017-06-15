/*globals _, describe, it , unused ,expect, beforeEach, inject, angular, mock, module, $controller, document, window, mockController */
describe('presetEditorController,', function () {
  'use strict';

  var controller, scope, module;
  beforeEach(function () {
    var mocked_controller = mockController('presetEditorController');
    controller = mocked_controller.controller;
    scope = mocked_controller.scope;
    module = mocked_controller.module;
  });
  unused(module);

  it("should be a valid module", function () {
    expect(controller).toBeDefined();
  });

  describe('init()', function () {
    it('should init  ', function () {
      scope.init();
      expect(scope.available_opers).toEqual(['in', 'not in']);
    });
    it('should create the string to view from the conditions', function () {
      var cond = { param: 'rank_2', vals: [5, 7]};
      var cond2 = { param: 'age_group', vals: ['25-34', '12-24']};
      var cond3 = { param: 'gender', vals: ['male', 'female']};
      var cretria = scope.getFilterName(cond);
      expect(cretria).toEqual('Rank (5,7)');
      cretria = scope.getFilterName(cond2);
      expect(cretria).toEqual('Age (25-34,12-24)');
      expect(scope.getFilterName(cond3)).toEqual('gender (male,female)');
    });
  });

});