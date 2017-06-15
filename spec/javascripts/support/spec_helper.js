/*globals document, window, angular, _ */

function init_spec_helper(version) {
  'use strict';
  var meta = document.createElement("META");
  meta.setAttribute('name', 'csrf-token');
  meta.setAttribute('content', 'csrf');

  (function mock_JST() {
    window.JST = {};
    var jsts_paths = [
      version + '/analyze_main',
      version + '/analyze_sidebar',
      version + '/directory_sidebar',
      version + '/directory_main',
      version + '/dashboard_main',
      version + '/dashboard_sidebar',
      version + '/groups_widget',
      version + '/footer',
      version + '/header',
      version + '/graph',
      version + '/view_analyze',
      version + '/view_pin_editor',
      version + '/view_tip',
      version + '/pins',
      version + '/floating_status_bar',
      version + '/analyze_sidebar_criteria',
      version + '/employee_personal_card',
      version + '/employee_card',
      version + '/bars',
      version + '/setting_main',
      version + '/setting_sidebar',
      version + '/graph_header',
      version + '/group_card',
      version + '/presets_widget',
      version + '/edit_preset',
      version + '/new_graph_main',
      version + '/new_graph_sidebar',
      version + '/workflow',
      version + '/top_talent',
      version + '/productivity',
      version + '/collaboration',
      version + '/explore',
      version + '/directory',
      version + '/settings',
      version + '/explore_setting',
      version + '/left_dashboard_panel',
      version + '/left_explore_panel',
      version + '/update_filter_menu',
      version + '/blood_test',
      version + '/observation',
      version + '/date_picker',
      version + '/page_unavailable',
      version + '/questionnaire_managmnet_view',
      version + '/resend_all_modal',
      version + '/questionnaire_dropdown_directive',
      version + '/filter_employee_table',
      version + '/choose_layer_filter'
    ];
    var mock_jst_template = function (path) {
      window.JST[path] = function () { return; };
    };
    _.each(jsts_paths, mock_jst_template);
  }());

  document.head.appendChild(meta);
  window.karma_running = true;

  window.mockController = function (controller_name) {
    var scope, controller, module;

    module = angular.mock.module('workships');
    angular.mock.inject(function ($rootScope, $controller) {
      scope = $rootScope.$new();
      controller = $controller(controller_name, {
        $scope: scope,
        $element : angular.element('<div></div>')
      });
    });
    return {
      module: module,
      controller: controller,
      scope: scope,
    };
  };
}
