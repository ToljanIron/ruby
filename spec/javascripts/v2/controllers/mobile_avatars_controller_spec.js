/*globals _, describe, unused , it, expect, beforeEach, angular, mock, module, $controller, document, window, mockController */

describe('mobileAvatarsController,', function () {
  'use strict';

  var controller, scope;

  beforeEach(function () {
    var mocked_controller = mockController('mobileAvatarsController');
    controller = mocked_controller.controller;
    scope = mocked_controller.scope;
    scope.init();
  });
  it("should be a valid controller", function () {
    expect(controller).toBeDefined();
  });
  describe('response structure', function () {
    it('should construct a response structure for each question', function () {
      expect(scope.numberOfQuestions()).toEqual(scope.questions_to_answer.length);
    });
    it('responses should include a response object with the number of required employees', function () {
      var q = scope.questions_to_answer[0];
      var responses = scope.responses[q.id].responses;
      expect(responses.length).toEqual(q.employee_ids.length);
    });
    it('responses should include a response object with ids of required employees', function () {
      var q = scope.questions_to_answer[0];
      var responses = scope.responses[q.id].responses;
      expect(responses[0].employee_id).toEqual(q.employee_ids[0]);
    });
  });
  describe('capturing responses from user', function () {
    it('should not update anything given a wrong question id or a wrong employee id', function () {
      var old_responses = _.clone(scope.responses, true);
      scope.onUserResponse(1, 1, true);
      expect(old_responses).toEqual(scope.responses);
    });

    it('should update the response in the specific response section', function () {
      scope.onUserResponse(22, 2, true);
      var e = _.where(scope.responsesForQuestion(22), {
        employee_id: 2
      })[0];
      expect(e.response).toBe(true);
    });
  });
  describe('undoing operations', function () {
    it('should do nothing when undoing nothing', function () {
      var old_responses = _.clone(scope.responses, true);
      scope.onUndo();
      expect(old_responses).toEqual(scope.responses);
    });
    it('should undo a single operation', function () {
      var old_responses = _.clone(scope.responses, true);
      scope.onUserResponse(22, 4, true);
      scope.onUndo();
      expect(old_responses).toEqual(scope.responses);
    });
    it('should undo two operation', function () {
      var old_responses = _.clone(scope.responses, true);
      scope.onUserResponse(22, 4, true);
      scope.onUserResponse(22, 4, false);
      scope.onUndo();
      scope.onUndo();
      expect(old_responses).toEqual(scope.responses);
    });
  });
  describe('inquieries about answers', function () {
    it('should report the number of answered questions when answering 1', function () {
      scope.onUserResponse(22, 4, true);
      var answered = scope.numberOfEmployeesAnsweredForQuestion(22);
      expect(answered).toEqual(1);
    });
    it('should report if an employee has an answer', function () {
      expect(scope.employeeHasResponseForQuestion(22, 4)).toEqual(false);
      scope.onUserResponse(22, 4, true);
      expect(scope.employeeHasResponseForQuestion(22, 4)).toEqual(true);
    });
    it('should report the number of answered questions when none is answered', function () {
      var answered = scope.numberOfEmployeesAnsweredForQuestion(22);
      expect(answered).toEqual(0);
    });
    it('should report the number of answered questions when all are answered', function () {
      scope.onUserResponse(22, 1, true);
      scope.onUserResponse(22, 2, true);
      scope.onUserResponse(22, 3, true);
      scope.onUserResponse(22, 4, true);
      var answered = scope.numberOfEmployeesAnsweredForQuestion(22);
      expect(answered).toEqual(4);
    });
  });

});
