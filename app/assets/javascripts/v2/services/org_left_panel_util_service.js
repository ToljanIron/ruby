/*globals angular*/

angular.module('workships.services').factory('OrgLeftPanelUtilService', function () {
  'use strict';
  var org = {};
  var EXPLORE_PANEL = 2;
  var MAIN_PANEL = 1;
  org.showCheckbox = function (func, page) {
    return (func && page.id === EXPLORE_PANEL);
  };
  org.leaveHover = function (hover, group) {
    hover[group.group_id] = false;
  };
  org.inHover = function (hover, group) {
    hover[group.group_id] = true;
  };
  org.isSelected = function (selected, group, page) {
    return (group.group_id === selected.id && selected.type === 'group' && page.id === MAIN_PANEL);
  };
  org.isExploreSelected = function (selected, group, page) {
    return (group.group_id === selected.id && selected.type === 'group' && page.id === EXPLORE_PANEL);
  };
  org.displayDrillDown = function (hover, group, selected) {
    return (hover[group.group_id] || selected.id === group.group_id);
  };
  return org;
});
