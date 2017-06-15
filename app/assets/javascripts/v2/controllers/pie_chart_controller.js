/*globals angular , window, Chart ,document, unused, _  */
angular.module('workships').controller('pieChartController', function ($scope) {
  'use strict';

  /* istanbul ignore next */
  $scope.setColor = function (index, left_side) {
    var color;
    if (left_side) {
      if (index === 0) {
        color = $scope.colors[1];
      } else {
        color = $scope.colors[0];
      }
    } else {
      color = $scope.colors[index];
    }
    return {
      'background-color': color
    };
  };
  /* istanbul ignore next */
  $scope.$watch('listOfSectors', function () {
    if (!$scope.listOfSectors) {
      return;
    }
    var data = [];
    data.push(['name', 'size']);
    _.each($scope.listOfSectors, function (sector, index) {
      var temp = [];
      temp.value = sector.size;
      temp.label = sector.name;
      temp = [temp.label, temp.value];
      temp.color = $scope.colors[index];
      data.push(temp);
    });
    $scope.list_to_view = [];
    _.each($scope.listOfSectors, function (sector, index) {
      if (index === 0) {
        $scope.list_to_view[1] = sector;
      } else if (index === 1) {
        $scope.list_to_view[0] = sector;
      } else {
        $scope.list_to_view[index] = sector;
      }
    });
    var chart1 = {};
    chart1.type = "PieChart";
    chart1.data = data;
    chart1.options = {
      legend: 'none',
      tooltip: {
        text: 'percentage',
      },
      pieSliceTextStyle: {
        fontSize: 10,
        color: '#225278',
      },
      slices: {
        4: { offset: 0.1}
      },
      displayExactValues: false,
      width: 250,
      height: 250,
      is3D: false,
      colors: $scope.colors,
      chartArea: {left: 20, top: 10, bottom: 0, height: "90%", width: "90%"}
    };
    $scope.chart = chart1;
  });
  /* istanbul ignore next */
  $scope.init = function () {
    $scope.colors = ['rgb(165, 212, 106)', 'rgb(243, 164, 164)', 'rgb(65, 209, 213)', 'rgb(159, 175, 250)', 'rgb(245, 240, 235)'];
  };
});
