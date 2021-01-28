angular.module('workships-mobile.directives').directive('autoFocus', function () {
  'use strict';
    return {
        restrict: 'AC',
        link: function(_scope, _element) {
                _element[0].focus();
        }
    };
});