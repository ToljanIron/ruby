/*global angular, JST, $compile, unused */
/* istanbul ignore next */
angular.module('workships.directives').directive('graphSidebar', function ($timeout) {
  'use strict';
  return {
    restrict: 'AE',
    template: JST['v2/analyze_sidebar'](),
    link: function (scope, elem) {
      var click_add_event, click_update_event, add_filter, update_filter; //, origin_width;
      var addFilterClick = function () {
        angular.element(elem)[0].scrollTop = 0;
        angular.element(elem)[0].style.width = '700px';
      };
      var updateFilterClick = function () {
        angular.element(elem)[0].style.width = '300px';
      };

      $timeout(function () {
        add_filter = angular.element(elem)[0].getElementsByClassName('workships_button_left')[0];
        update_filter = angular.element(elem)[0].getElementsByClassName('update-filter')[0];
        click_add_event = add_filter.addEventListener("click", addFilterClick);
        click_update_event = update_filter.addEventListener("click", updateFilterClick);
      });

      scope.$on('$destroy', function () {
        add_filter.removeEventListener(click_add_event, "click", addFilterClick);
        update_filter.removeEventListener(click_update_event, "click", updateFilterClick);
      });
    }
  };
});
