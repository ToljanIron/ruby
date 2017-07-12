/*globals angular, _, document, window, unused, console*/
angular.module('workships.services').factory('questionnaireService', function ($timeout) {
  'use strict';
  var questionnaire = {};
  questionnaire.setQuestionniareId = function (q_id) {
    questionnaire.id = q_id;
  };
  questionnaire.createFlash = function (text, status) {
    questionnaire.flash_text = text;
    questionnaire.status = status;
    questionnaire.show_flash = true;
    $timeout(function () {
      questionnaire.show_flash = false;
    }, 3500);
  };
  questionnaire.setQuestionnaire = function () {
    questionnaire.question = questionnaire;
  };
  questionnaire.qpname = '';
  questionnaire.eid = null;
  return questionnaire;
});