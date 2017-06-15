/*global angular, JST, $compile, unused */
angular.module('workships.directives').directive('groupDirective', function ($timeout) {
  'use strict';
  return {
    restrict: 'E',
    transclude: true,
    template: JST['v2/group'](),
    scope: {
      group: '=',
      stylecolor: '@',
      selectedInExplore: '='
    },
    link: function (scope, iElement, iAttrs) {
      scope.imphsize = function () {
        return { 'font-weight': '600','margin-left': '2px'};
      };
      scope.deimphsize = function () {
        return { 'font-weight': '400','margin-left': '2px'};
      };

      /** TODO: Removed inorder to reduce CPU overload. those watches are called hunders of times **/
      // scope.$watch(
      //   function () {
      //     return scope.group.selected;
      //   },
      //   function (newValue, oldValue) {
      //     console.log('group');
      //     scope.bolden_line = scope.deimphsize();
      //     if (newValue === true || newValue === 'true') {
      //       scope.bolden_line = scope.imphsize();
      //     }
      //   }
      // );
      // scope.$watch(
      //   function () {
      //     return document.getElementById('scroller').scrollHeight;
      //   },
      //   function (newValue, oldValue) {
      //     console.log('scroller');
      //     $(document).ready(function () {
      //       $timeout(function () {
      //         if (document.getElementById('scroller').scrollHeight > 1000) {
      //           scope.moveElipsToLeft = true;
      //         }
      //         if (document.getElementById('scroller').scrollHeight <= 1000) {
      //           scope.moveElipsToLeft = false;
      //         }
      //       }, 100);
      //     });
      //   }
      // );
    }
  };
});
