/*globals angular, console, unused, _ */
angular.module('workships').controller('analyzeSidebarController', function ($scope, utilService, analyzeMediator, directoryMediator, dataModelService, ajaxService, overlayBlockerService, editPresetMediator) {

  'use strict';

  /************************ PRIVATE ************************/
  var self = this;
  var GROUPS_TAB = 0;
  var CRITERIA_TAB = 1;
  var STRUCTURE = 'formal_structure';
  var filters_list;
  $scope.NETWORK_PAGE_NUM = 2;
  $scope.DIRECTORY_PAGE_NUM = 3;

  var isEpanded = function (ranges) {
    var expanded = false;
    _.each(ranges, function (range) {
      if (range === true) {
        expanded = true;
      }
    });
    return expanded;
  };
  var isAllActive = function (ranges) {
    var all_active = true;
    _.each(ranges, function (range) {
      if (range === false) {
        all_active = false;
      }
    });
    return all_active;
  };
  var isLevelFilterExpanded = function (ranges) {
    var expanded = false;
    if (ranges.from !== 0 ||  ranges.to !== 10) {
      expanded = true;
    }
    return expanded;
  };

  function expandToCheckBoxFormat(obj) {
    obj.expanded = isEpanded(obj.ranges);
    obj.checkbox_to_expand = false;
    obj.all_active = isAllActive(obj.ranges);
  }

  function expandedLevelFilterFormat(obj) {
    obj.expanded = isLevelFilterExpanded(obj.ranges);
    obj.checkbox_to_expand = false;
  }


  function bindToFilterMidiator(filter_attr, filter) {
    var title = filter_attr;
    var ranges = filter[filter_attr];
    return {
      title: title,
      ranges: ranges
    };
  }

  function loadFilterService(page_num) {
    if (page_num === $scope.NETWORK_PAGE_NUM) {
      $scope.fm = $scope.selected.filter;
    } else {
      $scope.fm = $scope.selected.filter;
    }
    if (!$scope.selected.isFilterInit()) {
      $scope.fm.init(filters_list);
      $scope.selected.initFilter();
    }
  }

  function loadLevelsFilters() {
    $scope.levels_filters = [];
    var filter = $scope.fm.getFilter();
    var friendship = bindToFilterMidiator('friendship', filter);
    var collaboration = bindToFilterMidiator('collaboration', filter);
    var trust = bindToFilterMidiator('trust', filter);
    var most_expert = bindToFilterMidiator('expert', filter);
    var most_social_power = bindToFilterMidiator('social_power', filter);
    var centrality = bindToFilterMidiator('centrality', filter);
    var central = bindToFilterMidiator('central', filter);
    var in_the_loop = bindToFilterMidiator('in_the_loop', filter);
    var politician = bindToFilterMidiator('politician', filter);

    expandedLevelFilterFormat(friendship);
    expandedLevelFilterFormat(collaboration);
    expandedLevelFilterFormat(trust);
    expandedLevelFilterFormat(most_expert);
    expandedLevelFilterFormat(most_social_power);
    expandedLevelFilterFormat(centrality);
    expandedLevelFilterFormat(central);
    expandedLevelFilterFormat(in_the_loop);
    expandedLevelFilterFormat(politician);

    $scope.levels_filters.push(friendship);
    $scope.levels_filters.push(collaboration);
    $scope.levels_filters.push(trust);
    $scope.levels_filters.push(most_expert);
    $scope.levels_filters.push(most_social_power);
    $scope.levels_filters.push(centrality);
    $scope.levels_filters.push(central);
    $scope.levels_filters.push(in_the_loop);
    $scope.levels_filters.push(politician);
  }

  function loadCriterias() {
    $scope.criterias = [];
    var filter = $scope.fm.getFilter();
    var age = bindToFilterMidiator('age_group', filter);
    var seniority = bindToFilterMidiator('seniority', filter);
    var rank_1 = bindToFilterMidiator('rank', filter);
    var rank_2 = bindToFilterMidiator('rank_2', filter);
    var gender = bindToFilterMidiator('gender', filter);

    $scope.criterias.push(age);
    $scope.criterias.push(seniority);
    $scope.criterias.push(rank_1);
    $scope.criterias.push(rank_2);
    $scope.criterias.push(gender);
  }

  function loadSeconderyFilters() {
    $scope.filter_groups = [];
    var filter = $scope.fm.getFilter();
    var marital_status = bindToFilterMidiator('marital_status', filter);
    var office = bindToFilterMidiator('office', filter);
    var role_type = bindToFilterMidiator('role_type', filter);
    var job_title = bindToFilterMidiator('job_title', filter);
    expandToCheckBoxFormat(marital_status);
    expandToCheckBoxFormat(office);
    expandToCheckBoxFormat(role_type);
    expandToCheckBoxFormat(job_title);


    $scope.filter_groups.push(marital_status);
    $scope.filter_groups.push(office);
    $scope.filter_groups.push(role_type);
    $scope.filter_groups.push(job_title);
  }

  function getFilters(company_id, page_num) {
    var method = 'GET';
    var url = "get_filters_values";
    var params = {
      company_id: company_id
    };
    var succ = function (data) {
      filters_list = data;
      loadFilterService(page_num);
      loadCriterias();
      loadSeconderyFilters();
      loadLevelsFilters();
    };
    var err = function () {
    };
    ajaxService.sendMsg(method, url, params, succ, err);
  }

  function manipulateAllFilterGroup(filter_group, arg) {
    _.forEach($scope.util.getObjKeys(filter_group.ranges), function (key) {
      filter_group.ranges[key] = arg;
    });
    filter_group.all_active = arg;
  }

  function checkIfAllGroupActive(filter_group) {
    var all_group_active = true;
    _.forEach(filter_group.ranges, function (range) {
      if (!range) {
        all_group_active = false;
      }
    });
    filter_group.all_active = all_group_active;
  }

  function loadDataModel(page_num) {
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
      }
      $scope.filter_group_ids = $scope.selected.filter.getFilterGroupIds();
      getFilters(1, page_num);
    };
    promise_2.then(func2);
    var promise_3 = $scope.data_model.getPins();
    var func3 = function (pins) {
      $scope.pins_status = pins;
    };
    promise_3.then(func3);

    var promise_4 = $scope.data_model.getManagers();
    var func4 = function (managers) {
      $scope.managers = managers;
    };
    promise_4.then(func4);

    $scope.search_list = $scope.data_model.getSearchList();
  }

  self.processGroups = function () {
    _.each($scope.groups, function (g) {
      self.addGroupsToDictionary(g); // _TODO refactor to data model
    });
  };

  self.addGroupsToDictionary = function (g) { // _TODO refactor to data model
    $scope.dic[g.id] = g;
  };

  self.expandGroupWidgetByBreadCrumbs = function () {
    var bc = $scope.data_model.getBreadCrumbs($scope.selected.id, $scope.selected.type);
    _.each(bc, function (b) {
      $scope.show[b.id] = true;
    });
  };
  $scope.set_color = function (g_id) {
    var color = $scope.data_model.getColorsByName(STRUCTURE, g_id) || '8dc0c5';
    return { 'border-left-color': '#' + color };
  };
  $scope.selectGroup = function (group_id) {
    $scope.show_formal_structure = true;
    $scope.selected.setSelected(group_id, 'group');
    self.expandGroupWidgetByBreadCrumbs();
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
  $scope.selectPin = function (pin_id) {
    $scope.show_pins = true;
    $scope.show_active_pins = true;
    $scope.selected.setSelected(pin_id, 'pin');
  };

  $scope.inCriteriaTab = function () {
    return $scope.selected.selected_tab === CRITERIA_TAB;
  };

  $scope.inGroupsTab = function () {
    return $scope.selected.selected_tab === GROUPS_TAB;
  };

  $scope.switchToGroupsTab = function () {
    $scope.selected.selected_tab = GROUPS_TAB;
  };

  $scope.switchToCriteriaTab = function () {
    $scope.selected.selected_tab = CRITERIA_TAB;
  };

  $scope.toggleSelectedRange = function (ranges, key) {
    ranges[key] = !ranges[key];
  };

  $scope.toggleShowPins = function () {
    $scope.show_pins = !$scope.show_pins;
  };

  $scope.toggleShow = function (group_id) {
    $scope.show[group_id] = !$scope.show[group_id];
  };

  $scope.toggleShowActivePins = function () {
    $scope.show_active_pins = !$scope.show_active_pins;
  };

  $scope.toggleShowFormalStructure = function () {
    $scope.show_formal_structure = !$scope.show_formal_structure;
  };

  $scope.toggleUpdateFilterMenu = function (element_name) {
    if (!overlayBlockerService.isElemDisplayed(element_name)) {
      overlayBlockerService.block(element_name);
    } else {
      overlayBlockerService.unblock();
    }
  };

  $scope.showUpdateFilterMenu = function () {
    return overlayBlockerService.isElemDisplayed('update_filter_menu');
  };

  $scope.onClickFilterGroupChecbox = function (filter_group) {
    filter_group.all_active = !filter_group.all_active;
    manipulateAllFilterGroup(filter_group, filter_group.all_active);
  };

  $scope.onClickFilterChecbox = function (filter_group, key) {
    $scope.toggleSelectedRange(filter_group.ranges, key);
    checkIfAllGroupActive(filter_group);
  };

  $scope.onClickFilterMenuCheckbox = function (filter) {
    filter.checkbox_to_expand = !filter.checkbox_to_expand;
  };

  $scope.areThereCheckBoxesSelected = function () {
    var flag = false;
    _.forEach($scope.filter_groups, function (filter) {
      if (filter.checkbox_to_expand) {
        flag = true;
      }
    });
    _.forEach($scope.levels_filters, function (filter) {
      if (filter.checkbox_to_expand) {
        flag = true;
      }
    });
    return flag;
  };

  $scope.removeFilter = function (filter) {
    filter.expanded = false;
    filter.all_active = false;
    if (filter.ranges) {
      if ((filter.ranges.from || filter.ranges.from === 0) && filter.ranges.to) {
        filter.ranges.from = 0;
        filter.ranges.to = 10;
      } else {
        _.forEach(filter.ranges, function (value, key) {
          unused(value);
          filter.ranges[key] = false;
        });
      }
    }
  };

  $scope.onClickUpdateFilter = function () {
    var expandFilter = function (f) {
      if (!f.expanded && f.checkbox_to_expand) {
        f.expanded = true;
        f.checkbox_to_expand = false;
      }
    };
    _.forEach($scope.filter_groups, expandFilter);
    _.forEach($scope.levels_filters, expandFilter);
    $scope.toggleUpdateFilterMenu('update_filter_menu');
  };

  $scope.onSelect = function (search_node) {
    if (search_node.type === 'group') {
      $scope.selectGroup(search_node.id);
    } else {
      $scope.selectPin(search_node.id);
    }
  };

  $scope.clearFilter = function () {
    $scope.fm.init(filters_list);
  };

  $scope.displayFormattedTitle = function (str) {
    return utilService.displayFormattedTitle(str);
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
  };

  $scope.onClickRemoveGroupId = function (group_id) {
    var children = $scope.dm.getGroupBy(group_id).child_groups;
    _.forEach(children.concat([group_id]), function (child_id) {
      _.remove($scope.filter_group_ids, function (id) {
        return id === child_id;
      });
    });
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

  var isCheckboxInit = function () {
    var res = true;
    if ($scope.selected.inFirstTime()) {
      res = false;
    }
    return res;
  };

  $scope.openOrCloseDraft = function (pid) {
    if ($scope.page.id === $scope.DIRECTORY_PAGE_NUM) {
      editPresetMediator.openPresetPanel();
      $scope.toggleUpdateFilterMenu('preset-menu');
      editPresetMediator.uploadPreset(pid, true);
    }
  };


  // --------------

  $scope.init = function (page_num) {
    $scope.dm = dataModelService;
    $scope.util = utilService;
    loadDataModel(page_num);
    $scope.dic = {};
    $scope.page = {
      id: page_num
    };
    $scope.show = {};
    $scope.show_formal_structure = true;
    $scope.show_pins = true;
    $scope.show_active_pins = true;
    $scope.search_input = null;
    if (page_num === $scope.NETWORK_PAGE_NUM) {
      $scope.selected = analyzeMediator;
      $scope.initCheckbox = isCheckboxInit();
    } else {
      $scope.selected = directoryMediator;
      $scope.is_group_toogle_on = directoryMediator.is_group_toogle_on;
      $scope.initCheckbox = isCheckboxInit();
    }
    $scope.overlay_blocker_service = overlayBlockerService;

    $scope.$watch('[selected.id, selected.type]', function () {
      console.log('selected has been changed');
      if ($scope.selected.type === 'group') {
        $scope.selectGroup($scope.selected.id);
      } else if ($scope.selected.type === 'pin') {
        $scope.selectPin($scope.selected.id);
      }
    }, true);
    $scope.$watch('groups', function () {
      self.processGroups();
    }, true);
  };
});
