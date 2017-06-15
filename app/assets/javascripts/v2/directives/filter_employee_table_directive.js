/*globals angular, JST, _ */

angular.module('workships.directives').directive('filterEmployeeTable', function (dataModelService, questionnaireService, StateService) {
  'use strict';
  return {
    replace: true,
    scope: {
      employees: '=',
      resend: '&',
      resendAll: '&',
      freeze: '&',
      qId: '=',
      freezeState: '='
    },
    template: JST['v2/filter_employee_table'](),
    link: function (scope) {
      scope.state = StateService;
      function selectedGroups(group_id) {
        if (!group_id) { group_id = scope.state.get("Settings_selected"); }
        return _.union(_.find(scope.groups, {id: group_id}).child_groups, [group_id]);
      }
      function setGroups(res) {
        scope.groups = res;
        scope.selected_groups = selectedGroups();
      }
      dataModelService.getGroups().then(setGroups);
      scope.filtered_employees = _.cloneDeep(scope.employees);
      scope.questionnaire_service = questionnaireService;
      scope.title = 'All';
      scope.data_model = dataModelService;
      scope.search_input = '';
      scope.page_size = 100;
      scope.maxSize = 5;
      scope.current_page = 1;

      scope.onResendAll = function () {
        scope.resendAll({q_id: scope.qId});
      };

      scope.onFreezeQuestionnaire = function () {
        scope.freeze();
      };

      scope.onResendEmp = function (qp) {
        scope.resend({q_id: scope.qId, qp: qp});
      };

      function filterEmployeesByStatus(status) {
        scope.status = status;
      }

      scope.fetchNodeNames = function () {
        var names, role_types;
        names = [];
        role_types = [];
        _.each(scope.employees, function (e) {
          var emp = scope.data_model.getEmployeeById(e.employee_id);
          if (!_.include(selectedGroups(), emp.group_id)) { return; }
          names.push({ name: emp.first_name + ' ' + emp.last_name });
          if (!_.any(role_types, { name: emp.role_type })) {
            if (!emp.role_type) { return; }
            role_types.push({ name: emp.role_type });
          }
        });
        return _.union(names, role_types);
      };

      scope.setSearch = function () {
        scope.search = _.cloneDeep(scope.search_input);
      };


      scope.clearSearch = function () {
        scope.search_input = '';
        scope.search = null;
        return;
      };

      scope.statuses = [{
        name: 'All',
        onClick: function () {
          scope.title = 'All';
          filterEmployeesByStatus('');
        }
      }, {
        name: 'In progress',
        onClick: function () {
          scope.title = 'In progress';
          filterEmployeesByStatus('in_process');
        }
      }, {
        name: 'Not started',
        onClick: function () {
          scope.title = 'Not started';
          filterEmployeesByStatus('notstarted');
        }
      }, {
        name: 'Completed',
        onClick: function () {
          scope.title = 'Completed';
          filterEmployeesByStatus('completed');
        }
      }];

      function searchEmptyCheckStatus(search, status, qp) {
        return !search && (!status || qp.status === status);
      }

      function statusEmptyCheckSearch(search, status, emp) {
        return !status && (search && ((emp.first_name === search.split(' ')[0] && emp.last_name === search.split(' ')[1]) || emp.role_type === search));
      }

      function checkStatusAndSearch(search, status, qp, emp) {
        return status && qp.status === status && (search && ((emp.first_name === search.split(' ')[0] && emp.last_name === search.split(' ')[1]) || emp.role_type === search));
      }

      scope.$watch('employees', function (v) {
        scope.filtered_employees = _.cloneDeep(_.filter(v, function (qp) {
          var emp = scope.data_model.getEmployeeById(qp.employee_id);
          return _.include(selectedGroups(scope.group_id), emp.group_id);
        }));
        scope.current_page = 1;
        scope.total_items = scope.filtered_employees.length;
      });
      scope.$watch('[status, search, state.get("Settings_selected")]', function (v, oldV) {
        if (v === oldV) { return; }
        var status, search, group_id;
        status = v[0];
        search = v[1];
        group_id = v[2];
        scope.filtered_employees = _.filter(scope.employees, function (qp) {
          var emp = scope.data_model.getEmployeeById(qp.employee_id);
          if (!search && !status) { return _.include(selectedGroups(group_id), emp.group_id); }
          return (searchEmptyCheckStatus(search, status, qp) ||
                           statusEmptyCheckSearch(search, status, emp) ||
                           checkStatusAndSearch(search, status, qp, emp)) && _.include(selectedGroups(group_id), emp.group_id);
        });
        scope.current_page = 1;
        scope.total_items = scope.filtered_employees.length;
      });
    }
  };
});
