/*globals angular, JST */

angular.module('workships.directives').directive('observation', function () {

  'use strict';

  return {

    scope: {
      color: '=',
      picPath: '@',
      text:'@',
    },
    template: JST["v2/observation"](),

    link: function () {
    }
  };
});