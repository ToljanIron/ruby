/*globals angular, document, JST, window */

angular.module('workships').config(['$httpProvider', '$compileProvider', function ($httpProvider, $compileProvider) {
  'use strict';
  $compileProvider.debugInfoEnabled(false);
  var csrf_token = document.getElementsByName('csrf-token')[0].content;
  $httpProvider.defaults.headers.post['X-CSRF-Token'] = csrf_token;
  $httpProvider.defaults.headers.put['X-CSRF-Token'] = csrf_token;
  $httpProvider.defaults.headers.patch['X-CSRF-Token'] = csrf_token;

}]);

angular.element(document).ready(function () {
  'use strict';
  angular.bootstrap(document, ['workships']);
});

window.unused = function () {
  'use strict';
  return undefined;
};

angular.module('workships').run(function ($templateCache, $window, $rootScope, $timeout, initializeAppState) {
  'use strict';
  /* istanbul ignore next */
  angular.element($window).bind('resize', function () {
    $rootScope.$broadcast('resize');
  });
  /* istanbul ignore next */
  $timeout(function () {
    $rootScope.$broadcast('resize');
  }, 1500);
  /* istanbul ignore next */
  angular.element($window).bind('$locationChangeSuccess', function () {
    $rootScope.$broadcast('resize');
  });

  initializeAppState.initialize();

  //MAIN TABS V2
  $templateCache.put('dashboard_main',            JST['v2/dashboard_main']());
  $templateCache.put('workflow',                  JST['v2/workflow']());
  $templateCache.put('top_talent',                JST['v2/top_talent']());
  $templateCache.put('productivity',              JST['v2/productivity']());
  $templateCache.put('collaboration',             JST['v2/collaboration']());
  $templateCache.put('explore',                   JST['v2/explore']());
  $templateCache.put('directory_main',            JST['v2/directory_main']());
  $templateCache.put('settings',                  JST['v2/settings']());
  $templateCache.put('explore_setting',           JST['v2/explore_setting']());

  //OTHER TEMPLATES V2
  $templateCache.put('update_filter_menu',        JST['v2/update_filter_menu']());
  $templateCache.put('resend_all_modal',          JST['v2/resend_all_modal']());
  $templateCache.put('group_card',                JST['v2/group_card']());
  $templateCache.put('blood_test',                JST['v2/blood_test']());
  $templateCache.put('observation',               JST['v2/observation']());
  $templateCache.put('date_picker',               JST['v2/date_picker']());
  $templateCache.put('page_unavailable',          JST['v2/page_unavailable']());
  $templateCache.put('choose_layer_filter',       JST['v2/choose_layer_filter']());


  //OLD TEMPLATES V1
  $templateCache.put('analyze_main',              JST['v2/analyze_main']());
  $templateCache.put('analyze_sidebar',           JST['v2/analyze_sidebar']());
  $templateCache.put('directory_sidebar',         JST['v2/directory_sidebar']());
  $templateCache.put('dashboard_sidebar',         JST['v2/dashboard_sidebar']());
  $templateCache.put('setting_main',              JST['v2/setting_main']());
  $templateCache.put('setting_sidebar',           JST['v2/setting_sidebar']());
  $templateCache.put('groups_widget',             JST['v2/groups_widget']());
  $templateCache.put('left_dashboard_panel',      JST['v2/left_dashboard_panel']());
  $templateCache.put('left_explore_panel',        JST['v2/left_explore_panel']());
  $templateCache.put('presets_widget',            JST['v2/presets_widget']());
  $templateCache.put('edit_preset',               JST['v2/edit_preset']());
  $templateCache.put('footer',                    JST['v2/footer']());
  $templateCache.put('header',                    JST['v2/header']());
  // $templateCache.put('graph',                     JST['v2/graph']());
  $templateCache.put('view_analyze',              JST['v2/view_analyze']());
  $templateCache.put('view_pin_editor',           JST['v2/view_pin_editor']());
  $templateCache.put('view_tip',                  JST['v2/view_tip']());
  $templateCache.put('floating_status_bar',       JST['v2/floating_status_bar']());
  $templateCache.put('pins',                      JST['v2/pins']());
  $templateCache.put('analyze_sidebar_criteria',  JST['v2/analyze_sidebar_criteria']());
  $templateCache.put('employee_card',             JST['v2/employee_card']());
  $templateCache.put('employee_personal_card',    JST['v2/employee_personal_card']());
  $templateCache.put('graph_header',              JST['v2/graph_header']());
  $templateCache.put('bars',                      JST['v2/bars']());
  $templateCache.put('new_graph_main',            JST['v2/new_graph_main']());
  $templateCache.put('questionnaire_managmnet_view', JST['v2/questionnaire_managmnet_view']());
  $templateCache.put('questionnaire_dropdown_directive',JST['v2/questionnaire_dropdown_directive']());
  $templateCache.put('filter_employee_table',     JST['v2/filter_employee_table']());

  //$templateCache.put('new_graph_sidebar',         JST['v2/new_graph_sidebar']());
});
