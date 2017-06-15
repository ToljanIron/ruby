/*globals angular */

angular.module('workships').controller('resendController', function ($scope, overlayBlockerService, dataModelService, questionnaireService) {
  'use strict';

  $scope.init = function () {
    $scope.questionnaire_service = questionnaireService;
    $scope.overlay_blocker_service = overlayBlockerService;
  };
  $scope.resendAll = function (q_id) {
    console.log("******************&*&*&*");
    dataModelService.resendAllQuestionnaire(q_id).then(function (data) {
      if (data === true) { return $scope.questionnaire_service.createFlash('Emails will be sent within one hour', true); }
      return $scope.questionnaire_service.createFlash('Emails could not be sent. Please contact support', false);
    });
    overlayBlockerService.unblock();
  };
});
