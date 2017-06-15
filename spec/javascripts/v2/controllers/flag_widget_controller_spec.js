/*globals _, describe, it , unused ,expect, beforeEach, angular, mock, module, $controller, document, window, mockController */
describe('flagsWidgetController,', function () {
  'use strict';

  var controller, scope, module;

  beforeEach(function () {
    var mocked_controller = mockController('flagsWidgetController');
    controller = mocked_controller.controller;
    scope = mocked_controller.scope;
    module = mocked_controller.module;

  });
  unused(module);

  it("should be a valid module", function () {
    expect(controller).toBeDefined();
  });

  describe('addSubGroupFlag', function () {
    it('should get undefined if type  is overall ', function () {
      var args = [{ g_id: 1, type: 'overall'}];
      var expcted = [undefined];
      var res;
      _.each(args, function (arg, i) {
        res = scope.addSubGroupFlag(arg.g_id, arg.type);
        expect(res).toBe(expcted[i]);
      });
    });
  });

  describe('getIndexOfCurrentGroupSelected', function () {
    it('should get index 0 if breadcrumbs empty ', function () {
      var id = [0, 1, 2, 3];
      var args = [{bread_crumbs: []}, {bread_crumbs: [{id : 1 }]}, {bread_crumbs: [{id : 1 }, {id : 2}]}, {bread_crumbs: [{id : 1 }, {id : 2}, {id : 3}]} ];
      var expcted = [undefined, 0, 1, 2];
      var res;
      _.each(args, function (arg, i) {
        scope.selected = {id: id[i] };
        res = controller.getIndexOfCurrentGroupSelected(arg.bread_crumbs);
        expect(res).toBe(expcted[i]);
      });
    });
  });

  describe('removeSubGroup', function () {
    it('should get undefined if type  is overall ', function () {
      scope.selected = { id : 1 };
      var g_id = 1;
      var expcted = false;
      scope.removeSubGroup(g_id);
      expect(scope.show_bredcrumbs).toBe(expcted);
    });
  });

});