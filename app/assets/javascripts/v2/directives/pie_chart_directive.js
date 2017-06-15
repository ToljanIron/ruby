/*global angular, JST, $compile, unused, google, _, document */
/* istanbul ignore next */
angular.module('workships.directives').directive('pieChart', function (dataModelService, $window, $timeout) {
  'use strict';
  return {
    restrict: 'E',
    transclude: true,
    template: JST["v2/pie_chart"](),
    scope: {
      listOfSectors: '=',
      groupId: '='
    },
    link: function (scope) {
      var piechart = document.getElementById('piechart')
      piechart.style.height = String($window.innerHeight - 380) + 'px';

      scope.colors = ['#cfbbe7', '#b795dd', '#9956d1', '#874cb9', '#74409d'];

      scope.$watch('listOfSectors', function (value) {
        if (!value) { return; }
        function drawChart() {

          var data = [
            ['Department', 'Emails']
          ];
          _.each(value, function (o) {
            data.push([o.name, o.size]);
          });

          data = google.visualization.arrayToDataTable(data);

          var options = {
            colors: scope.colors,
            tooltip: {
              text: 'percentage'
            },
            legend: {
              position: 'bottom'
            },
            chartArea: { top: 50, width:"100%" }
          };

          var chart = new google.visualization.PieChart(document.getElementById('piechart'));

          chart.draw(data, options);
          piechart.children[0].children[0].style.margin = 'auto';
        }
        google.charts.load('current', {packages:['corechart'], callback: drawChart});
        // google.charts.setOnLoadCallback(drawChart);
      });
      scope.$watch('groupId', function (value) {
        scope.title = 'COMMUNICATION PERCENTAGE (' + dataModelService.getGroupBy(value).name.toUpperCase() + ')';
      });
    }
  };
});
