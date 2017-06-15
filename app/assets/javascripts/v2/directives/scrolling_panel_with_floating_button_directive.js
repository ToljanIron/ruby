/*globals angular */

angular.module('workships.directives').directive('scrollingPanelWithFloatingButton',['tabService', function (tabService) {
  'use strict';

  return {
    transclude: true,
    scope: {
      toShow: '=',
      buttonOnClick: '=',
      classHide: '@',
      classShow: '@'
    },
    template: "<div class='left-panel-wrapper {{miniHeaderAdjustments()}}'>"+
              "<div class='add-criteria-button clickable shadow {{setClassName()}} ' ng-click='buttonOnClick()'>" +
                "<div class='float-left-content'>+</div>" +
                "<div class='float-left-content'>Add Criteria</div>" +
              "</div>" +
              "<scrolling-panel class='scroller-explore {{setClassName(true)}}'>" +
                "<ng-transclude></ng-transclude>" +
              "</scrolling-panel>" +
              "</div>",
    link: function (scope) {
      scope.setClassName = function (panel) {
        if (scope.toShow) {
          if (panel) {
            return scope.classShow;
          }
          return '';
        }
        return scope.classHide;
      };

      scope.miniHeaderAdjustments = function(){
        if (tabService.showMiniHeader){
          return 'criteria-small';
        }
        return '';
      } ;     
    }
  };
}]);