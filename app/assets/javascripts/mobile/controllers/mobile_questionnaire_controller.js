/*globals angular, unused, localStorage, _, $, document, Promise */
'use strict';

angular.module('workships-mobile')
  .config(['$logProvider', function($logProvider){
        $logProvider.debugEnabled(false);
  }])
  .controller('mobileQuestionnaireController', [
    '$scope', 'ajaxService', '$q', 'mobileAppService', '$timeout', '$log',
    function ($scope, ajaxService, $q, mobileAppService, $timeout, $log) {

  var undo_stack = [];
  var mass = mobileAppService.s;

  function buildQuestionResponseStructs() {
    $scope.responses = {};

    var q = $scope.questions_to_answer;

    $scope.responses[q.id] = {
      question_id: q.id,
      question: q.question,
      question_title: q.question_title,

      responses: _.map(q.employee_data, function (data) {
        return {
          employee_details_id: data.employee_details_id,
          employee_id: data.e_id,
          response: data.answer,
        };
      }),
    };
  }

  function getSearchList() {
    $log.debug('In getSearchList()');
    return function () {
      var res = [];
      _.each($scope.employees, function (emp) {
        if (!emp) { return; }
        if (_.find($scope.r.responses, { employee_details_id: emp.id, selected: true })) { return; }
        if (!_.find($scope.tiny_array, {employee_details_id: emp.id}) ) {return;}
        var role = emp.role === undefined ? 'N/A' : emp.role;
        res.push({
          id: emp.id,
          name: emp.name, // + ', ' + role,
        });
      });
      return res;
    };
  }

  function format_questions_to_answer(data) {
    $log.debug('In format_questions_to_answer()');
    var res = {};
    res.id = data.q_id;
    res.question = data.question;
    res.question_title = data.question_title;
    res.employee_data = [];
    _.each(data.replies, function (r) {
      if (r.answer === null) {
        res.employee_data.push({e_id: r.e_id, answer: r.answer, employee_details_id: r.employee_details_id});
      }
    });
    return res;
  }

  $scope.clearSearch = function () {
    $scope.search_input.text = '';
  };

  $scope.responsesForQuestion = function (question_id) {
    $log.debug('In ponsesForQuestion()');
    var r = $scope.responses[question_id];
    if (!r) {
      return;
    }
    return r.responses;
  };

  $scope.responseForQuestionAndEmployee = function (question_id, employee_id) {
    $log.debug('In responseForQuestionAndEmployee()');
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
    $log.debug('In nextEmployeeIdWithoutResponseForQuestion()');
    var r = $scope.responsesForQuestion(question_id);
    var i, j;

    for (i = 0; i < r.length; ++i) {
      if (r[i].employee_id === employee_id) {
        for (j = i; j < r.length; ++j) {
          if (r[j].response === null) { return r[j].employee_id; }
        }
        for (j = i; j >= 0; --j) {
          if (r[j].response === null) { return r[j].employee_id; }
        }
      }
    }
    return -1;
  };

  function resetQuestion() {
    $scope.init(false, {reset_question: true});
  }

  function isLessAvailableEmployeesThanMinimum() {
    if (!mass.isFunnelQuestion()) { return; }

    if ($scope.numberOfEmployeesForQuestion($scope.r.question_id) - $scope.numberOfEmployeesAnsweredFalseForQuestion($scope.r.question_id) < mobileAppService.getMinMaxAmounts().min) {
      $timeout(function () {
        mobileAppService.displayOverlayBlocker(mobileAppService.getMinMaxAmounts().min, {unblock_on_click: true});
        $scope.onUndo();
      }, 0);
    }
  }

  $scope.onUserResponse = function (question_id, employee_id, response, employee_details_id, needToFocus) {
    $log.debug('In onUserResponse()');
    $scope.state_saved[0] = false;
    var r = $scope.responseForQuestionAndEmployee(question_id, employee_id);
    if (!r) { return; }
    var undo_step = {
      question_id: question_id,
      employee_details_id: employee_details_id,
      employee_id: employee_id,
      response: response,
    };
    undo_stack.push(undo_step);

    r.response = response;
    mass.updateRepliesNumberUp(response);

    var emp = $scope.unselected_workers.splice(_.findIndex($scope.unselected_workers, {id: employee_id}), 1);

    var inx = $scope.search_added_emps.indexOf(employee_id);
    $scope.search_added_emps.splice( inx, inx + 1);
    var added_employee = _.find($scope.employees, function (e) {
      return e.qp_id === employee_id;
    });
    if (!_.any($scope.original_data.replies, function (reply) { return reply.e_id === employee_id; })) {
      $scope.original_data.replies.splice(0, 0, { e_id: employee_id, employee_details_id: added_employee.id });
    }
    if (emp[0]) { $scope.undo_worker_stack.push(emp[0]); }

    if (needToFocus === undefined || needToFocus === true) {
      $scope.currentlyFocusedEmployeeId = $scope.nextEmployeeIdWithoutResponseForQuestion(question_id, employee_id);
    }

    // force click on next when the max number of replies was reached
    if ($scope.numberOfEmployeesAnsweredForQuestion($scope.r.question_id) === $scope.numberOfEmployeesForQuestion($scope.r.question_id)) {
      $scope.clicked_on_next[0] = true; // force click on next
    }

    if (mobileAppService.isQuestionTypeMinMax()) {
      isLessAvailableEmployeesThanMinimum();
    }

    // Save partial results to the database
    if ( ($scope.numberOfEmployeesAnsweredForQuestion($scope.r.question_id) % 3) === 0) {
      $scope.continueLater();
    }
  };

  $scope.onUndo = function () {
    if ($scope.isUndoDisabled()) { return; }
    $scope.state_saved[0] = false;
    if (!$scope.clicked_on_next[0]) {
      var undo_step = undo_stack.pop();
      if (!undo_step) {
        resetQuestion();
        return;
      }
      var r = $scope.responseForQuestionAndEmployee(undo_step.question_id, undo_step.employee_id);
      $scope.unselected_workers.push($scope.undo_worker_stack.pop());
      if (!r) { return; }
      r.response = null;
      $scope.currentlyFocusedEmployeeId = undo_step.employee_id;

      mass.updateRepliesNumberDown(undo_step.response);
    }
    $scope.clicked_on_next[0] = false;
  };

  $scope.numberOfEmployeesForQuestion = function (question_id) {
    if ($scope.isLoaded()) {
      var r = $scope.responsesForQuestion(question_id);
      if (!r) { return -1; }
      return r.length;
    }
  };

  $scope.numberOfEmployeesAnsweredForQuestion = function (question_id) {
    if ($scope.isLoaded()) {
      var responses = $scope.responsesForQuestion(question_id);
      return _.filter(responses, function (r) {
        return r.response !== null;
      }).length;
    }
  };

  $scope.numberOfEmployeesAnsweredTrueForQuestion = function (question_id) {
    if ($scope.isLoaded()) {
      var responses = $scope.responsesForQuestion(question_id);
      return _.filter(responses, function (r) {
        return r.response === true;
      }).length;
    }
  };

  /************************************************
   * New state implemenations
   ************************************************/

  $scope.numOfAnswers = function() {
    if (mass.is_funnel_question) {
      return mass.num_replies_true;
    }
    return mass.num_replies_true + mass.num_replies_false;
  };

  $scope.clientMaxReplies = function() {
    return mass.client_max_replies;
  };

  // If is a funnel question then only replies whose value is 'true' count.
  // Otherwise, we count both 'true' and 'false'
  $scope.isFinished = function () {
    if (mass.is_funnel_question) {
      return mass.num_replies_true === mass.client_max_replies;
    }
    var num_reps = mass.num_replies_true + mass.num_replies_false;
    return num_reps === mass.client_max_replies;
  };

  $scope.canFinish = function () {
    
    if (mass.is_funnel_question) {
      return mass.num_replies_true >= 3 &&
             mass.num_replies_true <= mass.client_max_replies;
    }
    var num_reps = mass.num_replies_true + mass.num_replies_false;
    // console.log('&&&&&&&&&&&&&&&&&&&&&&&')
    // console.log(mass)
    // console.log('num_reps: ', num_reps, ', mass.client_max_replies: ', mass.client_max_replies)
    // console.log('&&&&&&&&&&&&&&&&&&&&&&&')
    return num_reps === mass.client_max_replies
  };

  $scope.isAnsweredAllNessecearyQuestions = function () {
    // console.log('Deprecated function');
  };

  /************************************************
   * End of new state implemenations
   ************************************************/


  $scope.numberOfEmployeesAnsweredFalseForQuestion = function (question_id) {
    if ($scope.isLoaded()) {
      var responses = $scope.responsesForQuestion(question_id);
      return _.filter(responses, function (r) {
        return r.response === false;
      }).length;
    }
  };

  $scope.numberOfQuestions = function () {
    return _.keys($scope.responses).length;
  };

  $scope.employeeById = function (employee_id) {
    var e =  _.find($scope.employees, {
      id: employee_id
    });
    return e;
  };

  $scope.onForwardQuestion = function () {
    $log.debug('In onForwardQuestion()');
    var i = $scope.index_of_current_question - 1;
    if (i >= $scope.numberOfQuestions()) {
      return;
    }
    $scope.index_of_current_question = $scope.index_of_current_question + 1;
    $scope.r = $scope.responses[_.keys($scope.responses)[$scope.index_of_current_question - 1]];
  };

  $scope.employeeHasResponseForQuestion = function (question_id, employee_id) {
    $log.debug('In employeeHasResponseForQuestion()');
    var r = $scope.responseForQuestionAndEmployee(question_id, employee_id);
    if (!r) {
      return false;
    }
    return r.response !== null;
  };


  $scope.isUndoDisabled = function () {
    if ($scope.isLoaded()) {
      return $scope.numberOfEmployeesAnsweredForQuestion($scope.r.question_id) === 0;
    }
  };

  $scope.isLoaded = function () {
    return $scope.loaded[0];
  };

  $scope.employeeDoesNotHaveResponseForQuestion = function (question_id, employee_id) {
    return !$scope.employeeHasResponseForQuestion(question_id, employee_id);
  };

  $scope.searchAdded = function (employee_id) {
    return _.any($scope.search_added_emps, function (id) { return id === employee_id; });
  };

  $scope.displayMaxAmount = function () {
    $log.debug('In displayMaxAmount()');
    if (!$scope.isLoaded()) { return; }
    if (mobileAppService.getMinMaxAmounts().max > $scope.numberOfEmployeesForQuestion($scope.r.question_id)) {
      return $scope.numberOfEmployeesForQuestion($scope.r.question_id);
    }
    return mobileAppService.getMinMaxAmounts().max;
  };

  $scope.toggleFullQuestionView = function () {
    $scope.show_full_question = !$scope.show_full_question;
  };

  function resetAllReplies(replies) {
    _.each(replies, function (r) {
      r.answer = null;
    });
    return replies;
  }

  /////////////////////////////////////////////////////////////////////////////
  //  Handle results returning from the get_questionnaire_employees API
  /////////////////////////////////////////////////////////////////////////////
  function handleEmployeesResult(response) {
    $scope.employees = response.data;
    _.each($scope.employees, function (e) {
      e.id = +e.id;
      e.qp_id = +e.qp_id;
    });
    $scope.search_list = getSearchList();
  }

  /////////////////////////////////////////////////////////////////////////////
  //  Handle results returning from the get_next_question API
  /////////////////////////////////////////////////////////////////////////////
  function handleGetNextQuestionResult(response, options) {
    $scope.original_data = response.data;
    var employee_ids_in_question =  _.pluck(response.data.replies, 'employee_details_id');
    var employees_for_question = _.filter($scope.employees, function (e) { return _.include(employee_ids_in_question, e.id); });
    $scope.workers = employees_for_question;
    $scope.unselected_workers = $scope.workers;

    if (options && options.reset_question) {
      $scope.original_data.replies = resetAllReplies($scope.original_data.replies);
      $scope.currentlyFocusedEmployeeId = -1;
    }
    mobileAppService.setIndexOfCurrentQuestion(response.data.current_question_position);

    if (response.data.min === response.data.max) {
      mobileAppService.setQuestionTypeClearScreen();
    } else {
      mobileAppService.setQuestionTypeMinMax(response.data.min, response.data.max);
    }

    $scope.questions_to_answer = format_questions_to_answer(response.data);

    buildQuestionResponseStructs();
    mobileAppService.updateState(response.data);
  }

  /////////////////////////////////////////////////////////////////////////////
  //  Handle results returning from the close_question API
  /////////////////////////////////////////////////////////////////////////////
  function handleCloseQuestionResult(response) {

    if (response === undefined) { return; }
    var res = response.data;
    if (res && res.status === 'fail') {
      console.error('Question was not closed becuase: ', res.reason);
    }
  }

  function syncDataWithServer(params, options) {
    if (options && options.continue_later) {
      params.continue_later = true;
    } else {
      params.continue_later = false;
    }

    var p1 = ajaxService.get_employees(params);
    // The reason for doing this here is that the first time this function is
    // called we don't want to close the question, but in subsequent calls we
    // do. At any rate we can only call get_next_question if the previouse
    // question was already called.
    var p2 = (options && options.close_question ?
              ajaxService.close_question(params) :
              Promise.resolve());

    if (options && options.reset) {
      $q.all([
        p1.then(function (response) {
          handleEmployeesResult(response);
        }),
        p2.then(function (response) {
            handleCloseQuestionResult(response);
          }).then(function () {
              return ajaxService.get_next_question(params);
            }).then(function (response) {
              handleGetNextQuestionResult(response, options);
            })
      ]).then(function () {
        if ($scope.original_data.status === 'done') {
          mobileAppService.setFinishView();
        } else {
          $scope.r = $scope.responses[_.keys($scope.responses)[0]];
          $scope.tiny_array = $scope.r.responses.slice(0, 10);
          $scope.currentlyFocusedEmployeeId = $scope.tiny_array[0].employee_id;
          if (!options.reset_question) {
            $scope.show_full_question = true;
          }
          $scope.loaded[0] = true;
        }
      });
    }
  }

  function updateReplies(params) {
    ajaxService.update_replies(params).then(function(res) {
      console.log('update_replies() - res: ', res);
    });
  }

  $scope.loadMore = function () {
    $log.debug('In loadMore()');
    var startIndex = $scope.tiny_array.length;
    $scope.tiny_array = _.union($scope.tiny_array, $scope.r.responses.slice(startIndex, startIndex + 10));
  };

  function updateScopeResponsesFromAnswers() {
    var responses = $scope.responses[_.keys($scope.responses)[0]].responses;

    // The arrays: responses and $scope.original_data.replies do not have the same size,
    // so we fix it here.
    var updated_replies = [];
    _.forEach($scope.original_data.replies, function (r) {
      // Find the right employee
      var response = _.find(responses, function(resp) { return resp.employee_id === r.e_id; });

      if ( response !== undefined ) {
        r.answer = response.response;
        updated_replies.push(r);
      }
    });
    $scope.original_data.replies = updated_replies;
  }

  $scope.minMaxOnFinish = function () {
    $log.debug('In minMaxOnFinish()');
    if (!$scope.canFinish()) {
      $scope.clicked_on_next[0] = true;
    } else {
      updateScopeResponsesFromAnswers();
      $scope.init($scope.original_data, {close_question: true});
      $scope.currentlyFocusedEmployeeId = -1;
    }
  };

  $scope.clearScreenOnFinish = function () {
    if (!$scope.canFinish()) { return; }
    updateScopeResponsesFromAnswers();
    $scope.init($scope.original_data, {close_question: true});
  };

  $scope.continueLater = function () {
    $log.debug('In continueLater()');
    updateScopeResponsesFromAnswers();
    $scope.state_saved[0] = true;
    $scope.original_data.token = $scope.params.token;
    updateReplies($scope.original_data);
  };

  $scope.getEmployeeIdByName = function (name) {
    return (_.find($scope.unselected_workers, { name: name })).id;
  };

  $scope.findOrLoadAndFind = function (id) {
    $log.debug('In findOrLoadAndFind()');
    var foundItem = _.find($scope.tiny_array, { 'employee_details_id': id });
    if (!foundItem && $scope.tiny_array.length !== $scope.r.responses.length) {
      $scope.loadMore();
      return $scope.findOrLoadAndFind(id);
    } return foundItem;
  };

  $scope.onSelect = function ($item) {
    console.log('qqqqqqqq 1')
    if (confirm("Are you sure you want to select this person?")) {
      console.log('qqqqqqqq 2')
      var emp = _.find($scope.employees, { 'id': $item.id });
      var qpid = emp.qp_id
      console.log('emp: ', emp)
      $scope.onUserResponse(undefined, qpid, true, undefined, false);
    }
    console.log('qqqqqqqq 3')
    return
    // $log.debug('In onSelect()');
    // if (_.any($scope.r.responses, function (r) { return r.employee_details_id === $item.id; })) {
    //   var employee_with_focus =  $scope.findOrLoadAndFind($item.id);
    //   $scope.currentlyFocusedEmployeeId = employee_with_focus.employee_id;
    // } else {
    //   var emp = _.find($scope.employees, { 'id': $item.id });
    //   $scope.search_added_emps.push(emp.qp_id);
    //   $scope.r.responses.splice(0, 0, { employee_id: emp.qp_id, employee_details_id: emp.id });
    //   $scope.tiny_array.splice(0, 0, { employee_id: emp.qp_id, employee_details_id: emp.id });
    //   $scope.currentlyFocusedEmployeeId = emp.qp_id;
    // }
  };

  $scope.matchString = function (pattern, str) {
    if (pattern === undefined || pattern === null || pattern === "") { return true; }
    return (str.toLowerCase().indexOf(pattern.toLowerCase()) >= 0);
  };

  $scope.getParticipantId = function () {
    return $scope.original_data.token
  }

  $scope.init = function (next_question_params, options) {
    $scope._ = _;
    $scope.search_added_emps = [];
    options = options || {};
    $scope.undo_worker_stack = [];
    $scope.clicked_on_next = [false];
    $scope.state_saved = [false];
    $scope.loaded = [false];
    setTimeout(function () {
      $scope.heightOfContainer = document.getElementById('main_container').getBoundingClientRect().height;
    }, 0);

    $scope.swipe = {
      right: false,
      left: false,
    };
    $scope.params = next_question_params || { token: mobileAppService.getToken() };
    $scope.params.token = mobileAppService.getToken();
    var opts = {
      continue_later: !next_question_params,
      reset: true,
      reset_question: options.reset_question,
      close_question: (options.close_question === true ? true : false)
    };
    syncDataWithServer($scope.params, opts);
    $scope.search_input = { text: ''};

    $scope.workers = null;
    $scope.unselected_workers = null;
    $scope.names = {};
    _.forEach($scope.workers, function (worker) { $scope.names[worker.id] = worker.name; });
  };
}]);
