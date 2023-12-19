/*globals angular, window, _*/

angular.module('workships-mobile.services').factory('mobileAppService', function () {
  'use strict';

  var mobileAppService = {};

  var OVERLAY_BLOCKER = {display: false, message: '', unblock_on_click: true};

  var CONNECTION_LOST_OVERLAY_BLOCKER = {display: false, unblock_on_click: true};

  var VIEW;
  var USER_NAME = '';
  var TOKEN;
  var IS_SNOWBALL;
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
  var FIRST_ENTER_SNOWBALL_VIEW = 7;

  //var LANGUAGE_DIRECTION = 'rtl';
  var LANGUAGE_DIRECTION = 'ltr';
  var DICT = {};
  var AVATAR_COLORS = ['#4577A9','#92D050','#BF9000','#00B0F0','#4D4E4E','#FBB03B']
  var DISPLAY_SAFARI_MSG = true;
  // var SAFARI_BROWSER = /^((?!chrome|android).)*safari/i

  // Questionnaire state
  var s = null;

  // This is the state as we receive it from the server
  mobileAppService.setState = function(_state) {
    s = _.clone( _state );
    IS_SNOWBALL = s.is_snowball_q
    s.num_replies_true  = _.filter(s.replies, function(e) {
      return  e.answer;
    }).length;
    s.num_replies_false = _.filter(s.replies, function(e) {
      return ((e.answer !== null) && (e.answer === false));
    }).length;
    s.replies = null;
    LANGUAGE_DIRECTION = (s.language =='Hebrew' ? 'rtl' : 'ltr');

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
    mobileAppService.s.is_referral_btn = _state.is_referral_btn;
    mobileAppService.s.logo_url = _state.logo_url;
    mobileAppService.s.referral_btn_url = _state.referral_btn_url;
    mobileAppService.s.referral_btn_color = _state.referral_btn_color;
    mobileAppService.s.external_id = _state.external_id;
    mobileAppService.s.close_title = _state.close_title;
    mobileAppService.s.close_sub_title = _state.close_sub_title;
    mobileAppService.s.referral_btn_text = _state.referral_btn_text;
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

  mobileAppService.inFirstEnterSnowballView = function () {
    return VIEW === FIRST_ENTER_SNOWBALL_VIEW;
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
    VIEW = IS_SNOWBALL ? FIRST_ENTER_SNOWBALL_VIEW : FIRST_ENTER_VIEW;
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

  mobileAppService.getIsSnowball = function () {
    return IS_SNOWBALL;
  };

  mobileAppService.langDirection = function() {
    return LANGUAGE_DIRECTION;
  };

  mobileAppService.isLangRtl = function() {
    //LANGUAGE_DIRECTION = 'rtl'
    return LANGUAGE_DIRECTION == 'rtl'
    //return false;
  };
  mobileAppService.setDictionary = function(dict) {
    DICT = dict.questionnaire
  }
  mobileAppService.t = function(str) {
    return DICT[str];
  }
  mobileAppService.setDirection = function(language) {
    LANGUAGE_DIRECTION = (language =='Hebrew' ? 'rtl' : 'ltr');
  }
  mobileAppService.get_avatar_colors = function(){
    return AVATAR_COLORS;
  }
  mobileAppService.not_display_safari_msg = function(){
    DISPLAY_SAFARI_MSG = false
  }
  mobileAppService.is_display_safari_msg = function(){
    return DISPLAY_SAFARI_MSG
  }
  mobileAppService.isSafari = function(user_agent){
    var iOS = !!user_agent.match(/iPad/i) || !!user_agent.match(/iPhone/i);
    var webkit = !!user_agent.match(/WebKit/i);
    var iOSSafari = iOS && webkit && !user_agent.match(/CriOS/i);
    return iOSSafari
  }

  return mobileAppService;
});
