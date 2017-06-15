/*globals angular */
angular.module('workships.services', []);
angular.module('workships.directives', []);
angular.module('workships.filters', []);

angular.module('workships', ['googlechart', 'pasvaz.bindonce', 'workships.services', 'workships.directives', 'workships.filters', 'ui.bootstrap', 'duScroll', 'StateRouter']);