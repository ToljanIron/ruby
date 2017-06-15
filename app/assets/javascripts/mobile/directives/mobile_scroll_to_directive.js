/*globals angular, unused, localStorage, _, $, document */
angular.module('workships-mobile.directives').directive('mobileScrollToDirective', function ($document) {
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
            var ele = angular.element(document.getElementsByTagName('body')[0]);
            $document.scrollTop(-current_body_top + from_top - (scope.offsetScroll / 1 || 0), 1000).then(function () {
              console && console.log('.');
            });
          }
        }
      }, true);
    }

  };
});