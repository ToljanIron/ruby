/*global angular, JST, $compile, unused */
angular.module('workships.directives').directive('dashboardInsight', function (dataModelService, StateService, tabService, dashboradMediator) {
  'use strict';
  return {
    restrict: 'E',
    template: JST["v2/dashboard_insight"](),
    scope: {
      goodMeasure: '=',
      score: '=',
      linkToTab: '=',
      groupId: '=',
      algorithmName: '=',
      blockSize: '=',
      mainTabName: '=',
      subTabId: '='
    },
    link: function (scope) {
      scope.score = Math.ceil(scope.score / scope.blockSize);
      scope.score = Math.max(scope.score, 1);

      if (scope.goodMeasure) {
        scope.score < 3 ? scope.descWord = 'High' : scope.descWord = 'Very high';
      } else {
        scope.score > 2 ? scope.descWord = 'Very low' : scope.descWord = 'Low';
      }
      var dm = dataModelService;
      dm.getGroups().then(function (res) {
        scope.group_name = _.find(res, function (g) {
          return g.id === scope.groupId;
        });
        scope.group_name = scope.group_name.name;
      });
      // scope.jumpToTab = function (tab, group_id) {

      // };
      scope.jumpToTab = function () {
        dashboradMediator.setSelected(scope.groupId, 'group');
        dashboradMediator.jump_to_state = true;
        tabService.setSubTab(scope.mainTabName, scope.subTabId);
        tabService.saveTabState(scope.mainTabName);
        tabService.selectTab(scope.mainTabName);
      };
    }
  };
});
