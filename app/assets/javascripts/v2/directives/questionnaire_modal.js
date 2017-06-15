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
      var RESEND_EMP = 0;
      var RESEND_ALL = 1;
      var SUBMIT_RESULT = 2;
      if (scope.type === RESEND_ALL) {
        scope.title = 'resend all';
        scope.content = 'Are you sure you want to resend to all employees that have not completed the questionnaire ?';
      } else if (scope.type === RESEND_EMP) {
        scope.title = 'resend to';
        scope.content = 'Are you sure you want to send the questionnaire to ' + questionnaireService.qpname + '?';
      } else if (scope.type === SUBMIT_RESULT) {
        scope.title = 'submit results';
        scope.content = 'The questionnaire data will be added to the explore tab and metric calculations, Continue? ';
      }
      scope.questionnaire_service = questionnaireService;
      scope.overlay_blocker_service = overlayBlockerService;
      scope.resendAll = function (q_id) {
        dataModelService.resendAllQuestionnaire(q_id).then(function (data) {
          if (data === true) { return scope.questionnaire_service.createFlash('Emails will be sent within one hour', true); }
          return scope.questionnaire_service.createFlash('Emails could not be sent. Please contact support', false);
        });
        overlayBlockerService.unblock();
      };
      scope.resendEmpById = function () {
        $http.post('questionnaire/send_questionnaire_per_employee', { eid: questionnaireService.eid, questionnaire_id: questionnaireService.id }).then(function (res) {
          if (res.data === true) {
            return;
            // scope.questionnaire_service.createFlash('Email will be sent within one hour', true); 
          }
          return;
          // return scope.questionnaire_service.createFlash('Email could not be sent. Please contact support', false);
        });
        overlayBlockerService.unblock();
      };
      scope.onSubmit = function () {
        if (scope.type ===  RESEND_ALL) {
          scope.resendAll(scope.questionnaire_service.id);
        } else if (scope.type === RESEND_EMP) {
          scope.resendEmpById();
        } else if (scope.type ===  SUBMIT_RESULT) {
          scope.submit();
        }
      };
      scope.submit = function () {
        $rootScope.$broadcast('submit result');
        overlayBlockerService.unblock();
      };
    }
  };
});
