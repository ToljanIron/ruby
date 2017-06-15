/*globals angular, document */

angular.module('workships-mobile.directives').directive('stretch', function ($timeout) {
  'use strict';

  return {
    link: function (scope, element) {
      var e = element[0];
      $timeout(function () {
        var questionnaire_headline = document.getElementsByClassName('header-wrapper')[0].offsetHeight;
        questionnaire_headline = questionnaire_headline + 21;
        e.style.height = 'calc(100vh - ' +  questionnaire_headline + 'px)';
      }, 0);
    }
  };

});