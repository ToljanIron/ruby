/*globals angular , window, unused, _, console  */
angular.module('workships').controller('SettingsController', function ($scope, dataModelService, tabService, questionnaireService, ajaxService, overlayBlockerService, $timeout, $rootScope, StateService) {
  'use strict';

  var SUBMIT_MESSAGE = 'Submitting the questionnaire data and performing the calculations needed to display the data in the explore and collaborations tabs may take serval minutes. Continue?';

  $scope.not_started = "Haven't Started";
  var getDate = function (date) {
    var d = date.slice(0, 10).split('-');
    return d[2] + '/' + d[1] + '/' + d[0];
  };

  $scope.goToQuestionnaireManagment = function (questionnaire) {
    $scope.questionnaire_table = true;
    $scope.q = _.cloneDeep(questionnaire);
    $scope.q.created_at = $scope.q.created_at.split(' ')[1];
    $scope.q.updated_at = $scope.q.updated_at.split('T')[0].split('-').reverse().join('/');
    if ($scope.q.last_submitted) {
      $scope.q.last_submitted = $scope.q.last_submitted.split('T')[0].split('-').reverse().join('/');
    }
  };

  $scope.backToQuestionnaire = function () {
    StateService.set({ name: 'settings_tab', value: 1 });
    $scope.questionnaire_table = false;
    $scope.selected_questionnaire = null;
  };

  function setQuestionnaireParticipantsByQuestionnaire(questionnaire_participants_array) {
    $scope.questionnaire_participants_array = questionnaire_participants_array;
    _.each($scope.questionnaire_participants_array, function (q) {
      _.each(q.participants_employees, function (e) {
        if (!e.last_action) { return; }
        var date_array = e.last_action.split('T');
        e.last_action = date_array[0].toString() + ' ' + date_array[1].split('.')[0].split(':').splice(0, 2).join(':').toString();
      });
      $scope.by_questionnaire[q.q_id] = q;
    });
  }

  function setQuestionnaires(questionnaires) {
    $scope.questionnaires = questionnaires;
    _.each($scope.questionnaires, function (quest) {
      if (quest.questionnaire.state === 'notstarted') {
        quest.questionnaire.state = 'not started';
      }
      quest.questionnaire.created_at = 'Created' + ' ' + getDate(quest.questionnaire.created_at);
      if (quest.questionnaire.sent_date) {
        quest.questionnaire.sent_date = getDate(quest.questionnaire.sent_date);
      }
      if (quest.questionnaire.completed_at) {
        quest.questionnaire.completed_at = '- ' + getDate(quest.questionnaire.completed_at);
      }
    });
  }

  var callTimes = 0;
  var inFreezQuestionnaireState = false;
  $scope.freezeQuestionnaire = function() {
    if ( confirm(SUBMIT_MESSAGE) ) {
      dataModelService.freezQuestionnaire();
      inFreezQuestionnaireState = true;
      getFreezeState();
    }
  };

  var getFreezeState = function() {
    if ( !inFreezQuestionnaireState ) {
      $scope.freezeState = 'Submit';
      return;
    }

    callTimes += 1;
    dataModelService.getFreezQuestionnaireStatus().then(function(state) {
      if (state === 'completed') {
        $scope.freezeState = 'Completed';
        inFreezQuestionnaireState = false;
      } else {
        $scope.freezeState = 'Running ..';
      }

      if (state !== 'completed' && callTimes < 100) {
        setTimeout(getFreezeState, 10000);
      }
      if(!$scope.$$phase) {
        $scope.$apply();
      }
    });
  }

  $scope.init = function () {
    $scope.by_questionnaire = {};
    $scope.questionnaire_service = questionnaireService;
    $scope.questionnaire_table = false;
    $scope.tabService = tabService;
    $scope.product_type = window.__workships_bootstrap__.companies.product_type;
    tabService.setSubTab('Settings', 0);
    $scope.data_model = dataModelService;
    dataModelService.getQuestionnaireParticipantsByQuestionnaire().then(setQuestionnaireParticipantsByQuestionnaire).then(dataModelService.getQuestionnaires).then(setQuestionnaires);
    getFreezeState();
  };
  $scope.$on('submit result', function () {
    $scope.submit();
  });

  $scope.isQuestionnaireOnly = function() {
    return true;
    //return ($scope.product_type === 'questionnaire_only');
  };

  $scope.submit = function () {
    var last_submitted = _.cloneDeep($scope.q.last_submitted);
    $scope.q.last_submitted = 'Submitting';
    var dots = 0;
    var loading = setInterval(function () {
      $scope.$apply(function () {
        if (dots < 3) {
          $scope.q.last_submitted += '.';
          dots += 1;
        } else {
          $scope.q.last_submitted = $scope.q.last_submitted.replace('...', '');
          dots = 0;
        }
      });
    }, 200);
    ajaxService.getPromise('get', 'questionnaire/capture_snapshot', { questionnaire_id: $scope.q.id }).then(function (res) {
      clearInterval(loading);
      $scope.q.last_submitted = '  ';
      $timeout(function () {
        $scope.q.last_submitted = res.data.last_submitted.split('T')[0].split('-').reverse().join('/');
      }, 150);
      dataModelService.getQuestionnaires(true).then(setQuestionnaires);
    }, function (res) {
      clearInterval(loading);
      $scope.q.last_submitted = '  ';
      $timeout(function () {
        $scope.q.last_submitted = last_submitted;
      }, 150);
      console.log('error', res.data.error);
    });
  };

  $scope.toggleUpdateFilterMenu = function (modal_name) {
    if (!overlayBlockerService.isElemDisplayed(modal_name)) {
      overlayBlockerService.block(modal_name);
    } else {
      overlayBlockerService.unblock();
    }
  };
  $scope.showUpdateFilterMenu = function () {
    return overlayBlockerService.isElemDisplayed(modal_name);
  };

  $scope.openSubmitResult = function () {
    questionnaireService.setQuestionnaire($scope.q);
    $scope.toggleUpdateFilterMenu('submit_results_modal');
  };

  $scope.openResendModal = function (q_id, qp) {
    questionnaireService.setQuestionniareId(q_id);
    if (!qp) {
      $scope.toggleUpdateFilterMenu('resend_all_modal');
    } else {
      var emp = dataModelService.getEmployeeById(qp.employee_id);
      questionnaireService.qpname = emp.first_name + ' ' + emp.last_name;
      questionnaireService.eid = qp.employee_id;
      $scope.toggleUpdateFilterMenu('resend_emp_modal');
    }
  };

  $scope.get_employees_for_questionnaire = function (q) {
    StateService.set({ name: 'settings_tab', value: 2 });
    var questionnaire_data = $scope.by_questionnaire[q.id];
    if (questionnaire_data) { $scope.questionnaire_participant = questionnaire_data; }
    $scope.questionnaire_participant.participants_employees = _.sortBy($scope.questionnaire_participant.participants_employees, function (qp) {
      var emp = dataModelService.getEmployeeById(qp.employee_id);
      return emp.first_name + emp.last_name;
    });
    $scope.goToQuestionnaireManagment(q);
  };
});

