/*global angular, JST, $compile, unused */
/* istanbul ignore next */
angular.module('workships.directives').directive('questionnaireModal', function (overlayBlockerService, dataModelService, questionnaireService, $rootScope, $http) {
  'use strict';
  return {
    restrict: 'AE',
    template: JST['v2/resend_all_modal'](),
    scope: {
      type: '='
    },
    link: function (scope) {
      scope.title = 'resend questionnaire to all employees';
      scope.content = 'Are you sure you want to resend to all employees who did not complete the questionnaire ?';
      
      // var RESEND_EMP = 0;
      // var RESEND_ALL = 1;
      // var SUBMIT_RESULT = 2;
      // var RESET_EMP = 3;
      // if (scope.type === RESEND_ALL) {
      //   scope.title = 'resend questionnaire to all employees';
      //   scope.content = 'Are you sure you want to resend to all employees that have not completed the questionnaire ?';
      // } else if (scope.type === RESEND_EMP) {
      //   scope.title = 'resend questionnaire';
      //   scope.content = 'Are you sure you want to send the questionnaire to ' + questionnaireService.qpname + '?';
      // } else if (scope.type === SUBMIT_RESULT) {
      //   scope.title = 'submit results';
      //   scope.content = 'The questionnaire data will be added to the explore tab and metric calculations, Continue? ';
      // } else if (scope.type === RESET_EMP) {
      //   scope.title = 'reset questionnaire for employee';
      //   scope.content = 'You are about to reset the questionnaire for this employee. All of his answers will be deleted. Continue?';
      // }
      
      scope.questionnaire_service = questionnaireService;
      scope.overlay_blocker_service = overlayBlockerService;

      scope.resendQuestionnaireToAll = function (q_id) {
        dataModelService.resendAllQuestionnaire(q_id).then(function (data) {
          if (data === true) { return scope.questionnaire_service.createFlash('Emails will be sent within one hour', true); }
          return scope.questionnaire_service.createFlash('Emails could not be sent. Please contact support', false);
        });
        overlayBlockerService.unblock();
      };

      // scope.resendQuestionnaireToEmp = function (q_id, emp_id) {
      //   $http.post('questionnaire/send_questionnaire_per_employee', { questionnaire_id: q_id, eid: emp_id }).then(function (res) {
      //     if (res.data === true) {
      //       console.log("Received true answer from server when trying to send email to emp");
      //       return;
      //       // scope.questionnaire_service.createFlash('Email will be sent within one hour', true); 
      //     }
      //     return;
      //     // return scope.questionnaire_service.createFlash('Email could not be sent. Please contact support', false);
      //   });
      //   overlayBlockerService.unblock();
      // };

      scope.onSubmit = function () {
        scope.resendQuestionnaireToAll(scope.questionnaire_service.id);
        // if (scope.type ===  RESEND_ALL) {
        //   scope.resendQuestionnaireToAll(scope.questionnaire_service.id);
        // } else if (scope.type === RESEND_EMP) {
        //   scope.resendQuestionnaireToEmp(scope.questionnaire_service.id, questionnaireService.eid);
        // } else if (scope.type ===  SUBMIT_RESULT) {
        //   scope.submit();
        // } else if (scope.type ===  RESET_EMP_QUES){
        // }
      };

      scope.submit = function () {
        $rootScope.$broadcast('submit result');
        overlayBlockerService.unblock();
      };
    }
  };
});
