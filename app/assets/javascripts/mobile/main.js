/*globals angular, document, JST, window */

angular.module('workships-mobile.services', []);
angular.module('workships-mobile.directives', []);
angular.module('workships-mobile.filters', []);

angular.module('workships-mobile', ['ngSanitize', 'workships-mobile.services', 'workships-mobile.directives', 'workships-mobile.filters', 'ui.bootstrap'], ['$httpProvider',
  function ($httpProvider) {
    'use strict';

    var csrf_token = document.getElementsByName('csrf-token')[0].content;
    $httpProvider.defaults.headers.post['X-CSRF-Token'] = csrf_token;
    $httpProvider.defaults.headers.put['X-CSRF-Token'] = csrf_token;
    $httpProvider.defaults.headers.patch['X-CSRF-Token'] = csrf_token;
  }]);

angular.element(document).ready(function () {
  'use strict';
  angular.bootstrap(document, ['workships-mobile']);
});

window.unused = function () {
  'use strict';
  return undefined;
};
window.goBack = function () {
  'use strict';
  window.history.back();
};

angular.module('workships-mobile').run(function ($templateCache) {
  $templateCache.put('questionnaire', JST['mobile/questionnaire']());
  $templateCache.put('finish', JST['mobile/finish']());
  $templateCache.put('welcome_back', JST['mobile/welcome_back']());
  $templateCache.put('first_enter', JST['mobile/first_enter']());
  $templateCache.put('desktop', JST['mobile/desktop']());
  $templateCache.put('desktop_dependent', JST['mobile/desktop_dependent']());
  $templateCache.put('first_enter_snowball', JST['mobile/first_enter_snowball']());
});
