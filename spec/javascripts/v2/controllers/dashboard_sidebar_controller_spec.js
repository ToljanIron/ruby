/*globals describe, unused, it, expect, beforeEach, angular, mock, inject, module, $controller, document, window, mockController, _ */

describe('dashboardSidebarController,', function () {
  'use strict';

  var controller, scope, module, g1, g2;
  beforeEach(function () {
    var mocked_controller = mockController('dashboardSidebarController');
    controller = mocked_controller.controller;
    scope = mocked_controller.scope;
    module = mocked_controller.module;
    // short circuit access to service VVVVVVVV
    controller.setGroups = function () {
      g1 = {
        "id": 1,
        "name": "group_1",
        "employees_ids": [1, 2, 3],
        "child_groups": [2]
      };
      g2 = {
        "id": 2,
        "name": "group_2",
        "employees_ids": [4, 5, 6, 7, 8],
        "child_groups": []
      };
      scope.groups = [g1, g2];
    };

    controller.setFormalStructure = function () {
      scope.formal_structure = [
        {
          "group_id": 1,
          "child_groups": [2]
        }, {
          "group_id": 2,
          "child_groups": null
        }, {
          "group_id": 3,
          "child_groups": null
        }];
    };
    // short circuit access to service ^^^^^^^^^

  });
  unused(module);

  it("should be a valid controller", function () {
    expect(controller).toBeDefined();
  });

  describe('setters', function () {

    it("setGroups()", function () {
      expect(scope.groups).not.toBeDefined();
      controller.setGroups();
      expect(scope.groups).toBeDefined();
    });

    it("setFormalStructure()", function () {
      expect(scope.formal_structure).not.toBeDefined();
      controller.setFormalStructure();
      expect(scope.formal_structure).toBeDefined();
    });

  });

  //tests starts here 
  describe('after init()', function () {

    beforeEach(function () {
      scope.init();
    });

    describe('init()', function () {

      it("scope.show should be defined", function () {
        expect(scope.dic).toEqual({});
      });

      it("scope.dic should be defined", function () {
        expect(scope.show).toEqual({});
      });
      it("scope.groups_names should be defined", function () {
        expect(scope.autoCompleteList).toEqual([]);
      });
    });

    describe('groups computations', function () {
      beforeEach(function () {
        controller.setGroups();
      });

      describe('addGroupNameToAutoCompleteList(group)', function () {
        it("addGroupNameToAutoCompleteList should set groups_names", function () {
          controller.addGroupNameToAutoCompleteList(g1);
          expect(scope.autoCompleteList).toEqual(["group_1"]);
          controller.addGroupNameToAutoCompleteList(g2);
          expect(scope.autoCompleteList).toEqual(["group_1", "group_2"]);
        });
      });

      describe('addGroupsToDictionary(group)', function () {
        it("addGroupsToDictionary should set map group ids to group objects", function () {
          controller.addGroupsToDictionary(g1);
          expect(scope.dic[1]).toEqual(g1);
          controller.addGroupsToDictionary(g2);
          expect(scope.dic[2]).toEqual(g2);
        });
      });

      describe('computeGroupDad(group)', function () {
        it("computeGroupDad should create pointers from group to its parent", function () {
          controller.computeGroupDad(g1);
          expect(g2.dad).toEqual(g1);
        });
      });
    });

    describe('toggleShow(id)', function () {
      var tabService = {};
      beforeEach(inject(function (_tabService_) {
        tabService  = _tabService_;
        tabService.fixHeightWhenHaveScroll = function (something) {
          unused(something);
        };
      }));

      it("should toggle show[i]", function () {
        var id = 1;
        expect(scope.show[id]).toBe(undefined);
        scope.toggleShow(id);
        expect(scope.show[id]).toBe(true);
        scope.toggleShow(id);
        expect(scope.show[id]).toBe(false);
        scope.toggleShow(id);
        expect(scope.show[id]).toBe(true);
      });
    });

    describe('collapseAll()', function () {
      it('should reset scope.show', function () {
        beforeEach(function () {
          scope.show = "some val";
          scope.collapseAll();
        });
        expect(scope.show).toEqual({});
      });
    });
  });
});
