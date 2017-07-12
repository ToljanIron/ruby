/*global angular, JST, $compile, unused */
/* istanbul ignore next */
angular.module('workships.directives').directive('questionnaireResetModal', function (overlayBlockerService, dataModelService, questionnaireService, $rootScope, $http) {
  'use strict';
  return {
    restrict: 'AE',
    template: JST['v2/reset_emp_quest_modal'](),
    link: function (scope) {
      
      scope.title = 'reset questionnaire for employee';
      scope.content = 'You are about to reset the questionnaire for ' + questionnaireService.qpname +'. All of his answers will be deleted. Continue?';

      scope.questionnaire_service = questionnaireService;
      scope.overlay_blocker_service = overlayBlockerService;

      scope.resetQuestionnaireForEmp = function (q_id, emp_id) {
        $http.post('questionnaire/reset_questionnaire_for_emp', { questionnaire_id: q_id, eid: emp_id }).then(function (res) {
          if (res.data === true) {
            console.log("Received true answer from server when trying to reset questionnaire for emp");
            return;
          }
          return;
        });
        overlayBlockerService.unblock();
      };

      scope.onSubmit = function () {
        scope.resetQuestionnaireForEmp(scope.questionnaire_service.id, questionnaireService.eid);
      };
    }
  };
});
