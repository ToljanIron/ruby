/*global angular, JST, $compile, unused */
/* istanbul ignore next */
angular.module('workships.directives').directive('questionnaireResendModal', function (overlayBlockerService, dataModelService, questionnaireService, $rootScope, $http) {
  'use strict';
  return {
    restrict: 'AE',
    template: JST['v2/resend_emp_modal'](),
    link: function (scope) {
      scope.title = 'resend questionnaire';
      scope.content = 'Are you sure you want to send the questionnaire to ' + questionnaireService.qpname + '?';
      
      scope.questionnaire_service = questionnaireService;
      scope.overlay_blocker_service = overlayBlockerService;

      scope.resendQuestionnaireToEmp = function (q_id, emp_id) {
        $http.post('questionnaire/resend_questionnaire_for_emp', { questionnaire_id: q_id, eid: emp_id }).then(function (res) {
          if (res.data === true) {
            console.log("Received true answer from server when trying to send email to emp");
            return;
            // scope.questionnaire_service.createFlash('Email will be sent within one hour', true); 
          }
          return;
          // return scope.questionnaire_service.createFlash('Email could not be sent. Please contact support', false);
        });
        overlayBlockerService.unblock();
      };

      scope.onSubmit = function () {
        scope.resendQuestionnaireToEmp(scope.questionnaire_service.id, questionnaireService.eid);
      };
    }
  };
});
