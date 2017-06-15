/*globals _, StateService, unused, $provide, describe, it, expect, beforeEach, angular, mock, module, inject, unused, spyOn */
describe('tabService,', function () {
  'use strict';

  beforeEach(angular.mock.module('workships.services'));

  beforeEach(module(function ($provide) {
    var StateService = {};
    StateService.defineState = function (something) {
      unused(something);
    };
    StateService.set = function (something) {
      unused(something);
    };
    StateService.get = function () {
      return 1;
    };
    $provide.value("StateService", StateService);
  }));

  var tabService, StateService;

    beforeEach(inject(function (_tabService_, _StateService_) {
      tabService   = _tabService_;
      StateService = _StateService_;
    }));

  describe('', function () {
    beforeEach(function () {
      StateService.set = function (something) {
        unused(something);
      };
      StateService.get = function (something) {
        unused(something);
        return 1;
      };
    });

    describe('functionality', function () {
      it('should be defined', function () {
        expect(tabService).toBeDefined();
      });
    });

    describe('initOnlySelect()', function () {
      it('should change selected to false for all groups', function () {
        var groups = [{ id: 1}, { id: 2}, { id: 3}];
        tabService.initOnlySelect(groups);
        _.each(groups, function (grp) {
          expect(grp.selected).toBe(false);
        });
      });

      it('should change selected to false for all groups', function () {
        var groups = [{ id: 1}, { id: 2}, { id: 3}];
        tabService.initOnlySelect(groups);
        _.each(groups, function (grp) {
          expect(grp.selected).toBe(false);
        });
      });

    });

    describe('keepSelections()', function () {
      it('should change parent group to select', function () {
        var groups;
        beforeEach(function () {
          tabService.init();
          tabService.selectTab('Dashboard');
          groups = [{id: 1, parent: null, selected: false}, {id: 2, parent: 1, selected: true}];
          tabService.keepSelections(groups);
        });
        groups = [{id: 1, parent: null, selected: false}, {id: 2, parent: 1, selected: true}];
        tabService.keepSelections(groups);
        expect(groups[0].selected).toEqual(true);
      });
    });

    describe('keepStates', function () {

      it('should keep state when current tab is dashboard', function () {
        var group_id = 10;
        tabService.init();
        tabService.selectTab('Dashboard');
        tabService.keepStates('_selected', group_id);
      });
    });

    describe('changeTab(),', function () {

      // tabService.changeTab(oldTabCount, screen_size_width, leftSeenTab);
      it('Screen width increased to maximum', function () {
        var res = tabService.changeTab(3, 1000, 0);
        expect(res.leftSeenTab).toBe(0);
        expect(res.rightSeenTab).toBe(6);
        expect(res.currTabCount).toBe(8);
      });

      it('Screen width increased to maximum and left tab should be set to 0', function () {
        var res = tabService.changeTab(3, 1000, 3);
        expect(res.leftSeenTab).toBe(0);
      });

      it('Screen width increased not to maximum width', function () {
        var res = tabService.changeTab(3, 710, 1);
        expect(res.leftSeenTab).toBe(1);
        expect(res.rightSeenTab).toBe(4);
        expect(res.currTabCount).toBe(4);
      });

      it('Screen width increased not to maximum width and right tab already set to 7', function () {
        var res = tabService.changeTab(3, 710, 5);
        expect(res.leftSeenTab).toBe(3);
        expect(res.rightSeenTab).toBe(6);
        expect(res.currTabCount).toBe(4);
      });

      it('Nothing changed', function () {
        var res = tabService.changeTab(3, 600, 5);
        expect(res.leftSeenTab).toBe(5);
        expect(res.rightSeenTab).toBe(7);
        expect(res.currTabCount).toBe(3);
      });

      it('Screen width decreased', function () {
        var res = tabService.changeTab(5, 600, 2);
        expect(res.leftSeenTab).toBe(2);
        expect(res.rightSeenTab).toBe(4);
        expect(res.currTabCount).toBe(3);
      });

      it('Screen width decreased and right tab was at maximum', function () {
        var res = tabService.changeTab(5, 600, 3);
        expect(res.leftSeenTab).toBe(3);
        expect(res.rightSeenTab).toBe(5);
        expect(res.currTabCount).toBe(3);
      });

    });
  });

  describe('selectTab', function () {
    beforeEach(function () {
      StateService.set = function (obj) {
        StateService[obj.name] = obj.value;
      };
      StateService.get = function (name) {
        return StateService[name];
      };
      StateService.set({name: 'selected_tab', value: 'Dashboard'});
    });
    it('should call saveTabState with previous tab name', function () {
      spyOn(tabService, 'saveTabState');
      tabService.selectTab('Explore');
      expect(tabService.saveTabState).toHaveBeenCalledWith('Dashboard');
    });
    it('should call loadTabState with new tab name', inject(function ($timeout) {
      spyOn(tabService, 'loadTabState');
      tabService.selectTab('Explore');
      $timeout.flush();
      expect(tabService.loadTabState).toHaveBeenCalledWith('Explore');
    }));
  });
  describe('saveTabState', function () {
    beforeEach(function () {
      spyOn(StateService, 'set');
    });
    it('should save scrollHeight for tab', function () {
      tabService.saveTabState('Dashboard');
      expect(StateService.set).toHaveBeenCalledWith({ name: 'Dashboard_scrollTop', value: 0 });
    });
    it('should save subTab for tab', function () {
      tabService.subTabs.Collaboration = 10;
      tabService.saveTabState('Collaboration');
      expect(StateService.set).toHaveBeenCalledWith({ name: 'Collaboration_subTab', value: 10 });
    });
  });

  describe('loadTabState', function () {
    beforeEach(function () {
      StateService.set = function (obj) {
        StateService[obj.name] = obj.value;
      };
      StateService.get = function (name) {
        return StateService[name];
      };
      StateService['Workflow_scrollTop'] = 100;
      StateService['Workflow_subTab'] = 11;
      spyOn(tabService, 'setSubTab');
    });
    it('should call setSubTab with saved subtab', function () {
      tabService.loadTabState('Workflow');
      expect(tabService.setSubTab).toHaveBeenCalledWith('Workflow', 11);
    });
  });

  unused(StateService);
});
