/*globals angular, window, _*/

angular.module('workships-mobile.services').factory('mobileAppService', function () {
  'use strict';

  var mobileAppService = {};

  var OVERLAY_BLOCKER = {display: false, message: '', unblock_on_click: true};

  var CONNECTION_LOST_OVERLAY_BLOCKER = {display: false, unblock_on_click: true};

  var VIEW;
  var USER_NAME = '';
  var TOKEN;
  var CURRENT_QUESTION_INDEX = -1;
  var TOTAL_QUESTIONS = 0;
  var QUESTION_TYPE;

  var MIN_MAX = 1;
  var CLEAR_SCREEN = 2;

  var MIN = 0;
  var MAX = 0;

  var QUESTIONNARIE_VIEW = 1;
  var FINISH_VIEW = 2;
  var WELCOME_BACK_VIEW = 3;
  var FIRST_ENTER_VIEW = 4;

  // var LANGUAGE_DIRECTION = 'rtl';
  var LANGUAGE_DIRECTION = 'ltr';

  // Questionnaire state
  var s = null;

  // This is the state as we receive it from the server
  mobileAppService.setState = function(_state) {
    s = _.clone( _state );

    s.num_replies_true  = _.filter(s.replies, function(e) {
      return  e.answer;
    }).length;
    s.num_replies_false = _.filter(s.replies, function(e) {
      return ((e.answer !== null) && (e.answer === false));
    }).length;
    s.replies = null;

    s.updateRepliesNumberUp = function(response) {
      if (response) {
        s.num_replies_true += 1;
      } else {
        s.num_replies_false += 1;
      }
    };
    s.updateRepliesNumberDown = function(response) {
      if (response) {
        s.num_replies_true -= 1;
      } else {
        s.num_replies_false -= 1;
      }
    };

    s.isFunnelQuestion = function() {
      return false;
    };

    mobileAppService.s = s;
  };

  mobileAppService.updateState = function(_state) {
    mobileAppService.s.num_replies_true  = _.filter(_state.replies, function(e) {
      return  e.answer;
    }).length;

    mobileAppService.s.num_replies_false = _.filter(_state.replies, function(e) {
      return ((e.answer !== null) && (e.answer === false));
    }).length;

    mobileAppService.s.client_max_replies = _state.client_max_replies;
    mobileAppService.s.is_funnel_question = _state.is_funnel_question;
    mobileAppService.s.is_contain_funnel_question = _state.is_contain_funnel_question;
  };

  mobileAppService.displayConnectionLostOverlayBlocker = function (options) {
    if (options) {
      CONNECTION_LOST_OVERLAY_BLOCKER.unblock_on_click = options.unblock_on_click;
    }
    CONNECTION_LOST_OVERLAY_BLOCKER.display = true;
  };

  mobileAppService.hideConnectionLostOverlayBlocker = function () {
    CONNECTION_LOST_OVERLAY_BLOCKER.display = false;
    CONNECTION_LOST_OVERLAY_BLOCKER.message = '';
  };

  mobileAppService.isConnectionLostOverlayBlockerDisplayed = function () {
    return CONNECTION_LOST_OVERLAY_BLOCKER.display;
  };

  mobileAppService.displayOverlayBlocker = function (message, options) {
    if (options) {
      OVERLAY_BLOCKER.unblock_on_click = options.unblock_on_click;
    }
    OVERLAY_BLOCKER.display = true;
    OVERLAY_BLOCKER.message = message;
  };

  mobileAppService.hideOverlayBlocker = function () {
    OVERLAY_BLOCKER.display = false;
    OVERLAY_BLOCKER.message = '';
  };

  mobileAppService.onClickOverlayBlocker = function () {
    if (!OVERLAY_BLOCKER.unblock_on_click) { return; }
    mobileAppService.hideOverlayBlocker();
  };

  mobileAppService.isOverlayBlockerDisplayed = function () {
    return OVERLAY_BLOCKER.display;
  };

  mobileAppService.getOverlayBlockerMessage = function () {
    return OVERLAY_BLOCKER.message;
  };

  mobileAppService.getMinMaxAmounts = function () {
    return {min: MIN, max: MAX};
  };

  mobileAppService.setQuestionTypeMinMax = function (min, max) {
    QUESTION_TYPE = MIN_MAX;
    MIN = min;
    MAX = max;
  };

  mobileAppService.setQuestionTypeClearScreen = function () {
    QUESTION_TYPE = CLEAR_SCREEN;
  };

  mobileAppService.isQuestionTypeMinMax = function () {
    return QUESTION_TYPE === MIN_MAX;
  };

  mobileAppService.isQuestionTypeClearScreen = function () {
    return QUESTION_TYPE === CLEAR_SCREEN;
  };

  mobileAppService.setToken = function (token) {
    TOKEN = token;
  };

  mobileAppService.getToken = function () {
    return TOKEN;
  };

  mobileAppService.getUserName = function () {
    return USER_NAME;
  };

  mobileAppService.setUserName = function (user_name) {
    USER_NAME = user_name;
  };

  mobileAppService.inQuestionnaireView = function () {
    return VIEW === QUESTIONNARIE_VIEW;
  };

  mobileAppService.inFinishView = function () {
    return VIEW === FINISH_VIEW;
  };

  mobileAppService.inWelcomeBackView = function () {
    return VIEW === WELCOME_BACK_VIEW;
  };

  mobileAppService.inFirstEnterView = function () {
    return VIEW === FIRST_ENTER_VIEW;
  };

  mobileAppService.setQuestionnaireView = function () {
    VIEW = QUESTIONNARIE_VIEW;
  };

  mobileAppService.setFinishView = function () {
    VIEW = FINISH_VIEW;
  };

  mobileAppService.setWelcomeBackView = function () {
    VIEW = WELCOME_BACK_VIEW;
  };

  mobileAppService.setFirstEnterView = function () {
    VIEW = FIRST_ENTER_VIEW;
  };

  mobileAppService.setIndexOfCurrentQuestion = function (current_question_index) {
    CURRENT_QUESTION_INDEX = current_question_index;
  };

  mobileAppService.setTotalQuestions = function (total_questions) {
    TOTAL_QUESTIONS = total_questions;
  };

  mobileAppService.getIndexOfCurrentQuestion = function () {
    return CURRENT_QUESTION_INDEX;
  };

  mobileAppService.getTotalQuestions = function () {
    return TOTAL_QUESTIONS;
  };

  mobileAppService.langDirection = function() {
    return LANGUAGE_DIRECTION;
  };

  mobileAppService.isLangRtl = function() {
    return true;
    //return false;
  };

  return mobileAppService;
});
