/*globals angular, _, window, unused */
angular.module('workships-mobile').controller('companiesDataController', function ($scope, $http) {
  'use strict';

  function initTabs(selected_tab) {
    $scope.EMPLOYEES_TAB = 1;
    $scope.QUESTIONS_TAB = 2;
    $scope.QUESTIONIRE_TAB = 3;
    $scope.curr_tab = selected_tab;
  }

  function initEditModes(e, q, t) {
    var i;
    $scope.employee_in_edit_state = [];
    $scope.employee_in_delete_state = [];
    for (i = 0; i < e; i++) {
      $scope.employee_in_edit_state[i] = false;
      $scope.employee_in_delete_state[i] = false;
    }
    $scope.question_in_edit_state = [];
    $scope.question_in_delete_state = [];
    for (i = 0; i < q; i++) {
      $scope.question_in_edit_state[i] = false;
      $scope.question_in_delete_state[i] = false;

    }
    $scope.tests_in_edit_state = [];
    for (i = 0; i < t; i++) {
      //$scope.test_in_edit_state[i] = false;
    }
  }
  function initActive(employees, questions) {
    _.each(employees, function (emp) {
      if (emp.active === true) { $scope.active_employees.push(emp.questionnaire_participant_id); }
    });
    _.each(questions, function (emp) {
      if (emp.active === true) { $scope.active_questions.push(emp.questionnaire_question_id); }
    });
  }

  $scope.init = function (employees_count, qustions_count, tests_count, selected_tab, employees, questions, current_question) {
    initTabs(selected_tab);
    $scope.active_employees = [];
    $scope.active_questions = [];
    $scope.current_question = current_question;
    initActive(employees, questions);
    initEditModes(employees_count, qustions_count, tests_count);
  };

  $scope.changeTab = function (i) {
    $scope.curr_tab = i;
  };

  $scope.updateActiveList = function (emp_p_id) {
    var index;
    if (_.include($scope.active_employees, emp_p_id)) {
      index = _.indexOf($scope.active_employees, emp_p_id);
      $scope.active_employees.splice(index, 1);
    } else {
      $scope.active_employees.push(emp_p_id);
    }
  };

  $scope.updateActiveList = function (emp_p_id) {
    var index;
    if (_.include($scope.active_employees, emp_p_id)) {
      index = _.indexOf($scope.active_employees, emp_p_id);
      $scope.active_employees.splice(index, 1);
    } else {
      $scope.active_employees.push(emp_p_id);
    }
  };

  $scope.isQuestionnaireSent = function () {
    return $scope.current_question.state === 'notstarted';
  };

  $scope.isEmployeeActive = function (emp_p_id) {
    return (_.include($scope.active_employees, emp_p_id));
  };


  $scope.updateActiveEmployees = function (questionnaire_id) {
    window.location = "question/active_employess?questionnaire_id=" + questionnaire_id + "&emps_arr=" + JSON.stringify($scope.active_employees);
  };

  $scope.toggleEmployeeEditState = function (i) {
    $scope.employee_in_edit_state[i] = !$scope.employee_in_edit_state[i];
  };
  $scope.toggleEmployeeDeleteState = function (i) {
    $scope.employee_in_delete_state[i] = !$scope.employee_in_delete_state[i];
  };

  $scope.toggleQuestionEditState = function (i) {
    $scope.question_in_edit_state[i] = !$scope.question_in_edit_state[i];
  };
  $scope.toggleQuestionDeleteState = function (i) {
    $scope.question_in_delete_state[i] = !$scope.question_in_delete_state[i];
  };

});