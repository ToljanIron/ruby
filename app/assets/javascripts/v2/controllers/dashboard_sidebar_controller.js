/*globals angular, unused, _ */
angular.module('workships').controller('dashboardSidebarController',
  function ($scope, overlayBlockerService, dataModelService, dashboradMediator, StateService, tabService, OrgLeftPanelUtilService, pleaseWaitService) {
  'use strict';

  /************************ PRIVATE ************************/
  var self = this;
  var STRUCTURE = 'formal_structure';
  /* istanbul ignore next */

  self.processGroups = function () {
    _.each($scope.groups, function (g) {
      self.addGroupNameToAutoCompleteList(g);
      self.addGroupsToDictionary(g);
      self.computeGroupDad(g);
    });
  };

  self.addGroupNameToAutoCompleteList = function (g) {
    $scope.autoCompleteList.push(g.name);
  };

  self.addGroupsToDictionary = function (g) {
    $scope.dic[g.id] = g;
  };

  self.computeGroupDad = function (g) {
    _.each(g.child_groups, function (child_id) {
      var child = _.find($scope.groups, function (g2) {
        return g2.id === child_id;
      });
      if (child_id) {
        child.dad = g;
      } else {
        unused();
      }
    });
  };

  self.expandGroupWidgetByBreadCrumbs = function () {
    var bc = $scope.data_model.getBreadCrumbs($scope.selected.id, $scope.selected.type);
    _.each(bc, function (b) {
      $scope.show[b.id] = true;
    });
  };

  /************************ PUBLIC ************************/
  $scope.set_color = function (g_id) {
    var color = $scope.data_model.getColorsByName(STRUCTURE, g_id) || '8dc0c5';
    return { 'fill': '#' + color };
  };
  $scope.collapseAll = function () {
    $scope.show = {};
  };

  $scope.toggleShow = function (group_id) {
    $scope.show[group_id] = !$scope.show[group_id];
    tabService.saveOpenGroups($scope.groups, $scope.show);
  };

  function updateData(rest) {
    pleaseWaitService.on();
    $scope.data_model.getMeasures($scope.selected.id, -1, rest);
    $scope.data_model.getFlags($scope.selected.id, -1, rest);
  }

  $scope.selectGroup = function (group_id) {
    // handle_wordcloud
    if (tabService.current_tab === 'Explore') { return; }
    $scope.selected.setSelected(group_id, 'group');
    self.expandGroupWidgetByBreadCrumbs();
    tabService.keepStates('_selected', group_id);
    tabService.keepSelections($scope.groups);
    tabService.saveOpenGroups($scope.groups, $scope.show);
    updateData(true);
  };

  $scope.onSelect = function (search_node) {
    if (search_node.type === 'group') {
      $scope.selectGroup(search_node.id);
    } else {
      $scope.selectPin(search_node.id);
    }
  };

  $scope.selectPin = function (pin_id) {
    $scope.show_pins = true;
    $scope.show_active_pins = true;
    $scope.selected.setSelected(pin_id, 'pin');
  };


  $scope.toggleShowFormalStructure = function () {
    $scope.show_formal_structure = !$scope.show_formal_structure;
    if (tabService.current_tab !== 'Explore' && tabService.current_tab !== 'Dashboard') {
      $scope.show_formal_structure_not_Explore = !$scope.show_formal_structure_not_Explore;
      $scope.show_formal_structure = $scope.show_formal_structure_not_Explore;
    }
    tabService.keepStates('_structure_open', $scope.show_formal_structure);
    if ($scope.arrow_img === '/assets/minimize.png') {
      $scope.arrow_img = '/assets/expand.png';
    } else {
      if ($scope.arrow_img === '/assets/expand.png') {
        $scope.arrow_img = '/assets/minimize.png';
      }
    }
  };

  $scope.toggleShowPins = function () {
    $scope.show_pins = !$scope.show_pins;
  };

  $scope.toggleShowActivePins = function () {
    $scope.show_active_pins = !$scope.show_active_pins;
  };

  var createDisplayForStrcture = function (parent) {
    if (tabService.current_tab && $scope.startStructure === false) {
      StateService.set({name: tabService.current_tab + '_structure_open', value:  $scope.show_formal_structure });
      $scope.startStructure = true;
    }
    $scope.show_formal_structure = true;
    if (StateService.get(tabService.current_tab + '_structure_open')) {
      $scope.show_formal_structure = StateService.get(tabService.current_tab + '_structure_open');
    }
    tabService.initDisplayForOrgStructure($scope.groups, $scope.show);
    tabService.displayTheDeafultHierarchy($scope.show, parent);
  };

  function loadDataModel() {
    $scope.data_model = dataModelService;
    var promise_1 = $scope.data_model.getGroups();
    var func1 = function (groups) {
      $scope.groups = groups;
    };
    promise_1.then(func1);
    var promise_2 = $scope.data_model.getFormalStructure();
    var func2 = function (formal_structure) {
      $scope.formal_structure = formal_structure;
      if ($scope.selected.inFirstTime()) {
        $scope.selected.init($scope.formal_structure[0].group_id);
        createDisplayForStrcture($scope.formal_structure[0].group_id);
      }
    };
    promise_2.then(func2);

    $scope.search_list = $scope.data_model.getSearchList();
  }

  $scope.$watch('tabService.current_tab', function (newValue, oldValue) {
    angular.noop(newValue);
    if (dashboradMediator.jump_to_state) {
      $scope.selectGroup($scope.selected.id);
      $scope.selected.jump_to_state = null;
    }
    if (oldValue && $scope.startStructure === false) {
      StateService.set({name: oldValue + '_structure_open', value:  $scope.show_formal_structure  });
      $scope.startStructure = true;
    }
    $scope.show_formal_structure = true;
    if (StateService.get(tabService.current_tab + '_structure_open')) {
      $scope.show_formal_structure = StateService.get(tabService.current_tab + '_structure_open');
    }
    tabService.initDisplayForOrgStructure($scope.group, $scope.show);
    if (StateService.get(tabService.current_tab + '_selected')) {
      $scope.selected.setSelected(StateService.get(tabService.current_tab + '_selected'), 'group');
      tabService.displayTheOrgStructre($scope.groups);
    }
    if (StateService.get(tabService.current_tab + '_open')) {
      _.each(StateService.get(tabService.current_tab + '_open'), function (shown) {
        $scope.show[shown] = true;
      });
    }
  });

  $scope.init = function () {
    $scope.StateService = StateService;
    $scope.show_formal_structure = true;
    $scope.startStructure = false;
    $scope.header_str = tabService.current_tab;
    $scope.org = OrgLeftPanelUtilService;
    // Uncommented loadDataModel() call (was commented to reduce redundant ajax calls). 
    // Need this to get groups, for example, to show employees in questionnaire
    loadDataModel();
    $scope.moveExpandToLeft = false;
    $scope.show_pins = true;
    $scope.show_active_pins = true;
    $scope.dic = {};
    $scope.show = {};
    $scope.page = {
      id: 1
    };
    $scope.autoCompleteList = [];
    $scope.selected = dashboradMediator;
    $scope.arrow_img = '/assets/minimize.png';
    $scope.search_input = null;
    $scope.show_formal_structure_not_Explore = true;
    $scope.show_formal_structure_Explore = true;
    $scope.$watch('groups', function () {
      if (!$scope.groups) { return; }
      self.processGroups();
    });
    $scope.$watch('[selected.id, selected.type]', function () {
      // pleaseWaitService.on();
      if ($scope.selected.type === 'group') {
        $scope.selectGroup($scope.selected.id);
      }
    }, true);
    $scope.overlay_blocker_service = overlayBlockerService;
  };
});
