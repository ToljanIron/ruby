/*global angular, unused */

angular.module('workships.directives').directive('awesomeIf', [function () {
  'use strict';
  return {
    multiElement: true,
    transclude: 'element',
    priority: 600,
    terminal: true,
    restrict: 'A',
    $$tlb: true,
    link: function ($scope, $element, $attr, ctrlr, $transclude) {
      angular.noop(ctrlr);

      var block, childScope;
      function shouldReuseDom() {
        if (block) {
          return true;
        }

        return false;
      }

      function reuseDom() {
        if (childScope.restart) {
          childScope.restart();
        } else {
          childScope.$broadcast('restart', {});
        }
        $element.after(block.clone);
      }

      function removeButCacheDom() {
        block.clone[0].parentNode.removeChild(block.clone[0]);
        if (childScope.stop) {
          childScope.stop();
        } else {
          childScope.$broadcast('stop', {});
        }
      }

      function isDomCreated() {
        if (block) {
          return true;
        }

        return false;
      }

      function createDom() {
        $transclude(function (clone, newScope) {
          childScope = newScope;
          block = {
            clone: clone
          };

          $element.after(block.clone);
        });
      }

      $scope.$watch($attr.awesomeIf, function awesomeIfWatchAction(value) {
        if (value) {
          if (!childScope || block) {
            if (shouldReuseDom()) {
              reuseDom();
              return;
            }

            createDom();
          }
        } else {
          if (isDomCreated()) {
            removeButCacheDom();
          }
        }
      });
    }
  };
}]);