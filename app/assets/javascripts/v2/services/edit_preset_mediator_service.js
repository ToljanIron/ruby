/*globals angular, _ */
angular.module('workships.services').factory('editPresetMediator', function (FilterFactoryService, $timeout, dataModelService, overlayBlockerService) {
  'use strict';
  var preset = {};
  var edit_preset_open = false;
  var SAVED_AS_DRAFT = 1;
  var GENERATE = 2;
  var number_of_all_employee;
  var all_groups = 0;
  var all_employees = 0;
  var all_cretria = 0;
  var DELETE = true;
  preset.filter = FilterFactoryService.create();
  function loadGroups(groups) {
    all_groups = groups;
    preset.definition.groups = _.clone(all_groups);
  }

  preset.getGroupsToPreset = function () {
    return all_groups;
  };

  function loadEmployess(employess_list) {
    all_employees = employess_list;
    preset.definition.employees = _.clone(all_employees);
  }

  preset.getEmployeesToPreset = function () {
    return all_employees;
  };

  preset.isCheckboxExsists = function () {
    return (preset.getEmployeesToPreset().length > 0 || preset.getGroupsToPreset().length > 0 || preset.getCretriaToPreset().length > 0);
  };

  function loadCretria(cretria, from_server) {
    if (!from_server) {
      all_cretria = [];
      var rank = { vals: [] };
      _.each(cretria, function (cond, key) {
        if (key === 'rank_2' || key === 'rank') {
          rank.param = 'rank';
          rank.vals = _.union(rank.vals, cond);
        } else {
          all_cretria.push({
            param: key,
            vals: cond,
          });
        }
      });
      if (rank.param) {
        all_cretria.push(rank);
      }
    } else {
      all_cretria = cretria;
    }
    preset.definition.conditions = _.clone(all_cretria);
  }

  preset.getCretriaToPreset = function () {
    return all_cretria;
  };
  preset.uploadPreset = function (id, draft) {
    if (draft) {
      preset.draft_or_new_preset = true;
    } else {
      preset.draft_or_new_preset = false;
    }
    var current_prest = dataModelService.findPinById(id);
    preset.definition = {};
    preset.name = current_prest.name;
    preset.id = current_prest.id;
    loadGroups(current_prest.definition.groups);
    loadEmployess(current_prest.definition.employees);
    loadCretria(current_prest.ui_definition.conditions, true);
    preset.calculateNumberOfEmployessChecked();
  };

  preset.isInNewOrDraftMode = function () {
    return preset.draft_or_new_preset;
  };

  preset.isCurrentPresetSelected = function (pid) {
    var res = false;
    if (preset.id) {
      if (preset.id === pid) {
        res = true;
      }
    }
    return res;
  };

  var isChangePresetDefinition  = function () {
    var res = false;
    if (preset.getCretriaToPreset().length !== preset.definition.conditions.length ||
        preset.getEmployeesToPreset().length !== preset.definition.employees.length ||
        preset.getGroupsToPreset().length !== preset.definition.groups.length) {
      res = true;
    }
    return res;
  };

  preset.saveDraftSucss = function () {
    preset.changePresetMode();
    overlayBlockerService.unblock();
    preset.getSystemAlert('Saving preset...', 'success');
  };

  preset.generateSucss = function () {
    preset.changePresetMode();
    overlayBlockerService.unblock();
    preset.getSystemAlert('Saving preset...', 'success');
  };

  preset.OnClicksSaveDraft = function () {
    dataModelService.createPreset(preset.name, preset.definition, preset.id, SAVED_AS_DRAFT).then(preset.saveDraftSucss);
  };

  preset.OnClickGeneratePin = function () {
    if (isChangePresetDefinition() || preset.isInNewOrDraftMode()) {
      dataModelService.createPreset(preset.name, preset.definition, preset.id, GENERATE).then(preset.generateSucss);
    } else {
      dataModelService.updatePinNameOnServer(preset);
      overlayBlockerService.unblock();
    }
  };


  preset.onClickDelete = function () {
    preset.closePresetPanel();
    overlayBlockerService.unblock();
    preset.getSystemAlert('Are you sure you want to delete this presert?', 'error', DELETE);
  };

  preset.CanDelete = function (delete_preset) {
    if (delete_preset) {
      if (preset.id) {
        dataModelService.deletePinOnServer(preset.id);
      }
    }
    preset.removeSetting();
    preset.show_alert_system = false;
    preset.show_delete_alert_modal = false;

  };

  preset.create = function (filter, employess_list) {
    preset.draft_or_new_preset = true;
    // preset.name = 'Preset name';
    preset.definition = {};
    var cretria = _.clone(filter.getFiltered());
    var groups = _.clone(filter.getFilterGroupIds());
    var employees = _.clone(employess_list);
    preset.id = undefined;
    loadGroups(groups);
    loadEmployess(employees);
    loadCretria(cretria);
    preset.calculateNumberOfEmployessChecked();
  };

  preset.isInEditPresetMode = function () {
    return edit_preset_open;
  };
  preset.changePresetMode = function () {
    edit_preset_open = !edit_preset_open;
  };
  preset.openPresetPanel = function () {
    edit_preset_open = true;
  };
  preset.closePresetPanel = function () {
    edit_preset_open = false;
  };
  preset.isGroupChecked = function (g_id) {
    return _.contains(preset.definition.groups, g_id);
  };
  preset.removeSetting = function () {
    preset.id = undefined;
  };
  preset.onClickFilterGroupChecbox = function (gid) {
    if (!_.contains(preset.definition.groups, gid)) {
      preset.definition.groups.push(gid);
      preset.calculateNumberOfEmployessChecked();
    }
  };
  preset.onRemoveFilterGroupChecbox = function (gid) {
    _.remove(preset.definition.groups, function (group) {
      return group === gid;
    });
    preset.calculateNumberOfEmployessChecked();
  };
  preset.isEmployeeChecked = function (emp) {
    return _.contains(preset.definition.employees, emp);
  };

  preset.onClickAddEmployee = function (emp) {
    if (!_.contains(preset.definition.employees, emp)) {
      preset.definition.employees.push(emp);
      preset.calculateNumberOfEmployessChecked();
    }
  };
  preset.onClickRemoveEmployee = function (emp) {
    _.remove(preset.definition.employees, function (emp_mail) {
      return emp_mail === emp;
    });
    preset.calculateNumberOfEmployessChecked();
  };
  preset.isFilterChecked = function (cond) {
    return _.contains(preset.definition.conditions, cond);
  };
  preset.onClickFilterChecbox = function (cond) {
    if (!_.contains(preset.definition.conditions, cond)) {
      preset.definition.conditions.push(cond);
      preset.calculateNumberOfEmployessChecked();
    }
  };
  preset.onRemoveFilterChecbox = function (cond) {
    _.remove(preset.definition.conditions, function (cretria) {
      return cretria === cond;
    });
    preset.calculateNumberOfEmployessChecked();
  };

  function cheackCretriaEmployeesNumber(emp) {
    if (preset.definition.conditions.length === 0) {
      return false;
    }
    var j = 0;
    var cretria_condition = [];
    _.each(preset.definition.conditions, function (condition_list) {
      if (!_.isEmpty(condition_list)) {
        cretria_condition[j] = false;
        _.each(condition_list.vals, function (condition) {
          if (emp[condition_list.param] === condition) {
            cretria_condition[j] = true;
          }
        });
        j += 1;
      }
    });
    var creatria_res = true;
    _.each(cretria_condition, function (cond_of_cretria) {
      creatria_res = creatria_res && cond_of_cretria;
    });
    return creatria_res;
  }

  preset.calculateNumberOfEmployessChecked = function () {
    var emp_list = [];
    dataModelService.getEmployees().then(function (employees) {
      _.each(employees, function (emp) {
        var i = 0;
        var add_to_list = false;
        var condition_list = [];
        condition_list[i] = false;
        if (_.include(preset.definition.groups, emp.group_id)) {
          condition_list[i] = true;
        }
        i += 1;
        condition_list[i] = false;
        if (_.include(preset.definition.employees, emp.email)) {
          condition_list[i] = true;
        }
        var creatria_res = cheackCretriaEmployeesNumber(emp);
        _.each(condition_list, function (condition_res) {
          add_to_list = add_to_list || condition_res;
        });
        if (add_to_list || creatria_res) {
          emp_list.push(emp);
        }
      });
      number_of_all_employee = emp_list.length;
    });
  };

  preset.getNumberOfAllEmployeesChecked = function () {
    return number_of_all_employee;
  };

  preset.selectAll = function () {
    _.each(all_groups, function (gid) {
      preset.onClickFilterGroupChecbox(gid);
    });
    _.each(all_cretria, function (cond) {
      preset.onClickFilterChecbox(cond);
    });
    _.each(all_employees, function (emp) {
      preset.onClickAddEmployee(emp);
    });
  };

  preset.unselectAll = function () {
    _.each(all_groups, function (gid) {
      preset.onRemoveFilterGroupChecbox(gid);
    });
    _.each(all_cretria, function (cond) {
      preset.onRemoveFilterChecbox(cond);
    });
    _.each(all_employees, function (emp) {
      preset.onClickRemoveEmployee(emp);
    });
  };


  preset.getSystemAlert = function (message, type, delete_alert) {
    preset.system_alert = {};
    preset.system_alert.type = type;
    preset.system_alert.message = message;
    preset.show_alert_system = true;
    if (!delete_alert) {
      $timeout(function () {
        preset.show_alert_system = false;
      }, 5000);
    } else {
      preset.show_delete_alert_modal = true;
    }
  };

  return preset;
});
