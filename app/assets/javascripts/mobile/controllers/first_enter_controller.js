/*globals angular, unused */
angular.module('workships-mobile').controller('firstEnterController', ['$scope', function ($scope) {
  'use strict';

  $scope.init = function () {
    var textContainerSize = { height: document.getElementsByClassName('page_content')[0].getBoundingClientRect().height,
                              width: document.getElementsByClassName('page_content')[0].getBoundingClientRect().width };
    $scope.container_height = textContainerSize.height + 'px';
    $scope.container_width = textContainerSize.width - 80 + 'px';
  };
}]);
