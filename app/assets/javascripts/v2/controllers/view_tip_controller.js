/*globals angular , $ ,  window , _ , unused */
angular.module('workships').controller('viewTipController', function ($scope) {
  'use strict';

  // *******  Init  *******
  $scope.init = function () {
    $scope.tip_list = {};
    $scope.tip_list.title = 'Lorem ipsum dolor sit amet, consecutetur';
    $scope.tip_list.content = 'Suspendisse in mi augue tempor gravida sed eget elit Phasellous luctus one cursus.';
    unused();

  };

});
