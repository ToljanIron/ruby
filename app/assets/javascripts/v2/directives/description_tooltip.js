/*globals angular, unused,  JST */

angular.module('workships.directives').directive('descriptionTooltip', function () {

  'use strict';

  return {

    scope: {
      text: '=',
    },
    template: JST["v2/description_tooltip"](),

    link: function (scope) {
      unused(scope);
    }
  };
});