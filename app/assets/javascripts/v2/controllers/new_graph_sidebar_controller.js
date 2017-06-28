/*globals angular, console, unused, _ */
// angular.module('workships').controller('NewGraphSidebarController', function ($scope, utilService, dashboradMediator, analyzeMediator, directoryMediator, dataModelService, ajaxService, overlayBlockerService, editPresetMediator) {
angular.module('workships').controller('NewGraphSidebarController',
  function ($scope, $timeout, dataModelService, analyzeMediator, ajaxService, overlayBlockerService, StateService, tabService, utilService, OrgLeftPanelUtilService, graphService, currentUserService) {

  'use strict';

  /************************ PRIVATE ************************/
  var self = this;
  // var GROUPS_TAB = 0;
  // var CRITERIA_TAB = 1;
  var STRUCTURE = 'formal_structure';
  var filters_list;
  $scope.NETWORK_PAGE_NUM = 2;
  // $scope.DIRECTORY_PAGE_NUM = 3;

  function bindToFilterMidiator(filter_attr, filter, limit, filter_attr_to_merge) {
    var title = filter_attr;
    var ranges = filter[filter_attr];
    if (filter_attr_to_merge) {
      ranges = _.merge(ranges, filter[filter_attr_to_merge]);
    }
    return {
      title: title,
      values: ranges,
      limit: limit
    };
  }

  function loadFilterService() {
    $scope.fm = $scope.selected.filter;
    if (!$scope.selected.isFilterInit()) {
      $scope.fm.init(filters_list);
      $scope.selected.initFilter();
    }
  }

  $scope.removeGroupFilter = function () {
    $scope.selected.filter.removeFilterGroupIds();
  };

  function loadCriterias() {
    $scope.selected.criteria_list = [];
    $scope.selected.show_criteria = [];
    var filter = $scope.fm.getFilter();
    var role_type = bindToFilterMidiator('role_type', filter, 4);
    var rank_1 = bindToFilterMidiator('rank', filter, 4, 'rank_2'); //rank_1 merge with rank_2

    var age = bindToFilterMidiator('age_group', filter, 4);
    var seniority = bindToFilterMidiator('seniority', filter, 4);
    var gender = bindToFilterMidiator('gender', filter, 4);
    var marital_status = bindToFilterMidiator('marital_status', filter, 4);
    var office = bindToFilterMidiator('office', filter, 4);
    var job_title = bindToFilterMidiator('job_title', filter, 4);

    $scope.selected.criteria_list.push(age);
    $scope.selected.criteria_list.push(seniority);
    $scope.selected.criteria_list.push(role_type);
    $scope.selected.criteria_list.push(rank_1);
    $scope.selected.criteria_list.push(gender);
    $scope.selected.criteria_list.push(marital_status);
    $scope.selected.criteria_list.push(office);
    $scope.selected.criteria_list.push(job_title);

    $scope.selected.show_criteria.push('role_type');
    $scope.selected.show_criteria.push('rank');
    $scope.selected.show_criteria.push('office');
  }

  function setSnapshots(snapshot_list) {
    $scope.snapshot_list = snapshot_list;
    if ($scope.selected.getSnapshotByIndex() === undefined) {
      $scope.selected.setSnapshotByIndex(0);
      $scope.snapshot_id = $scope.snapshot_list[0];
    } else {
      $scope.snapshot_id = $scope.snapshot_list[$scope.selected.getSnapshotByIndex()];
    }
  }

  function getFilters(company_id) {
    var method = 'GET';
    var url = "get_filters_values";
    var params = {
      company_id: company_id
    };
    var succ = function (data) {
      filters_list = data;
      loadFilterService();
      loadCriterias();
    };
    var err = function () {
    };
    ajaxService.sendMsg(method, url, params, succ, err);
  }

  var createDisplayForStrcture = function (parent) {
    if (tabService.current_tab && $scope.startStructure === false) {
      return;
      StateService.set({name: + '_structure_open', value:  $scope.show_formal_structure });
      $scope.startStructure = true;
    }
    $scope.show_formal_structure = true;
    if (StateService.get(tabService.current_tab + '_structure_open')) {
      $scope.show_formal_structure = StateService.get(tabService.current_tab + '_structure_open');
    }
    tabService.initDisplayForOrgStructure($scope.groups, $scope.show);
    tabService.displayTheDeafultHierarchy($scope.show, parent);
    $timeout(function () {
      $scope.drill_down_state.show = $scope.inDrillDownMode();
    }, 0);
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
      createDisplayForStrcture($scope.formal_structure[0].group_id);
      if ($scope.selected.inFirstTime()) {
        if (!$scope.selected.id) {
          $scope.selected.init($scope.formal_structure[0].group_id);
        }
      }
      $scope.filter_group_ids = $scope.selected.filter.getFilterGroupIds();
      getFilters(1);
    };
    promise_2.then(func2);
    var promise_4 = $scope.data_model.getManagers();
    var func4 = function (managers) {
      $scope.managers = managers;
    };
    promise_4.then(func4);
    $scope.search_list = $scope.data_model.getSearchList();
    dataModelService.getOverlayEntityGroup();
  }

  self.processGroups = function () {
    _.each($scope.groups, function (g) {
      self.addGroupsToDictionary(g); // _TODO refactor to data model
    });
  };

  self.addGroupsToDictionary = function (g) { // _TODO refactor to data model
    $scope.dic[g.id] = g;
  };

  $scope.set_color = function (g_id) {
    var color = $scope.data_model.getColorsByName(STRUCTURE, g_id) || '8dc0c5';
    return { fill: '#' + color };
  };
  $scope.selectGroup = function (group_id) {
    if (tabService.current_tab !== 'Explore') { return; }
    if ($scope.dm.getGroupBy) {
      if ($scope.initCheckbox) {
        $scope.initCheckbox = false;
      } else {
        if ($scope.NETWORK_PAGE_NUM === $scope.page.id) {
          $scope.filter_group_ids.splice(0, $scope.filter_group_ids.length);
          $scope.onClickAddGroupId(group_id);
        }
      }
    }
  };

  $scope.changeGroup = function (group_id) {
    if (tabService.current_tab !== 'Explore') { return; }
    $scope.show_formal_structure = true;
    $scope.selected.setSelected(group_id, 'group');
    tabService.keepStates('_selected', group_id);
    tabService.displayTheOrgStructreInExplore($scope.groups, $scope.show);
    tabService.keepSelections($scope.groups);
    tabService.saveOpenGroups($scope.groups, $scope.show);
    tabService.setDrillDownOriginGroup();
    $scope.drill_down_state.show = $scope.inDrillDownMode();
  };

  $scope.toggleShow = function (group_id) {
    $scope.show[group_id] = !$scope.show[group_id];
  };

  $scope.toggleShowFormalStructure = function () {
    $scope.show_formal_structure = !$scope.show_formal_structure;
    if (tabService.current_tab === 'Explore') {
      $scope.show_formal_structure_Explore = !$scope.show_formal_structure_Explore;
      $scope.show_formal_structure = $scope.show_formal_structure_Explore;
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

  $scope.clearOrganizationalStructure = function () {
    $scope.filter_group_ids.splice(0, $scope.filter_group_ids.length);
    graphService.setFilter($scope.selected.filter.getFiltered(), $scope.selected.filter.getFilterGroupIds());
  };

  $scope.toggleUpdateFilterMenu = function () {
    if (!overlayBlockerService.isElemDisplayed('update_filter_menu')) {
      overlayBlockerService.block('update_filter_menu');
    } else {
      overlayBlockerService.unblock();
    }
  };

  $scope.showUpdateFilterMenu = function () {
    return overlayBlockerService.isElemDisplayed('update_filter_menu');
  };

  $scope.toggleChooseLayerFilter = function (layer) {
    if ($scope.drillDown && $scope.drillDownLayer !== layer) { return; }
    $scope.selected.layer = layer;
    overlayBlockerService.block('choose_layer_filter');
  };

  // functions for the checkbox groups filter

  $scope.onClickAddGroupId = function (group_id) {
    var addIdToFilterGroupIds = function (id) {
      if (!_.contains($scope.filter_group_ids, id)) {
        $scope.filter_group_ids.push(id);
      }
    };
    var children = $scope.dm.getGroupBy(group_id).child_groups;
    _.forEach(children.concat([group_id]), function (id) {
      addIdToFilterGroupIds(id);
    });
    graphService.setFilter($scope.selected.filter.getFiltered(), $scope.selected.filter.getFilterGroupIds());
  };

  $scope.onClickRemoveGroupId = function (group_id) {
    var children = $scope.dm.getGroupBy(group_id).child_groups;
    _.forEach(children.concat([group_id]), function (child_id) {
      _.remove($scope.filter_group_ids, function (id) {
        return id === child_id;
      });
    });
    graphService.setFilter($scope.selected.filter.getFiltered(), $scope.selected.filter.getFilterGroupIds());
  };

  $scope.groupChecked = function (group_id) {
    return _.contains($scope.filter_group_ids, group_id);
  };

  $scope.showCheckbox = function (group_id) {
    var parent_id = $scope.dm.getGroupBy(group_id).parent;
    var parent_checkbox_shown;
    if (parent_id) {
      parent_checkbox_shown = $scope.showCheckbox(parent_id);
    } else {
      parent_checkbox_shown = false;
    }
    return ($scope.page.id === 3) || (($scope.page.id === 2 && (group_id === $scope.selected.id)) || parent_checkbox_shown);
  };

  $scope.inDrillDownMode = function () {
    if (!$scope.formal_structure) { return false; }
    return ($scope.selected.id !== $scope.formal_structure[0].group_id);
  };

  $scope.backToCompany = function () {
    $scope.changeGroup($scope.formal_structure[0].group_id);
  };

  $scope.selectGroupDrillDown = function (group_id) {
    $scope.removeGroupFilter();
    $scope.changeGroup(group_id);
  };


  // --------------

  $scope.getLimit = function (criteria) {
    if (criteria.expanded) {
      return _.keys(criteria.values).length;
    }
    return criteria.limit;
  };

  $scope.toggleExpandCollapseCriteria = function (criteria) {
    criteria.expanded = !criteria.expanded;
  };

  $scope.criteriaToShow = function (list, names_to_show) {
    return _.filter(list, function (e) {
      return _.contains(names_to_show, e.title);
    });
  };

  $scope.resetCriteria = function (c) {
    c.hidden = false;
    c.expanded = false;
    $scope.clearAll(c);
  };

  $scope.removeCriteria = function (names_to_show, c) {
    $scope.resetCriteria(c);
    _.remove(names_to_show, function (n) {
      return n === c.title;
    });
  };

  $scope.addCriteria = function (names_to_show, title) {
    names_to_show = _.union(names_to_show, [title]);
  };

  $scope.openAddCriteriaModal = function () {
    $scope.toggleUpdateFilterMenu();
  };

  $scope.toggleFilter = function (criteria, filter_name, value) {
    if (criteria.title === 'keywords' && criteria.values[filter_name] === undefined) {
      var values = $scope.selected.filter.getFilter().keywords_names;
      values[filter_name] = value;
    } else {
      criteria.values[filter_name] = value;
    }
    graphService.setFilter($scope.selected.filter.getFiltered(), $scope.selected.filter.getFilterGroupIds());
  };

  $scope.toggleAll = function (criteria, value) {
    _.each(criteria.values, function (v, k) {
      angular.noop(v);
      if (_.includes($scope.selected.shown_overlay_groups, k.split(' (')[0])) {
        $scope.toggleFilter(criteria, k, value);
      }
    });
    if (criteria.title === 'keywords') {
      _.each($scope.selected.filter.getFilter().keywords_names, function (v, k) {
        angular.noop(v);
        $scope.toggleFilter(criteria, k, value);
      });
    }
  };

  $scope.isAllChecked = function (criteria) {
    var res = _.all(criteria.values, function (v, k) {
      // angular.noop(k);
      return !_.includes($scope.selected.shown_overlay_groups, k.split(' (')[0]) || v;
    });
    if (criteria.title === 'keywords') {
      res = res && _.all($scope.selected.filter.getFilter().keywords_names, function (v, k) {
        angular.noop(k);
        return v === true;
      });
    }
    return res;
  };

  $scope.clearAll = function (criteria) {
    _.each(_.keys(criteria.values), function (k) {
      criteria.values[k] = false;
    });
    graphService.setFilter($scope.selected.filter.getFiltered(), $scope.selected.filter.getFilterGroupIds());
  };

  $scope.toggleHideCriteria = function (criteria) {
    if (criteria.hidden === undefined) {
      criteria.hidden = true;
      return;
    }
    criteria.hidden = !criteria.hidden;
  };

  function isSingleKeyword(key) {
    return key.indexOf(' (') === -1;
  }

  $scope.setDrillDown = function (key, layer) {
    $scope.drillDown = key;
    $scope.drillDownLayer = layer;
    // if (!key) {
    //   $scope.selected.overlay_entity = null;
    //   return;
    // }
    // var drillDownType, collection;
    // if (isSingleKeyword(key)) {
    //   drillDownType = 'id';
    //   collection = $scope.dm.overlay_snapshot_data.overlay_entities;
    // } else {
    //   drillDownType = 'group';
    //   collection = $scope.dm.overlay_snapshot_data.overlay_entity_groups;
    // }
    // $scope.selected.overlay_entity = {
    //   id: _.find(collection, { name: key.split(' (')[0] }).id,
    //   type: drillDownType
    // };
    // tabService.setDrillDownOriginOverlay();
  };

  $scope.layerValuesToShow = function (layer) {
    var filtered_values = {};
    if ($scope.drillDown && $scope.drillDownLayer === layer) {
      if (layer.values[$scope.drillDown]) {
        filtered_values[$scope.drillDown] = layer.values[$scope.drillDown];
      } else {
        filtered_values[$scope.drillDown] = $scope.selected.filter.getFilter().keywords_names[$scope.drillDown];
      }
      return filtered_values;
    }
    _.each(layer.values, function (v, k) {
      if (_.contains($scope.selected.shown_overlay_groups, k.split(' (')[0])) {
        filtered_values[k] = v;
      }
    });
    if (layer.title === 'keywords') {
      _.each($scope.selected.filter.getFilter().keywords_names, function (v, k) {
        filtered_values[k] = v;
      });
    }
    return filtered_values;
  };

  $scope.includeLayers = function () {
    if (analyzeMediator.overlay_entity_group_id === undefined) {
      analyzeMediator.toogle_on_overlay = !analyzeMediator.toogle_on_overlay;
      return;
    }
    //var entitiy_group_ids_of_showing = dataModelService.fetchGroupIdsFromOverlayEntity(analyzeMediator.shown_overlay_groups);
    //dataModelService.getOverlaySnapshotData(entitiy_group_ids_of_showing, analyzeMediator.entity_ids_of_showing || [], graphService.group_id, graphService.sid, true).then(function () { 
    //  analyzeMediator.toogle_on_overlay = !analyzeMediator.toogle_on_overlay;
    //});
  };

  $scope.$watch('tabService.current_tab', function (newValue, oldValue) {
    angular.noop(newValue);
    if (tabService.current_tab !== 'Explore') { return; }
    if ($scope.selected.getFlagData()) {
      if ($scope.selected.getFlagData().jump_to === true) {
        $scope.changeGroup($scope.selected.id);
        $scope.selected.getFlagData().jump_to = false;
      }
    } else {
      graphService.setTabToClicked();
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

  $scope.setSearch = function (node) {
    graphService.latest_search = node;
    graphService.setSearch(node);
  };

  $scope.clearSearch = function () {
    $scope.search.input = '';
    graphService.latest_search = null;
    graphService.setSearch();
  };

  $scope.fetchNodeNames = function () {
    var names = _.map(_.union(graphService.getNodes(), graphService.getEverythingInsideAllCombos()), function (node) {
      return {
        id: node.id,
        type: node.type,
        name: node.type === 'single' ? node.first_name + ' ' + node.last_name + ', ' + node.job_title : String(node.name)
      };
    });
    if (!currentUserService.isCurrentUserAdmin()) {
      return names;
    }
    var emails = _(_.union(graphService.getNodes(), graphService.getEverythingInsideAllCombos())).filter(function (node) {
      return node.type === 'single';
    }).map(function (node) {
      return {
        id: node.id,
        type: node.type,
        name: node.email
      };
    });
    return _.union(names, emails.value());
  };

  $scope.init = function () {
    $scope._ = _;
    $scope.graphService = graphService;
    $scope.obs = overlayBlockerService;
    $scope.dm = dataModelService;
    $scope.util = utilService;
    $scope.show_formal_structure = true;
    $scope.startStructure = false;
    $scope.selected = analyzeMediator;

    $scope.search = {};

    $scope.org = OrgLeftPanelUtilService;
    $scope.layer_icons = {};
    loadDataModel();
    $scope.dic = {};
    $scope.show = {};
    $scope.page = {
      id: $scope.NETWORK_PAGE_NUM
    };
    $scope.drill_down_state = { show: false };
    $scope.show_formal_structure_not_Explore = true;
    $scope.show_formal_structure_Explore = true;
    $scope.arrow_img = '/assets/minimize.png';

    $scope.$watch('[selected.id, selected.type]', function () {
      if ($scope.selected.type === 'group') {
        $scope.changeGroup($scope.selected.id);
      }
    }, true);
    $scope.$watch('groups', function () {
      if (!$scope.groups) { return; }
      self.processGroups();
    });
  };
});
