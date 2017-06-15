/*global angular, JST, $compile, unused */
angular.module('workships.directives').directive('statisticsCard', function (tabService, ajaxService) {
  'use strict';
  return {
    restrict: 'E',
    transclude: true,
    template: JST['v2/statistics_card'](),
    scope: {
      details: '='
    },
    link: function postLink(scope, elem, attr) {

      unused(elem);
      unused(attr);
      scope.goToLink = function () {
        if (tabService.current_tab === 'Dashboard') {
          if (scope.details.link_to) {
            scope.showToolTip = false;
            tabService.selectTab(scope.details.link_to);
          }
        }
      };
        scope.isLink = function(){
            if(scope.details){
                return !!scope.details.link_to;
            }
        }
      scope.tabService = tabService;
    },
  };
});
