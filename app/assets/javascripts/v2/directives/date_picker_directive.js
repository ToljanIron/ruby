/*global angular, JST, $, unused */

angular.module('workships.directives').directive('datePicker', function () {
  'use strict';
  return {
    template: JST["v2/date_picker"](),
    scope: {
      selectedWeek: '='
    },
    link: function ($scope) {

      $scope.formData = {};
      $scope.data = {};

       $scope.dateOptions = {
        formatYear: 'yy',
        startingDay: 0,
        showWeeks:'false'
      };
      $scope.ok = function(){
              alert(show);
            };

      $scope.$watch('formData.dueDate',function(dateVal){
        var weekYear = getWeekNumber(dateVal);
        var year = weekYear[0];
        var week = weekYear[1];

        if(angular.isDefined(week) && angular.isDefined(year)){
          var startDate = getStartDateOfWeek(week, year);
        }
        var weekPeriod = getStartDateOfWeek(week, year);
        if(weekPeriod[0] != 'NaN/NaN/NaN' && weekPeriod[1] != 'NaN/NaN/NaN'){
          $scope.formData.dueDate = "W-"+ week + " : " + weekPeriod[0] + " - "+ weekPeriod[1];
        }

      });

      function getStartDateOfWeek(w, y) {
        var simple = new Date(y, 0, 1 + (w - 1) * 7);
        var dow = simple.getDay();
        var ISOweekStart = simple;
        if (dow <= 4)
          ISOweekStart.setDate(simple.getDate() - simple.getDay());
        else
          ISOweekStart.setDate(simple.getDate() + 7 - simple.getDay());

        var ISOweekEnd = new Date(ISOweekStart);
        ISOweekEnd.setDate(ISOweekEnd.getDate() + 7);

        ISOweekStart = ISOweekStart.getDate()+'/'+(ISOweekStart.getMonth()+1)+'/'+ISOweekStart.getFullYear();
        ISOweekEnd = ISOweekEnd.getDate()+'/'+(ISOweekEnd.getMonth()+1)+'/'+ISOweekEnd.getFullYear();
        return [ISOweekStart, ISOweekEnd];
      }

      function getWeekNumber(d) {
        d = new Date(+d);
        d.setHours(0,0,0);
        d.setDate(d.getDate() + 4 - (d.getDay()||7));
        var yearStart = new Date(d.getFullYear(),0,1);
        var weekNo = Math.ceil(( ( (d - yearStart) / 86400000) + 1)/7);
        return [d.getFullYear(), weekNo];
      }
    }
  };
});
