/*globals angular ,  $ ,   window , document, KeyLines ,  _ ,  unused, setTimeout */
angular.module('workships').controller('directoryController', function ($scope, dataModelService, sidebarMediator, employeeWidgetFactoryService, groupByService, directoryMediator, ceoReportService, overlayBlockerService, editPresetMediator, $timeout) {
  'use strict';
  var user_first_letter = '';
  var self = this;
  var MAX_NUMBER_OF_PRESET = "You've reached the maximum amount of presets";
  var PATH = 'assets/analyze_color/';
  var EXTENSION = '.png';
  var STRUCTURE = 'formal_structure';

  var filterEmployees = function () {
    var employees_after_filter = [];
    _.each($scope.employees_list, function (employee) {
      var i = 0;
      var condition_res_list = [];
      var add_to_list = true;
      condition_res_list[i] = false;
      if (_.include($scope.filter_group_ids, employee.id)) {
        condition_res_list[i] = true;
      }
      i += 1;
      _.each($scope.filter_list, function (condition_list, keys) {
        if (!_.isEmpty(condition_list)) {
          condition_res_list[i] = false;
          _.each(condition_list, function (condition) {
            if (employee[keys] === condition) {
              condition_res_list[i] = true;
            }
          });
          i += 1;
        }
      });
      _.each(condition_res_list, function (condition_res) {
        add_to_list = add_to_list && condition_res;
      });
      if (add_to_list) {
        employees_after_filter.push(employee);
      }
    });
    return employees_after_filter;
  };

  $scope.elem_to_scroll = function elem_to_scroll(key) {
    $scope.current_scroll_elem.to = '';
    $timeout(function () {
      $scope.current_scroll_elem.to = key;
    }, 0);
  };
  self.getAttrIndex = function (attributes_list, emp) {
    var res;
    _.each(attributes_list, function (attr, index) {
      if (_.include(attr.employees_id, emp.id)) {
        res = index;
      }
    });
    return res;
  };
  /* istanbul ignore next */
  var getIndexOfEmployeeInAttributesLists = function (emp) {
    $scope.index_of_current_employee_age = self.getAttrIndex($scope.age_list, emp);
    $scope.index_of_current_employee_seniority = self.getAttrIndex($scope.seniority_list, emp);
    $scope.index_of_current_employee_rank = self.getAttrIndex($scope.rank_list, emp);
  };

  self.createListToBar = function (attribute_list, total_employees_number) {
    if (total_employees_number === 0) {
      return;
    }
    var res = [];
    _.each(attribute_list, function (single_attr, key) {
      var temp = {};
      temp.size = Math.round(single_attr.length * (100 / total_employees_number));
      temp.name = key;
      temp.employees_id = single_attr;
      res.push(temp);
    });
    return res;
  };

  /* istanbul ignore next */
  var getEmployeesIdList = function () {
    var res = [];
    _.each($scope.employees_list, function (emp) {
      res.push(emp.id);
    });
    return res;
  };

  /* istanbul ignore next */
  var getAgeList = function (employees_id_list) {
    var age_list = groupByService.groupEmployeesBy(employees_id_list, 'age');
    $scope.age_list = self.createListToBar(age_list, employees_id_list.length);
    $scope.index_of_current_employee_age = 0;
  };

  /* istanbul ignore next */
  var getSeniorityList = function (employees_id_list) {
    var seniority_list = groupByService.groupEmployeesBy(employees_id_list, 'seniority');
    $scope.seniority_list = self.createListToBar(seniority_list, employees_id_list.length);
  };

  /* istanbul ignore next */
  var getRankList = function (employees_id_list) {
    var rank_list = groupByService.groupEmployeesBy(employees_id_list, 'rank');
    $scope.rank_list = self.createListToBar(rank_list, employees_id_list.length);
  };
  /* istanbul ignore next */
  var getAttributeslist = function () {
    var employees_id_list = getEmployeesIdList();
    getAgeList(employees_id_list);
    getSeniorityList(employees_id_list);
    getRankList(employees_id_list);
  };

  var employeesSuccess = function (employees_list) {
    $scope.employees_list = _.sortBy(employees_list, function (employee) {
      return employee.last_name.toLowerCase();
    });
    $scope.employees_after_filter = filterEmployees();
    getAttributeslist();
    $scope.selected.filter.setEmployeesNumber($scope.employees_after_filter.length);
    $scope.create_employee_by_char(employees_list);
    $scope.all_employees = employees_list;
    if ($scope.selected.show_employee_card === true) {
      $scope.selected.show_employee_card = false;
      var selected_employee = _.find($scope.employees_list, { id: parseInt($scope.selected.employee_id, 10) });
      setTimeout(function () {
        $scope.$broadcast('resize');
      }, 0);
      $scope.showEmployeePersonalCard(selected_employee, true);
    }
  };
  /* istanbul ignore next */
  $scope.getDivision = function (group_id) {
    if (group_id) {
      return dataModelService.getDivisionName(group_id);
    }
  };

  self.getPreviewsEmployee = function (index_of_employee_card) {
    if (index_of_employee_card === 0) {
      $scope.prev_employee = $scope.employees_list[$scope.employees_list.length - 1];
    } else {
      $scope.prev_employee = $scope.employees_list[index_of_employee_card - 1];
    }
  };
  self.getNextEmployee = function (index_of_employee_card) {
    if (index_of_employee_card === $scope.employees_list.length - 1) {
      $scope.next_employee = $scope.employees_list[0];
    } else {
      $scope.next_employee = $scope.employees_list[index_of_employee_card + 1];
    }
  };

  /* istanbul ignore next */
  var getEmployeesList = function (attr_list) {
    var res = [];
    _.each(attr_list, function (attr) {
      var emp = dataModelService.getEmployeeById(attr);
      res.push(emp);
    });
    return res;
  };
  /* istanbul ignore next */
  var getFormalAndSubordinates = function (employee) {
    $scope.formal_list = getEmployeesList([employee.manager_id]);
      $scope.subordinates_list = getEmployeesList(employee.subordinates);

  };
  /* istanbul ignore next */
  var setDataToPieChart = function (data_to_pie_chart) {
    $scope.sectors_list = data_to_pie_chart;
  };
  var getSectorsList = function (employee) {
    dataModelService.getPieChartData(employee.id).then(setDataToPieChart);
  };

  var setEmployeeScores = function (data) {
    $scope.emp_scores_measures_list = data;
  };

  $scope.isFilteredOut = function (employee) {
    if ($scope.all_employees.length === $scope.employees_after_filter.length) {
      return false;
    }
    var emp = _.find($scope.employees_after_filter, function (emp) {
      return employee.id === emp.id;
    });
    return emp === undefined;
  };

  $scope.showEmployeePersonalCard = function (employee, first_time) {
    if (!$scope.modalOn()) {
      setTimeout(function () {
        $scope.$broadcast('resize');
      }, 0);
      if (first_time) {
        $scope.sidebar.change_to_employee_page = false;
        $scope.sidebar.show_personal_card = true;
        $scope.state_of_preset_before_show_employee_card = $scope.edit_preset.isInEditPresetMode();
        $scope.edit_preset.closePresetPanel();
        $scope.sidebar.state_before_employee_card = $scope.sidebar.should_show_sidebar;
        $scope.sidebar.should_show_sidebar = false;
        $scope.show_directory = false;
      }
      var index_of_employee_card = $scope.employees_list.indexOf(employee);
      $scope.employee_to_card = $scope.employees_list[index_of_employee_card];
      getIndexOfEmployeeInAttributesLists(employee);
      getFormalAndSubordinates(employee);
      getSectorsList(employee);
      self.getPreviewsEmployee(index_of_employee_card);
      self.getNextEmployee(index_of_employee_card);
      dataModelService.getEmployeeScoresById(employee.id).then(setEmployeeScores);
      getSectorsList(employee);
    }
  };

  var getFirstChar = function (obj) {
    var res;
    var find = false;
    _.find(obj, function (value, key) {
      if (value.length > 0 && !find) {
        res = key;
        find = true;
        return;
      }
    });
    return res;
  };

  $scope.backToDirectoryPage = function () {
    setTimeout(function () {
      $scope.$broadcast('resize');
    }, 0);
    $scope.sidebar.show_personal_card = false;
    if ($scope.state_of_preset_before_show_employee_card === true) {
      $scope.edit_preset.openPresetPanel();
    }
    $scope.sidebar.should_show_sidebar = $scope.sidebar.state_before_employee_card;
    $scope.show_directory = !$scope.show_directory;
  };

  /* istanbul ignore next */
  $scope.changeToListView = function () {
    $scope.selected.view_in_list = true;
  };

  /* istanbul ignore next */
  $scope.changeToGreedView = function () {
    $scope.selected.view_in_list = false;
  };
  /* istanbul ignore next */
  var initAbcByChar = function () {
    return {
      a: [],
      b: [],
      c: [],
      d: [],
      e: [],
      f: [],
      g: [],
      h: [],
      i: [],
      j: [],
      k: [],
      l: [],
      m: [],
      n: [],
      o: [],
      p: [],
      q: [],
      r: [],
      s: [],
      t: [],
      u: [],
      v: [],
      w: [],
      x: [],
      y: [],
      z: []
    };
  };

  $scope.create_employee_by_char = function (employees_list) {
    $scope.selected.filter.setEmployeesNumber(employees_list.length);
    $scope.employee_by_char = initAbcByChar();
    angular.forEach(employees_list, function (value, key) {
      unused(key);
      user_first_letter = value.last_name.charAt(0).toLowerCase();
      $scope.employee_by_char[user_first_letter].push(value);
    });
    $scope.first_char = getFirstChar($scope.employee_by_char);
  };


  $scope.stop_groups_by_char = {
    'A': [{
      'title': 'aligo title',
      'img_url': 'url/#1',
      'total': '22',
      'group_id': '1',
      'group_name': '1.2'
    }, {'title': 'amram', 'img_url': 'url/#2', 'total': '110', 'group_id': '2', 'group_name': '1.12'}],
    'B': [{
      'title': 'barz',
      'img_url': 'url/#121',
      'total': '701',
      'group_id': '3.23',
      'group_name': '1.12'
    }, {
      'title': 'Bligo',
      'img_url': 'url/#11',
      'total': '301',
      'group_id': '3.23',
      'group_name': '1.12'
    }, {'title': 'barbor', 'img_url': 'url/#231', 'total': '50', 'group_id': '5', 'group_name': '9.2'}],
    'C': [{
      'title': 'cargoziak',
      'img_url': 'url/#11',
      'total': '101',
      'group_id': '3.63',
      'group_name': '7.12'
    }, {'title': 'gabour', 'img_url': 'url/#231', 'total': '50', 'group_id': '5', 'group_name': '9.2'}]
  };
  $scope.modalOn = function () {
    return overlayBlockerService.isElemDisplayed('report-modal-window-directory');
  };

  $scope.modalPresetOn = function () {
    return overlayBlockerService.isElemDisplayed('preset-menu');
  };

  $scope.getNumSelectedEmps = function () {
    return $scope.employees_to_report.length;
  };

  $scope.getNumAllEmps = function () {
    return $scope.all_employees.length;
  };

  $scope.employeeChecked = function (employee) {
    var res;
    if (employee) {
      if ($scope.modalOn()) {
        res = ceoReportService.employeeChecked($scope.employees_to_report, employee.id);
      } else {
        res = _.contains($scope.employees_to_preset, employee.email);
      }
    }
    return res;
  };

  $scope.checkEmployee = function (employee) {
    if ($scope.modalOn()) {
      ceoReportService.addEmployeeToReport($scope.employees_to_report, employee.id);
    } else {
      $scope.employees_to_preset.push(employee.email);
    }
  };

  $scope.uncheckEmployee = function (employee) {
    if ($scope.modalOn()) {
      ceoReportService.removeEmployeeFromReport($scope.employees_to_report, employee.id);
    } else {
      _.remove($scope.employees_to_preset, function (email_to_preset) {
        return email_to_preset === employee.email;
      });
    }
  };

  $scope.checkGroup = function (group_id) {
    $scope.group_ids.push(group_id);
  };

  $scope.uncheckGroup = function (group_id) {
    _.remove($scope.group_ids, function (id) {
      return id === group_id;
    });
  };

  $scope.groupChecked = function (group_id) {
    return _.contains($scope.group_ids, group_id);
  };


  $scope.allChecked = function () {
    var result = true;
    _.each($scope.all_employees, function (employee) {
      if (!$scope.employeeChecked(employee.id)) {
        result = false;
      }
    });
    return result;
  };

  $scope.checkAll = function () {
    _.each($scope.all_employees, function (employee) {
      $scope.checkEmployee(employee);
    });
  };

  $scope.uncheckAll = function () {
    _.each($scope.all_employees, function (employee) {
      $scope.uncheckEmployee(employee);
    });
  };

  $scope.sendDirectoryEmployeesToReport = function () {
    var group_id = -1;
    var pin_id = -1;
    var data = {};
    if ($scope.selected.type === 'group') {
      group_id = $scope.selected.id;
    } else if ($scope.selected.type === 'pin') {
      pin_id = $scope.selected.id;
    }
    if ($scope.employees_to_report.length > 0) {
      data = {
        employee_data: [{title: 'Directory', employee_ids: $scope.employees_to_report}],
        group_id: group_id,
        pin_id: pin_id
      };
      ceoReportService.sendFlaggedEmployeesToReport(data);
      ceoReportService.toggleShowReportModal('report-modal-window-directory');
    }
  };

  var getGroupImgUrl = function (structure, group_id, path_url, extantion) {
    var color = dataModelService.getColorsByName(structure, group_id) || '8dc0c5';
    return path_url + color + extantion;
  };
  var sort_obj_by_char = function (groups_by_pre_char) {
    var name_first_letter;
    var arr = [];
    $scope.groups_by_char = initAbcByChar();
    angular.forEach(groups_by_pre_char, function (value, key) {
      unused(key);
      name_first_letter = value.name.charAt(0).toLowerCase();
      arr.push(name_first_letter);
      $scope.groups_by_char[name_first_letter].push(value);
    });
    $scope.last_group_char = arr.sort()[arr.length - 1];
  };

  var genGroupsObject = function (current_main_group, recreate) {
    if (recreate) {
      $scope.groups_by_pre_char = {};
    }
    var id = current_main_group.id;
    $scope.groups_by_pre_char[id] = {'char': id };
    if (current_main_group.name) {
      $scope.groups_by_pre_char[id].name = current_main_group.name;
    }
    if (current_main_group.employees_ids) {
      $scope.groups_by_pre_char[id].total_employees = current_main_group.employees_ids.length;
    }
    if (current_main_group.parent) {
      $scope.groups_by_pre_char[id].department = dataModelService.getGroupBy(current_main_group.parent).name;
    }
    $scope.groups_by_pre_char[id].img_url = getGroupImgUrl(STRUCTURE, id, PATH, EXTENSION);
    $scope.groups_by_pre_char[id].division = dataModelService.getDivisionName(current_main_group.id);
    if (current_main_group.child_groups.length > 0) {
      var i = 0, current_id;
      for (i; i < current_main_group.child_groups.length; i++) {
        current_id = current_main_group.child_groups[i];
        genGroupsObject(dataModelService.getGroupBy(current_id));
      }
    }
    sort_obj_by_char($scope.groups_by_pre_char);
    $scope.first_group_char = getFirstChar($scope.groups_by_char);
  };
  var setEmployessPin = function (emps) {
    $scope.filter_group_ids = emps;
  };

  var updateDirectory = function () {
    if ($scope.selected) {
      if ($scope.selected.type === 'group') {
        if (!dataModelService.getGroupBy) {
          return;
        }
        var current_main_group = dataModelService.getGroupBy($scope.selected.id);
        $scope.filter_group_ids = current_main_group.employees_ids;
        genGroupsObject(current_main_group, 1);
      } else if ($scope.selected.type === 'pin') {
        $scope.groups_by_char = null;
        dataModelService.getEmployeesPin($scope.selected.id).then(setEmployessPin);
      }
    }
  };

  $scope.changeToEditPreset = function () {
    if ($scope.dm.getNumberOfPreset() < 6 && $scope.sidebar.show_personal_card === false) {
      $scope.edit_preset.create($scope.selected.filter, $scope.employees_to_preset);
      ceoReportService.toggleShowReportModal('preset-menu');
      $scope.edit_preset.changePresetMode();
    } else {
      $scope.edit_preset.getSystemAlert(MAX_NUMBER_OF_PRESET, 'error');
    }
  };

  $scope.presetOff = function () {
    $scope.edit_preset.removeSetting();
    $scope.edit_preset.changePresetMode();
  };
  $scope.getAllEmpsNumber = function () {
    if ($scope.dm.getAllEmpsNumber) {
      return $scope.dm.getAllEmpsNumber();
    }
  };

  $scope.$parent.restart = function () {
    $scope.init();
  };

  /* watch */
  $scope.$watch('[df, filter_group_ids, group_ids]', function () {
    $scope.filter_list = $scope.selected.filter.getFiltered();
    $scope.employees_after_filter = filterEmployees();
    $scope.selected.filter.setEmployeesNumber($scope.employees_after_filter.length);
    $scope.group_ids = $scope.selected.filter.getFilterGroupIds();
    $scope.all_employees = _.sortBy($scope.all_employees, function (employee) {
      return employee.last_name.toLowerCase();
    });
    $scope.employees_to_report.splice(0, $scope.employees_to_report.length);
  }, true);

  $scope.init = function () {
    $scope.others_status = true;
    $scope.dm = dataModelService;
    $scope.edit_preset = editPresetMediator;
    $scope.selected = directoryMediator;
    $scope.sidebar = sidebarMediator;
    $scope.show_directory = true;
    $scope.displayTwoDigitsAfterDecimal = employeeWidgetFactoryService.displayTwoDigitsAfterDecimal;
    $scope.taskbars = [{
      'name': 'Group by' //11TODO do we need this??
    }, {
      'name': 'Sort by'
    }];
    $scope.time_filter = 1;
    $scope.df = $scope.selected.filter.getFilter();
    dataModelService.getEmployees().then(employeesSuccess);
    $scope.current_scroll_elem = {};
    $scope.overlay_blocker_service = overlayBlockerService;
    $scope.cr = ceoReportService;
    $scope.employees_to_report = [];
    $scope.employees_to_preset = [];
    $scope.is_group_toogle_on = directoryMediator.is_group_toogle_on;
    $scope.groups_by_pre_char = {};
    $scope.$watch('[selected.id , selected.type]', function () {
      updateDirectory();
    }, true);
  };

});
