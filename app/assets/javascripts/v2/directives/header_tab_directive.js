/*global angular, JST, $compile, unused */
angular.module('workships.directives').directive('headerTab', function () {
  'use strict';
  return {
    restrict: 'E',
    transclude: true,
    template: JST['v2/header_tab'](),
    scope: {
      atab: "=",
    },
    link: function postLink(scope, elem, attr) {
      unused(elem);
      unused(attr);
      scope.get_img = function () {
        return scope.atab.selected ? 'assets/header_imgs/' + scope.atab.img_selected : 'assets/header_imgs/' + scope.atab.img;
      };

      scope.get_img_style = function () {
        var img_height = '-1';
        switch (scope.atab.img) {
        case 'Dashboard_idle.png':
          img_height = '45';
          break;
        case 'TopTalent_idle.png':
          img_height = '45';
          break;
        case 'Collaboration_idle.png':
          img_height = '45';
          break;
        case 'Settings_idle.png':
          img_height = '45';
          break;
        default:
          img_height = '45';
          break;
        }
        return 'width: 45px; height: ' + img_height + 'px;';
      };

      scope.get_container_style = function () {
        var padding_top = '-1';
        switch (scope.atab.img) {
        case 'Dashboard_idle.png':
          padding_top = '7';
          break;
        case 'TopTalent_idle.png':
          padding_top = '17';
          break;
        case 'Collaboration_idle.png':
          padding_top = '7';
          break;
        case 'Settings_idle.png':
          padding_top = '7';
          break;
        default:
          padding_top = '7';
          break;
        }
        return 'padding-top: ' + padding_top + 'px;';
      };
    }
  };
});
