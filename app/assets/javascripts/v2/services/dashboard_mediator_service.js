/*globals angular*/

angular.module('workships.services').factory('dashboradMediator', function (dataModelService) {
  'use strict';
  var selected = {};
  var first_time = true;
  selected.init = function (id) {
    selected.type = 'group';
    selected.id = id;
    dataModelService.getGroupOrIndividualView().then(function (group_view) {
      selected.group_overoll_state = group_view;
    });
    selected.show_metrics = 0;
    first_time = false;
  };
  // selected.setGroupOrIndividual
  selected.setSelected = function (id, type) {
    selected.type = type;
    selected.id = id;
  };
  selected.inFirstTime = function () {
    return first_time;
  };

  return selected;
});
