/*global angular, document, unused */
angular.module('workships.directives').directive('scrollToDirective', function () {
  'use strict';
  return {
    scope: {
      scrollId: '@',
      currentScroll: '@',
      offsetScroll: '@'
    },
    link: function (scope, elem) {
      scope.$watch('currentScroll', function (new_val) {
        if (scope.scrollId === new_val) {
          var from_top = elem[0].getBoundingClientRect().top;
          var current_body_top = document.getElementsByTagName('body')[0].getBoundingClientRect().top;
          if (from_top) {
            document.getElementsByTagName('body')[0].scrollTop = -current_body_top + from_top - (parseInt(scope.offsetScroll, 10) || 0);
          }
        }
      }, true);
    }

  };
});
