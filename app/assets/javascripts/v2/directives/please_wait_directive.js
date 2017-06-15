/*globals angular */
angular.module('workships.directives').directive('pleaseWait', function (pleaseWaitService) {
  'use strict';
  return {
    replace: true,
    template: "<div ng-class='{\"show\": pleaseWaitService.enabled()}' class='please-wait-overlay'><div class='spinner'></div></div>",
    link: function (scope) {
      scope.pleaseWaitService = pleaseWaitService;
    }
  };
});