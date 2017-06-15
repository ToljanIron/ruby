/*globals angular*/

angular.module('workships.services').factory('sidebarMediator', function () {
  'use strict';
  var sidebar = {};
  sidebar.init = function (state) {
    sidebar.should_show_sidebar = state;
    sidebar.show_personal_card  = false;
    sidebar.change_to_employee_page = false;
    sidebar.state_before_employee_card = sidebar.should_show_sidebar;
  };
  sidebar.setSelected = function (state) {
    sidebar.should_show_sidebar = state;
  };
  return sidebar;
});
