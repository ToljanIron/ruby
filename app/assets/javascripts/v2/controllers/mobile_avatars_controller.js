/*globals angular, unused, localStorage, _, $ */
'use strict';

angular.module('workships').controller('mobileAvatarsController', function ($scope) {
  var undo_stack = [];

  function sendResponsesToServer() {
    unused();
    //$http.post $scope.responses
  }

  function loadEmployeesFromServer() {
    $scope.employees = [
      {
        id: 0,
        name: '0',
        image_url: '/assets/Avatar0.png'

      },
      {
        id: 1,
        name: '1',
        image_url: '/assets/Avatar1.png'
      },
      {
        id: 2,
        name: '2',
        image_url: '/assets/Avatar2.png'
      },
      {
        id: 3,
        name: '3',
        image_url: '/assets/Avatar3.png'
      },
      {
        id: 4,
        name: '4',
        image_url: '/assets/Avatar4.png'
      },
      {
        id: 5,
        name: '5',
        image_url: '/assets/Avatar5.png'
      },
      {
        id: 6,
        name: '6',
        image_url: '/assets/Avatar6.png'
      },
      {
        id: 7,
        name: '7',
        image_url: '/assets/Avatar7.png'
      },
      {
        id: 8,
        name: '8',
        image_url: '/assets/Avatar8.png'
      },
    ];
  }

  function loadQuestionsToAnswerFromServer() {
    $scope.questions_to_answer = [
      {
        id: 22,
        question: 'Who do you know?',
        employee_ids: [0, 1, 2, 3, 4, 5, 6, 7, 8]
      },
      {
        id: 24,
        question: 'Who do you like?',
        employee_ids: [4, 8, 2, 1]
      },
    ];
  }

  function buildQuestionResponseStructs() {
    $scope.responses = {};
    _.each($scope.questions_to_answer, function (q) {
      $scope.responses[q.id] = {
        question_id: q.id,
        question: q.question,
        responding_employee_id: $scope.current_employee_id,
        responses: _.map(q.employee_ids, function (eid) {
          return {
            employee_id: eid,
            response: null
          };
        }),
      };
    });
  }

  $scope.heightOfContainer = function (question_id) {
    var r = $scope.responses[question_id];
    if (!r) {
      return;
    }
    return r.responses;
  };

  $scope.responsesForQuestion = function (question_id) {
    var r = $scope.responses[question_id];
    if (!r) {
      return;
    }
    return r.responses;
  };

  $scope.responseForQuestionAndEmployee = function (question_id, employee_id) {
    var r = $scope.responsesForQuestion(question_id);
    var employee_response = _.where(r, {
      employee_id: employee_id
    });
    if (employee_response.length !== 1) {
      return;
    }
    return employee_response[0];
  };

  $scope.nextEmployeeIdWithoutResponseForQuestion = function (question_id, employee_id) {
    var r = $scope.responsesForQuestion(question_id);
    var i, j;

    for (i = 0; i < r.length; ++i) {
      if (r[i].employee_id === employee_id) {
        for (j = i; j < r.length; ++j) {
          if (r[j].response === null) {
            return r[j].employee_id;
          }
        }
        for (j = i; j >= 0; --j) {
          if (r[j].response === null) {
            return r[j].employee_id;
          }
        }
      }
    }
    return -1;
  };

  $scope.onUserResponse = function (question_id, employee_id, response) {
    var r = $scope.responseForQuestionAndEmployee(question_id, employee_id);
    if (!r) {
      return;
    }
    var undo_step = {
      question_id: question_id,
      employee_id: employee_id,
      response: null,
    };
    undo_stack.push(undo_step);
    r.response = response;
    $scope.currentlyFocusedEmployeeId = $scope.nextEmployeeIdWithoutResponseForQuestion(question_id, employee_id);
  };

  $scope.onUndo = function () {
    var undo_step = undo_stack.pop();
    if (!undo_step) {
      return;
    }
    var r = $scope.responseForQuestionAndEmployee(undo_step.question_id, undo_step.employee_id);
    if (!r) {
      return;
    }
    r.response = undo_step.response;
    $scope.currentlyFocusedEmployeeId = undo_step.employee_id;
  };

  $scope.numberOfEmployeesForQuestion = function (question_id) {
    var r = $scope.responsesForQuestion(question_id);
    if (!r) {
      return -1;
    }
    return r.length;
  };

  $scope.numberOfEmployeesAnsweredForQuestion = function (question_id) {
    var responses = $scope.responsesForQuestion(question_id);
    return _.reject(responses, { response: null }).length;
  };

  $scope.numberOfQuestions = function () {
    return _.keys($scope.responses).length;
  };

  $scope.employeeById = function (employee_id) {
    return _.find($scope.employees, {
      id: employee_id
    });
  };

  $scope.onForwardQuestion = function () {
    var i = $scope.index_of_current_question - 1;
    if (i >= $scope.numberOfQuestions()) {
      return;
    }
    $scope.index_of_current_question = $scope.index_of_current_question + 1;
    $scope.r = $scope.responses[_.keys($scope.responses)[$scope.index_of_current_question - 1]];
  };

  $scope.onFinish = function () {
    sendResponsesToServer();
  };

  $scope.employeeHasResponseForQuestion = function (question_id, employee_id) {
    var r = $scope.responseForQuestionAndEmployee(question_id, employee_id);
    if (!r) {
      return false;
    }
    return r.response !== null;
  };

  $scope.employeeDoesNotHaveResponseForQuestion = function (question_id, employee_id) {
    return !$scope.employeeHasResponseForQuestion(question_id, employee_id);
  };

  $scope.init = function () {
    if ($(".mobile-container")[0]) {
      $scope.heightOfContainer = $(".mobile-container")[0].getBoundingClientRect().height;
    }
    $scope.current_employee_id = 0;
    loadEmployeesFromServer();
    loadQuestionsToAnswerFromServer();
    buildQuestionResponseStructs();
    $scope.index_of_current_question = 1;
    $scope.r = $scope.responses[_.keys($scope.responses)[$scope.index_of_current_question - 1]];
  };
});
