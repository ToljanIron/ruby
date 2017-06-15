/*global angular, JST, unused, window, document*/
angular.module('workships.directives').directive('tabsLevel', function () {
  'use strict';
  return {
    restrict: 'E',
    template: JST['v2/tabs_level'](),
    scope: {
      list: '=',
      selected: '=',
      displayKey: '=',
      topSelectedColor: '=',
      onClickFunc: '='
    },
    link: function (scope) {
      scope.product_type = window.__workships_bootstrap__.companies.product_type;
      scope.getSelectedStyle = function () {
        return ({'border-top': scope.topSelectedColor  + ' 3px solid'});
      };
      scope.getSeperatorWidth = function () {
        if (!angular.element(document.querySelectorAll(".levels-warrper"))[0]) { return; }
        var tabs_width = angular.element(document.querySelectorAll(".levels-warrper"))[0].clientWidth;
        if (!scope.list) { return; }
        var width = tabs_width + 4;
        return ({ width : 'calc(100% - ' + width + 'px)'});
      };
    }
  };
});
