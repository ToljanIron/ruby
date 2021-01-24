/*globals angular, unused, navigator */
angular.module('workships-mobile').controller('mobileClientController', ['$scope', 'ajaxService', 'mobileAppService', function ($scope, ajaxService, mobileAppService) {
  'use strict';

  function initFromParams(data) {
    mobileAppService.setIndexOfCurrentQuestion(data.current_question_position);
    mobileAppService.setTotalQuestions(data.total_questions);
    mobileAppService.setState(data);

    if (data.min === data.max) {
      mobileAppService.setQuestionTypeClearScreen();
    } else {
      mobileAppService.setQuestionTypeMinMax(data.min, data.max);
    }
    switch (data.status) {
    case 'first time':
      mobileAppService.setFirstEnterView();
      break;
    case 'done':
      mobileAppService.setFinishView();
      break;
    case 'in process':
      mobileAppService.setWelcomeBackView();
      break;
    default:
      mobileAppService.setWelcomeBackView();
    }
  }

  $scope.detectMobile = function () {
    var mobileDetectRegex = /Mobile|iP(hone|od|ad)|Android|BlackBerry|IEMobile|Kindle|NetFront|Silk-Accelerated|(hpw|web)OS|Fennec|Minimo|Opera M(obi|ini)|Blazer|Dolfin|Dolphin|Skyfire|Zune/;
    return mobileDetectRegex.test(navigator.userAgent);
  };


  $scope.init = function (name, token,  dict) {
    $scope.mobile_app_service = mobileAppService;
    mobileAppService.setToken(token);
    mobileAppService.setUserName(name);
    mobileAppService.setDictionary(dict)
    var params = { token: token };
    // TODO !!!!!!!!!!!  ajaxService.keepAlive({alive: true});
    ajaxService.get_next_question(params).then(function (response) {
      initFromParams(response.data);
    });
  };
}]);
