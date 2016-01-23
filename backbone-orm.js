/*
  backbone-orm.js 0.7.13
  Copyright (c) 2013-2016 Vidigami
  License: MIT (http://www.opensource.org/licenses/mit-license.php)
  Source: https://github.com/vidigami/backbone-orm
  Dependencies: Backbone.js and Underscore.js.
*/
(function webpackUniversalModuleDefinition(root, factory) {
	if(typeof exports === 'object' && typeof module === 'object')
		module.exports = factory(require("underscore"), require("backbone"), (function webpackLoadOptionalExternalModule() { try { return require("stream"); } catch(e) {} }()));
	else if(typeof define === 'function' && define.amd)
		define(["underscore", "backbone"], function webpackLoadOptionalExternalModuleAmd(__WEBPACK_EXTERNAL_MODULE_1__, __WEBPACK_EXTERNAL_MODULE_2__) {
			return factory(__WEBPACK_EXTERNAL_MODULE_1__, __WEBPACK_EXTERNAL_MODULE_2__, root["stream"]);
		});
	else if(typeof exports === 'object')
		exports["BackboneORM"] = factory(require("underscore"), require("backbone"), (function webpackLoadOptionalExternalModule() { try { return require("stream"); } catch(e) {} }()));
	else
		root["BackboneORM"] = factory(root["_"], root["Backbone"], root["stream"]);
})(this, function(__WEBPACK_EXTERNAL_MODULE_1__, __WEBPACK_EXTERNAL_MODULE_2__, __WEBPACK_EXTERNAL_MODULE_37__) {
return /******/ (function(modules) { // webpackBootstrap
/******/ 	// The module cache
/******/ 	var installedModules = {};

/******/ 	// The require function
/******/ 	function __webpack_require__(moduleId) {

/******/ 		// Check if module is in cache
/******/ 		if(installedModules[moduleId])
/******/ 			return installedModules[moduleId].exports;

/******/ 		// Create a new module (and put it into the cache)
/******/ 		var module = installedModules[moduleId] = {
/******/ 			exports: {},
/******/ 			id: moduleId,
/******/ 			loaded: false
/******/ 		};

/******/ 		// Execute the module function
/******/ 		modules[moduleId].call(module.exports, module, module.exports, __webpack_require__);

/******/ 		// Flag the module as loaded
/******/ 		module.loaded = true;

/******/ 		// Return the exports of the module
/******/ 		return module.exports;
/******/ 	}


/******/ 	// expose the modules object (__webpack_modules__)
/******/ 	__webpack_require__.m = modules;

/******/ 	// expose the module cache
/******/ 	__webpack_require__.c = installedModules;

/******/ 	// __webpack_public_path__
/******/ 	__webpack_require__.p = "";

/******/ 	// Load entry module and return exports
/******/ 	return __webpack_require__(0);
/******/ })
/************************************************************************/
/******/ ([
/* 0 */
/***/ function(module, exports, __webpack_require__) {

	
	/*
	  backbone-orm.js 0.7.14
	  Copyright (c) 2013-2016 Vidigami
	  License: MIT (http://www.opensource.org/licenses/mit-license.php)
	  Source: https://github.com/vidigami/backbone-orm
	  Dependencies: Backbone.js and Underscore.js.
	 */
	var Backbone, BackboneORM, _, publish;

	_ = __webpack_require__(1);

	Backbone = __webpack_require__(2);

	module.exports = BackboneORM = __webpack_require__(3);

	publish = {
	  configure: __webpack_require__(4),
	  sync: __webpack_require__(47),
	  Utils: __webpack_require__(24),
	  JSONUtils: __webpack_require__(33),
	  DateUtils: __webpack_require__(40),
	  TestUtils: __webpack_require__(48),
	  Queue: __webpack_require__(11),
	  DatabaseURL: __webpack_require__(32),
	  Fabricator: __webpack_require__(49),
	  MemoryStore: __webpack_require__(12),
	  Cursor: __webpack_require__(42),
	  Schema: __webpack_require__(43),
	  ConnectionPool: __webpack_require__(50),
	  BaseConvention: __webpack_require__(7),
	  _: _,
	  Backbone: Backbone
	};

	_.extend(BackboneORM, publish);

	__webpack_require__(51);

	BackboneORM.modules = {
	  underscore: _,
	  backbone: Backbone,
	  url: __webpack_require__(25),
	  querystring: __webpack_require__(27),
	  'lru-cache': __webpack_require__(13),
	  inflection: __webpack_require__(6)
	};

	try {
	  BackboneORM.modules.stream = __webpack_require__(37);
	} catch (undefined) {}


/***/ },
/* 1 */
/***/ function(module, exports) {

	module.exports = __WEBPACK_EXTERNAL_MODULE_1__;

/***/ },
/* 2 */
/***/ function(module, exports) {

	module.exports = __WEBPACK_EXTERNAL_MODULE_2__;

/***/ },
/* 3 */
/***/ function(module, exports) {

	module.exports = {};


/***/ },
/* 4 */
/***/ function(module, exports, __webpack_require__) {

	var ALL_CONVENTIONS, BackboneORM, _;

	_ = __webpack_require__(1);

	BackboneORM = __webpack_require__(3);

	ALL_CONVENTIONS = {
	  "default": __webpack_require__(5),
	  underscore: __webpack_require__(5),
	  camelize: __webpack_require__(8),
	  classify: __webpack_require__(9)
	};

	BackboneORM.naming_conventions = ALL_CONVENTIONS["default"];

	BackboneORM.model_cache = new (__webpack_require__(10))();

	module.exports = function(options) {
	  var convention, key, results, value;
	  if (options == null) {
	    options = {};
	  }
	  results = [];
	  for (key in options) {
	    value = options[key];
	    switch (key) {
	      case 'model_cache':
	        results.push(BackboneORM.model_cache.configure(options.model_cache));
	        break;
	      case 'naming_conventions':
	        if (_.isString(value)) {
	          if (convention = ALL_CONVENTIONS[value]) {
	            BackboneORM.naming_conventions = convention;
	            continue;
	          }
	          results.push(console.log("BackboneORM configure: could not find naming_conventions: " + value + ". Available: " + (_.keys(ALL_CONVENTIONS).join(', '))));
	        } else {
	          results.push(BackboneORM.naming_conventions = value);
	        }
	        break;
	      default:
	        results.push(BackboneORM[key] = value);
	    }
	  }
	  return results;
	};


/***/ },
/* 5 */
/***/ function(module, exports, __webpack_require__) {

	var BaseConvention, UnderscoreConvention, inflection,
	  extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
	  hasProp = {}.hasOwnProperty;

	inflection = __webpack_require__(6);

	BaseConvention = __webpack_require__(7);

	module.exports = UnderscoreConvention = (function(superClass) {
	  extend(UnderscoreConvention, superClass);

	  function UnderscoreConvention() {
	    return UnderscoreConvention.__super__.constructor.apply(this, arguments);
	  }

	  UnderscoreConvention.attribute = function(model_name, plural) {
	    return inflection[plural ? 'pluralize' : 'singularize'](inflection.underscore(model_name));
	  };

	  return UnderscoreConvention;

	})(BaseConvention);


/***/ },
/* 6 */
/***/ function(module, exports, __webpack_require__) {

	var __WEBPACK_AMD_DEFINE_FACTORY__, __WEBPACK_AMD_DEFINE_ARRAY__, __WEBPACK_AMD_DEFINE_RESULT__;/*!
	 * inflection
	 * Copyright(c) 2011 Ben Lin <ben@dreamerslab.com>
	 * MIT Licensed
	 *
	 * @fileoverview
	 * A port of inflection-js to node.js module.
	 */

	( function ( root, factory ){
	  if( true ){
	    !(__WEBPACK_AMD_DEFINE_ARRAY__ = [], __WEBPACK_AMD_DEFINE_FACTORY__ = (factory), __WEBPACK_AMD_DEFINE_RESULT__ = (typeof __WEBPACK_AMD_DEFINE_FACTORY__ === 'function' ? (__WEBPACK_AMD_DEFINE_FACTORY__.apply(exports, __WEBPACK_AMD_DEFINE_ARRAY__)) : __WEBPACK_AMD_DEFINE_FACTORY__), __WEBPACK_AMD_DEFINE_RESULT__ !== undefined && (module.exports = __WEBPACK_AMD_DEFINE_RESULT__));
	  }else if( typeof exports === 'object' ){
	    module.exports = factory();
	  }else{
	    root.inflection = factory();
	  }
	}( this, function (){

	  /**
	   * @description This is a list of nouns that use the same form for both singular and plural.
	   *              This list should remain entirely in lower case to correctly match Strings.
	   * @private
	   */
	  var uncountable_words = [
	    // 'access',
	    'accommodation',
	    'adulthood',
	    'advertising',
	    'advice',
	    'aggression',
	    'aid',
	    'air',
	    'aircraft',
	    'alcohol',
	    'anger',
	    'applause',
	    'arithmetic',
	    // 'art',
	    'assistance',
	    'athletics',
	    // 'attention',

	    'bacon',
	    'baggage',
	    // 'ballet',
	    // 'beauty',
	    'beef',
	    // 'beer',
	    // 'behavior',
	    'biology',
	    // 'billiards',
	    'blood',
	    'botany',
	    // 'bowels',
	    'bread',
	    // 'business',
	    'butter',

	    'carbon',
	    'cardboard',
	    'cash',
	    'chalk',
	    'chaos',
	    'chess',
	    'crossroads',
	    'countryside',

	    // 'damage',
	    'dancing',
	    // 'danger',
	    'deer',
	    // 'delight',
	    // 'dessert',
	    'dignity',
	    'dirt',
	    // 'distribution',
	    'dust',

	    'economics',
	    'education',
	    'electricity',
	    // 'employment',
	    // 'energy',
	    'engineering',
	    'enjoyment',
	    // 'entertainment',
	    'envy',
	    'equipment',
	    'ethics',
	    'evidence',
	    'evolution',

	    // 'failure',
	    // 'faith',
	    'fame',
	    'fiction',
	    // 'fish',
	    'flour',
	    'flu',
	    'food',
	    // 'freedom',
	    // 'fruit',
	    'fuel',
	    'fun',
	    // 'funeral',
	    'furniture',

	    'gallows',
	    'garbage',
	    'garlic',
	    // 'gas',
	    'genetics',
	    // 'glass',
	    'gold',
	    'golf',
	    'gossip',
	    'grammar',
	    // 'grass',
	    'gratitude',
	    'grief',
	    // 'ground',
	    'guilt',
	    'gymnastics',

	    // 'hair',
	    'happiness',
	    'hardware',
	    'harm',
	    'hate',
	    'hatred',
	    'health',
	    'heat',
	    // 'height',
	    'help',
	    'homework',
	    'honesty',
	    'honey',
	    'hospitality',
	    'housework',
	    'humour',
	    'hunger',
	    'hydrogen',

	    'ice',
	    'importance',
	    'inflation',
	    'information',
	    // 'injustice',
	    'innocence',
	    // 'intelligence',
	    'iron',
	    'irony',

	    'jam',
	    // 'jealousy',
	    // 'jelly',
	    'jewelry',
	    // 'joy',
	    'judo',
	    // 'juice',
	    // 'justice',

	    'karate',
	    // 'kindness',
	    'knowledge',

	    // 'labour',
	    'lack',
	    // 'land',
	    'laughter',
	    'lava',
	    'leather',
	    'leisure',
	    'lightning',
	    'linguine',
	    'linguini',
	    'linguistics',
	    'literature',
	    'litter',
	    'livestock',
	    'logic',
	    'loneliness',
	    // 'love',
	    'luck',
	    'luggage',

	    'macaroni',
	    'machinery',
	    'magic',
	    // 'mail',
	    'management',
	    'mankind',
	    'marble',
	    'mathematics',
	    'mayonnaise',
	    'measles',
	    // 'meat',
	    // 'metal',
	    'methane',
	    'milk',
	    'money',
	    // 'moose',
	    'mud',
	    'music',
	    'mumps',

	    'nature',
	    'news',
	    'nitrogen',
	    'nonsense',
	    'nurture',
	    'nutrition',

	    'obedience',
	    'obesity',
	    // 'oil',
	    'oxygen',

	    // 'paper',
	    // 'passion',
	    'pasta',
	    'patience',
	    // 'permission',
	    'physics',
	    'poetry',
	    'pollution',
	    'poverty',
	    // 'power',
	    'pride',
	    // 'production',
	    // 'progress',
	    // 'pronunciation',
	    'psychology',
	    'publicity',
	    'punctuation',

	    // 'quality',
	    // 'quantity',
	    'quartz',

	    'racism',
	    // 'rain',
	    // 'recreation',
	    'relaxation',
	    'reliability',
	    'research',
	    'respect',
	    'revenge',
	    'rice',
	    'rubbish',
	    'rum',

	    'safety',
	    // 'salad',
	    // 'salt',
	    // 'sand',
	    // 'satire',
	    'scenery',
	    'seafood',
	    'seaside',
	    'series',
	    'shame',
	    'sheep',
	    'shopping',
	    // 'silence',
	    'sleep',
	    // 'slang'
	    'smoke',
	    'smoking',
	    'snow',
	    'soap',
	    'software',
	    'soil',
	    // 'sorrow',
	    // 'soup',
	    'spaghetti',
	    // 'speed',
	    'species',
	    // 'spelling',
	    // 'sport',
	    'steam',
	    // 'strength',
	    'stuff',
	    'stupidity',
	    // 'success',
	    // 'sugar',
	    'sunshine',
	    'symmetry',

	    // 'tea',
	    'tennis',
	    'thirst',
	    'thunder',
	    'timber',
	    // 'time',
	    // 'toast',
	    // 'tolerance',
	    // 'trade',
	    'traffic',
	    'transportation',
	    // 'travel',
	    'trust',

	    // 'understanding',
	    'underwear',
	    'unemployment',
	    'unity',
	    // 'usage',

	    'validity',
	    'veal',
	    'vegetation',
	    'vegetarianism',
	    'vengeance',
	    'violence',
	    // 'vision',
	    'vitality',

	    'warmth',
	    // 'water',
	    'wealth',
	    'weather',
	    // 'weight',
	    'welfare',
	    'wheat',
	    // 'whiskey',
	    // 'width',
	    'wildlife',
	    // 'wine',
	    'wisdom',
	    // 'wood',
	    // 'wool',
	    // 'work',

	    // 'yeast',
	    'yoga',

	    'zinc',
	    'zoology'
	  ];

	  /**
	   * @description These rules translate from the singular form of a noun to its plural form.
	   * @private
	   */

	  var regex = {
	    plural : {
	      men       : new RegExp( '^(m|wom)en$'             , 'gi' ),
	      people    : new RegExp( '(pe)ople$'               , 'gi' ),
	      children  : new RegExp( '(child)ren$'             , 'gi' ),
	      tia       : new RegExp( '([ti])a$'                , 'gi' ),
	      analyses  : new RegExp( '((a)naly|(b)a|(d)iagno|(p)arenthe|(p)rogno|(s)ynop|(t)he)ses$','gi' ),
	      hives     : new RegExp( '(hi|ti)ves$'             , 'gi' ),
	      curves    : new RegExp( '(curve)s$'               , 'gi' ),
	      lrves     : new RegExp( '([lr])ves$'              , 'gi' ),
	      foves     : new RegExp( '([^fo])ves$'             , 'gi' ),
	      movies    : new RegExp( '(m)ovies$'               , 'gi' ),
	      aeiouyies : new RegExp( '([^aeiouy]|qu)ies$'      , 'gi' ),
	      series    : new RegExp( '(s)eries$'               , 'gi' ),
	      xes       : new RegExp( '(x|ch|ss|sh)es$'         , 'gi' ),
	      mice      : new RegExp( '([m|l])ice$'             , 'gi' ),
	      buses     : new RegExp( '(bus)es$'                , 'gi' ),
	      oes       : new RegExp( '(o)es$'                  , 'gi' ),
	      shoes     : new RegExp( '(shoe)s$'                , 'gi' ),
	      crises    : new RegExp( '(cris|ax|test)es$'       , 'gi' ),
	      octopi    : new RegExp( '(octop|vir)i$'           , 'gi' ),
	      aliases   : new RegExp( '(alias|canvas|status)es$', 'gi' ),
	      summonses : new RegExp( '^(summons)es$'           , 'gi' ),
	      oxen      : new RegExp( '^(ox)en'                 , 'gi' ),
	      matrices  : new RegExp( '(matr)ices$'             , 'gi' ),
	      vertices  : new RegExp( '(vert|ind)ices$'         , 'gi' ),
	      feet      : new RegExp( '^feet$'                  , 'gi' ),
	      teeth     : new RegExp( '^teeth$'                 , 'gi' ),
	      geese     : new RegExp( '^geese$'                 , 'gi' ),
	      quizzes   : new RegExp( '(quiz)zes$'              , 'gi' ),
	      whereases : new RegExp( '^(whereas)es$'           , 'gi' ),
	      criteria  : new RegExp( '^(criteri)a$'            , 'gi' ),
	      ss        : new RegExp( 'ss$'                     , 'gi' ),
	      s         : new RegExp( 's$'                      , 'gi' )
	    },

	    singular : {
	      man     : new RegExp( '^(m|wom)an$'           , 'gi' ),
	      person  : new RegExp( '(pe)rson$'             , 'gi' ),
	      child   : new RegExp( '(child)$'              , 'gi' ),
	      ox      : new RegExp( '^(ox)$'                , 'gi' ),
	      axis    : new RegExp( '(ax|test)is$'          , 'gi' ),
	      octopus : new RegExp( '(octop|vir)us$'        , 'gi' ),
	      alias   : new RegExp( '(alias|status|canvas)$', 'gi' ),
	      summons : new RegExp( '^(summons)$'           , 'gi' ),
	      bus     : new RegExp( '(bu)s$'                , 'gi' ),
	      buffalo : new RegExp( '(buffal|tomat|potat)o$', 'gi' ),
	      tium    : new RegExp( '([ti])um$'             , 'gi' ),
	      sis     : new RegExp( 'sis$'                  , 'gi' ),
	      ffe     : new RegExp( '(?:([^f])fe|([lr])f)$' , 'gi' ),
	      hive    : new RegExp( '(hi|ti)ve$'            , 'gi' ),
	      aeiouyy : new RegExp( '([^aeiouy]|qu)y$'      , 'gi' ),
	      x       : new RegExp( '(x|ch|ss|sh)$'         , 'gi' ),
	      matrix  : new RegExp( '(matr)ix$'             , 'gi' ),
	      vertex  : new RegExp( '(vert|ind)ex$'         , 'gi' ),
	      mouse   : new RegExp( '([m|l])ouse$'          , 'gi' ),
	      foot    : new RegExp( '^foot$'                , 'gi' ),
	      tooth   : new RegExp( '^tooth$'               , 'gi' ),
	      goose   : new RegExp( '^goose$'               , 'gi' ),
	      quiz    : new RegExp( '(quiz)$'               , 'gi' ),
	      whereas : new RegExp( '^(whereas)$'           , 'gi' ),
	      criterion : new RegExp( '^(criteri)on$'       , 'gi' ),
	      s       : new RegExp( 's$'                    , 'gi' ),
	      common  : new RegExp( '$'                     , 'gi' )
	    }
	  };

	  var plural_rules = [

	    // do not replace if its already a plural word
	    [ regex.plural.men       ],
	    [ regex.plural.people    ],
	    [ regex.plural.children  ],
	    [ regex.plural.tia       ],
	    [ regex.plural.analyses  ],
	    [ regex.plural.hives     ],
	    [ regex.plural.curves    ],
	    [ regex.plural.lrves     ],
	    [ regex.plural.foves     ],
	    [ regex.plural.aeiouyies ],
	    [ regex.plural.series    ],
	    [ regex.plural.movies    ],
	    [ regex.plural.xes       ],
	    [ regex.plural.mice      ],
	    [ regex.plural.buses     ],
	    [ regex.plural.oes       ],
	    [ regex.plural.shoes     ],
	    [ regex.plural.crises    ],
	    [ regex.plural.octopi    ],
	    [ regex.plural.aliases   ],
	    [ regex.plural.summonses ],
	    [ regex.plural.oxen      ],
	    [ regex.plural.matrices  ],
	    [ regex.plural.feet      ],
	    [ regex.plural.teeth     ],
	    [ regex.plural.geese     ],
	    [ regex.plural.quizzes   ],
	    [ regex.plural.whereases ],
	    [ regex.plural.criteria  ],

	    // original rule
	    [ regex.singular.man    , '$1en' ],
	    [ regex.singular.person , '$1ople' ],
	    [ regex.singular.child  , '$1ren' ],
	    [ regex.singular.ox     , '$1en' ],
	    [ regex.singular.axis   , '$1es' ],
	    [ regex.singular.octopus, '$1i' ],
	    [ regex.singular.alias  , '$1es' ],
	    [ regex.singular.summons, '$1es' ],
	    [ regex.singular.bus    , '$1ses' ],
	    [ regex.singular.buffalo, '$1oes' ],
	    [ regex.singular.tium   , '$1a' ],
	    [ regex.singular.sis    , 'ses' ],
	    [ regex.singular.ffe    , '$1$2ves' ],
	    [ regex.singular.hive   , '$1ves' ],
	    [ regex.singular.aeiouyy, '$1ies' ],
	    [ regex.singular.matrix , '$1ices' ],
	    [ regex.singular.vertex , '$1ices' ],
	    [ regex.singular.x      , '$1es' ],
	    [ regex.singular.mouse  , '$1ice' ],
	    [ regex.singular.foot   , 'feet' ],
	    [ regex.singular.tooth  , 'teeth' ],
	    [ regex.singular.goose  , 'geese' ],
	    [ regex.singular.quiz   , '$1zes' ],
	    [ regex.singular.whereas, '$1es' ],
	    [ regex.singular.criterion, '$1a' ],

	    [ regex.singular.s     , 's' ],
	    [ regex.singular.common, 's' ]
	  ];

	  /**
	   * @description These rules translate from the plural form of a noun to its singular form.
	   * @private
	   */
	  var singular_rules = [

	    // do not replace if its already a singular word
	    [ regex.singular.man     ],
	    [ regex.singular.person  ],
	    [ regex.singular.child   ],
	    [ regex.singular.ox      ],
	    [ regex.singular.axis    ],
	    [ regex.singular.octopus ],
	    [ regex.singular.alias   ],
	    [ regex.singular.summons ],
	    [ regex.singular.bus     ],
	    [ regex.singular.buffalo ],
	    [ regex.singular.tium    ],
	    [ regex.singular.sis     ],
	    [ regex.singular.ffe     ],
	    [ regex.singular.hive    ],
	    [ regex.singular.aeiouyy ],
	    [ regex.singular.x       ],
	    [ regex.singular.matrix  ],
	    [ regex.singular.mouse   ],
	    [ regex.singular.foot    ],
	    [ regex.singular.tooth   ],
	    [ regex.singular.goose   ],
	    [ regex.singular.quiz    ],
	    [ regex.singular.whereas ],
	    [ regex.singular.criterion ],

	    // original rule
	    [ regex.plural.men      , '$1an' ],
	    [ regex.plural.people   , '$1rson' ],
	    [ regex.plural.children , '$1' ],
	    [ regex.plural.criteria, '$1on'],
	    [ regex.plural.tia      , '$1um' ],
	    [ regex.plural.analyses , '$1$2sis' ],
	    [ regex.plural.hives    , '$1ve' ],
	    [ regex.plural.curves   , '$1' ],
	    [ regex.plural.lrves    , '$1f' ],
	    [ regex.plural.foves    , '$1fe' ],
	    [ regex.plural.movies   , '$1ovie' ],
	    [ regex.plural.aeiouyies, '$1y' ],
	    [ regex.plural.series   , '$1eries' ],
	    [ regex.plural.xes      , '$1' ],
	    [ regex.plural.mice     , '$1ouse' ],
	    [ regex.plural.buses    , '$1' ],
	    [ regex.plural.oes      , '$1' ],
	    [ regex.plural.shoes    , '$1' ],
	    [ regex.plural.crises   , '$1is' ],
	    [ regex.plural.octopi   , '$1us' ],
	    [ regex.plural.aliases  , '$1' ],
	    [ regex.plural.summonses, '$1' ],
	    [ regex.plural.oxen     , '$1' ],
	    [ regex.plural.matrices , '$1ix' ],
	    [ regex.plural.vertices , '$1ex' ],
	    [ regex.plural.feet     , 'foot' ],
	    [ regex.plural.teeth    , 'tooth' ],
	    [ regex.plural.geese    , 'goose' ],
	    [ regex.plural.quizzes  , '$1' ],
	    [ regex.plural.whereases, '$1' ],

	    [ regex.plural.ss, 'ss' ],
	    [ regex.plural.s , '' ]
	  ];

	  /**
	   * @description This is a list of words that should not be capitalized for title case.
	   * @private
	   */
	  var non_titlecased_words = [
	    'and', 'or', 'nor', 'a', 'an', 'the', 'so', 'but', 'to', 'of', 'at','by',
	    'from', 'into', 'on', 'onto', 'off', 'out', 'in', 'over', 'with', 'for'
	  ];

	  /**
	   * @description These are regular expressions used for converting between String formats.
	   * @private
	   */
	  var id_suffix         = new RegExp( '(_ids|_id)$', 'g' );
	  var underbar          = new RegExp( '_', 'g' );
	  var space_or_underbar = new RegExp( '[\ _]', 'g' );
	  var uppercase         = new RegExp( '([A-Z])', 'g' );
	  var underbar_prefix   = new RegExp( '^_' );

	  var inflector = {

	  /**
	   * A helper method that applies rules based replacement to a String.
	   * @private
	   * @function
	   * @param {String} str String to modify and return based on the passed rules.
	   * @param {Array: [RegExp, String]} rules Regexp to match paired with String to use for replacement
	   * @param {Array: [String]} skip Strings to skip if they match
	   * @param {String} override String to return as though this method succeeded (used to conform to APIs)
	   * @returns {String} Return passed String modified by passed rules.
	   * @example
	   *
	   *     this._apply_rules( 'cows', singular_rules ); // === 'cow'
	   */
	    _apply_rules : function ( str, rules, skip, override ){
	      if( override ){
	        str = override;
	      }else{
	        var ignore = ( inflector.indexOf( skip, str.toLowerCase()) > -1 );

	        if( !ignore ){
	          var i = 0;
	          var j = rules.length;

	          for( ; i < j; i++ ){
	            if( str.match( rules[ i ][ 0 ])){
	              if( rules[ i ][ 1 ] !== undefined ){
	                str = str.replace( rules[ i ][ 0 ], rules[ i ][ 1 ]);
	              }
	              break;
	            }
	          }
	        }
	      }

	      return str;
	    },



	  /**
	   * This lets us detect if an Array contains a given element.
	   * @public
	   * @function
	   * @param {Array} arr The subject array.
	   * @param {Object} item Object to locate in the Array.
	   * @param {Number} from_index Starts checking from this position in the Array.(optional)
	   * @param {Function} compare_func Function used to compare Array item vs passed item.(optional)
	   * @returns {Number} Return index position in the Array of the passed item.
	   * @example
	   *
	   *     var inflection = require( 'inflection' );
	   *
	   *     inflection.indexOf([ 'hi','there' ], 'guys' ); // === -1
	   *     inflection.indexOf([ 'hi','there' ], 'hi' ); // === 0
	   */
	    indexOf : function ( arr, item, from_index, compare_func ){
	      if( !from_index ){
	        from_index = -1;
	      }

	      var index = -1;
	      var i     = from_index;
	      var j     = arr.length;

	      for( ; i < j; i++ ){
	        if( arr[ i ]  === item || compare_func && compare_func( arr[ i ], item )){
	          index = i;
	          break;
	        }
	      }

	      return index;
	    },



	  /**
	   * This function adds pluralization support to every String object.
	   * @public
	   * @function
	   * @param {String} str The subject string.
	   * @param {String} plural Overrides normal output with said String.(optional)
	   * @returns {String} Singular English language nouns are returned in plural form.
	   * @example
	   *
	   *     var inflection = require( 'inflection' );
	   *
	   *     inflection.pluralize( 'person' ); // === 'people'
	   *     inflection.pluralize( 'octopus' ); // === 'octopi'
	   *     inflection.pluralize( 'Hat' ); // === 'Hats'
	   *     inflection.pluralize( 'person', 'guys' ); // === 'guys'
	   */
	    pluralize : function ( str, plural ){
	      return inflector._apply_rules( str, plural_rules, uncountable_words, plural );
	    },



	  /**
	   * This function adds singularization support to every String object.
	   * @public
	   * @function
	   * @param {String} str The subject string.
	   * @param {String} singular Overrides normal output with said String.(optional)
	   * @returns {String} Plural English language nouns are returned in singular form.
	   * @example
	   *
	   *     var inflection = require( 'inflection' );
	   *
	   *     inflection.singularize( 'people' ); // === 'person'
	   *     inflection.singularize( 'octopi' ); // === 'octopus'
	   *     inflection.singularize( 'Hats' ); // === 'Hat'
	   *     inflection.singularize( 'guys', 'person' ); // === 'person'
	   */
	    singularize : function ( str, singular ){
	      return inflector._apply_rules( str, singular_rules, uncountable_words, singular );
	    },


	  /**
	   * This function will pluralize or singularlize a String appropriately based on an integer value
	   * @public
	   * @function
	   * @param {String} str The subject string.
	   * @param {Number} count The number to base pluralization off of.
	   * @param {String} singular Overrides normal output with said String.(optional)
	   * @param {String} plural Overrides normal output with said String.(optional)
	   * @returns {String} English language nouns are returned in the plural or singular form based on the count.
	   * @example
	   *
	   *     var inflection = require( 'inflection' );
	   *
	   *     inflection.inflect( 'people' 1 ); // === 'person'
	   *     inflection.inflect( 'octopi' 1 ); // === 'octopus'
	   *     inflection.inflect( 'Hats' 1 ); // === 'Hat'
	   *     inflection.inflect( 'guys', 1 , 'person' ); // === 'person'
	   *     inflection.inflect( 'person', 2 ); // === 'people'
	   *     inflection.inflect( 'octopus', 2 ); // === 'octopi'
	   *     inflection.inflect( 'Hat', 2 ); // === 'Hats'
	   *     inflection.inflect( 'person', 2, null, 'guys' ); // === 'guys'
	   */
	    inflect : function ( str, count, singular, plural ){
	      count = parseInt( count, 10 );

	      if( isNaN( count )) return str;

	      if( count === 0 || count > 1 ){
	        return inflector._apply_rules( str, plural_rules, uncountable_words, plural );
	      }else{
	        return inflector._apply_rules( str, singular_rules, uncountable_words, singular );
	      }
	    },



	  /**
	   * This function adds camelization support to every String object.
	   * @public
	   * @function
	   * @param {String} str The subject string.
	   * @param {Boolean} low_first_letter Default is to capitalize the first letter of the results.(optional)
	   *                                 Passing true will lowercase it.
	   * @returns {String} Lower case underscored words will be returned in camel case.
	   *                  additionally '/' is translated to '::'
	   * @example
	   *
	   *     var inflection = require( 'inflection' );
	   *
	   *     inflection.camelize( 'message_properties' ); // === 'MessageProperties'
	   *     inflection.camelize( 'message_properties', true ); // === 'messageProperties'
	   */
	    camelize : function ( str, low_first_letter ){
	      var str_path = str.split( '/' );
	      var i        = 0;
	      var j        = str_path.length;
	      var str_arr, init_x, k, l, first;

	      for( ; i < j; i++ ){
	        str_arr = str_path[ i ].split( '_' );
	        k       = 0;
	        l       = str_arr.length;

	        for( ; k < l; k++ ){
	          if( k !== 0 ){
	            str_arr[ k ] = str_arr[ k ].toLowerCase();
	          }

	          first = str_arr[ k ].charAt( 0 );
	          first = low_first_letter && i === 0 && k === 0
	            ? first.toLowerCase() : first.toUpperCase();
	          str_arr[ k ] = first + str_arr[ k ].substring( 1 );
	        }

	        str_path[ i ] = str_arr.join( '' );
	      }

	      return str_path.join( '::' );
	    },



	  /**
	   * This function adds underscore support to every String object.
	   * @public
	   * @function
	   * @param {String} str The subject string.
	   * @param {Boolean} all_upper_case Default is to lowercase and add underscore prefix.(optional)
	   *                  Passing true will return as entered.
	   * @returns {String} Camel cased words are returned as lower cased and underscored.
	   *                  additionally '::' is translated to '/'.
	   * @example
	   *
	   *     var inflection = require( 'inflection' );
	   *
	   *     inflection.underscore( 'MessageProperties' ); // === 'message_properties'
	   *     inflection.underscore( 'messageProperties' ); // === 'message_properties'
	   *     inflection.underscore( 'MP', true ); // === 'MP'
	   */
	    underscore : function ( str, all_upper_case ){
	      if( all_upper_case && str === str.toUpperCase()) return str;

	      var str_path = str.split( '::' );
	      var i        = 0;
	      var j        = str_path.length;

	      for( ; i < j; i++ ){
	        str_path[ i ] = str_path[ i ].replace( uppercase, '_$1' );
	        str_path[ i ] = str_path[ i ].replace( underbar_prefix, '' );
	      }

	      return str_path.join( '/' ).toLowerCase();
	    },



	  /**
	   * This function adds humanize support to every String object.
	   * @public
	   * @function
	   * @param {String} str The subject string.
	   * @param {Boolean} low_first_letter Default is to capitalize the first letter of the results.(optional)
	   *                                 Passing true will lowercase it.
	   * @returns {String} Lower case underscored words will be returned in humanized form.
	   * @example
	   *
	   *     var inflection = require( 'inflection' );
	   *
	   *     inflection.humanize( 'message_properties' ); // === 'Message properties'
	   *     inflection.humanize( 'message_properties', true ); // === 'message properties'
	   */
	    humanize : function ( str, low_first_letter ){
	      str = str.toLowerCase();
	      str = str.replace( id_suffix, '' );
	      str = str.replace( underbar, ' ' );

	      if( !low_first_letter ){
	        str = inflector.capitalize( str );
	      }

	      return str;
	    },



	  /**
	   * This function adds capitalization support to every String object.
	   * @public
	   * @function
	   * @param {String} str The subject string.
	   * @returns {String} All characters will be lower case and the first will be upper.
	   * @example
	   *
	   *     var inflection = require( 'inflection' );
	   *
	   *     inflection.capitalize( 'message_properties' ); // === 'Message_properties'
	   *     inflection.capitalize( 'message properties', true ); // === 'Message properties'
	   */
	    capitalize : function ( str ){
	      str = str.toLowerCase();

	      return str.substring( 0, 1 ).toUpperCase() + str.substring( 1 );
	    },



	  /**
	   * This function replaces underscores with dashes in the string.
	   * @public
	   * @function
	   * @param {String} str The subject string.
	   * @returns {String} Replaces all spaces or underscores with dashes.
	   * @example
	   *
	   *     var inflection = require( 'inflection' );
	   *
	   *     inflection.dasherize( 'message_properties' ); // === 'message-properties'
	   *     inflection.dasherize( 'Message Properties' ); // === 'Message-Properties'
	   */
	    dasherize : function ( str ){
	      return str.replace( space_or_underbar, '-' );
	    },



	  /**
	   * This function adds titleize support to every String object.
	   * @public
	   * @function
	   * @param {String} str The subject string.
	   * @returns {String} Capitalizes words as you would for a book title.
	   * @example
	   *
	   *     var inflection = require( 'inflection' );
	   *
	   *     inflection.titleize( 'message_properties' ); // === 'Message Properties'
	   *     inflection.titleize( 'message properties to keep' ); // === 'Message Properties to Keep'
	   */
	    titleize : function ( str ){
	      str         = str.toLowerCase().replace( underbar, ' ' );
	      var str_arr = str.split( ' ' );
	      var i       = 0;
	      var j       = str_arr.length;
	      var d, k, l;

	      for( ; i < j; i++ ){
	        d = str_arr[ i ].split( '-' );
	        k = 0;
	        l = d.length;

	        for( ; k < l; k++){
	          if( inflector.indexOf( non_titlecased_words, d[ k ].toLowerCase()) < 0 ){
	            d[ k ] = inflector.capitalize( d[ k ]);
	          }
	        }

	        str_arr[ i ] = d.join( '-' );
	      }

	      str = str_arr.join( ' ' );
	      str = str.substring( 0, 1 ).toUpperCase() + str.substring( 1 );

	      return str;
	    },



	  /**
	   * This function adds demodulize support to every String object.
	   * @public
	   * @function
	   * @param {String} str The subject string.
	   * @returns {String} Removes module names leaving only class names.(Ruby style)
	   * @example
	   *
	   *     var inflection = require( 'inflection' );
	   *
	   *     inflection.demodulize( 'Message::Bus::Properties' ); // === 'Properties'
	   */
	    demodulize : function ( str ){
	      var str_arr = str.split( '::' );

	      return str_arr[ str_arr.length - 1 ];
	    },



	  /**
	   * This function adds tableize support to every String object.
	   * @public
	   * @function
	   * @param {String} str The subject string.
	   * @returns {String} Return camel cased words into their underscored plural form.
	   * @example
	   *
	   *     var inflection = require( 'inflection' );
	   *
	   *     inflection.tableize( 'MessageBusProperty' ); // === 'message_bus_properties'
	   */
	    tableize : function ( str ){
	      str = inflector.underscore( str );
	      str = inflector.pluralize( str );

	      return str;
	    },



	  /**
	   * This function adds classification support to every String object.
	   * @public
	   * @function
	   * @param {String} str The subject string.
	   * @returns {String} Underscored plural nouns become the camel cased singular form.
	   * @example
	   *
	   *     var inflection = require( 'inflection' );
	   *
	   *     inflection.classify( 'message_bus_properties' ); // === 'MessageBusProperty'
	   */
	    classify : function ( str ){
	      str = inflector.camelize( str );
	      str = inflector.singularize( str );

	      return str;
	    },



	  /**
	   * This function adds foreign key support to every String object.
	   * @public
	   * @function
	   * @param {String} str The subject string.
	   * @param {Boolean} drop_id_ubar Default is to seperate id with an underbar at the end of the class name,
	                                 you can pass true to skip it.(optional)
	   * @returns {String} Underscored plural nouns become the camel cased singular form.
	   * @example
	   *
	   *     var inflection = require( 'inflection' );
	   *
	   *     inflection.foreign_key( 'MessageBusProperty' ); // === 'message_bus_property_id'
	   *     inflection.foreign_key( 'MessageBusProperty', true ); // === 'message_bus_propertyid'
	   */
	    foreign_key : function ( str, drop_id_ubar ){
	      str = inflector.demodulize( str );
	      str = inflector.underscore( str ) + (( drop_id_ubar ) ? ( '' ) : ( '_' )) + 'id';

	      return str;
	    },



	  /**
	   * This function adds ordinalize support to every String object.
	   * @public
	   * @function
	   * @param {String} str The subject string.
	   * @returns {String} Return all found numbers their sequence like '22nd'.
	   * @example
	   *
	   *     var inflection = require( 'inflection' );
	   *
	   *     inflection.ordinalize( 'the 1 pitch' ); // === 'the 1st pitch'
	   */
	    ordinalize : function ( str ){
	      var str_arr = str.split( ' ' );
	      var i       = 0;
	      var j       = str_arr.length;

	      for( ; i < j; i++ ){
	        var k = parseInt( str_arr[ i ], 10 );

	        if( !isNaN( k )){
	          var ltd = str_arr[ i ].substring( str_arr[ i ].length - 2 );
	          var ld  = str_arr[ i ].substring( str_arr[ i ].length - 1 );
	          var suf = 'th';

	          if( ltd != '11' && ltd != '12' && ltd != '13' ){
	            if( ld === '1' ){
	              suf = 'st';
	            }else if( ld === '2' ){
	              suf = 'nd';
	            }else if( ld === '3' ){
	              suf = 'rd';
	            }
	          }

	          str_arr[ i ] += suf;
	        }
	      }

	      return str_arr.join( ' ' );
	    },

	  /**
	   * This function performs multiple inflection methods on a string
	   * @public
	   * @function
	   * @param {String} str The subject string.
	   * @param {Array} arr An array of inflection methods.
	   * @returns {String}
	   * @example
	   *
	   *     var inflection = require( 'inflection' );
	   *
	   *     inflection.transform( 'all job', [ 'pluralize', 'capitalize', 'dasherize' ]); // === 'All-jobs'
	   */
	    transform : function ( str, arr ){
	      var i = 0;
	      var j = arr.length;

	      for( ;i < j; i++ ){
	        var method = arr[ i ];

	        if( this.hasOwnProperty( method )){
	          str = this[ method ]( str );
	        }
	      }

	      return str;
	    }
	  };

	/**
	 * @public
	 */
	  inflector.version = '1.8.0';

	  return inflector;
	}));


/***/ },
/* 7 */
/***/ function(module, exports, __webpack_require__) {

	var BaseConvention, inflection;

	inflection = __webpack_require__(6);

	module.exports = BaseConvention = (function() {
	  function BaseConvention() {}

	  BaseConvention.modelName = function(table_name, plural) {
	    return inflection[plural ? 'pluralize' : 'singularize'](inflection.classify(table_name));
	  };

	  BaseConvention.tableName = function(model_name) {
	    return inflection.pluralize(inflection.underscore(model_name));
	  };

	  BaseConvention.foreignKey = function(model_name, plural) {
	    if (plural) {
	      return inflection.singularize(inflection.underscore(model_name)) + '_ids';
	    } else {
	      return inflection.underscore(model_name) + '_id';
	    }
	  };

	  BaseConvention.attribute = function(model_name, plural) {
	    return inflection[plural ? 'pluralize' : 'singularize'](inflection.underscore(model_name));
	  };

	  return BaseConvention;

	})();


/***/ },
/* 8 */
/***/ function(module, exports, __webpack_require__) {

	var BaseConvention, CamelizeConvention, inflection,
	  extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
	  hasProp = {}.hasOwnProperty;

	inflection = __webpack_require__(6);

	BaseConvention = __webpack_require__(7);

	module.exports = CamelizeConvention = (function(superClass) {
	  extend(CamelizeConvention, superClass);

	  function CamelizeConvention() {
	    return CamelizeConvention.__super__.constructor.apply(this, arguments);
	  }

	  CamelizeConvention.attribute = function(model_name, plural) {
	    return inflection[plural ? 'pluralize' : 'singularize'](inflection.camelize(model_name, true));
	  };

	  return CamelizeConvention;

	})(BaseConvention);


/***/ },
/* 9 */
/***/ function(module, exports, __webpack_require__) {

	var BaseConvention, ClassifyConvention, inflection,
	  extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
	  hasProp = {}.hasOwnProperty;

	inflection = __webpack_require__(6);

	BaseConvention = __webpack_require__(7);

	module.exports = ClassifyConvention = (function(superClass) {
	  extend(ClassifyConvention, superClass);

	  function ClassifyConvention() {
	    return ClassifyConvention.__super__.constructor.apply(this, arguments);
	  }

	  ClassifyConvention.attribute = function(model_name, plural) {
	    return inflection[plural ? 'pluralize' : 'singularize'](inflection.camelize(model_name, false));
	  };

	  return ClassifyConvention;

	})(BaseConvention);


/***/ },
/* 10 */
/***/ function(module, exports, __webpack_require__) {

	
	/*
	  backbone-orm.js 0.7.14
	  Copyright (c) 2013-2016 Vidigami
	  License: MIT (http://www.opensource.org/licenses/mit-license.php)
	  Source: https://github.com/vidigami/backbone-orm
	  Dependencies: Backbone.js and Underscore.js.
	 */
	var Backbone, MemoryStore, ModelCache, Queue, _;

	Backbone = __webpack_require__(2);

	_ = __webpack_require__(1);

	Queue = __webpack_require__(11);

	MemoryStore = __webpack_require__(12);

	module.exports = ModelCache = (function() {
	  function ModelCache() {
	    this.enabled = false;
	    this.caches = {};
	    this.options = {
	      modelTypes: {}
	    };
	    this.verbose = false;
	  }

	  ModelCache.prototype.configure = function(options) {
	    var base, key, value, value_key, value_value, values;
	    if (options == null) {
	      options = {};
	    }
	    this.enabled = options.enabled;
	    for (key in options) {
	      value = options[key];
	      if (_.isObject(value)) {
	        (base = this.options)[key] || (base[key] = {});
	        values = this.options[key];
	        for (value_key in value) {
	          value_value = value[value_key];
	          values[value_key] = value_value;
	        }
	      } else {
	        this.options[key] = value;
	      }
	    }
	    return this.reset();
	  };

	  ModelCache.prototype.configureSync = function(model_type, sync_fn) {
	    if (model_type.prototype._orm_never_cache || !this.createCache(model_type)) {
	      return sync_fn;
	    }
	    return (__webpack_require__(21))(model_type, sync_fn);
	  };

	  ModelCache.prototype.reset = function() {
	    var key, ref, results, value;
	    ref = this.caches;
	    results = [];
	    for (key in ref) {
	      value = ref[key];
	      results.push(this.createCache(value.model_type));
	    }
	    return results;
	  };

	  ModelCache.prototype.createCache = function(model_type) {
	    var cache_info, cuid, model_name, options;
	    if (!(model_name = model_type != null ? model_type.model_name : void 0)) {
	      throw new Error("Missing model name for cache");
	    }
	    cuid = model_type.cuid || (model_type.cuid = _.uniqueId('cuid'));
	    if (cache_info = this.caches[cuid]) {
	      delete this.caches[cuid];
	      cache_info.cache.reset();
	      cache_info.model_type.cache = null;
	    }
	    if (!this.enabled) {
	      return null;
	    }
	    if (!(options = this.options.modelTypes[model_name])) {
	      if (!(this.options.store || this.options.max || this.options.max_age)) {
	        return null;
	      }
	      options = this.options;
	    }
	    cache_info = this.caches[cuid] = {
	      cache: (typeof options.store === "function" ? options.store() : void 0) || new MemoryStore(options),
	      model_type: model_type
	    };
	    return model_type.cache = cache_info.cache;
	  };

	  return ModelCache;

	})();


/***/ },
/* 11 */
/***/ function(module, exports) {

	
	/*
	  backbone-orm.js 0.7.14
	  Copyright (c) 2013-2016 Vidigami
	  License: MIT (http://www.opensource.org/licenses/mit-license.php)
	  Source: https://github.com/vidigami/backbone-orm
	  Dependencies: Backbone.js and Underscore.js.
	 */
	var Queue,
	  bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

	module.exports = Queue = (function() {
	  function Queue(parallelism) {
	    this.parallelism = parallelism;
	    this._doneTask = bind(this._doneTask, this);
	    this.parallelism || (this.parallelism = Infinity);
	    this.tasks = [];
	    this.running_count = 0;
	    this.error = null;
	    this.await_callback = null;
	  }

	  Queue.prototype.defer = function(callback) {
	    this.tasks.push(callback);
	    return this._runTasks();
	  };

	  Queue.prototype.await = function(callback) {
	    if (this.await_callback) {
	      throw new Error("Awaiting callback was added twice: " + callback);
	    }
	    this.await_callback = callback;
	    if (this.error || !(this.tasks.length + this.running_count)) {
	      return this._callAwaiting();
	    }
	  };

	  Queue.prototype._doneTask = function(err) {
	    this.running_count--;
	    this.error || (this.error = err);
	    return this._runTasks();
	  };

	  Queue.prototype._runTasks = function() {
	    var current;
	    if (this.error || !(this.tasks.length + this.running_count)) {
	      return this._callAwaiting();
	    }
	    while (this.running_count < this.parallelism) {
	      if (!this.tasks.length) {
	        return;
	      }
	      current = this.tasks.shift();
	      this.running_count++;
	      current(this._doneTask);
	    }
	  };

	  Queue.prototype._callAwaiting = function() {
	    if (this.await_called || !this.await_callback) {
	      return;
	    }
	    this.await_called = true;
	    return this.await_callback(this.error);
	  };

	  return Queue;

	})();


/***/ },
/* 12 */
/***/ function(module, exports, __webpack_require__) {

	
	/*
	  backbone-orm.js 0.7.14
	  Copyright (c) 2013-2016 Vidigami
	  License: MIT (http://www.opensource.org/licenses/mit-license.php)
	  Source: https://github.com/vidigami/backbone-orm
	  Dependencies: Backbone.js and Underscore.js.
	 */
	var LRU, MemoryStore, _,
	  bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

	_ = __webpack_require__(1);

	LRU = __webpack_require__(13);

	module.exports = MemoryStore = (function() {
	  function MemoryStore(options) {
	    var max_age;
	    if (options == null) {
	      options = {};
	    }
	    this.forEach = bind(this.forEach, this);
	    this.reset = bind(this.reset, this);
	    this.destroy = bind(this.destroy, this);
	    this.get = bind(this.get, this);
	    this.set = bind(this.set, this);
	    if (max_age = options.max_age) {
	      (options = _.omit(options, 'max_age'))['maxAge'] = max_age;
	    }
	    this.cache = new LRU(options);
	  }

	  MemoryStore.prototype.set = function(key, value, callback) {
	    if (value._orm_never_cache) {
	      return (typeof callback === "function" ? callback(null, value) : void 0) || this;
	    }
	    this.cache.set(key, value);
	    if (typeof callback === "function") {
	      callback(null, value);
	    }
	    return this;
	  };

	  MemoryStore.prototype.get = function(key, callback) {
	    var value;
	    value = this.cache.get(key);
	    if (typeof callback === "function") {
	      callback(null, value);
	    }
	    return value;
	  };

	  MemoryStore.prototype.destroy = function(key, callback) {
	    this.cache.del(key);
	    if (typeof callback === "function") {
	      callback();
	    }
	    return this;
	  };

	  MemoryStore.prototype.del = MemoryStore.prototype.destroy;

	  MemoryStore.prototype.reset = function(callback) {
	    this.cache.reset();
	    if (typeof callback === "function") {
	      callback();
	    }
	    return this;
	  };

	  MemoryStore.prototype.forEach = function(callback) {
	    return this.cache.forEach(callback);
	  };

	  return MemoryStore;

	})();


/***/ },
/* 13 */
/***/ function(module, exports, __webpack_require__) {

	module.exports = LRUCache

	// This will be a proper iterable 'Map' in engines that support it,
	// or a fakey-fake PseudoMap in older versions.
	var Map = __webpack_require__(14)
	var util = __webpack_require__(17)

	// A linked list to keep track of recently-used-ness
	var Yallist = __webpack_require__(20)

	// use symbols if possible, otherwise just _props
	var symbols = {}
	var hasSymbol = typeof Symbol === 'function'
	var makeSymbol
	if (hasSymbol) {
	  makeSymbol = function (key) {
	    return Symbol.for(key)
	  }
	} else {
	  makeSymbol = function (key) {
	    return '_' + key
	  }
	}

	function priv (obj, key, val) {
	  var sym
	  if (symbols[key]) {
	    sym = symbols[key]
	  } else {
	    sym = makeSymbol(key)
	    symbols[key] = sym
	  }
	  if (arguments.length === 2) {
	    return obj[sym]
	  } else {
	    obj[sym] = val
	    return val
	  }
	}

	function naiveLength () { return 1 }

	// lruList is a yallist where the head is the youngest
	// item, and the tail is the oldest.  the list contains the Hit
	// objects as the entries.
	// Each Hit object has a reference to its Yallist.Node.  This
	// never changes.
	//
	// cache is a Map (or PseudoMap) that matches the keys to
	// the Yallist.Node object.
	function LRUCache (options) {
	  if (!(this instanceof LRUCache)) {
	    return new LRUCache(options)
	  }

	  if (typeof options === 'number') {
	    options = { max: options }
	  }

	  if (!options) {
	    options = {}
	  }

	  var max = priv(this, 'max', options.max)
	  // Kind of weird to have a default max of Infinity, but oh well.
	  if (!max ||
	      !(typeof max === 'number') ||
	      max <= 0) {
	    priv(this, 'max', Infinity)
	  }

	  var lc = options.length || naiveLength
	  if (typeof lc !== 'function') {
	    lc = naiveLength
	  }
	  priv(this, 'lengthCalculator', lc)

	  priv(this, 'allowStale', options.stale || false)
	  priv(this, 'maxAge', options.maxAge || 0)
	  priv(this, 'dispose', options.dispose)
	  this.reset()
	}

	// resize the cache when the max changes.
	Object.defineProperty(LRUCache.prototype, 'max', {
	  set: function (mL) {
	    if (!mL || !(typeof mL === 'number') || mL <= 0) {
	      mL = Infinity
	    }
	    priv(this, 'max', mL)
	    trim(this)
	  },
	  get: function () {
	    return priv(this, 'max')
	  },
	  enumerable: true
	})

	Object.defineProperty(LRUCache.prototype, 'allowStale', {
	  set: function (allowStale) {
	    priv(this, 'allowStale', !!allowStale)
	  },
	  get: function () {
	    return priv(this, 'allowStale')
	  },
	  enumerable: true
	})

	Object.defineProperty(LRUCache.prototype, 'maxAge', {
	  set: function (mA) {
	    if (!mA || !(typeof mA === 'number') || mA < 0) {
	      mA = 0
	    }
	    priv(this, 'maxAge', mA)
	    trim(this)
	  },
	  get: function () {
	    return priv(this, 'maxAge')
	  },
	  enumerable: true
	})

	// resize the cache when the lengthCalculator changes.
	Object.defineProperty(LRUCache.prototype, 'lengthCalculator', {
	  set: function (lC) {
	    if (typeof lC !== 'function') {
	      lC = naiveLength
	    }
	    if (lC !== priv(this, 'lengthCalculator')) {
	      priv(this, 'lengthCalculator', lC)
	      priv(this, 'length', 0)
	      priv(this, 'lruList').forEach(function (hit) {
	        hit.length = priv(this, 'lengthCalculator').call(this, hit.value, hit.key)
	        priv(this, 'length', priv(this, 'length') + hit.length)
	      }, this)
	    }
	    trim(this)
	  },
	  get: function () { return priv(this, 'lengthCalculator') },
	  enumerable: true
	})

	Object.defineProperty(LRUCache.prototype, 'length', {
	  get: function () { return priv(this, 'length') },
	  enumerable: true
	})

	Object.defineProperty(LRUCache.prototype, 'itemCount', {
	  get: function () { return priv(this, 'lruList').length },
	  enumerable: true
	})

	LRUCache.prototype.rforEach = function (fn, thisp) {
	  thisp = thisp || this
	  for (var walker = priv(this, 'lruList').tail; walker !== null;) {
	    var prev = walker.prev
	    forEachStep(this, fn, walker, thisp)
	    walker = prev
	  }
	}

	function forEachStep (self, fn, node, thisp) {
	  var hit = node.value
	  if (isStale(self, hit)) {
	    del(self, node)
	    if (!priv(self, 'allowStale')) {
	      hit = undefined
	    }
	  }
	  if (hit) {
	    fn.call(thisp, hit.value, hit.key, self)
	  }
	}

	LRUCache.prototype.forEach = function (fn, thisp) {
	  thisp = thisp || this
	  for (var walker = priv(this, 'lruList').head; walker !== null;) {
	    var next = walker.next
	    forEachStep(this, fn, walker, thisp)
	    walker = next
	  }
	}

	LRUCache.prototype.keys = function () {
	  return priv(this, 'lruList').toArray().map(function (k) {
	    return k.key
	  }, this)
	}

	LRUCache.prototype.values = function () {
	  return priv(this, 'lruList').toArray().map(function (k) {
	    return k.value
	  }, this)
	}

	LRUCache.prototype.reset = function () {
	  if (priv(this, 'dispose') &&
	      priv(this, 'lruList') &&
	      priv(this, 'lruList').length) {
	    priv(this, 'lruList').forEach(function (hit) {
	      priv(this, 'dispose').call(this, hit.key, hit.value)
	    }, this)
	  }

	  priv(this, 'cache', new Map()) // hash of items by key
	  priv(this, 'lruList', new Yallist()) // list of items in order of use recency
	  priv(this, 'length', 0) // length of items in the list
	}

	LRUCache.prototype.dump = function () {
	  return priv(this, 'lruList').map(function (hit) {
	    if (!isStale(this, hit)) {
	      return {
	        k: hit.key,
	        v: hit.value,
	        e: hit.now + (hit.maxAge || 0)
	      }
	    }
	  }, this).toArray().filter(function (h) {
	    return h
	  })
	}

	LRUCache.prototype.dumpLru = function () {
	  return priv(this, 'lruList')
	}

	LRUCache.prototype.inspect = function (n, opts) {
	  var str = 'LRUCache {'
	  var extras = false

	  var as = priv(this, 'allowStale')
	  if (as) {
	    str += '\n  allowStale: true'
	    extras = true
	  }

	  var max = priv(this, 'max')
	  if (max && max !== Infinity) {
	    if (extras) {
	      str += ','
	    }
	    str += '\n  max: ' + util.inspect(max, opts)
	    extras = true
	  }

	  var maxAge = priv(this, 'maxAge')
	  if (maxAge) {
	    if (extras) {
	      str += ','
	    }
	    str += '\n  maxAge: ' + util.inspect(maxAge, opts)
	    extras = true
	  }

	  var lc = priv(this, 'lengthCalculator')
	  if (lc && lc !== naiveLength) {
	    if (extras) {
	      str += ','
	    }
	    str += '\n  length: ' + util.inspect(priv(this, 'length'), opts)
	    extras = true
	  }

	  var didFirst = false
	  priv(this, 'lruList').forEach(function (item) {
	    if (didFirst) {
	      str += ',\n  '
	    } else {
	      if (extras) {
	        str += ',\n'
	      }
	      didFirst = true
	      str += '\n  '
	    }
	    var key = util.inspect(item.key).split('\n').join('\n  ')
	    var val = { value: item.value }
	    if (item.maxAge !== maxAge) {
	      val.maxAge = item.maxAge
	    }
	    if (lc !== naiveLength) {
	      val.length = item.length
	    }
	    if (isStale(this, item)) {
	      val.stale = true
	    }

	    val = util.inspect(val, opts).split('\n').join('\n  ')
	    str += key + ' => ' + val
	  })

	  if (didFirst || extras) {
	    str += '\n'
	  }
	  str += '}'

	  return str
	}

	LRUCache.prototype.set = function (key, value, maxAge) {
	  maxAge = maxAge || priv(this, 'maxAge')

	  var now = maxAge ? Date.now() : 0
	  var len = priv(this, 'lengthCalculator').call(this, value, key)

	  if (priv(this, 'cache').has(key)) {
	    if (len > priv(this, 'max')) {
	      del(this, priv(this, 'cache').get(key))
	      return false
	    }

	    var node = priv(this, 'cache').get(key)
	    var item = node.value

	    // dispose of the old one before overwriting
	    if (priv(this, 'dispose')) {
	      priv(this, 'dispose').call(this, key, item.value)
	    }

	    item.now = now
	    item.maxAge = maxAge
	    item.value = value
	    priv(this, 'length', priv(this, 'length') + (len - item.length))
	    item.length = len
	    this.get(key)
	    trim(this)
	    return true
	  }

	  var hit = new Entry(key, value, len, now, maxAge)

	  // oversized objects fall out of cache automatically.
	  if (hit.length > priv(this, 'max')) {
	    if (priv(this, 'dispose')) {
	      priv(this, 'dispose').call(this, key, value)
	    }
	    return false
	  }

	  priv(this, 'length', priv(this, 'length') + hit.length)
	  priv(this, 'lruList').unshift(hit)
	  priv(this, 'cache').set(key, priv(this, 'lruList').head)
	  trim(this)
	  return true
	}

	LRUCache.prototype.has = function (key) {
	  if (!priv(this, 'cache').has(key)) return false
	  var hit = priv(this, 'cache').get(key).value
	  if (isStale(this, hit)) {
	    return false
	  }
	  return true
	}

	LRUCache.prototype.get = function (key) {
	  return get(this, key, true)
	}

	LRUCache.prototype.peek = function (key) {
	  return get(this, key, false)
	}

	LRUCache.prototype.pop = function () {
	  var node = priv(this, 'lruList').tail
	  if (!node) return null
	  del(this, node)
	  return node.value
	}

	LRUCache.prototype.del = function (key) {
	  del(this, priv(this, 'cache').get(key))
	}

	LRUCache.prototype.load = function (arr) {
	  // reset the cache
	  this.reset()

	  var now = Date.now()
	  // A previous serialized cache has the most recent items first
	  for (var l = arr.length - 1; l >= 0; l--) {
	    var hit = arr[l]
	    var expiresAt = hit.e || 0
	    if (expiresAt === 0) {
	      // the item was created without expiration in a non aged cache
	      this.set(hit.k, hit.v)
	    } else {
	      var maxAge = expiresAt - now
	      // dont add already expired items
	      if (maxAge > 0) {
	        this.set(hit.k, hit.v, maxAge)
	      }
	    }
	  }
	}

	LRUCache.prototype.prune = function () {
	  var self = this
	  priv(this, 'cache').forEach(function (value, key) {
	    get(self, key, false)
	  })
	}

	function get (self, key, doUse) {
	  var node = priv(self, 'cache').get(key)
	  if (node) {
	    var hit = node.value
	    if (isStale(self, hit)) {
	      del(self, node)
	      if (!priv(self, 'allowStale')) hit = undefined
	    } else {
	      if (doUse) {
	        priv(self, 'lruList').unshiftNode(node)
	      }
	    }
	    if (hit) hit = hit.value
	  }
	  return hit
	}

	function isStale (self, hit) {
	  if (!hit || (!hit.maxAge && !priv(self, 'maxAge'))) {
	    return false
	  }
	  var stale = false
	  var diff = Date.now() - hit.now
	  if (hit.maxAge) {
	    stale = diff > hit.maxAge
	  } else {
	    stale = priv(self, 'maxAge') && (diff > priv(self, 'maxAge'))
	  }
	  return stale
	}

	function trim (self) {
	  if (priv(self, 'length') > priv(self, 'max')) {
	    for (var walker = priv(self, 'lruList').tail;
	         priv(self, 'length') > priv(self, 'max') && walker !== null;) {
	      // We know that we're about to delete this one, and also
	      // what the next least recently used key will be, so just
	      // go ahead and set it now.
	      var prev = walker.prev
	      del(self, walker)
	      walker = prev
	    }
	  }
	}

	function del (self, node) {
	  if (node) {
	    var hit = node.value
	    if (priv(self, 'dispose')) {
	      priv(self, 'dispose').call(this, hit.key, hit.value)
	    }
	    priv(self, 'length', priv(self, 'length') - hit.length)
	    priv(self, 'cache').delete(hit.key)
	    priv(self, 'lruList').removeNode(node)
	  }
	}

	// classy, since V8 prefers predictable objects.
	function Entry (key, value, length, now, maxAge) {
	  this.key = key
	  this.value = value
	  this.length = length
	  this.now = now
	  this.maxAge = maxAge || 0
	}


/***/ },
/* 14 */
/***/ function(module, exports, __webpack_require__) {

	/* WEBPACK VAR INJECTION */(function(process) {if (process.env.npm_package_name === 'pseudomap' &&
	    process.env.npm_lifecycle_script === 'test')
	  process.env.TEST_PSEUDOMAP = 'true'

	if (typeof Map === 'function' && !process.env.TEST_PSEUDOMAP) {
	  module.exports = Map
	} else {
	  module.exports = __webpack_require__(16)
	}

	/* WEBPACK VAR INJECTION */}.call(exports, __webpack_require__(15)))

/***/ },
/* 15 */
/***/ function(module, exports) {

	// shim for using process in browser

	var process = module.exports = {};
	var queue = [];
	var draining = false;
	var currentQueue;
	var queueIndex = -1;

	function cleanUpNextTick() {
	    draining = false;
	    if (currentQueue.length) {
	        queue = currentQueue.concat(queue);
	    } else {
	        queueIndex = -1;
	    }
	    if (queue.length) {
	        drainQueue();
	    }
	}

	function drainQueue() {
	    if (draining) {
	        return;
	    }
	    var timeout = setTimeout(cleanUpNextTick);
	    draining = true;

	    var len = queue.length;
	    while(len) {
	        currentQueue = queue;
	        queue = [];
	        while (++queueIndex < len) {
	            if (currentQueue) {
	                currentQueue[queueIndex].run();
	            }
	        }
	        queueIndex = -1;
	        len = queue.length;
	    }
	    currentQueue = null;
	    draining = false;
	    clearTimeout(timeout);
	}

	process.nextTick = function (fun) {
	    var args = new Array(arguments.length - 1);
	    if (arguments.length > 1) {
	        for (var i = 1; i < arguments.length; i++) {
	            args[i - 1] = arguments[i];
	        }
	    }
	    queue.push(new Item(fun, args));
	    if (queue.length === 1 && !draining) {
	        setTimeout(drainQueue, 0);
	    }
	};

	// v8 likes predictible objects
	function Item(fun, array) {
	    this.fun = fun;
	    this.array = array;
	}
	Item.prototype.run = function () {
	    this.fun.apply(null, this.array);
	};
	process.title = 'browser';
	process.browser = true;
	process.env = {};
	process.argv = [];
	process.version = ''; // empty string to avoid regexp issues
	process.versions = {};

	function noop() {}

	process.on = noop;
	process.addListener = noop;
	process.once = noop;
	process.off = noop;
	process.removeListener = noop;
	process.removeAllListeners = noop;
	process.emit = noop;

	process.binding = function (name) {
	    throw new Error('process.binding is not supported');
	};

	process.cwd = function () { return '/' };
	process.chdir = function (dir) {
	    throw new Error('process.chdir is not supported');
	};
	process.umask = function() { return 0; };


/***/ },
/* 16 */
/***/ function(module, exports) {

	var hasOwnProperty = Object.prototype.hasOwnProperty

	module.exports = PseudoMap

	function PseudoMap (set) {
	  if (!(this instanceof PseudoMap)) // whyyyyyyy
	    throw new TypeError("Constructor PseudoMap requires 'new'")

	  this.clear()

	  if (set) {
	    if ((set instanceof PseudoMap) ||
	        (typeof Map === 'function' && set instanceof Map))
	      set.forEach(function (value, key) {
	        this.set(key, value)
	      }, this)
	    else if (Array.isArray(set))
	      set.forEach(function (kv) {
	        this.set(kv[0], kv[1])
	      }, this)
	    else
	      throw new TypeError('invalid argument')
	  }
	}

	PseudoMap.prototype.forEach = function (fn, thisp) {
	  thisp = thisp || this
	  Object.keys(this._data).forEach(function (k) {
	    if (k !== 'size')
	      fn.call(thisp, this._data[k].value, this._data[k].key)
	  }, this)
	}

	PseudoMap.prototype.has = function (k) {
	  return !!find(this._data, k)
	}

	PseudoMap.prototype.get = function (k) {
	  var res = find(this._data, k)
	  return res && res.value
	}

	PseudoMap.prototype.set = function (k, v) {
	  set(this._data, k, v)
	}

	PseudoMap.prototype.delete = function (k) {
	  var res = find(this._data, k)
	  if (res) {
	    delete this._data[res._index]
	    this._data.size--
	  }
	}

	PseudoMap.prototype.clear = function () {
	  var data = Object.create(null)
	  data.size = 0

	  Object.defineProperty(this, '_data', {
	    value: data,
	    enumerable: false,
	    configurable: true,
	    writable: false
	  })
	}

	Object.defineProperty(PseudoMap.prototype, 'size', {
	  get: function () {
	    return this._data.size
	  },
	  set: function (n) {},
	  enumerable: true,
	  configurable: true
	})

	PseudoMap.prototype.values =
	PseudoMap.prototype.keys =
	PseudoMap.prototype.entries = function () {
	  throw new Error('iterators are not implemented in this version')
	}

	// Either identical, or both NaN
	function same (a, b) {
	  return a === b || a !== a && b !== b
	}

	function Entry (k, v, i) {
	  this.key = k
	  this.value = v
	  this._index = i
	}

	function find (data, k) {
	  for (var i = 0, s = '_' + k, key = s;
	       hasOwnProperty.call(data, key);
	       key = s + i++) {
	    if (same(data[key].key, k))
	      return data[key]
	  }
	}

	function set (data, k, v) {
	  for (var i = 0, s = '_' + k, key = s;
	       hasOwnProperty.call(data, key);
	       key = s + i++) {
	    if (same(data[key].key, k)) {
	      data[key].value = v
	      return
	    }
	  }
	  data.size++
	  data[key] = new Entry(k, v, key)
	}


/***/ },
/* 17 */
/***/ function(module, exports, __webpack_require__) {

	/* WEBPACK VAR INJECTION */(function(global, process) {// Copyright Joyent, Inc. and other Node contributors.
	//
	// Permission is hereby granted, free of charge, to any person obtaining a
	// copy of this software and associated documentation files (the
	// "Software"), to deal in the Software without restriction, including
	// without limitation the rights to use, copy, modify, merge, publish,
	// distribute, sublicense, and/or sell copies of the Software, and to permit
	// persons to whom the Software is furnished to do so, subject to the
	// following conditions:
	//
	// The above copyright notice and this permission notice shall be included
	// in all copies or substantial portions of the Software.
	//
	// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
	// OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
	// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN
	// NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
	// DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
	// OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE
	// USE OR OTHER DEALINGS IN THE SOFTWARE.

	var formatRegExp = /%[sdj%]/g;
	exports.format = function(f) {
	  if (!isString(f)) {
	    var objects = [];
	    for (var i = 0; i < arguments.length; i++) {
	      objects.push(inspect(arguments[i]));
	    }
	    return objects.join(' ');
	  }

	  var i = 1;
	  var args = arguments;
	  var len = args.length;
	  var str = String(f).replace(formatRegExp, function(x) {
	    if (x === '%%') return '%';
	    if (i >= len) return x;
	    switch (x) {
	      case '%s': return String(args[i++]);
	      case '%d': return Number(args[i++]);
	      case '%j':
	        try {
	          return JSON.stringify(args[i++]);
	        } catch (_) {
	          return '[Circular]';
	        }
	      default:
	        return x;
	    }
	  });
	  for (var x = args[i]; i < len; x = args[++i]) {
	    if (isNull(x) || !isObject(x)) {
	      str += ' ' + x;
	    } else {
	      str += ' ' + inspect(x);
	    }
	  }
	  return str;
	};


	// Mark that a method should not be used.
	// Returns a modified function which warns once by default.
	// If --no-deprecation is set, then it is a no-op.
	exports.deprecate = function(fn, msg) {
	  // Allow for deprecating things in the process of starting up.
	  if (isUndefined(global.process)) {
	    return function() {
	      return exports.deprecate(fn, msg).apply(this, arguments);
	    };
	  }

	  if (process.noDeprecation === true) {
	    return fn;
	  }

	  var warned = false;
	  function deprecated() {
	    if (!warned) {
	      if (process.throwDeprecation) {
	        throw new Error(msg);
	      } else if (process.traceDeprecation) {
	        console.trace(msg);
	      } else {
	        console.error(msg);
	      }
	      warned = true;
	    }
	    return fn.apply(this, arguments);
	  }

	  return deprecated;
	};


	var debugs = {};
	var debugEnviron;
	exports.debuglog = function(set) {
	  if (isUndefined(debugEnviron))
	    debugEnviron = process.env.NODE_DEBUG || '';
	  set = set.toUpperCase();
	  if (!debugs[set]) {
	    if (new RegExp('\\b' + set + '\\b', 'i').test(debugEnviron)) {
	      var pid = process.pid;
	      debugs[set] = function() {
	        var msg = exports.format.apply(exports, arguments);
	        console.error('%s %d: %s', set, pid, msg);
	      };
	    } else {
	      debugs[set] = function() {};
	    }
	  }
	  return debugs[set];
	};


	/**
	 * Echos the value of a value. Trys to print the value out
	 * in the best way possible given the different types.
	 *
	 * @param {Object} obj The object to print out.
	 * @param {Object} opts Optional options object that alters the output.
	 */
	/* legacy: obj, showHidden, depth, colors*/
	function inspect(obj, opts) {
	  // default options
	  var ctx = {
	    seen: [],
	    stylize: stylizeNoColor
	  };
	  // legacy...
	  if (arguments.length >= 3) ctx.depth = arguments[2];
	  if (arguments.length >= 4) ctx.colors = arguments[3];
	  if (isBoolean(opts)) {
	    // legacy...
	    ctx.showHidden = opts;
	  } else if (opts) {
	    // got an "options" object
	    exports._extend(ctx, opts);
	  }
	  // set default options
	  if (isUndefined(ctx.showHidden)) ctx.showHidden = false;
	  if (isUndefined(ctx.depth)) ctx.depth = 2;
	  if (isUndefined(ctx.colors)) ctx.colors = false;
	  if (isUndefined(ctx.customInspect)) ctx.customInspect = true;
	  if (ctx.colors) ctx.stylize = stylizeWithColor;
	  return formatValue(ctx, obj, ctx.depth);
	}
	exports.inspect = inspect;


	// http://en.wikipedia.org/wiki/ANSI_escape_code#graphics
	inspect.colors = {
	  'bold' : [1, 22],
	  'italic' : [3, 23],
	  'underline' : [4, 24],
	  'inverse' : [7, 27],
	  'white' : [37, 39],
	  'grey' : [90, 39],
	  'black' : [30, 39],
	  'blue' : [34, 39],
	  'cyan' : [36, 39],
	  'green' : [32, 39],
	  'magenta' : [35, 39],
	  'red' : [31, 39],
	  'yellow' : [33, 39]
	};

	// Don't use 'blue' not visible on cmd.exe
	inspect.styles = {
	  'special': 'cyan',
	  'number': 'yellow',
	  'boolean': 'yellow',
	  'undefined': 'grey',
	  'null': 'bold',
	  'string': 'green',
	  'date': 'magenta',
	  // "name": intentionally not styling
	  'regexp': 'red'
	};


	function stylizeWithColor(str, styleType) {
	  var style = inspect.styles[styleType];

	  if (style) {
	    return '\u001b[' + inspect.colors[style][0] + 'm' + str +
	           '\u001b[' + inspect.colors[style][1] + 'm';
	  } else {
	    return str;
	  }
	}


	function stylizeNoColor(str, styleType) {
	  return str;
	}


	function arrayToHash(array) {
	  var hash = {};

	  array.forEach(function(val, idx) {
	    hash[val] = true;
	  });

	  return hash;
	}


	function formatValue(ctx, value, recurseTimes) {
	  // Provide a hook for user-specified inspect functions.
	  // Check that value is an object with an inspect function on it
	  if (ctx.customInspect &&
	      value &&
	      isFunction(value.inspect) &&
	      // Filter out the util module, it's inspect function is special
	      value.inspect !== exports.inspect &&
	      // Also filter out any prototype objects using the circular check.
	      !(value.constructor && value.constructor.prototype === value)) {
	    var ret = value.inspect(recurseTimes, ctx);
	    if (!isString(ret)) {
	      ret = formatValue(ctx, ret, recurseTimes);
	    }
	    return ret;
	  }

	  // Primitive types cannot have properties
	  var primitive = formatPrimitive(ctx, value);
	  if (primitive) {
	    return primitive;
	  }

	  // Look up the keys of the object.
	  var keys = Object.keys(value);
	  var visibleKeys = arrayToHash(keys);

	  if (ctx.showHidden) {
	    keys = Object.getOwnPropertyNames(value);
	  }

	  // IE doesn't make error fields non-enumerable
	  // http://msdn.microsoft.com/en-us/library/ie/dww52sbt(v=vs.94).aspx
	  if (isError(value)
	      && (keys.indexOf('message') >= 0 || keys.indexOf('description') >= 0)) {
	    return formatError(value);
	  }

	  // Some type of object without properties can be shortcutted.
	  if (keys.length === 0) {
	    if (isFunction(value)) {
	      var name = value.name ? ': ' + value.name : '';
	      return ctx.stylize('[Function' + name + ']', 'special');
	    }
	    if (isRegExp(value)) {
	      return ctx.stylize(RegExp.prototype.toString.call(value), 'regexp');
	    }
	    if (isDate(value)) {
	      return ctx.stylize(Date.prototype.toString.call(value), 'date');
	    }
	    if (isError(value)) {
	      return formatError(value);
	    }
	  }

	  var base = '', array = false, braces = ['{', '}'];

	  // Make Array say that they are Array
	  if (isArray(value)) {
	    array = true;
	    braces = ['[', ']'];
	  }

	  // Make functions say that they are functions
	  if (isFunction(value)) {
	    var n = value.name ? ': ' + value.name : '';
	    base = ' [Function' + n + ']';
	  }

	  // Make RegExps say that they are RegExps
	  if (isRegExp(value)) {
	    base = ' ' + RegExp.prototype.toString.call(value);
	  }

	  // Make dates with properties first say the date
	  if (isDate(value)) {
	    base = ' ' + Date.prototype.toUTCString.call(value);
	  }

	  // Make error with message first say the error
	  if (isError(value)) {
	    base = ' ' + formatError(value);
	  }

	  if (keys.length === 0 && (!array || value.length == 0)) {
	    return braces[0] + base + braces[1];
	  }

	  if (recurseTimes < 0) {
	    if (isRegExp(value)) {
	      return ctx.stylize(RegExp.prototype.toString.call(value), 'regexp');
	    } else {
	      return ctx.stylize('[Object]', 'special');
	    }
	  }

	  ctx.seen.push(value);

	  var output;
	  if (array) {
	    output = formatArray(ctx, value, recurseTimes, visibleKeys, keys);
	  } else {
	    output = keys.map(function(key) {
	      return formatProperty(ctx, value, recurseTimes, visibleKeys, key, array);
	    });
	  }

	  ctx.seen.pop();

	  return reduceToSingleString(output, base, braces);
	}


	function formatPrimitive(ctx, value) {
	  if (isUndefined(value))
	    return ctx.stylize('undefined', 'undefined');
	  if (isString(value)) {
	    var simple = '\'' + JSON.stringify(value).replace(/^"|"$/g, '')
	                                             .replace(/'/g, "\\'")
	                                             .replace(/\\"/g, '"') + '\'';
	    return ctx.stylize(simple, 'string');
	  }
	  if (isNumber(value))
	    return ctx.stylize('' + value, 'number');
	  if (isBoolean(value))
	    return ctx.stylize('' + value, 'boolean');
	  // For some reason typeof null is "object", so special case here.
	  if (isNull(value))
	    return ctx.stylize('null', 'null');
	}


	function formatError(value) {
	  return '[' + Error.prototype.toString.call(value) + ']';
	}


	function formatArray(ctx, value, recurseTimes, visibleKeys, keys) {
	  var output = [];
	  for (var i = 0, l = value.length; i < l; ++i) {
	    if (hasOwnProperty(value, String(i))) {
	      output.push(formatProperty(ctx, value, recurseTimes, visibleKeys,
	          String(i), true));
	    } else {
	      output.push('');
	    }
	  }
	  keys.forEach(function(key) {
	    if (!key.match(/^\d+$/)) {
	      output.push(formatProperty(ctx, value, recurseTimes, visibleKeys,
	          key, true));
	    }
	  });
	  return output;
	}


	function formatProperty(ctx, value, recurseTimes, visibleKeys, key, array) {
	  var name, str, desc;
	  desc = Object.getOwnPropertyDescriptor(value, key) || { value: value[key] };
	  if (desc.get) {
	    if (desc.set) {
	      str = ctx.stylize('[Getter/Setter]', 'special');
	    } else {
	      str = ctx.stylize('[Getter]', 'special');
	    }
	  } else {
	    if (desc.set) {
	      str = ctx.stylize('[Setter]', 'special');
	    }
	  }
	  if (!hasOwnProperty(visibleKeys, key)) {
	    name = '[' + key + ']';
	  }
	  if (!str) {
	    if (ctx.seen.indexOf(desc.value) < 0) {
	      if (isNull(recurseTimes)) {
	        str = formatValue(ctx, desc.value, null);
	      } else {
	        str = formatValue(ctx, desc.value, recurseTimes - 1);
	      }
	      if (str.indexOf('\n') > -1) {
	        if (array) {
	          str = str.split('\n').map(function(line) {
	            return '  ' + line;
	          }).join('\n').substr(2);
	        } else {
	          str = '\n' + str.split('\n').map(function(line) {
	            return '   ' + line;
	          }).join('\n');
	        }
	      }
	    } else {
	      str = ctx.stylize('[Circular]', 'special');
	    }
	  }
	  if (isUndefined(name)) {
	    if (array && key.match(/^\d+$/)) {
	      return str;
	    }
	    name = JSON.stringify('' + key);
	    if (name.match(/^"([a-zA-Z_][a-zA-Z_0-9]*)"$/)) {
	      name = name.substr(1, name.length - 2);
	      name = ctx.stylize(name, 'name');
	    } else {
	      name = name.replace(/'/g, "\\'")
	                 .replace(/\\"/g, '"')
	                 .replace(/(^"|"$)/g, "'");
	      name = ctx.stylize(name, 'string');
	    }
	  }

	  return name + ': ' + str;
	}


	function reduceToSingleString(output, base, braces) {
	  var numLinesEst = 0;
	  var length = output.reduce(function(prev, cur) {
	    numLinesEst++;
	    if (cur.indexOf('\n') >= 0) numLinesEst++;
	    return prev + cur.replace(/\u001b\[\d\d?m/g, '').length + 1;
	  }, 0);

	  if (length > 60) {
	    return braces[0] +
	           (base === '' ? '' : base + '\n ') +
	           ' ' +
	           output.join(',\n  ') +
	           ' ' +
	           braces[1];
	  }

	  return braces[0] + base + ' ' + output.join(', ') + ' ' + braces[1];
	}


	// NOTE: These type checking functions intentionally don't use `instanceof`
	// because it is fragile and can be easily faked with `Object.create()`.
	function isArray(ar) {
	  return Array.isArray(ar);
	}
	exports.isArray = isArray;

	function isBoolean(arg) {
	  return typeof arg === 'boolean';
	}
	exports.isBoolean = isBoolean;

	function isNull(arg) {
	  return arg === null;
	}
	exports.isNull = isNull;

	function isNullOrUndefined(arg) {
	  return arg == null;
	}
	exports.isNullOrUndefined = isNullOrUndefined;

	function isNumber(arg) {
	  return typeof arg === 'number';
	}
	exports.isNumber = isNumber;

	function isString(arg) {
	  return typeof arg === 'string';
	}
	exports.isString = isString;

	function isSymbol(arg) {
	  return typeof arg === 'symbol';
	}
	exports.isSymbol = isSymbol;

	function isUndefined(arg) {
	  return arg === void 0;
	}
	exports.isUndefined = isUndefined;

	function isRegExp(re) {
	  return isObject(re) && objectToString(re) === '[object RegExp]';
	}
	exports.isRegExp = isRegExp;

	function isObject(arg) {
	  return typeof arg === 'object' && arg !== null;
	}
	exports.isObject = isObject;

	function isDate(d) {
	  return isObject(d) && objectToString(d) === '[object Date]';
	}
	exports.isDate = isDate;

	function isError(e) {
	  return isObject(e) &&
	      (objectToString(e) === '[object Error]' || e instanceof Error);
	}
	exports.isError = isError;

	function isFunction(arg) {
	  return typeof arg === 'function';
	}
	exports.isFunction = isFunction;

	function isPrimitive(arg) {
	  return arg === null ||
	         typeof arg === 'boolean' ||
	         typeof arg === 'number' ||
	         typeof arg === 'string' ||
	         typeof arg === 'symbol' ||  // ES6 symbol
	         typeof arg === 'undefined';
	}
	exports.isPrimitive = isPrimitive;

	exports.isBuffer = __webpack_require__(18);

	function objectToString(o) {
	  return Object.prototype.toString.call(o);
	}


	function pad(n) {
	  return n < 10 ? '0' + n.toString(10) : n.toString(10);
	}


	var months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep',
	              'Oct', 'Nov', 'Dec'];

	// 26 Feb 16:19:34
	function timestamp() {
	  var d = new Date();
	  var time = [pad(d.getHours()),
	              pad(d.getMinutes()),
	              pad(d.getSeconds())].join(':');
	  return [d.getDate(), months[d.getMonth()], time].join(' ');
	}


	// log is just a thin wrapper to console.log that prepends a timestamp
	exports.log = function() {
	  console.log('%s - %s', timestamp(), exports.format.apply(exports, arguments));
	};


	/**
	 * Inherit the prototype methods from one constructor into another.
	 *
	 * The Function.prototype.inherits from lang.js rewritten as a standalone
	 * function (not on Function.prototype). NOTE: If this file is to be loaded
	 * during bootstrapping this function needs to be rewritten using some native
	 * functions as prototype setup using normal JavaScript does not work as
	 * expected during bootstrapping (see mirror.js in r114903).
	 *
	 * @param {function} ctor Constructor function which needs to inherit the
	 *     prototype.
	 * @param {function} superCtor Constructor function to inherit prototype from.
	 */
	exports.inherits = __webpack_require__(19);

	exports._extend = function(origin, add) {
	  // Don't do anything if add isn't an object
	  if (!add || !isObject(add)) return origin;

	  var keys = Object.keys(add);
	  var i = keys.length;
	  while (i--) {
	    origin[keys[i]] = add[keys[i]];
	  }
	  return origin;
	};

	function hasOwnProperty(obj, prop) {
	  return Object.prototype.hasOwnProperty.call(obj, prop);
	}

	/* WEBPACK VAR INJECTION */}.call(exports, (function() { return this; }()), __webpack_require__(15)))

/***/ },
/* 18 */
/***/ function(module, exports) {

	module.exports = function isBuffer(arg) {
	  return arg && typeof arg === 'object'
	    && typeof arg.copy === 'function'
	    && typeof arg.fill === 'function'
	    && typeof arg.readUInt8 === 'function';
	}

/***/ },
/* 19 */
/***/ function(module, exports) {

	if (typeof Object.create === 'function') {
	  // implementation from standard node.js 'util' module
	  module.exports = function inherits(ctor, superCtor) {
	    ctor.super_ = superCtor
	    ctor.prototype = Object.create(superCtor.prototype, {
	      constructor: {
	        value: ctor,
	        enumerable: false,
	        writable: true,
	        configurable: true
	      }
	    });
	  };
	} else {
	  // old school shim for old browsers
	  module.exports = function inherits(ctor, superCtor) {
	    ctor.super_ = superCtor
	    var TempCtor = function () {}
	    TempCtor.prototype = superCtor.prototype
	    ctor.prototype = new TempCtor()
	    ctor.prototype.constructor = ctor
	  }
	}


/***/ },
/* 20 */
/***/ function(module, exports) {

	module.exports = Yallist

	Yallist.Node = Node
	Yallist.create = Yallist

	function Yallist (list) {
	  var self = this
	  if (!(self instanceof Yallist)) {
	    self = new Yallist()
	  }

	  self.tail = null
	  self.head = null
	  self.length = 0

	  if (list && typeof list.forEach === 'function') {
	    list.forEach(function (item) {
	      self.push(item)
	    })
	  } else if (arguments.length > 0) {
	    for (var i = 0, l = arguments.length; i < l; i++) {
	      self.push(arguments[i])
	    }
	  }

	  return self
	}

	Yallist.prototype.removeNode = function (node) {
	  if (node.list !== this) {
	    throw new Error('removing node which does not belong to this list')
	  }

	  var next = node.next
	  var prev = node.prev

	  if (next) {
	    next.prev = prev
	  }

	  if (prev) {
	    prev.next = next
	  }

	  if (node === this.head) {
	    this.head = next
	  }
	  if (node === this.tail) {
	    this.tail = prev
	  }

	  node.list.length --
	  node.next = null
	  node.prev = null
	  node.list = null
	}

	Yallist.prototype.unshiftNode = function (node) {
	  if (node === this.head) {
	    return
	  }

	  if (node.list) {
	    node.list.removeNode(node)
	  }

	  var head = this.head
	  node.list = this
	  node.next = head
	  if (head) {
	    head.prev = node
	  }

	  this.head = node
	  if (!this.tail) {
	    this.tail = node
	  }
	  this.length ++
	}

	Yallist.prototype.pushNode = function (node) {
	  if (node === this.tail) {
	    return
	  }

	  if (node.list) {
	    node.list.removeNode(node)
	  }

	  var tail = this.tail
	  node.list = this
	  node.prev = tail
	  if (tail) {
	    tail.next = node
	  }

	  this.tail = node
	  if (!this.head) {
	    this.head = node
	  }
	  this.length ++
	}

	Yallist.prototype.push = function () {
	  for (var i = 0, l = arguments.length; i < l; i++) {
	    push(this, arguments[i])
	  }
	  return this.length
	}

	Yallist.prototype.unshift = function () {
	  for (var i = 0, l = arguments.length; i < l; i++) {
	    unshift(this, arguments[i])
	  }
	  return this.length
	}

	Yallist.prototype.pop = function () {
	  if (!this.tail)
	    return undefined

	  var res = this.tail.value
	  this.tail = this.tail.prev
	  this.tail.next = null
	  this.length --
	  return res
	}

	Yallist.prototype.shift = function () {
	  if (!this.head)
	    return undefined

	  var res = this.head.value
	  this.head = this.head.next
	  this.head.prev = null
	  this.length --
	  return res
	}

	Yallist.prototype.forEach = function (fn, thisp) {
	  thisp = thisp || this
	  for (var walker = this.head, i = 0; walker !== null; i++) {
	    fn.call(thisp, walker.value, i, this)
	    walker = walker.next
	  }
	}

	Yallist.prototype.forEachReverse = function (fn, thisp) {
	  thisp = thisp || this
	  for (var walker = this.tail, i = this.length - 1; walker !== null; i--) {
	    fn.call(thisp, walker.value, i, this)
	    walker = walker.prev
	  }
	}

	Yallist.prototype.get = function (n) {
	  for (var i = 0, walker = this.head; walker !== null && i < n; i++) {
	    // abort out of the list early if we hit a cycle
	    walker = walker.next
	  }
	  if (i === n && walker !== null) {
	    return walker.value
	  }
	}

	Yallist.prototype.getReverse = function (n) {
	  for (var i = 0, walker = this.tail; walker !== null && i < n; i++) {
	    // abort out of the list early if we hit a cycle
	    walker = walker.prev
	  }
	  if (i === n && walker !== null) {
	    return walker.value
	  }
	}

	Yallist.prototype.map = function (fn, thisp) {
	  thisp = thisp || this
	  var res = new Yallist()
	  for (var walker = this.head; walker !== null; ) {
	    res.push(fn.call(thisp, walker.value, this))
	    walker = walker.next
	  }
	  return res
	}

	Yallist.prototype.mapReverse = function (fn, thisp) {
	  thisp = thisp || this
	  var res = new Yallist()
	  for (var walker = this.tail; walker !== null;) {
	    res.push(fn.call(thisp, walker.value, this))
	    walker = walker.prev
	  }
	  return res
	}

	Yallist.prototype.reduce = function (fn, initial) {
	  var acc
	  var walker = this.head
	  if (arguments.length > 1) {
	    acc = initial
	  } else if (this.head) {
	    walker = this.head.next
	    acc = this.head.value
	  } else {
	    throw new TypeError('Reduce of empty list with no initial value')
	  }

	  for (var i = 0; walker !== null; i++) {
	    acc = fn(acc, walker.value, i)
	    walker = walker.next
	  }

	  return acc
	}

	Yallist.prototype.reduceReverse = function (fn, initial) {
	  var acc
	  var walker = this.tail
	  if (arguments.length > 1) {
	    acc = initial
	  } else if (this.tail) {
	    walker = this.tail.prev
	    acc = this.tail.value
	  } else {
	    throw new TypeError('Reduce of empty list with no initial value')
	  }

	  for (var i = this.length - 1; walker !== null; i--) {
	    acc = fn(acc, walker.value, i)
	    walker = walker.prev
	  }

	  return acc
	}

	Yallist.prototype.toArray = function () {
	  var arr = new Array(this.length)
	  for (var i = 0, walker = this.head; walker !== null; i++) {
	    arr[i] = walker.value
	    walker = walker.next
	  }
	  return arr
	}

	Yallist.prototype.toArrayReverse = function () {
	  var arr = new Array(this.length)
	  for (var i = 0, walker = this.tail; walker !== null; i++) {
	    arr[i] = walker.value
	    walker = walker.prev
	  }
	  return arr
	}

	Yallist.prototype.slice = function (from, to) {
	  to = to || this.length
	  if (to < 0) {
	    to += this.length
	  }
	  from = from || 0
	  if (from < 0) {
	    from += this.length
	  }
	  var ret = new Yallist()
	  if (to < from || to < 0) {
	    return ret
	  }
	  if (from < 0) {
	    from = 0
	  }
	  if (to > this.length) {
	    to = this.length
	  }
	  for (var i = 0, walker = this.head; walker !== null && i < from; i++) {
	    walker = walker.next
	  }
	  for (; walker !== null && i < to; i++, walker = walker.next) {
	    ret.push(walker.value)
	  }
	  return ret
	}

	Yallist.prototype.sliceReverse = function (from, to) {
	  to = to || this.length
	  if (to < 0) {
	    to += this.length
	  }
	  from = from || 0
	  if (from < 0) {
	    from += this.length
	  }
	  var ret = new Yallist()
	  if (to < from || to < 0) {
	    return ret
	  }
	  if (from < 0) {
	    from = 0
	  }
	  if (to > this.length) {
	    to = this.length
	  }
	  for (var i = this.length, walker = this.tail; walker !== null && i > to; i--) {
	    walker = walker.prev
	  }
	  for (; walker !== null && i > from; i--, walker = walker.prev) {
	    ret.push(walker.value)
	  }
	  return ret
	}

	Yallist.prototype.reverse = function () {
	  var head = this.head
	  var tail = this.tail
	  for (var walker = head; walker !== null; walker = walker.prev) {
	    var p = walker.prev
	    walker.prev = walker.next
	    walker.next = p
	  }
	  this.head = tail
	  this.tail = head
	  return this
	}

	function push (self, item) {
	  self.tail = new Node(item, self.tail, null, self)
	  if (!self.head) {
	    self.head = self.tail
	  }
	  self.length ++
	}

	function unshift (self, item) {
	  self.head = new Node(item, null, self.head, self)
	  if (!self.tail) {
	    self.tail = self.head
	  }
	  self.length ++
	}

	function Node (value, prev, next, list) {
	  if (!(this instanceof Node)) {
	    return new Node(value, prev, next, list)
	  }

	  this.list = list
	  this.value = value

	  if (prev) {
	    prev.next = this
	    this.prev = prev
	  } else {
	    this.prev = null
	  }

	  if (next) {
	    next.prev = this
	    this.next = next
	  } else {
	    this.next = null
	  }
	}


/***/ },
/* 21 */
/***/ function(module, exports, __webpack_require__) {

	
	/*
	  backbone-orm.js 0.7.14
	  Copyright (c) 2013-2016 Vidigami
	  License: MIT (http://www.opensource.org/licenses/mit-license.php)
	  Source: https://github.com/vidigami/backbone-orm
	  Dependencies: Backbone.js and Underscore.js.
	 */
	var CacheCursor, CacheSync, DESTROY_BATCH_LIMIT, DESTROY_THREADS, Schema, Utils, _, bbCallback;

	_ = __webpack_require__(1);

	CacheCursor = __webpack_require__(22);

	Schema = __webpack_require__(43);

	Utils = __webpack_require__(24);

	bbCallback = Utils.bbCallback;

	DESTROY_BATCH_LIMIT = 1000;

	DESTROY_THREADS = 100;

	CacheSync = (function() {
	  function CacheSync(model_type1, wrapped_sync_fn1) {
	    this.model_type = model_type1;
	    this.wrapped_sync_fn = wrapped_sync_fn1;
	  }

	  CacheSync.prototype.initialize = function() {
	    if (this.is_initialized) {
	      return;
	    }
	    this.is_initialized = true;
	    this.wrapped_sync_fn('initialize');
	    if (!this.model_type.model_name) {
	      throw new Error('Missing model_name for model');
	    }
	  };

	  CacheSync.prototype.read = function(model, options) {
	    var cached_model;
	    if (!options.force && (cached_model = this.model_type.cache.get(model.id))) {
	      return options.success(cached_model.toJSON());
	    }
	    return this.wrapped_sync_fn('read', model, options);
	  };

	  CacheSync.prototype.create = function(model, options) {
	    return this.wrapped_sync_fn('create', model, {
	      success: (function(_this) {
	        return function(json) {
	          var attributes, cache_model;
	          (attributes = {})[_this.model_type.prototype.idAttribute] = json[_this.model_type.prototype.idAttribute];
	          model.set(attributes);
	          if (cache_model = _this.model_type.cache.get(model.id)) {
	            if (cache_model !== model) {
	              Utils.updateModel(cache_model, model);
	            }
	          } else {
	            _this.model_type.cache.set(model.id, model);
	          }
	          return options.success(json);
	        };
	      })(this),
	      error: (function(_this) {
	        return function(resp) {
	          return typeof options.error === "function" ? options.error(resp) : void 0;
	        };
	      })(this)
	    });
	  };

	  CacheSync.prototype.update = function(model, options) {
	    return this.wrapped_sync_fn('update', model, {
	      success: (function(_this) {
	        return function(json) {
	          var cache_model;
	          if (cache_model = _this.model_type.cache.get(model.id)) {
	            if (cache_model !== model) {
	              Utils.updateModel(cache_model, model);
	            }
	          } else {
	            _this.model_type.cache.set(model.id, model);
	          }
	          return options.success(json);
	        };
	      })(this),
	      error: (function(_this) {
	        return function(resp) {
	          return typeof options.error === "function" ? options.error(resp) : void 0;
	        };
	      })(this)
	    });
	  };

	  CacheSync.prototype["delete"] = function(model, options) {
	    this.model_type.cache.destroy(model.id);
	    return this.wrapped_sync_fn('delete', model, options);
	  };

	  CacheSync.prototype.resetSchema = function(options, callback) {
	    return this.model_type.cache.reset((function(_this) {
	      return function(err) {
	        if (err) {
	          return callback(err);
	        }
	        return _this.wrapped_sync_fn('resetSchema', options, callback);
	      };
	    })(this));
	  };

	  CacheSync.prototype.cursor = function(query) {
	    if (query == null) {
	      query = {};
	    }
	    return new CacheCursor(query, _.pick(this, ['model_type', 'wrapped_sync_fn']));
	  };

	  CacheSync.prototype.destroy = function(query, callback) {
	    return this.model_type.each(_.extend({
	      $each: {
	        limit: DESTROY_BATCH_LIMIT,
	        threads: DESTROY_THREADS
	      }
	    }, query), ((function(_this) {
	      return function(model, callback) {
	        return model.destroy(callback);
	      };
	    })(this)), callback);
	  };

	  CacheSync.prototype.connect = function(url) {
	    this.model_type.cache.reset();
	    return this.wrapped_sync_fn('connect');
	  };

	  return CacheSync;

	})();

	module.exports = function(model_type, wrapped_sync_fn) {
	  var sync, sync_fn;
	  sync = new CacheSync(model_type, wrapped_sync_fn);
	  model_type.prototype.sync = sync_fn = function(method, model, options) {
	    if (options == null) {
	      options = {};
	    }
	    sync.initialize();
	    if (method === 'createSync') {
	      return wrapped_sync_fn.apply(null, arguments);
	    }
	    if (method === 'sync') {
	      return sync;
	    }
	    if (sync[method]) {
	      return sync[method].apply(sync, Array.prototype.slice.call(arguments, 1));
	    }
	    return wrapped_sync_fn.apply(wrapped_sync_fn, Array.prototype.slice.call(arguments));
	  };
	  return sync_fn;
	};


/***/ },
/* 22 */
/***/ function(module, exports, __webpack_require__) {

	
	/*
	  backbone-orm.js 0.7.14
	  Copyright (c) 2013-2016 Vidigami
	  License: MIT (http://www.opensource.org/licenses/mit-license.php)
	  Source: https://github.com/vidigami/backbone-orm
	  Dependencies: Backbone.js and Underscore.js.
	 */
	var CacheCursor, _,
	  extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
	  hasProp = {}.hasOwnProperty;

	_ = __webpack_require__(1);

	module.exports = CacheCursor = (function(superClass) {
	  extend(CacheCursor, superClass);

	  function CacheCursor() {
	    return CacheCursor.__super__.constructor.apply(this, arguments);
	  }

	  CacheCursor.prototype.toJSON = function(callback) {
	    return this.wrapped_sync_fn('cursor', _.extend({}, this._find, this._cursor)).toJSON(callback);
	  };

	  return CacheCursor;

	})(__webpack_require__(23));


/***/ },
/* 23 */
/***/ function(module, exports, __webpack_require__) {

	
	/*
	  backbone-orm.js 0.7.14
	  Copyright (c) 2013-2016 Vidigami
	  License: MIT (http://www.opensource.org/licenses/mit-license.php)
	  Source: https://github.com/vidigami/backbone-orm
	  Dependencies: Backbone.js and Underscore.js.
	 */
	var Cursor, DateUtils, IS_MATCH_FNS, IS_MATCH_OPERATORS, JSONUtils, MemoryCursor, Queue, Utils, _, mergeQuery, valueToArray,
	  extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
	  hasProp = {}.hasOwnProperty,
	  indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

	_ = __webpack_require__(1);

	Queue = __webpack_require__(11);

	Utils = __webpack_require__(24);

	JSONUtils = __webpack_require__(33);

	DateUtils = __webpack_require__(40);

	Cursor = __webpack_require__(42);

	IS_MATCH_FNS = {
	  $ne: function(mv, tv) {
	    return !_.isEqual(mv, tv);
	  },
	  $lt: function(mv, tv) {
	    if (_.isNull(tv)) {
	      throw Error('Cannot compare to null');
	    }
	    return (_.isDate(tv) ? DateUtils.isBefore(mv, tv) : mv < tv);
	  },
	  $lte: function(mv, tv) {
	    if (_.isNull(tv)) {
	      throw Error('Cannot compare to null');
	    }
	    if (_.isDate(tv)) {
	      return !DateUtils.isAfter(mv, tv);
	    } else {
	      return mv <= tv;
	    }
	  },
	  $gt: function(mv, tv) {
	    if (_.isNull(tv)) {
	      throw Error('Cannot compare to null');
	    }
	    return (_.isDate(tv) ? DateUtils.isAfter(mv, tv) : mv > tv);
	  },
	  $gte: function(mv, tv) {
	    if (_.isNull(tv)) {
	      throw Error('Cannot compare to null');
	    }
	    if (_.isDate(tv)) {
	      return !DateUtils.isBefore(mv, tv);
	    } else {
	      return mv >= tv;
	    }
	  },
	  $exists: function(mv, tv) {
	    if (!tv) {
	      return _.isUndefined(mv);
	    } else {
	      return !_.isUndefined(mv);
	    }
	  }
	};

	IS_MATCH_OPERATORS = _.keys(IS_MATCH_FNS);

	valueToArray = function(value) {
	  return (_.isArray(value) ? value : (_.isNull(value) ? [] : (value.$in ? value.$in : [value])));
	};

	mergeQuery = function(query, key, value) {
	  return query[key] = query.hasOwnProperty(key) ? {
	    $in: _.intersection(valueToArray(query[key]), valueToArray(value))
	  } : value;
	};

	module.exports = MemoryCursor = (function(superClass) {
	  extend(MemoryCursor, superClass);

	  function MemoryCursor() {
	    return MemoryCursor.__super__.constructor.apply(this, arguments);
	  }

	  MemoryCursor.prototype.queryToJSON = function(callback) {
	    var exists;
	    if (this.hasCursorQuery('$zero')) {
	      return callback(null, this.hasCursorQuery('$one') ? null : []);
	    }
	    exists = this.hasCursorQuery('$exists');
	    return this.buildFindQuery((function(_this) {
	      return function(err, find_query) {
	        var json, keys, queue;
	        if (err) {
	          return callback(err);
	        }
	        json = [];
	        keys = null;
	        queue = new Queue(1);
	        queue.defer(function(callback) {
	          var i, ins, ins_is_empty, key, len, model_json, nins, nins_is_empty, ref, ref1, ref2, ref3, value;
	          ref = [{}, {}], ins = ref[0], nins = ref[1];
	          for (key in find_query) {
	            value = find_query[key];
	            if (value != null ? value.$in : void 0) {
	              delete find_query[key];
	              ins[key] = value.$in;
	            }
	            if (value != null ? value.$nin : void 0) {
	              delete find_query[key];
	              nins[key] = value.$nin;
	            }
	          }
	          ref1 = [JSONUtils.isEmptyObject(ins), JSONUtils.isEmptyObject(nins)], ins_is_empty = ref1[0], nins_is_empty = ref1[1];
	          keys = _.keys(find_query);
	          if (keys.length || !ins_is_empty || !nins_is_empty) {
	            if (_this._cursor.$ids) {
	              ref2 = _this.store;
	              for (i = 0, len = ref2.length; i < len; i++) {
	                model_json = ref2[i];
	                if ((ref3 = model_json.id, indexOf.call(_this._cursor.$ids, ref3) >= 0) && _.isEqual(_.pick(model_json, keys), find_query)) {
	                  json.push(JSONUtils.deepClone(model_json));
	                }
	              }
	              return callback();
	            } else {
	              return Utils.each(_this.store, (function(model_json, callback) {
	                var is_match, ref4, ref5, values;
	                if (exists && json.length) {
	                  return callback(null, true);
	                }
	                if (!ins_is_empty) {
	                  for (key in ins) {
	                    values = ins[key];
	                    if (ref4 = model_json[key], indexOf.call(values, ref4) < 0) {
	                      return callback();
	                    }
	                  }
	                }
	                if (!nins_is_empty) {
	                  for (key in nins) {
	                    values = nins[key];
	                    if (ref5 = model_json[key], indexOf.call(values, ref5) >= 0) {
	                      return callback();
	                    }
	                  }
	                }
	                is_match = true;
	                return Utils.eachDone(keys, (function(key, callback) {
	                  return _this._valueIsMatch(find_query, key, model_json, function(err, _is_match) {
	                    return callback(err, !(is_match = _is_match));
	                  });
	                }), function(err) {
	                  err || !is_match || json.push(JSONUtils.deepClone(model_json));
	                  return callback(err);
	                });
	              }), callback);
	            }
	          } else {
	            if (_this._cursor.$ids) {
	              json = (function() {
	                var j, len1, ref4, ref5, results;
	                ref4 = this.store;
	                results = [];
	                for (j = 0, len1 = ref4.length; j < len1; j++) {
	                  model_json = ref4[j];
	                  if ((ref5 = model_json.id, indexOf.call(this._cursor.$ids, ref5) >= 0)) {
	                    results.push(JSONUtils.deepClone(model_json));
	                  }
	                }
	                return results;
	              }).call(_this);
	            } else {
	              json = (function() {
	                var j, len1, ref4, results;
	                ref4 = this.store;
	                results = [];
	                for (j = 0, len1 = ref4.length; j < len1; j++) {
	                  model_json = ref4[j];
	                  results.push(JSONUtils.deepClone(model_json));
	                }
	                return results;
	              }).call(_this);
	            }
	            return callback();
	          }
	        });
	        if (!exists) {
	          queue.defer(function(callback) {
	            var $sort_fields, field, i, j, key, len, len1, model_json, number, ref, unique_json, unique_keys;
	            if (_this._cursor.$sort) {
	              $sort_fields = _.isArray(_this._cursor.$sort) ? _this._cursor.$sort : [_this._cursor.$sort];
	              json.sort(function(model, next_model) {
	                return Utils.jsonFieldCompare(model, next_model, $sort_fields);
	              });
	            }
	            if (_this._cursor.$unique) {
	              unique_json = [];
	              unique_keys = {};
	              for (i = 0, len = json.length; i < len; i++) {
	                model_json = json[i];
	                key = '';
	                ref = _this._cursor.$unique;
	                for (j = 0, len1 = ref.length; j < len1; j++) {
	                  field = ref[j];
	                  if (model_json.hasOwnProperty(field)) {
	                    key += field + ":" + (JSON.stringify(model_json[field]));
	                  }
	                }
	                if (unique_keys[key]) {
	                  continue;
	                }
	                unique_keys[key] = true;
	                unique_json.push(model_json);
	              }
	              json = unique_json;
	            }
	            if (_this._cursor.$offset) {
	              number = json.length - _this._cursor.$offset;
	              if (number < 0) {
	                number = 0;
	              }
	              json = number ? json.slice(_this._cursor.$offset, _this._cursor.$offset + number) : [];
	            }
	            if (_this._cursor.$one) {
	              json = json.slice(0, 1);
	            } else if (_this._cursor.$limit) {
	              json = json.splice(0, Math.min(json.length, _this._cursor.$limit));
	            }
	            return callback();
	          });
	          queue.defer(function(callback) {
	            return _this.fetchIncludes(json, callback);
	          });
	        }
	        queue.await(function() {
	          var count_cursor;
	          if (_this.hasCursorQuery('$count')) {
	            return callback(null, (_.isArray(json) ? json.length : (json ? 1 : 0)));
	          }
	          if (exists) {
	            return callback(null, (_.isArray(json) ? !!json.length : json));
	          }
	          if (_this.hasCursorQuery('$page')) {
	            count_cursor = new MemoryCursor(_.extend(_.pick(_this._cursor, '$unique'), _this._find), _.pick(_this, ['model_type', 'store']));
	            return count_cursor.count(function(err, count) {
	              if (err) {
	                return callback(err);
	              }
	              return callback(null, {
	                offset: _this._cursor.$offset || 0,
	                total_rows: count,
	                rows: _this.selectResults(json)
	              });
	            });
	          } else {
	            return callback(null, _this.selectResults(json));
	          }
	        });
	      };
	    })(this));
	  };

	  MemoryCursor.prototype.buildFindQuery = function(callback) {
	    var find_query, fn, key, queue, ref, ref1, relation_key, reverse_relation, value, value_key;
	    queue = new Queue();
	    find_query = {};
	    ref = this._find;
	    fn = (function(_this) {
	      return function(relation_key, value_key, value) {
	        return queue.defer(function(callback) {
	          var related_query, relation;
	          if (!(relation = _this.model_type.relation(relation_key))) {
	            mergeQuery(find_query, key, value);
	            return callback();
	          }
	          if (!relation.join_table && (value_key === 'id')) {
	            mergeQuery(find_query, relation.foreign_key, value);
	            return callback();
	          } else if (relation.join_table || (relation.type === 'belongsTo')) {
	            (related_query = {
	              $values: 'id'
	            })[value_key] = value;
	            return relation.reverse_relation.model_type.cursor(related_query).toJSON(function(err, related_ids) {
	              var join_query;
	              if (err) {
	                return callback(err);
	              }
	              if (relation.join_table) {
	                (join_query = {})[relation.reverse_relation.join_key] = {
	                  $in: related_ids
	                };
	                join_query.$values = relation.foreign_key;
	                return relation.join_table.cursor(join_query).toJSON(function(err, model_ids) {
	                  if (err) {
	                    return callback(err);
	                  }
	                  mergeQuery(find_query, 'id', {
	                    $in: model_ids
	                  });
	                  return callback();
	                });
	              } else {
	                mergeQuery(find_query, relation.foreign_key, {
	                  $in: related_ids
	                });
	                return callback();
	              }
	            });
	          } else {
	            (related_query = {})[value_key] = value;
	            related_query.$values = relation.foreign_key;
	            return relation.reverse_model_type.cursor(related_query).toJSON(function(err, model_ids) {
	              if (err) {
	                return callback(err);
	              }
	              mergeQuery(find_query, 'id', {
	                $in: model_ids
	              });
	              return callback();
	            });
	          }
	        });
	      };
	    })(this);
	    for (key in ref) {
	      value = ref[key];
	      if (key.indexOf('.') < 0) {
	        if (!(reverse_relation = this.model_type.reverseRelation(key))) {
	          mergeQuery(find_query, key, value);
	          continue;
	        }
	        if (!reverse_relation.embed && !reverse_relation.join_table) {
	          mergeQuery(find_query, key, value);
	          continue;
	        }
	        (function(_this) {
	          return (function(key, value, reverse_relation) {
	            return queue.defer(function(callback) {
	              var related_query;
	              if (reverse_relation.embed) {
	                throw Error("Embedded find is not yet supported. @_find: " + (JSONUtils.stringify(_this._find)));
	                (related_query = {}).id = value;
	                return reverse_relation.model_type.cursor(related_query).toJSON(function(err, models_json) {
	                  var model_json;
	                  if (err) {
	                    return callback(err);
	                  }
	                  mergeQuery(find_query, '_json', (function() {
	                    var i, len, results;
	                    results = [];
	                    for (i = 0, len = models_json.length; i < len; i++) {
	                      model_json = models_json[i];
	                      results.push(model_json[reverse_relation.key]);
	                    }
	                    return results;
	                  })());
	                  return callback();
	                });
	              } else {
	                (related_query = {})[key] = value;
	                related_query.$values = reverse_relation.reverse_relation.join_key;
	                return reverse_relation.join_table.cursor(related_query).toJSON(function(err, model_ids) {
	                  if (err) {
	                    return callback(err);
	                  }
	                  mergeQuery(find_query, 'id', {
	                    $in: model_ids
	                  });
	                  return callback();
	                });
	              }
	            });
	          });
	        })(this)(key, value, reverse_relation);
	        continue;
	      }
	      ref1 = key.split('.'), relation_key = ref1[0], value_key = ref1[1];
	      if (this.model_type.relationIsEmbedded(relation_key)) {
	        mergeQuery(find_query, key, value);
	        continue;
	      }
	      fn(relation_key, value_key, value);
	    }
	    return queue.await((function(_this) {
	      return function(err) {
	        return callback(err, find_query);
	      };
	    })(this));
	  };

	  MemoryCursor.prototype.fetchIncludes = function(json, callback) {
	    var fn, i, include_keys, j, key, len, len1, load_queue, model_json, relation;
	    if (!this._cursor.$include) {
	      return callback();
	    }
	    load_queue = new Queue(1);
	    include_keys = _.isArray(this._cursor.$include) ? this._cursor.$include : [this._cursor.$include];
	    for (i = 0, len = include_keys.length; i < len; i++) {
	      key = include_keys[i];
	      if (this.model_type.relationIsEmbedded(key)) {
	        continue;
	      }
	      if (!(relation = this.model_type.relation(key))) {
	        return callback(new Error("Included relation '" + key + "' is not a relation"));
	      }
	      fn = (function(_this) {
	        return function(key, model_json) {
	          return load_queue.defer(function(callback) {
	            return relation.cursor(model_json, key).toJSON(function(err, related_json) {
	              if (err) {
	                return callback(err);
	              }
	              delete model_json[relation.foriegn_key];
	              model_json[key] = related_json;
	              return callback();
	            });
	          });
	        };
	      })(this);
	      for (j = 0, len1 = json.length; j < len1; j++) {
	        model_json = json[j];
	        fn(key, model_json);
	      }
	    }
	    return load_queue.await(callback);
	  };

	  MemoryCursor.prototype._valueIsMatch = function(find_query, key_path, model_json, callback) {
	    var find_value, isMatch, key_components, model_type, next, operator, operators;
	    model_type = this.model_type;
	    find_value = find_query[key_path];
	    if (_.isObject(find_value)) {
	      operators = (function() {
	        var i, len, results;
	        results = [];
	        for (i = 0, len = IS_MATCH_OPERATORS.length; i < len; i++) {
	          operator = IS_MATCH_OPERATORS[i];
	          if (find_value.hasOwnProperty(operator)) {
	            results.push(operator);
	          }
	        }
	        return results;
	      })();
	    }
	    key_components = key_path.split('.');
	    isMatch = function(model_json, key) {
	      var i, len, model_value;
	      model_value = model_json[key];
	      if (operators && operators.length) {
	        for (i = 0, len = operators.length; i < len; i++) {
	          operator = operators[i];
	          if (!IS_MATCH_FNS[operator](model_value, find_value[operator])) {
	            return false;
	          }
	        }
	        return true;
	      }
	      return _.isEqual(model_value, find_value);
	    };
	    if (key_components.length === 1) {
	      return callback(null, isMatch(model_json, key_components[0]));
	    }
	    next = (function(_this) {
	      return function(err, model_json) {
	        var i, json, key, len, relation;
	        if (err) {
	          return callback(err);
	        }
	        key = key_components.shift();
	        if (key === 'id') {
	          key = _this.model_type.prototype.idAttribute;
	        }
	        if (key_components.length) {
	          if ((relation = model_type.relation(key)) && !relation.embed) {
	            return relation.cursor(model_json, key).toJSON(next);
	          }
	          return next(null, model_json[key]);
	        } else {
	          if (!_.isArray(model_json)) {
	            return callback(null, isMatch(model_json, key));
	          }
	          for (i = 0, len = model_json.length; i < len; i++) {
	            json = model_json[i];
	            if (isMatch(json, key)) {
	              return callback(null, true);
	            }
	          }
	          return callback(null, false);
	        }
	      };
	    })(this);
	    return next(null, model_json);
	  };

	  return MemoryCursor;

	})(Cursor);


/***/ },
/* 24 */
/***/ function(module, exports, __webpack_require__) {

	
	/*
	  backbone-orm.js 0.7.14
	  Copyright (c) 2013-2016 Vidigami
	  License: MIT (http://www.opensource.org/licenses/mit-license.php)
	  Source: https://github.com/vidigami/backbone-orm
	  Dependencies: Backbone.js and Underscore.js.
	 */
	var Backbone, BackboneORM, DatabaseURL, IterationUtils, JSONUtils, Queue, URL, Utils, _, modelExtensions,
	  extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
	  hasProp = {}.hasOwnProperty;

	URL = __webpack_require__(25);

	Backbone = __webpack_require__(2);

	_ = __webpack_require__(1);

	BackboneORM = __webpack_require__(3);

	DatabaseURL = __webpack_require__(32);

	Queue = __webpack_require__(11);

	JSONUtils = __webpack_require__(33);

	IterationUtils = __webpack_require__(34);

	modelExtensions = null;

	module.exports = Utils = (function() {
	  function Utils() {}

	  Utils.resetSchemas = function(model_types, options, callback) {
	    var failed_schemas, i, len, model_type, ref;
	    if (arguments.length === 2) {
	      ref = [{}, options], options = ref[0], callback = ref[1];
	    }
	    for (i = 0, len = model_types.length; i < len; i++) {
	      model_type = model_types[i];
	      model_type.schema();
	    }
	    failed_schemas = [];
	    return Utils.each(model_types, (function(model_type, callback) {
	      return model_type.resetSchema(options, function(err) {
	        if (err) {
	          failed_schemas.push(model_type.model_name);
	          console.log("Error when dropping schema for " + model_type.model_name + ". " + err);
	        }
	        return callback();
	      });
	    }), function(err) {
	      if (options.verbose) {
	        console.log((model_types.length - failed_schemas.length) + " schemas dropped.");
	      }
	      BackboneORM.model_cache.reset();
	      if (failed_schemas.length) {
	        return callback(new Error("Failed to migrate schemas: " + (failed_schemas.join(', '))));
	      }
	      return callback();
	    });
	  };

	  Utils.bbCallback = function(callback) {
	    return {
	      success: (function(model, resp, options) {
	        return callback(null, model, resp, options);
	      }),
	      error: (function(model, resp, options) {
	        return callback(resp || new Error('Backbone call failed'), model, resp, options);
	      })
	    };
	  };

	  Utils.wrapOptions = function(options, callback) {
	    if (options == null) {
	      options = {};
	    }
	    if (_.isFunction(options)) {
	      options = Utils.bbCallback(options);
	    }
	    return _.defaults(Utils.bbCallback(function(err, model, resp, modified_options) {
	      return callback(err, model, resp, options);
	    }), options);
	  };

	  Utils.isModel = function(obj) {
	    return obj && obj.attributes && ((obj instanceof Backbone.Model) || (obj.parse && obj.fetch));
	  };

	  Utils.isCollection = function(obj) {
	    return obj && obj.models && ((obj instanceof Backbone.Collection) || (obj.reset && obj.fetch));
	  };

	  Utils.get = function(obj, key, default_value) {
	    if (!obj._orm || !obj._orm.hasOwnProperty(key)) {
	      return default_value;
	    } else {
	      return obj._orm[key];
	    }
	  };

	  Utils.set = function(obj, key, value) {
	    return (obj._orm || (obj._orm = {}))[key] = value;
	  };

	  Utils.orSet = function(obj, key, value) {
	    if (!(obj._orm || (obj._orm = {})).hasOwnProperty(key)) {
	      obj._orm[key] = value;
	    }
	    return obj._orm[key];
	  };

	  Utils.unset = function(obj, key) {
	    return delete (obj._orm || (obj._orm = {}))[key];
	  };

	  Utils.findOrGenerateModelName = function(model_type) {
	    var model_name, url;
	    if (model_type.prototype.model_name) {
	      return model_type.prototype.model_name;
	    }
	    if (url = _.result(new model_type, 'url')) {
	      if (model_name = (new DatabaseURL(url)).modelName()) {
	        return model_name;
	      }
	    }
	    if (model_type.name) {
	      return model_type.name;
	    }
	    throw "Could not find or generate model name for " + model_type;
	  };

	  Utils.configureCollectionModelType = function(type, sync) {
	    var ORMModel, modelURL, model_type;
	    modelURL = function() {
	      var url, url_parts;
	      url = _.result(this.collection || type.prototype, 'url');
	      if (!this.isNew()) {
	        url_parts = URL.parse(url);
	        url_parts.pathname = url_parts.pathname + "/encodeURIComponent(@id)";
	        url = URL.format(url_parts);
	      }
	      return url;
	    };
	    model_type = type.prototype.model;
	    if (!model_type || (model_type === Backbone.Model)) {
	      ORMModel = (function(superClass) {
	        extend(ORMModel, superClass);

	        function ORMModel() {
	          return ORMModel.__super__.constructor.apply(this, arguments);
	        }

	        ORMModel.prototype.url = modelURL;

	        ORMModel.prototype.schema = type.prototype.schema;

	        ORMModel.prototype.sync = sync(ORMModel);

	        return ORMModel;

	      })(Backbone.Model);
	      return type.prototype.model = ORMModel;
	    } else if (model_type.prototype.sync === Backbone.Model.prototype.sync) {
	      model_type.prototype.url = modelURL;
	      model_type.prototype.schema = type.prototype.schema;
	      model_type.prototype.sync = sync(model_type);
	    }
	    return model_type;
	  };

	  Utils.configureModelType = function(type) {
	    modelExtensions || (modelExtensions = __webpack_require__(35));
	    return modelExtensions(type);
	  };

	  Utils.patchRemove = function(model_type, model, callback) {
	    var fn, key, queue, ref, relation, schema;
	    if (!(schema = model_type.schema())) {
	      return callback();
	    }
	    queue = new Queue(1);
	    ref = schema.relations;
	    fn = function(relation) {
	      return queue.defer(function(callback) {
	        return relation.patchRemove(model, callback);
	      });
	    };
	    for (key in ref) {
	      relation = ref[key];
	      fn(relation);
	    }
	    return queue.await(callback);
	  };

	  Utils.patchRemoveByJSON = function(model_type, model_json, callback) {
	    return Utils.patchRemove(model_type, model_json, callback);
	  };

	  Utils.presaveBelongsToRelationships = function(model, callback) {
	    var fn, i, key, len, queue, ref, related_model, related_models, relation, schema, value;
	    if (!model.schema) {
	      return callback();
	    }
	    queue = new Queue(1);
	    schema = model.schema();
	    ref = schema.relations;
	    for (key in ref) {
	      relation = ref[key];
	      if (relation.type !== 'belongsTo' || relation.isVirtual() || !(value = model.get(key))) {
	        continue;
	      }
	      related_models = value.models ? value.models : [value];
	      fn = (function(_this) {
	        return function(related_model) {
	          return queue.defer(function(callback) {
	            return related_model.save(callback);
	          });
	        };
	      })(this);
	      for (i = 0, len = related_models.length; i < len; i++) {
	        related_model = related_models[i];
	        if (related_model.id) {
	          continue;
	        }
	        fn(related_model);
	      }
	    }
	    return queue.await(callback);
	  };

	  Utils.dataId = function(data) {
	    if (_.isObject(data)) {
	      return data.id;
	    } else {
	      return data;
	    }
	  };

	  Utils.dataIsSameModel = function(data1, data2) {
	    if (Utils.dataId(data1) || Utils.dataId(data2)) {
	      return Utils.dataId(data1) === Utils.dataId(data2);
	    }
	    return _.isEqual(data1, data2);
	  };

	  Utils.dataToModel = function(data, model_type) {
	    var attributes, item, model;
	    if (!data) {
	      return null;
	    }
	    if (_.isArray(data)) {
	      return (function() {
	        var i, len, results;
	        results = [];
	        for (i = 0, len = data.length; i < len; i++) {
	          item = data[i];
	          results.push(Utils.dataToModel(item, model_type));
	        }
	        return results;
	      })();
	    }
	    if (Utils.isModel(data)) {
	      model = data;
	    } else if (Utils.dataId(data) !== data) {
	      model = new model_type(model_type.prototype.parse(data));
	    } else {
	      (attributes = {})[model_type.prototype.idAttribute] = data;
	      model = new model_type(attributes);
	      model.setLoaded(false);
	    }
	    return model;
	  };

	  Utils.updateModel = function(model, data) {
	    if (!data || (model === data) || data._orm_needs_load) {
	      return model;
	    }
	    if (Utils.isModel(data)) {
	      data = data.toJSON();
	    }
	    if (Utils.dataId(data) !== data) {
	      model.setLoaded(true);
	      model.set(data);
	    }
	    return model;
	  };

	  Utils.updateOrNew = function(data, model_type) {
	    var cache, id, model;
	    if ((cache = model_type.cache) && (id = Utils.dataId(data))) {
	      if (Utils.isModel(data) && data.isLoaded()) {
	        model = data;
	      } else if (model = cache.get(id)) {
	        Utils.updateModel(model, data);
	      }
	    }
	    if (!model) {
	      model = Utils.isModel(data) ? data : Utils.dataToModel(data, model_type);
	      if (model && cache) {
	        cache.set(model.id, model);
	      }
	    }
	    return model;
	  };

	  Utils.modelJSONSave = function(model_json, model_type, callback) {
	    var JSONModel, url_root;
	    model_type._orm || (model_type._orm = {});
	    if (!model_type._orm.model_type_json) {
	      try {
	        url_root = _.result(new model_type, 'url');
	      } catch (undefined) {}
	      model_type._orm.model_type_json = JSONModel = (function(superClass) {
	        extend(JSONModel, superClass);

	        function JSONModel() {
	          return JSONModel.__super__.constructor.apply(this, arguments);
	        }

	        JSONModel.prototype._orm_never_cache = true;

	        JSONModel.prototype.urlRoot = function() {
	          return url_root;
	        };

	        return JSONModel;

	      })(Backbone.Model);
	    }
	    if (model_type.prototype.whitelist) {
	      model_json = _.pick(model_json, model_type.prototype.whitelist);
	    }
	    return model_type.prototype.sync('update', new model_type._orm.model_type_json(model_json), Utils.bbCallback(callback));
	  };

	  Utils.each = IterationUtils.each;

	  Utils.eachC = function(array, callback, iterator) {
	    return IterationUtils.each(array, iterator, callback);
	  };

	  Utils.popEach = IterationUtils.popEach;

	  Utils.popEachC = function(array, callback, iterator) {
	    return IterationUtils.popEach(array, iterator, callback);
	  };

	  Utils.eachDone = IterationUtils.eachDone;

	  Utils.eachDoneC = function(array, callback, iterator) {
	    return IterationUtils.eachDone(array, iterator, callback);
	  };

	  Utils.isSorted = function(models, fields) {
	    var i, last_model, len, model;
	    fields = _.uniq(fields);
	    for (i = 0, len = models.length; i < len; i++) {
	      model = models[i];
	      if (last_model && this.fieldCompare(last_model, model, fields) === 1) {
	        return false;
	      }
	      last_model = model;
	    }
	    return true;
	  };

	  Utils.fieldCompare = function(model, other_model, fields) {
	    var desc, field;
	    field = fields[0];
	    if (_.isArray(field)) {
	      field = field[0];
	    }
	    if (field.charAt(0) === '-') {
	      field = field.substr(1);
	      desc = true;
	    }
	    if (model.get(field) === other_model.get(field)) {
	      if (fields.length > 1) {
	        return this.fieldCompare(model, other_model, fields.splice(1));
	      } else {
	        return 0;
	      }
	    }
	    if (desc) {
	      if (model.get(field) < other_model.get(field)) {
	        return 1;
	      } else {
	        return -1;
	      }
	    } else {
	      if (model.get(field) > other_model.get(field)) {
	        return 1;
	      } else {
	        return -1;
	      }
	    }
	  };

	  Utils.jsonFieldCompare = function(model, other_model, fields) {
	    var desc, field;
	    field = fields[0];
	    if (_.isArray(field)) {
	      field = field[0];
	    }
	    if (field.charAt(0) === '-') {
	      field = field.substr(1);
	      desc = true;
	    }
	    if (model[field] === other_model[field]) {
	      if (fields.length > 1) {
	        return this.jsonFieldCompare(model, other_model, fields.splice(1));
	      } else {
	        return 0;
	      }
	    }
	    if (desc) {
	      if (JSONUtils.stringify(model[field]) < JSONUtils.stringify(other_model[field])) {
	        return 1;
	      } else {
	        return -1;
	      }
	    } else {
	      if (JSONUtils.stringify(model[field]) > JSONUtils.stringify(other_model[field])) {
	        return 1;
	      } else {
	        return -1;
	      }
	    }
	  };

	  return Utils;

	})();


/***/ },
/* 25 */
/***/ function(module, exports, __webpack_require__) {

	// Copyright Joyent, Inc. and other Node contributors.
	//
	// Permission is hereby granted, free of charge, to any person obtaining a
	// copy of this software and associated documentation files (the
	// "Software"), to deal in the Software without restriction, including
	// without limitation the rights to use, copy, modify, merge, publish,
	// distribute, sublicense, and/or sell copies of the Software, and to permit
	// persons to whom the Software is furnished to do so, subject to the
	// following conditions:
	//
	// The above copyright notice and this permission notice shall be included
	// in all copies or substantial portions of the Software.
	//
	// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
	// OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
	// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN
	// NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
	// DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
	// OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE
	// USE OR OTHER DEALINGS IN THE SOFTWARE.

	var punycode = { encode : function (s) { return s } };
	var _ = __webpack_require__(1);
	var shims = __webpack_require__(26);

	exports.parse = urlParse;
	exports.resolve = urlResolve;
	exports.resolveObject = urlResolveObject;
	exports.format = urlFormat;

	exports.Url = Url;

	function Url() {
	  this.protocol = null;
	  this.slashes = null;
	  this.auth = null;
	  this.host = null;
	  this.port = null;
	  this.hostname = null;
	  this.hash = null;
	  this.search = null;
	  this.query = null;
	  this.pathname = null;
	  this.path = null;
	  this.href = null;
	}

	// Reference: RFC 3986, RFC 1808, RFC 2396

	// define these here so at least they only have to be
	// compiled once on the first module load.
	var protocolPattern = /^([a-z0-9.+-]+:)/i,
	    portPattern = /:[0-9]*$/,

	    // RFC 2396: characters reserved for delimiting URLs.
	    // We actually just auto-escape these.
	    delims = ['<', '>', '"', '`', ' ', '\r', '\n', '\t'],

	    // RFC 2396: characters not allowed for various reasons.
	    unwise = ['{', '}', '|', '\\', '^', '`'].concat(delims),

	    // Allowed by RFCs, but cause of XSS attacks.  Always escape these.
	    autoEscape = ['\''].concat(unwise),
	    // Characters that are never ever allowed in a hostname.
	    // Note that any invalid chars are also handled, but these
	    // are the ones that are *expected* to be seen, so we fast-path
	    // them.
	    nonHostChars = ['%', '/', '?', ';', '#'].concat(autoEscape),
	    hostEndingChars = ['/', '?', '#'],
	    hostnameMaxLen = 255,
	    hostnamePartPattern = /^[a-z0-9A-Z_-]{0,63}$/,
	    hostnamePartStart = /^([a-z0-9A-Z_-]{0,63})(.*)$/,
	    // protocols that can allow "unsafe" and "unwise" chars.
	    unsafeProtocol = {
	      'javascript': true,
	      'javascript:': true
	    },
	    // protocols that never have a hostname.
	    hostlessProtocol = {
	      'javascript': true,
	      'javascript:': true
	    },
	    // protocols that always contain a // bit.
	    slashedProtocol = {
	      'http': true,
	      'https': true,
	      'ftp': true,
	      'gopher': true,
	      'file': true,
	      'http:': true,
	      'https:': true,
	      'ftp:': true,
	      'gopher:': true,
	      'file:': true
	    },
	    querystring = __webpack_require__(27);

	function urlParse(url, parseQueryString, slashesDenoteHost) {
	  if (url && _.isObject(url) && url instanceof Url) return url;

	  var u = new Url;
	  u.parse(url, parseQueryString, slashesDenoteHost);
	  return u;
	}

	Url.prototype.parse = function(url, parseQueryString, slashesDenoteHost) {
	  if (!_.isString(url)) {
	    throw new TypeError("Parameter 'url' must be a string, not " + typeof url);
	  }

	  // Copy chrome, IE, opera backslash-handling behavior.
	  // See: https://code.google.com/p/chromium/issues/detail?id=25916
	  var hashSplit = url.split('#');
	  hashSplit[0] = hashSplit[0].replace(/\\/g, '/');
	  url = hashSplit.join('#');

	  var rest = url;

	  // trim before proceeding.
	  // This is to support parse stuff like "  http://foo.com  \n"
	  rest = rest.trim();

	  var proto = protocolPattern.exec(rest);
	  if (proto) {
	    proto = proto[0];
	    var lowerProto = proto.toLowerCase();
	    this.protocol = lowerProto;
	    rest = rest.substr(proto.length);
	  }

	  // figure out if it's got a host
	  // user@server is *always* interpreted as a hostname, and url
	  // resolution will treat //foo/bar as host=foo,path=bar because that's
	  // how the browser resolves relative URLs.
	  if (slashesDenoteHost || proto || rest.match(/^\/\/[^@\/]+@[^@\/]+/)) {
	    var slashes = rest.substr(0, 2) === '//';
	    if (slashes && !(proto && hostlessProtocol[proto])) {
	      rest = rest.substr(2);
	      this.slashes = true;
	    }
	  }

	  if (!hostlessProtocol[proto] &&
	      (slashes || (proto && !slashedProtocol[proto]))) {

	    // there's a hostname.
	    // the first instance of /, ?, ;, or # ends the host.
	    //
	    // If there is an @ in the hostname, then non-host chars *are* allowed
	    // to the left of the last @ sign, unless some host-ending character
	    // comes *before* the @-sign.
	    // URLs are obnoxious.
	    //
	    // ex:
	    // http://a@b@c/ => user:a@b host:c
	    // http://a@b?@c => user:a host:c path:/?@c

	    // v0.12 TODO(isaacs): This is not quite how Chrome does things.
	    // Review our test case against browsers more comprehensively.

	    // find the first instance of any hostEndingChars
	    var hostEnd = -1;
	    for (var i = 0; i < hostEndingChars.length; i++) {
	      var hec = rest.indexOf(hostEndingChars[i]);
	      if (hec !== -1 && (hostEnd === -1 || hec < hostEnd))
	        hostEnd = hec;
	    }

	    // at this point, either we have an explicit point where the
	    // auth portion cannot go past, or the last @ char is the decider.
	    var auth, atSign;
	    if (hostEnd === -1) {
	      // atSign can be anywhere.
	      atSign = rest.lastIndexOf('@');
	    } else {
	      // atSign must be in auth portion.
	      // http://a@b/c@d => host:b auth:a path:/c@d
	      atSign = rest.lastIndexOf('@', hostEnd);
	    }

	    // Now we have a portion which is definitely the auth.
	    // Pull that off.
	    if (atSign !== -1) {
	      auth = rest.slice(0, atSign);
	      rest = rest.slice(atSign + 1);
	      this.auth = decodeURIComponent(auth);
	    }

	    // the host is the remaining to the left of the first non-host char
	    hostEnd = -1;
	    for (var i = 0; i < nonHostChars.length; i++) {
	      var hec = rest.indexOf(nonHostChars[i]);
	      if (hec !== -1 && (hostEnd === -1 || hec < hostEnd))
	        hostEnd = hec;
	    }
	    // if we still have not hit it, then the entire thing is a host.
	    if (hostEnd === -1)
	      hostEnd = rest.length;

	    this.host = rest.slice(0, hostEnd);
	    rest = rest.slice(hostEnd);

	    // pull out port.
	    this.parseHost();

	    // we've indicated that there is a hostname,
	    // so even if it's empty, it has to be present.
	    this.hostname = this.hostname || '';

	    // if hostname begins with [ and ends with ]
	    // assume that it's an IPv6 address.
	    var ipv6Hostname = this.hostname[0] === '[' &&
	        this.hostname[this.hostname.length - 1] === ']';

	    // validate a little.
	    if (!ipv6Hostname) {
	      var hostparts = this.hostname.split(/\./);
	      for (var i = 0, l = hostparts.length; i < l; i++) {
	        var part = hostparts[i];
	        if (!part) continue;
	        if (!part.match(hostnamePartPattern)) {
	          var newpart = '';
	          for (var j = 0, k = part.length; j < k; j++) {
	            if (part.charCodeAt(j) > 127) {
	              // we replace non-ASCII char with a temporary placeholder
	              // we need this to make sure size of hostname is not
	              // broken by replacing non-ASCII by nothing
	              newpart += 'x';
	            } else {
	              newpart += part[j];
	            }
	          }
	          // we test again with ASCII char only
	          if (!newpart.match(hostnamePartPattern)) {
	            var validParts = hostparts.slice(0, i);
	            var notHost = hostparts.slice(i + 1);
	            var bit = part.match(hostnamePartStart);
	            if (bit) {
	              validParts.push(bit[1]);
	              notHost.unshift(bit[2]);
	            }
	            if (notHost.length) {
	              rest = '/' + notHost.join('.') + rest;
	            }
	            this.hostname = validParts.join('.');
	            break;
	          }
	        }
	      }
	    }

	    if (this.hostname.length > hostnameMaxLen) {
	      this.hostname = '';
	    } else {
	      // hostnames are always lower case.
	      this.hostname = this.hostname.toLowerCase();
	    }

	    if (!ipv6Hostname) {
	      // IDNA Support: Returns a puny coded representation of "domain".
	      // It only converts the part of the domain name that
	      // has non ASCII characters. I.e. it dosent matter if
	      // you call it with a domain that already is in ASCII.
	      var domainArray = this.hostname.split('.');
	      var newOut = [];
	      for (var i = 0; i < domainArray.length; ++i) {
	        var s = domainArray[i];
	        newOut.push(s.match(/[^A-Za-z0-9_-]/) ?
	            'xn--' + punycode.encode(s) : s);
	      }
	      this.hostname = newOut.join('.');
	    }

	    var p = this.port ? ':' + this.port : '';
	    var h = this.hostname || '';
	    this.host = h + p;
	    this.href += this.host;

	    // strip [ and ] from the hostname
	    // the host field still retains them, though
	    if (ipv6Hostname) {
	      this.hostname = this.hostname.substr(1, this.hostname.length - 2);
	      if (rest[0] !== '/') {
	        rest = '/' + rest;
	      }
	    }
	  }

	  // now rest is set to the post-host stuff.
	  // chop off any delim chars.
	  if (!unsafeProtocol[lowerProto]) {

	    // First, make 100% sure that any "autoEscape" chars get
	    // escaped, even if encodeURIComponent doesn't think they
	    // need to be.
	    for (var i = 0, l = autoEscape.length; i < l; i++) {
	      var ae = autoEscape[i];
	      var esc = encodeURIComponent(ae);
	      if (esc === ae) {
	        esc = escape(ae);
	      }
	      rest = rest.split(ae).join(esc);
	    }
	  }


	  // chop off from the tail first.
	  var hash = rest.indexOf('#');
	  if (hash !== -1) {
	    // got a fragment string.
	    this.hash = rest.substr(hash);
	    rest = rest.slice(0, hash);
	  }
	  var qm = rest.indexOf('?');
	  if (qm !== -1) {
	    this.search = rest.substr(qm);
	    this.query = rest.substr(qm + 1);
	    if (parseQueryString) {
	      this.query = querystring.parse(this.query);
	    }
	    rest = rest.slice(0, qm);
	  } else if (parseQueryString) {
	    // no query string, but parseQueryString still requested
	    this.search = '';
	    this.query = {};
	  }
	  if (rest) this.pathname = rest;
	  if (slashedProtocol[lowerProto] &&
	      this.hostname && !this.pathname) {
	    this.pathname = '/';
	  }

	  //to support http.request
	  if (this.pathname || this.search) {
	    var p = this.pathname || '';
	    var s = this.search || '';
	    this.path = p + s;
	  }

	  // finally, reconstruct the href based on what has been validated.
	  this.href = this.format();
	  return this;
	};

	// format a parsed object into a url string
	function urlFormat(obj) {
	  // ensure it's an object, and not a string url.
	  // If it's an obj, this is a no-op.
	  // this way, you can call url_format() on strings
	  // to clean up potentially wonky urls.
	  if (_.isString(obj)) obj = urlParse(obj);
	  if (!(obj instanceof Url)) return Url.prototype.format.call(obj);
	  return obj.format();
	}

	Url.prototype.format = function() {
	  var auth = this.auth || '';
	  if (auth) {
	    auth = encodeURIComponent(auth);
	    auth = auth.replace(/%3A/i, ':');
	    auth += '@';
	  }

	  var protocol = this.protocol || '',
	      pathname = this.pathname || '',
	      hash = this.hash || '',
	      host = false,
	      query = '';

	  if (this.host) {
	    host = auth + this.host;
	  } else if (this.hostname) {
	    host = auth + (this.hostname.indexOf(':') === -1 ?
	        this.hostname :
	        '[' + this.hostname + ']');
	    if (this.port) {
	      host += ':' + this.port;
	    }
	  }

	  if (this.query &&
	      _.isObject(this.query) &&
	      Object.keys(this.query).length) {
	    query = querystring.stringify(this.query);
	  }

	  var search = this.search || (query && ('?' + query)) || '';

	  if (protocol && protocol.substr(-1) !== ':') protocol += ':';

	  // only the slashedProtocols get the //.  Not mailto:, xmpp:, etc.
	  // unless they had them to begin with.
	  if (this.slashes ||
	      (!protocol || slashedProtocol[protocol]) && host !== false) {
	    host = '//' + (host || '');
	    if (pathname && pathname.charAt(0) !== '/') pathname = '/' + pathname;
	  } else if (!host) {
	    host = '';
	  }

	  if (hash && hash.charAt(0) !== '#') hash = '#' + hash;
	  if (search && search.charAt(0) !== '?') search = '?' + search;

	  pathname = pathname.replace(/[?#]/g, function(match) {
	    return encodeURIComponent(match);
	  });
	  search = search.replace('#', '%23');

	  return protocol + host + pathname + search + hash;
	};

	function urlResolve(source, relative) {
	  return urlParse(source, false, true).resolve(relative);
	}

	Url.prototype.resolve = function(relative) {
	  return this.resolveObject(urlParse(relative, false, true)).format();
	};

	function urlResolveObject(source, relative) {
	  if (!source) return relative;
	  return urlParse(source, false, true).resolveObject(relative);
	}

	Url.prototype.resolveObject = function(relative) {
	  if (_.isString(relative)) {
	    var rel = new Url();
	    rel.parse(relative, false, true);
	    relative = rel;
	  }

	  var result = new Url();
	  Object.keys(this).forEach(function(k) {
	    result[k] = this[k];
	  }, this);

	  // hash is always overridden, no matter what.
	  // even href="" will remove it.
	  result.hash = relative.hash;

	  // if the relative url is empty, then there's nothing left to do here.
	  if (relative.href === '') {
	    result.href = result.format();
	    return result;
	  }

	  // hrefs like //foo/bar always cut to the protocol.
	  if (relative.slashes && !relative.protocol) {
	    // take everything except the protocol from relative
	    Object.keys(relative).forEach(function(k) {
	      if (k !== 'protocol')
	        result[k] = relative[k];
	    });

	    //urlParse appends trailing / to urls like http://www.example.com
	    if (slashedProtocol[result.protocol] &&
	        result.hostname && !result.pathname) {
	      result.path = result.pathname = '/';
	    }

	    result.href = result.format();
	    return result;
	  }

	  if (relative.protocol && relative.protocol !== result.protocol) {
	    // if it's a known url protocol, then changing
	    // the protocol does weird things
	    // first, if it's not file:, then we MUST have a host,
	    // and if there was a path
	    // to begin with, then we MUST have a path.
	    // if it is file:, then the host is dropped,
	    // because that's known to be hostless.
	    // anything else is assumed to be absolute.
	    if (!slashedProtocol[relative.protocol]) {
	      Object.keys(relative).forEach(function(k) {
	        result[k] = relative[k];
	      });
	      result.href = result.format();
	      return result;
	    }

	    result.protocol = relative.protocol;
	    if (!relative.host && !hostlessProtocol[relative.protocol]) {
	      var relPath = (relative.pathname || '').split('/');
	      while (relPath.length && !(relative.host = relPath.shift()));
	      if (!relative.host) relative.host = '';
	      if (!relative.hostname) relative.hostname = '';
	      if (relPath[0] !== '') relPath.unshift('');
	      if (relPath.length < 2) relPath.unshift('');
	      result.pathname = relPath.join('/');
	    } else {
	      result.pathname = relative.pathname;
	    }
	    result.search = relative.search;
	    result.query = relative.query;
	    result.host = relative.host || '';
	    result.auth = relative.auth;
	    result.hostname = relative.hostname || relative.host;
	    result.port = relative.port;
	    // to support http.request
	    if (result.pathname || result.search) {
	      var p = result.pathname || '';
	      var s = result.search || '';
	      result.path = p + s;
	    }
	    result.slashes = result.slashes || relative.slashes;
	    result.href = result.format();
	    return result;
	  }

	  var isSourceAbs = (result.pathname && result.pathname.charAt(0) === '/'),
	      isRelAbs = (
	          relative.host ||
	          relative.pathname && relative.pathname.charAt(0) === '/'
	      ),
	      mustEndAbs = (isRelAbs || isSourceAbs ||
	                    (result.host && relative.pathname)),
	      removeAllDots = mustEndAbs,
	      srcPath = result.pathname && result.pathname.split('/') || [],
	      relPath = relative.pathname && relative.pathname.split('/') || [],
	      psychotic = result.protocol && !slashedProtocol[result.protocol];

	  // if the url is a non-slashed url, then relative
	  // links like ../.. should be able
	  // to crawl up to the hostname, as well.  This is strange.
	  // result.protocol has already been set by now.
	  // Later on, put the first path part into the host field.
	  if (psychotic) {
	    result.hostname = '';
	    result.port = null;
	    if (result.host) {
	      if (srcPath[0] === '') srcPath[0] = result.host;
	      else srcPath.unshift(result.host);
	    }
	    result.host = '';
	    if (relative.protocol) {
	      relative.hostname = null;
	      relative.port = null;
	      if (relative.host) {
	        if (relPath[0] === '') relPath[0] = relative.host;
	        else relPath.unshift(relative.host);
	      }
	      relative.host = null;
	    }
	    mustEndAbs = mustEndAbs && (relPath[0] === '' || srcPath[0] === '');
	  }

	  if (isRelAbs) {
	    // it's absolute.
	    result.host = (relative.host || relative.host === '') ?
	                  relative.host : result.host;
	    result.hostname = (relative.hostname || relative.hostname === '') ?
	                      relative.hostname : result.hostname;
	    result.search = relative.search;
	    result.query = relative.query;
	    srcPath = relPath;
	    // fall through to the dot-handling below.
	  } else if (relPath.length) {
	    // it's relative
	    // throw away the existing file, and take the new path instead.
	    if (!srcPath) srcPath = [];
	    srcPath.pop();
	    srcPath = srcPath.concat(relPath);
	    result.search = relative.search;
	    result.query = relative.query;
	  } else if (!(_.isNull(relative.search) || _.isUndefined(relative.search))) {
	    // just pull out the search.
	    // like href='?foo'.
	    // Put this after the other two cases because it simplifies the booleans
	    if (psychotic) {
	      result.hostname = result.host = srcPath.shift();
	      //occationaly the auth can get stuck only in host
	      //this especialy happens in cases like
	      //url.resolveObject('mailto:local1@domain1', 'local2@domain2')
	      var authInHost = result.host && result.host.indexOf('@') > 0 ?
	                       result.host.split('@') : false;
	      if (authInHost) {
	        result.auth = authInHost.shift();
	        result.host = result.hostname = authInHost.shift();
	      }
	    }
	    result.search = relative.search;
	    result.query = relative.query;
	    //to support http.request
	    if (!_.isNull(result.pathname) || !_.isNull(result.search)) {
	      result.path = (result.pathname ? result.pathname : '') +
	                    (result.search ? result.search : '');
	    }
	    result.href = result.format();
	    return result;
	  }

	  if (!srcPath.length) {
	    // no path at all.  easy.
	    // we've already handled the other stuff above.
	    result.pathname = null;
	    //to support http.request
	    if (result.search) {
	      result.path = '/' + result.search;
	    } else {
	      result.path = null;
	    }
	    result.href = result.format();
	    return result;
	  }

	  // if a url ENDs in . or .., then it must get a trailing slash.
	  // however, if it ends in anything else non-slashy,
	  // then it must NOT get a trailing slash.
	  var last = srcPath.slice(-1)[0];
	  var hasTrailingSlash = (
	      (result.host || relative.host) && (last === '.' || last === '..') ||
	      last === '');

	  // strip single dots, resolve double dots to parent dir
	  // if the path tries to go above the root, `up` ends up > 0
	  var up = 0;
	  for (var i = srcPath.length; i >= 0; i--) {
	    last = srcPath[i];
	    if (last === '.') {
	      srcPath.splice(i, 1);
	    } else if (last === '..') {
	      srcPath.splice(i, 1);
	      up++;
	    } else if (up) {
	      srcPath.splice(i, 1);
	      up--;
	    }
	  }

	  // if the path is allowed to go above the root, restore leading ..s
	  if (!mustEndAbs && !removeAllDots) {
	    for (; up--; up) {
	      srcPath.unshift('..');
	    }
	  }

	  if (mustEndAbs && srcPath[0] !== '' &&
	      (!srcPath[0] || srcPath[0].charAt(0) !== '/')) {
	    srcPath.unshift('');
	  }

	  if (hasTrailingSlash && (srcPath.join('/').substr(-1) !== '/')) {
	    srcPath.push('');
	  }

	  var isAbsolute = srcPath[0] === '' ||
	      (srcPath[0] && srcPath[0].charAt(0) === '/');

	  // put the host back
	  if (psychotic) {
	    result.hostname = result.host = isAbsolute ? '' :
	                                    srcPath.length ? srcPath.shift() : '';
	    //occationaly the auth can get stuck only in host
	    //this especialy happens in cases like
	    //url.resolveObject('mailto:local1@domain1', 'local2@domain2')
	    var authInHost = result.host && result.host.indexOf('@') > 0 ?
	                     result.host.split('@') : false;
	    if (authInHost) {
	      result.auth = authInHost.shift();
	      result.host = result.hostname = authInHost.shift();
	    }
	  }

	  mustEndAbs = mustEndAbs || (result.host && srcPath.length);

	  if (mustEndAbs && !isAbsolute) {
	    srcPath.unshift('');
	  }

	  if (!srcPath.length) {
	    result.pathname = null;
	    result.path = null;
	  } else {
	    result.pathname = srcPath.join('/');
	  }

	  //to support request.http
	  if (!_.isNull(result.pathname) || !_.isNull(result.search)) {
	    result.path = (result.pathname ? result.pathname : '') +
	                  (result.search ? result.search : '');
	  }
	  result.auth = relative.auth || result.auth;
	  result.slashes = result.slashes || relative.slashes;
	  result.href = result.format();
	  return result;
	};

	Url.prototype.parseHost = function() {
	  var host = this.host;
	  var port = portPattern.exec(host);
	  if (port) {
	    port = port[0];
	    if (port !== ':') {
	      this.port = port.substr(1);
	    }
	    host = host.substr(0, host.length - port.length);
	  }
	  if (host) this.hostname = host;
	};


/***/ },
/* 26 */
/***/ function(module, exports) {

	//
	// The shims in this file are not fully implemented shims for the ES5
	// features, but do work for the particular usecases there is in
	// the other modules.
	//

	// Array.prototype.forEach is supported in IE9
	exports.forEach = function forEach(xs, fn, self) {
	  if (xs.forEach) return xs.forEach(fn, self);
	  for (var i = 0; i < xs.length; i++) {
	    fn.call(self, xs[i], i, xs);
	  }
	};

	// String.prototype.substr - negative index don't work in IE8
	if ('ab'.substr(-1) !== 'b') {
	  exports.substr = function (str, start, length) {
	    // did we get a negative start, calculate how much it is from the beginning of the string
	    if (start < 0) start = str.length + start;

	    // call the original function
	    return str.substr(start, length);
	  };
	} else {
	  exports.substr = function (str, start, length) {
	    return str.substr(start, length);
	  };
	}

	// String.prototype.trim is supported in IE9
	exports.trim = function (str) {
	  if (str.trim) return str.trim();
	  return str.replace(/^\s+|\s+$/g, '');
	};


/***/ },
/* 27 */
/***/ function(module, exports, __webpack_require__) {

	/* WEBPACK VAR INJECTION */(function(Buffer) {// Copyright Joyent, Inc. and other Node contributors.
	//
	// Permission is hereby granted, free of charge, to any person obtaining a
	// copy of this software and associated documentation files (the
	// "Software"), to deal in the Software without restriction, including
	// without limitation the rights to use, copy, modify, merge, publish,
	// distribute, sublicense, and/or sell copies of the Software, and to permit
	// persons to whom the Software is furnished to do so, subject to the
	// following conditions:
	//
	// The above copyright notice and this permission notice shall be included
	// in all copies or substantial portions of the Software.
	//
	// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
	// OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
	// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN
	// NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
	// DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
	// OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE
	// USE OR OTHER DEALINGS IN THE SOFTWARE.

	// Query String Utilities

	var QueryString = exports;
	var _ = __webpack_require__(1);


	// If obj.hasOwnProperty has been overridden, then calling
	// obj.hasOwnProperty(prop) will break.
	// See: https://github.com/joyent/node/issues/1707
	function hasOwnProperty(obj, prop) {
	  return Object.prototype.hasOwnProperty.call(obj, prop);
	}


	function charCode(c) {
	  return c.charCodeAt(0);
	}


	// a safe fast alternative to decodeURIComponent
	QueryString.unescapeBuffer = function(s, decodeSpaces) {
	  var out = new Buffer(s.length);
	  var state = 'CHAR'; // states: CHAR, HEX0, HEX1
	  var n, m, hexchar;

	  for (var inIndex = 0, outIndex = 0; inIndex <= s.length; inIndex++) {
	    var c = s.charCodeAt(inIndex);
	    switch (state) {
	      case 'CHAR':
	        switch (c) {
	          case charCode('%'):
	            n = 0;
	            m = 0;
	            state = 'HEX0';
	            break;
	          case charCode('+'):
	            if (decodeSpaces) c = charCode(' ');
	            // pass thru
	          default:
	            out[outIndex++] = c;
	            break;
	        }
	        break;

	      case 'HEX0':
	        state = 'HEX1';
	        hexchar = c;
	        if (charCode('0') <= c && c <= charCode('9')) {
	          n = c - charCode('0');
	        } else if (charCode('a') <= c && c <= charCode('f')) {
	          n = c - charCode('a') + 10;
	        } else if (charCode('A') <= c && c <= charCode('F')) {
	          n = c - charCode('A') + 10;
	        } else {
	          out[outIndex++] = charCode('%');
	          out[outIndex++] = c;
	          state = 'CHAR';
	          break;
	        }
	        break;

	      case 'HEX1':
	        state = 'CHAR';
	        if (charCode('0') <= c && c <= charCode('9')) {
	          m = c - charCode('0');
	        } else if (charCode('a') <= c && c <= charCode('f')) {
	          m = c - charCode('a') + 10;
	        } else if (charCode('A') <= c && c <= charCode('F')) {
	          m = c - charCode('A') + 10;
	        } else {
	          out[outIndex++] = charCode('%');
	          out[outIndex++] = hexchar;
	          out[outIndex++] = c;
	          break;
	        }
	        out[outIndex++] = 16 * n + m;
	        break;
	    }
	  }

	  // TODO support returning arbitrary buffers.

	  return out.slice(0, outIndex - 1);
	};


	QueryString.unescape = function(s, decodeSpaces) {
	  return QueryString.unescapeBuffer(s, decodeSpaces).toString();
	};


	QueryString.escape = function(str) {
	  return encodeURIComponent(str);
	};

	var stringifyPrimitive = function(v) {
	  if (_.isString(v))
	    return v;
	  if (_.isBoolean(v))
	    return v ? 'true' : 'false';
	  if (_.isNumber(v))
	    return isFinite(v) ? v : '';
	  return '';
	};


	QueryString.stringify = QueryString.encode = function(obj, sep, eq, options) {
	  sep = sep || '&';
	  eq = eq || '=';
	  if (_.isNull(obj)) {
	    obj = undefined;
	  }

	  var encode = QueryString.escape;
	  if (options && typeof options.encodeURIComponent === 'function') {
	    encode = options.encodeURIComponent;
	  }

	  if (_.isObject(obj)) {
	    return Object.keys(obj).map(function(k) {
	      var ks = encode(stringifyPrimitive(k)) + eq;
	      if (_.isArray(obj[k])) {
	        return obj[k].map(function(v) {
	          return ks + encode(stringifyPrimitive(v));
	        }).join(sep);
	      } else {
	        return ks + encode(stringifyPrimitive(obj[k]));
	      }
	    }).join(sep);
	  }
	  return '';
	};

	// Parse a key=val string.
	QueryString.parse = QueryString.decode = function(qs, sep, eq, options) {
	  sep = sep || '&';
	  eq = eq || '=';
	  var obj = {};

	  if (!_.isString(qs) || qs.length === 0) {
	    return obj;
	  }

	  var regexp = /\+/g;
	  qs = qs.split(sep);

	  var maxKeys = 1000;
	  if (options && _.isNumber(options.maxKeys)) {
	    maxKeys = options.maxKeys;
	  }

	  var len = qs.length;
	  // maxKeys <= 0 means that we should not limit keys count
	  if (maxKeys > 0 && len > maxKeys) {
	    len = maxKeys;
	  }

	  var decode = decodeURIComponent;
	  if (options && typeof options.decodeURIComponent === 'function') {
	    decode = options.decodeURIComponent;
	  }

	  for (var i = 0; i < len; ++i) {
	    var x = qs[i].replace(regexp, '%20'),
	        idx = x.indexOf(eq),
	        kstr, vstr, k, v;

	    if (idx >= 0) {
	      kstr = x.substr(0, idx);
	      vstr = x.substr(idx + 1);
	    } else {
	      kstr = x;
	      vstr = '';
	    }

	    try {
	      k = decode(kstr);
	      v = decode(vstr);
	    } catch (e) {
	      k = QueryString.unescape(kstr, true);
	      v = QueryString.unescape(vstr, true);
	    }

	    if (!hasOwnProperty(obj, k)) {
	      obj[k] = v;
	    } else if (_.isArray(obj[k])) {
	      obj[k].push(v);
	    } else {
	      obj[k] = [obj[k], v];
	    }
	  }

	  return obj;
	};
	/* WEBPACK VAR INJECTION */}.call(exports, __webpack_require__(28).Buffer))

/***/ },
/* 28 */
/***/ function(module, exports, __webpack_require__) {

	/* WEBPACK VAR INJECTION */(function(Buffer, global) {/*!
	 * The buffer module from node.js, for the browser.
	 *
	 * @author   Feross Aboukhadijeh <feross@feross.org> <http://feross.org>
	 * @license  MIT
	 */
	/* eslint-disable no-proto */

	'use strict'

	var base64 = __webpack_require__(29)
	var ieee754 = __webpack_require__(30)
	var isArray = __webpack_require__(31)

	exports.Buffer = Buffer
	exports.SlowBuffer = SlowBuffer
	exports.INSPECT_MAX_BYTES = 50
	Buffer.poolSize = 8192 // not used by this implementation

	var rootParent = {}

	/**
	 * If `Buffer.TYPED_ARRAY_SUPPORT`:
	 *   === true    Use Uint8Array implementation (fastest)
	 *   === false   Use Object implementation (most compatible, even IE6)
	 *
	 * Browsers that support typed arrays are IE 10+, Firefox 4+, Chrome 7+, Safari 5.1+,
	 * Opera 11.6+, iOS 4.2+.
	 *
	 * Due to various browser bugs, sometimes the Object implementation will be used even
	 * when the browser supports typed arrays.
	 *
	 * Note:
	 *
	 *   - Firefox 4-29 lacks support for adding new properties to `Uint8Array` instances,
	 *     See: https://bugzilla.mozilla.org/show_bug.cgi?id=695438.
	 *
	 *   - Safari 5-7 lacks support for changing the `Object.prototype.constructor` property
	 *     on objects.
	 *
	 *   - Chrome 9-10 is missing the `TypedArray.prototype.subarray` function.
	 *
	 *   - IE10 has a broken `TypedArray.prototype.subarray` function which returns arrays of
	 *     incorrect length in some situations.

	 * We detect these buggy browsers and set `Buffer.TYPED_ARRAY_SUPPORT` to `false` so they
	 * get the Object implementation, which is slower but behaves correctly.
	 */
	Buffer.TYPED_ARRAY_SUPPORT = global.TYPED_ARRAY_SUPPORT !== undefined
	  ? global.TYPED_ARRAY_SUPPORT
	  : typedArraySupport()

	function typedArraySupport () {
	  function Bar () {}
	  try {
	    var arr = new Uint8Array(1)
	    arr.foo = function () { return 42 }
	    arr.constructor = Bar
	    return arr.foo() === 42 && // typed array instances can be augmented
	        arr.constructor === Bar && // constructor can be set
	        typeof arr.subarray === 'function' && // chrome 9-10 lack `subarray`
	        arr.subarray(1, 1).byteLength === 0 // ie10 has broken `subarray`
	  } catch (e) {
	    return false
	  }
	}

	function kMaxLength () {
	  return Buffer.TYPED_ARRAY_SUPPORT
	    ? 0x7fffffff
	    : 0x3fffffff
	}

	/**
	 * Class: Buffer
	 * =============
	 *
	 * The Buffer constructor returns instances of `Uint8Array` that are augmented
	 * with function properties for all the node `Buffer` API functions. We use
	 * `Uint8Array` so that square bracket notation works as expected -- it returns
	 * a single octet.
	 *
	 * By augmenting the instances, we can avoid modifying the `Uint8Array`
	 * prototype.
	 */
	function Buffer (arg) {
	  if (!(this instanceof Buffer)) {
	    // Avoid going through an ArgumentsAdaptorTrampoline in the common case.
	    if (arguments.length > 1) return new Buffer(arg, arguments[1])
	    return new Buffer(arg)
	  }

	  if (!Buffer.TYPED_ARRAY_SUPPORT) {
	    this.length = 0
	    this.parent = undefined
	  }

	  // Common case.
	  if (typeof arg === 'number') {
	    return fromNumber(this, arg)
	  }

	  // Slightly less common case.
	  if (typeof arg === 'string') {
	    return fromString(this, arg, arguments.length > 1 ? arguments[1] : 'utf8')
	  }

	  // Unusual.
	  return fromObject(this, arg)
	}

	function fromNumber (that, length) {
	  that = allocate(that, length < 0 ? 0 : checked(length) | 0)
	  if (!Buffer.TYPED_ARRAY_SUPPORT) {
	    for (var i = 0; i < length; i++) {
	      that[i] = 0
	    }
	  }
	  return that
	}

	function fromString (that, string, encoding) {
	  if (typeof encoding !== 'string' || encoding === '') encoding = 'utf8'

	  // Assumption: byteLength() return value is always < kMaxLength.
	  var length = byteLength(string, encoding) | 0
	  that = allocate(that, length)

	  that.write(string, encoding)
	  return that
	}

	function fromObject (that, object) {
	  if (Buffer.isBuffer(object)) return fromBuffer(that, object)

	  if (isArray(object)) return fromArray(that, object)

	  if (object == null) {
	    throw new TypeError('must start with number, buffer, array or string')
	  }

	  if (typeof ArrayBuffer !== 'undefined') {
	    if (object.buffer instanceof ArrayBuffer) {
	      return fromTypedArray(that, object)
	    }
	    if (object instanceof ArrayBuffer) {
	      return fromArrayBuffer(that, object)
	    }
	  }

	  if (object.length) return fromArrayLike(that, object)

	  return fromJsonObject(that, object)
	}

	function fromBuffer (that, buffer) {
	  var length = checked(buffer.length) | 0
	  that = allocate(that, length)
	  buffer.copy(that, 0, 0, length)
	  return that
	}

	function fromArray (that, array) {
	  var length = checked(array.length) | 0
	  that = allocate(that, length)
	  for (var i = 0; i < length; i += 1) {
	    that[i] = array[i] & 255
	  }
	  return that
	}

	// Duplicate of fromArray() to keep fromArray() monomorphic.
	function fromTypedArray (that, array) {
	  var length = checked(array.length) | 0
	  that = allocate(that, length)
	  // Truncating the elements is probably not what people expect from typed
	  // arrays with BYTES_PER_ELEMENT > 1 but it's compatible with the behavior
	  // of the old Buffer constructor.
	  for (var i = 0; i < length; i += 1) {
	    that[i] = array[i] & 255
	  }
	  return that
	}

	function fromArrayBuffer (that, array) {
	  if (Buffer.TYPED_ARRAY_SUPPORT) {
	    // Return an augmented `Uint8Array` instance, for best performance
	    array.byteLength
	    that = Buffer._augment(new Uint8Array(array))
	  } else {
	    // Fallback: Return an object instance of the Buffer class
	    that = fromTypedArray(that, new Uint8Array(array))
	  }
	  return that
	}

	function fromArrayLike (that, array) {
	  var length = checked(array.length) | 0
	  that = allocate(that, length)
	  for (var i = 0; i < length; i += 1) {
	    that[i] = array[i] & 255
	  }
	  return that
	}

	// Deserialize { type: 'Buffer', data: [1,2,3,...] } into a Buffer object.
	// Returns a zero-length buffer for inputs that don't conform to the spec.
	function fromJsonObject (that, object) {
	  var array
	  var length = 0

	  if (object.type === 'Buffer' && isArray(object.data)) {
	    array = object.data
	    length = checked(array.length) | 0
	  }
	  that = allocate(that, length)

	  for (var i = 0; i < length; i += 1) {
	    that[i] = array[i] & 255
	  }
	  return that
	}

	if (Buffer.TYPED_ARRAY_SUPPORT) {
	  Buffer.prototype.__proto__ = Uint8Array.prototype
	  Buffer.__proto__ = Uint8Array
	} else {
	  // pre-set for values that may exist in the future
	  Buffer.prototype.length = undefined
	  Buffer.prototype.parent = undefined
	}

	function allocate (that, length) {
	  if (Buffer.TYPED_ARRAY_SUPPORT) {
	    // Return an augmented `Uint8Array` instance, for best performance
	    that = Buffer._augment(new Uint8Array(length))
	    that.__proto__ = Buffer.prototype
	  } else {
	    // Fallback: Return an object instance of the Buffer class
	    that.length = length
	    that._isBuffer = true
	  }

	  var fromPool = length !== 0 && length <= Buffer.poolSize >>> 1
	  if (fromPool) that.parent = rootParent

	  return that
	}

	function checked (length) {
	  // Note: cannot use `length < kMaxLength` here because that fails when
	  // length is NaN (which is otherwise coerced to zero.)
	  if (length >= kMaxLength()) {
	    throw new RangeError('Attempt to allocate Buffer larger than maximum ' +
	                         'size: 0x' + kMaxLength().toString(16) + ' bytes')
	  }
	  return length | 0
	}

	function SlowBuffer (subject, encoding) {
	  if (!(this instanceof SlowBuffer)) return new SlowBuffer(subject, encoding)

	  var buf = new Buffer(subject, encoding)
	  delete buf.parent
	  return buf
	}

	Buffer.isBuffer = function isBuffer (b) {
	  return !!(b != null && b._isBuffer)
	}

	Buffer.compare = function compare (a, b) {
	  if (!Buffer.isBuffer(a) || !Buffer.isBuffer(b)) {
	    throw new TypeError('Arguments must be Buffers')
	  }

	  if (a === b) return 0

	  var x = a.length
	  var y = b.length

	  var i = 0
	  var len = Math.min(x, y)
	  while (i < len) {
	    if (a[i] !== b[i]) break

	    ++i
	  }

	  if (i !== len) {
	    x = a[i]
	    y = b[i]
	  }

	  if (x < y) return -1
	  if (y < x) return 1
	  return 0
	}

	Buffer.isEncoding = function isEncoding (encoding) {
	  switch (String(encoding).toLowerCase()) {
	    case 'hex':
	    case 'utf8':
	    case 'utf-8':
	    case 'ascii':
	    case 'binary':
	    case 'base64':
	    case 'raw':
	    case 'ucs2':
	    case 'ucs-2':
	    case 'utf16le':
	    case 'utf-16le':
	      return true
	    default:
	      return false
	  }
	}

	Buffer.concat = function concat (list, length) {
	  if (!isArray(list)) throw new TypeError('list argument must be an Array of Buffers.')

	  if (list.length === 0) {
	    return new Buffer(0)
	  }

	  var i
	  if (length === undefined) {
	    length = 0
	    for (i = 0; i < list.length; i++) {
	      length += list[i].length
	    }
	  }

	  var buf = new Buffer(length)
	  var pos = 0
	  for (i = 0; i < list.length; i++) {
	    var item = list[i]
	    item.copy(buf, pos)
	    pos += item.length
	  }
	  return buf
	}

	function byteLength (string, encoding) {
	  if (typeof string !== 'string') string = '' + string

	  var len = string.length
	  if (len === 0) return 0

	  // Use a for loop to avoid recursion
	  var loweredCase = false
	  for (;;) {
	    switch (encoding) {
	      case 'ascii':
	      case 'binary':
	      // Deprecated
	      case 'raw':
	      case 'raws':
	        return len
	      case 'utf8':
	      case 'utf-8':
	        return utf8ToBytes(string).length
	      case 'ucs2':
	      case 'ucs-2':
	      case 'utf16le':
	      case 'utf-16le':
	        return len * 2
	      case 'hex':
	        return len >>> 1
	      case 'base64':
	        return base64ToBytes(string).length
	      default:
	        if (loweredCase) return utf8ToBytes(string).length // assume utf8
	        encoding = ('' + encoding).toLowerCase()
	        loweredCase = true
	    }
	  }
	}
	Buffer.byteLength = byteLength

	function slowToString (encoding, start, end) {
	  var loweredCase = false

	  start = start | 0
	  end = end === undefined || end === Infinity ? this.length : end | 0

	  if (!encoding) encoding = 'utf8'
	  if (start < 0) start = 0
	  if (end > this.length) end = this.length
	  if (end <= start) return ''

	  while (true) {
	    switch (encoding) {
	      case 'hex':
	        return hexSlice(this, start, end)

	      case 'utf8':
	      case 'utf-8':
	        return utf8Slice(this, start, end)

	      case 'ascii':
	        return asciiSlice(this, start, end)

	      case 'binary':
	        return binarySlice(this, start, end)

	      case 'base64':
	        return base64Slice(this, start, end)

	      case 'ucs2':
	      case 'ucs-2':
	      case 'utf16le':
	      case 'utf-16le':
	        return utf16leSlice(this, start, end)

	      default:
	        if (loweredCase) throw new TypeError('Unknown encoding: ' + encoding)
	        encoding = (encoding + '').toLowerCase()
	        loweredCase = true
	    }
	  }
	}

	Buffer.prototype.toString = function toString () {
	  var length = this.length | 0
	  if (length === 0) return ''
	  if (arguments.length === 0) return utf8Slice(this, 0, length)
	  return slowToString.apply(this, arguments)
	}

	Buffer.prototype.equals = function equals (b) {
	  if (!Buffer.isBuffer(b)) throw new TypeError('Argument must be a Buffer')
	  if (this === b) return true
	  return Buffer.compare(this, b) === 0
	}

	Buffer.prototype.inspect = function inspect () {
	  var str = ''
	  var max = exports.INSPECT_MAX_BYTES
	  if (this.length > 0) {
	    str = this.toString('hex', 0, max).match(/.{2}/g).join(' ')
	    if (this.length > max) str += ' ... '
	  }
	  return '<Buffer ' + str + '>'
	}

	Buffer.prototype.compare = function compare (b) {
	  if (!Buffer.isBuffer(b)) throw new TypeError('Argument must be a Buffer')
	  if (this === b) return 0
	  return Buffer.compare(this, b)
	}

	Buffer.prototype.indexOf = function indexOf (val, byteOffset) {
	  if (byteOffset > 0x7fffffff) byteOffset = 0x7fffffff
	  else if (byteOffset < -0x80000000) byteOffset = -0x80000000
	  byteOffset >>= 0

	  if (this.length === 0) return -1
	  if (byteOffset >= this.length) return -1

	  // Negative offsets start from the end of the buffer
	  if (byteOffset < 0) byteOffset = Math.max(this.length + byteOffset, 0)

	  if (typeof val === 'string') {
	    if (val.length === 0) return -1 // special case: looking for empty string always fails
	    return String.prototype.indexOf.call(this, val, byteOffset)
	  }
	  if (Buffer.isBuffer(val)) {
	    return arrayIndexOf(this, val, byteOffset)
	  }
	  if (typeof val === 'number') {
	    if (Buffer.TYPED_ARRAY_SUPPORT && Uint8Array.prototype.indexOf === 'function') {
	      return Uint8Array.prototype.indexOf.call(this, val, byteOffset)
	    }
	    return arrayIndexOf(this, [ val ], byteOffset)
	  }

	  function arrayIndexOf (arr, val, byteOffset) {
	    var foundIndex = -1
	    for (var i = 0; byteOffset + i < arr.length; i++) {
	      if (arr[byteOffset + i] === val[foundIndex === -1 ? 0 : i - foundIndex]) {
	        if (foundIndex === -1) foundIndex = i
	        if (i - foundIndex + 1 === val.length) return byteOffset + foundIndex
	      } else {
	        foundIndex = -1
	      }
	    }
	    return -1
	  }

	  throw new TypeError('val must be string, number or Buffer')
	}

	// `get` is deprecated
	Buffer.prototype.get = function get (offset) {
	  console.log('.get() is deprecated. Access using array indexes instead.')
	  return this.readUInt8(offset)
	}

	// `set` is deprecated
	Buffer.prototype.set = function set (v, offset) {
	  console.log('.set() is deprecated. Access using array indexes instead.')
	  return this.writeUInt8(v, offset)
	}

	function hexWrite (buf, string, offset, length) {
	  offset = Number(offset) || 0
	  var remaining = buf.length - offset
	  if (!length) {
	    length = remaining
	  } else {
	    length = Number(length)
	    if (length > remaining) {
	      length = remaining
	    }
	  }

	  // must be an even number of digits
	  var strLen = string.length
	  if (strLen % 2 !== 0) throw new Error('Invalid hex string')

	  if (length > strLen / 2) {
	    length = strLen / 2
	  }
	  for (var i = 0; i < length; i++) {
	    var parsed = parseInt(string.substr(i * 2, 2), 16)
	    if (isNaN(parsed)) throw new Error('Invalid hex string')
	    buf[offset + i] = parsed
	  }
	  return i
	}

	function utf8Write (buf, string, offset, length) {
	  return blitBuffer(utf8ToBytes(string, buf.length - offset), buf, offset, length)
	}

	function asciiWrite (buf, string, offset, length) {
	  return blitBuffer(asciiToBytes(string), buf, offset, length)
	}

	function binaryWrite (buf, string, offset, length) {
	  return asciiWrite(buf, string, offset, length)
	}

	function base64Write (buf, string, offset, length) {
	  return blitBuffer(base64ToBytes(string), buf, offset, length)
	}

	function ucs2Write (buf, string, offset, length) {
	  return blitBuffer(utf16leToBytes(string, buf.length - offset), buf, offset, length)
	}

	Buffer.prototype.write = function write (string, offset, length, encoding) {
	  // Buffer#write(string)
	  if (offset === undefined) {
	    encoding = 'utf8'
	    length = this.length
	    offset = 0
	  // Buffer#write(string, encoding)
	  } else if (length === undefined && typeof offset === 'string') {
	    encoding = offset
	    length = this.length
	    offset = 0
	  // Buffer#write(string, offset[, length][, encoding])
	  } else if (isFinite(offset)) {
	    offset = offset | 0
	    if (isFinite(length)) {
	      length = length | 0
	      if (encoding === undefined) encoding = 'utf8'
	    } else {
	      encoding = length
	      length = undefined
	    }
	  // legacy write(string, encoding, offset, length) - remove in v0.13
	  } else {
	    var swap = encoding
	    encoding = offset
	    offset = length | 0
	    length = swap
	  }

	  var remaining = this.length - offset
	  if (length === undefined || length > remaining) length = remaining

	  if ((string.length > 0 && (length < 0 || offset < 0)) || offset > this.length) {
	    throw new RangeError('attempt to write outside buffer bounds')
	  }

	  if (!encoding) encoding = 'utf8'

	  var loweredCase = false
	  for (;;) {
	    switch (encoding) {
	      case 'hex':
	        return hexWrite(this, string, offset, length)

	      case 'utf8':
	      case 'utf-8':
	        return utf8Write(this, string, offset, length)

	      case 'ascii':
	        return asciiWrite(this, string, offset, length)

	      case 'binary':
	        return binaryWrite(this, string, offset, length)

	      case 'base64':
	        // Warning: maxLength not taken into account in base64Write
	        return base64Write(this, string, offset, length)

	      case 'ucs2':
	      case 'ucs-2':
	      case 'utf16le':
	      case 'utf-16le':
	        return ucs2Write(this, string, offset, length)

	      default:
	        if (loweredCase) throw new TypeError('Unknown encoding: ' + encoding)
	        encoding = ('' + encoding).toLowerCase()
	        loweredCase = true
	    }
	  }
	}

	Buffer.prototype.toJSON = function toJSON () {
	  return {
	    type: 'Buffer',
	    data: Array.prototype.slice.call(this._arr || this, 0)
	  }
	}

	function base64Slice (buf, start, end) {
	  if (start === 0 && end === buf.length) {
	    return base64.fromByteArray(buf)
	  } else {
	    return base64.fromByteArray(buf.slice(start, end))
	  }
	}

	function utf8Slice (buf, start, end) {
	  end = Math.min(buf.length, end)
	  var res = []

	  var i = start
	  while (i < end) {
	    var firstByte = buf[i]
	    var codePoint = null
	    var bytesPerSequence = (firstByte > 0xEF) ? 4
	      : (firstByte > 0xDF) ? 3
	      : (firstByte > 0xBF) ? 2
	      : 1

	    if (i + bytesPerSequence <= end) {
	      var secondByte, thirdByte, fourthByte, tempCodePoint

	      switch (bytesPerSequence) {
	        case 1:
	          if (firstByte < 0x80) {
	            codePoint = firstByte
	          }
	          break
	        case 2:
	          secondByte = buf[i + 1]
	          if ((secondByte & 0xC0) === 0x80) {
	            tempCodePoint = (firstByte & 0x1F) << 0x6 | (secondByte & 0x3F)
	            if (tempCodePoint > 0x7F) {
	              codePoint = tempCodePoint
	            }
	          }
	          break
	        case 3:
	          secondByte = buf[i + 1]
	          thirdByte = buf[i + 2]
	          if ((secondByte & 0xC0) === 0x80 && (thirdByte & 0xC0) === 0x80) {
	            tempCodePoint = (firstByte & 0xF) << 0xC | (secondByte & 0x3F) << 0x6 | (thirdByte & 0x3F)
	            if (tempCodePoint > 0x7FF && (tempCodePoint < 0xD800 || tempCodePoint > 0xDFFF)) {
	              codePoint = tempCodePoint
	            }
	          }
	          break
	        case 4:
	          secondByte = buf[i + 1]
	          thirdByte = buf[i + 2]
	          fourthByte = buf[i + 3]
	          if ((secondByte & 0xC0) === 0x80 && (thirdByte & 0xC0) === 0x80 && (fourthByte & 0xC0) === 0x80) {
	            tempCodePoint = (firstByte & 0xF) << 0x12 | (secondByte & 0x3F) << 0xC | (thirdByte & 0x3F) << 0x6 | (fourthByte & 0x3F)
	            if (tempCodePoint > 0xFFFF && tempCodePoint < 0x110000) {
	              codePoint = tempCodePoint
	            }
	          }
	      }
	    }

	    if (codePoint === null) {
	      // we did not generate a valid codePoint so insert a
	      // replacement char (U+FFFD) and advance only 1 byte
	      codePoint = 0xFFFD
	      bytesPerSequence = 1
	    } else if (codePoint > 0xFFFF) {
	      // encode to utf16 (surrogate pair dance)
	      codePoint -= 0x10000
	      res.push(codePoint >>> 10 & 0x3FF | 0xD800)
	      codePoint = 0xDC00 | codePoint & 0x3FF
	    }

	    res.push(codePoint)
	    i += bytesPerSequence
	  }

	  return decodeCodePointsArray(res)
	}

	// Based on http://stackoverflow.com/a/22747272/680742, the browser with
	// the lowest limit is Chrome, with 0x10000 args.
	// We go 1 magnitude less, for safety
	var MAX_ARGUMENTS_LENGTH = 0x1000

	function decodeCodePointsArray (codePoints) {
	  var len = codePoints.length
	  if (len <= MAX_ARGUMENTS_LENGTH) {
	    return String.fromCharCode.apply(String, codePoints) // avoid extra slice()
	  }

	  // Decode in chunks to avoid "call stack size exceeded".
	  var res = ''
	  var i = 0
	  while (i < len) {
	    res += String.fromCharCode.apply(
	      String,
	      codePoints.slice(i, i += MAX_ARGUMENTS_LENGTH)
	    )
	  }
	  return res
	}

	function asciiSlice (buf, start, end) {
	  var ret = ''
	  end = Math.min(buf.length, end)

	  for (var i = start; i < end; i++) {
	    ret += String.fromCharCode(buf[i] & 0x7F)
	  }
	  return ret
	}

	function binarySlice (buf, start, end) {
	  var ret = ''
	  end = Math.min(buf.length, end)

	  for (var i = start; i < end; i++) {
	    ret += String.fromCharCode(buf[i])
	  }
	  return ret
	}

	function hexSlice (buf, start, end) {
	  var len = buf.length

	  if (!start || start < 0) start = 0
	  if (!end || end < 0 || end > len) end = len

	  var out = ''
	  for (var i = start; i < end; i++) {
	    out += toHex(buf[i])
	  }
	  return out
	}

	function utf16leSlice (buf, start, end) {
	  var bytes = buf.slice(start, end)
	  var res = ''
	  for (var i = 0; i < bytes.length; i += 2) {
	    res += String.fromCharCode(bytes[i] + bytes[i + 1] * 256)
	  }
	  return res
	}

	Buffer.prototype.slice = function slice (start, end) {
	  var len = this.length
	  start = ~~start
	  end = end === undefined ? len : ~~end

	  if (start < 0) {
	    start += len
	    if (start < 0) start = 0
	  } else if (start > len) {
	    start = len
	  }

	  if (end < 0) {
	    end += len
	    if (end < 0) end = 0
	  } else if (end > len) {
	    end = len
	  }

	  if (end < start) end = start

	  var newBuf
	  if (Buffer.TYPED_ARRAY_SUPPORT) {
	    newBuf = Buffer._augment(this.subarray(start, end))
	  } else {
	    var sliceLen = end - start
	    newBuf = new Buffer(sliceLen, undefined)
	    for (var i = 0; i < sliceLen; i++) {
	      newBuf[i] = this[i + start]
	    }
	  }

	  if (newBuf.length) newBuf.parent = this.parent || this

	  return newBuf
	}

	/*
	 * Need to make sure that buffer isn't trying to write out of bounds.
	 */
	function checkOffset (offset, ext, length) {
	  if ((offset % 1) !== 0 || offset < 0) throw new RangeError('offset is not uint')
	  if (offset + ext > length) throw new RangeError('Trying to access beyond buffer length')
	}

	Buffer.prototype.readUIntLE = function readUIntLE (offset, byteLength, noAssert) {
	  offset = offset | 0
	  byteLength = byteLength | 0
	  if (!noAssert) checkOffset(offset, byteLength, this.length)

	  var val = this[offset]
	  var mul = 1
	  var i = 0
	  while (++i < byteLength && (mul *= 0x100)) {
	    val += this[offset + i] * mul
	  }

	  return val
	}

	Buffer.prototype.readUIntBE = function readUIntBE (offset, byteLength, noAssert) {
	  offset = offset | 0
	  byteLength = byteLength | 0
	  if (!noAssert) {
	    checkOffset(offset, byteLength, this.length)
	  }

	  var val = this[offset + --byteLength]
	  var mul = 1
	  while (byteLength > 0 && (mul *= 0x100)) {
	    val += this[offset + --byteLength] * mul
	  }

	  return val
	}

	Buffer.prototype.readUInt8 = function readUInt8 (offset, noAssert) {
	  if (!noAssert) checkOffset(offset, 1, this.length)
	  return this[offset]
	}

	Buffer.prototype.readUInt16LE = function readUInt16LE (offset, noAssert) {
	  if (!noAssert) checkOffset(offset, 2, this.length)
	  return this[offset] | (this[offset + 1] << 8)
	}

	Buffer.prototype.readUInt16BE = function readUInt16BE (offset, noAssert) {
	  if (!noAssert) checkOffset(offset, 2, this.length)
	  return (this[offset] << 8) | this[offset + 1]
	}

	Buffer.prototype.readUInt32LE = function readUInt32LE (offset, noAssert) {
	  if (!noAssert) checkOffset(offset, 4, this.length)

	  return ((this[offset]) |
	      (this[offset + 1] << 8) |
	      (this[offset + 2] << 16)) +
	      (this[offset + 3] * 0x1000000)
	}

	Buffer.prototype.readUInt32BE = function readUInt32BE (offset, noAssert) {
	  if (!noAssert) checkOffset(offset, 4, this.length)

	  return (this[offset] * 0x1000000) +
	    ((this[offset + 1] << 16) |
	    (this[offset + 2] << 8) |
	    this[offset + 3])
	}

	Buffer.prototype.readIntLE = function readIntLE (offset, byteLength, noAssert) {
	  offset = offset | 0
	  byteLength = byteLength | 0
	  if (!noAssert) checkOffset(offset, byteLength, this.length)

	  var val = this[offset]
	  var mul = 1
	  var i = 0
	  while (++i < byteLength && (mul *= 0x100)) {
	    val += this[offset + i] * mul
	  }
	  mul *= 0x80

	  if (val >= mul) val -= Math.pow(2, 8 * byteLength)

	  return val
	}

	Buffer.prototype.readIntBE = function readIntBE (offset, byteLength, noAssert) {
	  offset = offset | 0
	  byteLength = byteLength | 0
	  if (!noAssert) checkOffset(offset, byteLength, this.length)

	  var i = byteLength
	  var mul = 1
	  var val = this[offset + --i]
	  while (i > 0 && (mul *= 0x100)) {
	    val += this[offset + --i] * mul
	  }
	  mul *= 0x80

	  if (val >= mul) val -= Math.pow(2, 8 * byteLength)

	  return val
	}

	Buffer.prototype.readInt8 = function readInt8 (offset, noAssert) {
	  if (!noAssert) checkOffset(offset, 1, this.length)
	  if (!(this[offset] & 0x80)) return (this[offset])
	  return ((0xff - this[offset] + 1) * -1)
	}

	Buffer.prototype.readInt16LE = function readInt16LE (offset, noAssert) {
	  if (!noAssert) checkOffset(offset, 2, this.length)
	  var val = this[offset] | (this[offset + 1] << 8)
	  return (val & 0x8000) ? val | 0xFFFF0000 : val
	}

	Buffer.prototype.readInt16BE = function readInt16BE (offset, noAssert) {
	  if (!noAssert) checkOffset(offset, 2, this.length)
	  var val = this[offset + 1] | (this[offset] << 8)
	  return (val & 0x8000) ? val | 0xFFFF0000 : val
	}

	Buffer.prototype.readInt32LE = function readInt32LE (offset, noAssert) {
	  if (!noAssert) checkOffset(offset, 4, this.length)

	  return (this[offset]) |
	    (this[offset + 1] << 8) |
	    (this[offset + 2] << 16) |
	    (this[offset + 3] << 24)
	}

	Buffer.prototype.readInt32BE = function readInt32BE (offset, noAssert) {
	  if (!noAssert) checkOffset(offset, 4, this.length)

	  return (this[offset] << 24) |
	    (this[offset + 1] << 16) |
	    (this[offset + 2] << 8) |
	    (this[offset + 3])
	}

	Buffer.prototype.readFloatLE = function readFloatLE (offset, noAssert) {
	  if (!noAssert) checkOffset(offset, 4, this.length)
	  return ieee754.read(this, offset, true, 23, 4)
	}

	Buffer.prototype.readFloatBE = function readFloatBE (offset, noAssert) {
	  if (!noAssert) checkOffset(offset, 4, this.length)
	  return ieee754.read(this, offset, false, 23, 4)
	}

	Buffer.prototype.readDoubleLE = function readDoubleLE (offset, noAssert) {
	  if (!noAssert) checkOffset(offset, 8, this.length)
	  return ieee754.read(this, offset, true, 52, 8)
	}

	Buffer.prototype.readDoubleBE = function readDoubleBE (offset, noAssert) {
	  if (!noAssert) checkOffset(offset, 8, this.length)
	  return ieee754.read(this, offset, false, 52, 8)
	}

	function checkInt (buf, value, offset, ext, max, min) {
	  if (!Buffer.isBuffer(buf)) throw new TypeError('buffer must be a Buffer instance')
	  if (value > max || value < min) throw new RangeError('value is out of bounds')
	  if (offset + ext > buf.length) throw new RangeError('index out of range')
	}

	Buffer.prototype.writeUIntLE = function writeUIntLE (value, offset, byteLength, noAssert) {
	  value = +value
	  offset = offset | 0
	  byteLength = byteLength | 0
	  if (!noAssert) checkInt(this, value, offset, byteLength, Math.pow(2, 8 * byteLength), 0)

	  var mul = 1
	  var i = 0
	  this[offset] = value & 0xFF
	  while (++i < byteLength && (mul *= 0x100)) {
	    this[offset + i] = (value / mul) & 0xFF
	  }

	  return offset + byteLength
	}

	Buffer.prototype.writeUIntBE = function writeUIntBE (value, offset, byteLength, noAssert) {
	  value = +value
	  offset = offset | 0
	  byteLength = byteLength | 0
	  if (!noAssert) checkInt(this, value, offset, byteLength, Math.pow(2, 8 * byteLength), 0)

	  var i = byteLength - 1
	  var mul = 1
	  this[offset + i] = value & 0xFF
	  while (--i >= 0 && (mul *= 0x100)) {
	    this[offset + i] = (value / mul) & 0xFF
	  }

	  return offset + byteLength
	}

	Buffer.prototype.writeUInt8 = function writeUInt8 (value, offset, noAssert) {
	  value = +value
	  offset = offset | 0
	  if (!noAssert) checkInt(this, value, offset, 1, 0xff, 0)
	  if (!Buffer.TYPED_ARRAY_SUPPORT) value = Math.floor(value)
	  this[offset] = (value & 0xff)
	  return offset + 1
	}

	function objectWriteUInt16 (buf, value, offset, littleEndian) {
	  if (value < 0) value = 0xffff + value + 1
	  for (var i = 0, j = Math.min(buf.length - offset, 2); i < j; i++) {
	    buf[offset + i] = (value & (0xff << (8 * (littleEndian ? i : 1 - i)))) >>>
	      (littleEndian ? i : 1 - i) * 8
	  }
	}

	Buffer.prototype.writeUInt16LE = function writeUInt16LE (value, offset, noAssert) {
	  value = +value
	  offset = offset | 0
	  if (!noAssert) checkInt(this, value, offset, 2, 0xffff, 0)
	  if (Buffer.TYPED_ARRAY_SUPPORT) {
	    this[offset] = (value & 0xff)
	    this[offset + 1] = (value >>> 8)
	  } else {
	    objectWriteUInt16(this, value, offset, true)
	  }
	  return offset + 2
	}

	Buffer.prototype.writeUInt16BE = function writeUInt16BE (value, offset, noAssert) {
	  value = +value
	  offset = offset | 0
	  if (!noAssert) checkInt(this, value, offset, 2, 0xffff, 0)
	  if (Buffer.TYPED_ARRAY_SUPPORT) {
	    this[offset] = (value >>> 8)
	    this[offset + 1] = (value & 0xff)
	  } else {
	    objectWriteUInt16(this, value, offset, false)
	  }
	  return offset + 2
	}

	function objectWriteUInt32 (buf, value, offset, littleEndian) {
	  if (value < 0) value = 0xffffffff + value + 1
	  for (var i = 0, j = Math.min(buf.length - offset, 4); i < j; i++) {
	    buf[offset + i] = (value >>> (littleEndian ? i : 3 - i) * 8) & 0xff
	  }
	}

	Buffer.prototype.writeUInt32LE = function writeUInt32LE (value, offset, noAssert) {
	  value = +value
	  offset = offset | 0
	  if (!noAssert) checkInt(this, value, offset, 4, 0xffffffff, 0)
	  if (Buffer.TYPED_ARRAY_SUPPORT) {
	    this[offset + 3] = (value >>> 24)
	    this[offset + 2] = (value >>> 16)
	    this[offset + 1] = (value >>> 8)
	    this[offset] = (value & 0xff)
	  } else {
	    objectWriteUInt32(this, value, offset, true)
	  }
	  return offset + 4
	}

	Buffer.prototype.writeUInt32BE = function writeUInt32BE (value, offset, noAssert) {
	  value = +value
	  offset = offset | 0
	  if (!noAssert) checkInt(this, value, offset, 4, 0xffffffff, 0)
	  if (Buffer.TYPED_ARRAY_SUPPORT) {
	    this[offset] = (value >>> 24)
	    this[offset + 1] = (value >>> 16)
	    this[offset + 2] = (value >>> 8)
	    this[offset + 3] = (value & 0xff)
	  } else {
	    objectWriteUInt32(this, value, offset, false)
	  }
	  return offset + 4
	}

	Buffer.prototype.writeIntLE = function writeIntLE (value, offset, byteLength, noAssert) {
	  value = +value
	  offset = offset | 0
	  if (!noAssert) {
	    var limit = Math.pow(2, 8 * byteLength - 1)

	    checkInt(this, value, offset, byteLength, limit - 1, -limit)
	  }

	  var i = 0
	  var mul = 1
	  var sub = value < 0 ? 1 : 0
	  this[offset] = value & 0xFF
	  while (++i < byteLength && (mul *= 0x100)) {
	    this[offset + i] = ((value / mul) >> 0) - sub & 0xFF
	  }

	  return offset + byteLength
	}

	Buffer.prototype.writeIntBE = function writeIntBE (value, offset, byteLength, noAssert) {
	  value = +value
	  offset = offset | 0
	  if (!noAssert) {
	    var limit = Math.pow(2, 8 * byteLength - 1)

	    checkInt(this, value, offset, byteLength, limit - 1, -limit)
	  }

	  var i = byteLength - 1
	  var mul = 1
	  var sub = value < 0 ? 1 : 0
	  this[offset + i] = value & 0xFF
	  while (--i >= 0 && (mul *= 0x100)) {
	    this[offset + i] = ((value / mul) >> 0) - sub & 0xFF
	  }

	  return offset + byteLength
	}

	Buffer.prototype.writeInt8 = function writeInt8 (value, offset, noAssert) {
	  value = +value
	  offset = offset | 0
	  if (!noAssert) checkInt(this, value, offset, 1, 0x7f, -0x80)
	  if (!Buffer.TYPED_ARRAY_SUPPORT) value = Math.floor(value)
	  if (value < 0) value = 0xff + value + 1
	  this[offset] = (value & 0xff)
	  return offset + 1
	}

	Buffer.prototype.writeInt16LE = function writeInt16LE (value, offset, noAssert) {
	  value = +value
	  offset = offset | 0
	  if (!noAssert) checkInt(this, value, offset, 2, 0x7fff, -0x8000)
	  if (Buffer.TYPED_ARRAY_SUPPORT) {
	    this[offset] = (value & 0xff)
	    this[offset + 1] = (value >>> 8)
	  } else {
	    objectWriteUInt16(this, value, offset, true)
	  }
	  return offset + 2
	}

	Buffer.prototype.writeInt16BE = function writeInt16BE (value, offset, noAssert) {
	  value = +value
	  offset = offset | 0
	  if (!noAssert) checkInt(this, value, offset, 2, 0x7fff, -0x8000)
	  if (Buffer.TYPED_ARRAY_SUPPORT) {
	    this[offset] = (value >>> 8)
	    this[offset + 1] = (value & 0xff)
	  } else {
	    objectWriteUInt16(this, value, offset, false)
	  }
	  return offset + 2
	}

	Buffer.prototype.writeInt32LE = function writeInt32LE (value, offset, noAssert) {
	  value = +value
	  offset = offset | 0
	  if (!noAssert) checkInt(this, value, offset, 4, 0x7fffffff, -0x80000000)
	  if (Buffer.TYPED_ARRAY_SUPPORT) {
	    this[offset] = (value & 0xff)
	    this[offset + 1] = (value >>> 8)
	    this[offset + 2] = (value >>> 16)
	    this[offset + 3] = (value >>> 24)
	  } else {
	    objectWriteUInt32(this, value, offset, true)
	  }
	  return offset + 4
	}

	Buffer.prototype.writeInt32BE = function writeInt32BE (value, offset, noAssert) {
	  value = +value
	  offset = offset | 0
	  if (!noAssert) checkInt(this, value, offset, 4, 0x7fffffff, -0x80000000)
	  if (value < 0) value = 0xffffffff + value + 1
	  if (Buffer.TYPED_ARRAY_SUPPORT) {
	    this[offset] = (value >>> 24)
	    this[offset + 1] = (value >>> 16)
	    this[offset + 2] = (value >>> 8)
	    this[offset + 3] = (value & 0xff)
	  } else {
	    objectWriteUInt32(this, value, offset, false)
	  }
	  return offset + 4
	}

	function checkIEEE754 (buf, value, offset, ext, max, min) {
	  if (value > max || value < min) throw new RangeError('value is out of bounds')
	  if (offset + ext > buf.length) throw new RangeError('index out of range')
	  if (offset < 0) throw new RangeError('index out of range')
	}

	function writeFloat (buf, value, offset, littleEndian, noAssert) {
	  if (!noAssert) {
	    checkIEEE754(buf, value, offset, 4, 3.4028234663852886e+38, -3.4028234663852886e+38)
	  }
	  ieee754.write(buf, value, offset, littleEndian, 23, 4)
	  return offset + 4
	}

	Buffer.prototype.writeFloatLE = function writeFloatLE (value, offset, noAssert) {
	  return writeFloat(this, value, offset, true, noAssert)
	}

	Buffer.prototype.writeFloatBE = function writeFloatBE (value, offset, noAssert) {
	  return writeFloat(this, value, offset, false, noAssert)
	}

	function writeDouble (buf, value, offset, littleEndian, noAssert) {
	  if (!noAssert) {
	    checkIEEE754(buf, value, offset, 8, 1.7976931348623157E+308, -1.7976931348623157E+308)
	  }
	  ieee754.write(buf, value, offset, littleEndian, 52, 8)
	  return offset + 8
	}

	Buffer.prototype.writeDoubleLE = function writeDoubleLE (value, offset, noAssert) {
	  return writeDouble(this, value, offset, true, noAssert)
	}

	Buffer.prototype.writeDoubleBE = function writeDoubleBE (value, offset, noAssert) {
	  return writeDouble(this, value, offset, false, noAssert)
	}

	// copy(targetBuffer, targetStart=0, sourceStart=0, sourceEnd=buffer.length)
	Buffer.prototype.copy = function copy (target, targetStart, start, end) {
	  if (!start) start = 0
	  if (!end && end !== 0) end = this.length
	  if (targetStart >= target.length) targetStart = target.length
	  if (!targetStart) targetStart = 0
	  if (end > 0 && end < start) end = start

	  // Copy 0 bytes; we're done
	  if (end === start) return 0
	  if (target.length === 0 || this.length === 0) return 0

	  // Fatal error conditions
	  if (targetStart < 0) {
	    throw new RangeError('targetStart out of bounds')
	  }
	  if (start < 0 || start >= this.length) throw new RangeError('sourceStart out of bounds')
	  if (end < 0) throw new RangeError('sourceEnd out of bounds')

	  // Are we oob?
	  if (end > this.length) end = this.length
	  if (target.length - targetStart < end - start) {
	    end = target.length - targetStart + start
	  }

	  var len = end - start
	  var i

	  if (this === target && start < targetStart && targetStart < end) {
	    // descending copy from end
	    for (i = len - 1; i >= 0; i--) {
	      target[i + targetStart] = this[i + start]
	    }
	  } else if (len < 1000 || !Buffer.TYPED_ARRAY_SUPPORT) {
	    // ascending copy from start
	    for (i = 0; i < len; i++) {
	      target[i + targetStart] = this[i + start]
	    }
	  } else {
	    target._set(this.subarray(start, start + len), targetStart)
	  }

	  return len
	}

	// fill(value, start=0, end=buffer.length)
	Buffer.prototype.fill = function fill (value, start, end) {
	  if (!value) value = 0
	  if (!start) start = 0
	  if (!end) end = this.length

	  if (end < start) throw new RangeError('end < start')

	  // Fill 0 bytes; we're done
	  if (end === start) return
	  if (this.length === 0) return

	  if (start < 0 || start >= this.length) throw new RangeError('start out of bounds')
	  if (end < 0 || end > this.length) throw new RangeError('end out of bounds')

	  var i
	  if (typeof value === 'number') {
	    for (i = start; i < end; i++) {
	      this[i] = value
	    }
	  } else {
	    var bytes = utf8ToBytes(value.toString())
	    var len = bytes.length
	    for (i = start; i < end; i++) {
	      this[i] = bytes[i % len]
	    }
	  }

	  return this
	}

	/**
	 * Creates a new `ArrayBuffer` with the *copied* memory of the buffer instance.
	 * Added in Node 0.12. Only available in browsers that support ArrayBuffer.
	 */
	Buffer.prototype.toArrayBuffer = function toArrayBuffer () {
	  if (typeof Uint8Array !== 'undefined') {
	    if (Buffer.TYPED_ARRAY_SUPPORT) {
	      return (new Buffer(this)).buffer
	    } else {
	      var buf = new Uint8Array(this.length)
	      for (var i = 0, len = buf.length; i < len; i += 1) {
	        buf[i] = this[i]
	      }
	      return buf.buffer
	    }
	  } else {
	    throw new TypeError('Buffer.toArrayBuffer not supported in this browser')
	  }
	}

	// HELPER FUNCTIONS
	// ================

	var BP = Buffer.prototype

	/**
	 * Augment a Uint8Array *instance* (not the Uint8Array class!) with Buffer methods
	 */
	Buffer._augment = function _augment (arr) {
	  arr.constructor = Buffer
	  arr._isBuffer = true

	  // save reference to original Uint8Array set method before overwriting
	  arr._set = arr.set

	  // deprecated
	  arr.get = BP.get
	  arr.set = BP.set

	  arr.write = BP.write
	  arr.toString = BP.toString
	  arr.toLocaleString = BP.toString
	  arr.toJSON = BP.toJSON
	  arr.equals = BP.equals
	  arr.compare = BP.compare
	  arr.indexOf = BP.indexOf
	  arr.copy = BP.copy
	  arr.slice = BP.slice
	  arr.readUIntLE = BP.readUIntLE
	  arr.readUIntBE = BP.readUIntBE
	  arr.readUInt8 = BP.readUInt8
	  arr.readUInt16LE = BP.readUInt16LE
	  arr.readUInt16BE = BP.readUInt16BE
	  arr.readUInt32LE = BP.readUInt32LE
	  arr.readUInt32BE = BP.readUInt32BE
	  arr.readIntLE = BP.readIntLE
	  arr.readIntBE = BP.readIntBE
	  arr.readInt8 = BP.readInt8
	  arr.readInt16LE = BP.readInt16LE
	  arr.readInt16BE = BP.readInt16BE
	  arr.readInt32LE = BP.readInt32LE
	  arr.readInt32BE = BP.readInt32BE
	  arr.readFloatLE = BP.readFloatLE
	  arr.readFloatBE = BP.readFloatBE
	  arr.readDoubleLE = BP.readDoubleLE
	  arr.readDoubleBE = BP.readDoubleBE
	  arr.writeUInt8 = BP.writeUInt8
	  arr.writeUIntLE = BP.writeUIntLE
	  arr.writeUIntBE = BP.writeUIntBE
	  arr.writeUInt16LE = BP.writeUInt16LE
	  arr.writeUInt16BE = BP.writeUInt16BE
	  arr.writeUInt32LE = BP.writeUInt32LE
	  arr.writeUInt32BE = BP.writeUInt32BE
	  arr.writeIntLE = BP.writeIntLE
	  arr.writeIntBE = BP.writeIntBE
	  arr.writeInt8 = BP.writeInt8
	  arr.writeInt16LE = BP.writeInt16LE
	  arr.writeInt16BE = BP.writeInt16BE
	  arr.writeInt32LE = BP.writeInt32LE
	  arr.writeInt32BE = BP.writeInt32BE
	  arr.writeFloatLE = BP.writeFloatLE
	  arr.writeFloatBE = BP.writeFloatBE
	  arr.writeDoubleLE = BP.writeDoubleLE
	  arr.writeDoubleBE = BP.writeDoubleBE
	  arr.fill = BP.fill
	  arr.inspect = BP.inspect
	  arr.toArrayBuffer = BP.toArrayBuffer

	  return arr
	}

	var INVALID_BASE64_RE = /[^+\/0-9A-Za-z-_]/g

	function base64clean (str) {
	  // Node strips out invalid characters like \n and \t from the string, base64-js does not
	  str = stringtrim(str).replace(INVALID_BASE64_RE, '')
	  // Node converts strings with length < 2 to ''
	  if (str.length < 2) return ''
	  // Node allows for non-padded base64 strings (missing trailing ===), base64-js does not
	  while (str.length % 4 !== 0) {
	    str = str + '='
	  }
	  return str
	}

	function stringtrim (str) {
	  if (str.trim) return str.trim()
	  return str.replace(/^\s+|\s+$/g, '')
	}

	function toHex (n) {
	  if (n < 16) return '0' + n.toString(16)
	  return n.toString(16)
	}

	function utf8ToBytes (string, units) {
	  units = units || Infinity
	  var codePoint
	  var length = string.length
	  var leadSurrogate = null
	  var bytes = []

	  for (var i = 0; i < length; i++) {
	    codePoint = string.charCodeAt(i)

	    // is surrogate component
	    if (codePoint > 0xD7FF && codePoint < 0xE000) {
	      // last char was a lead
	      if (!leadSurrogate) {
	        // no lead yet
	        if (codePoint > 0xDBFF) {
	          // unexpected trail
	          if ((units -= 3) > -1) bytes.push(0xEF, 0xBF, 0xBD)
	          continue
	        } else if (i + 1 === length) {
	          // unpaired lead
	          if ((units -= 3) > -1) bytes.push(0xEF, 0xBF, 0xBD)
	          continue
	        }

	        // valid lead
	        leadSurrogate = codePoint

	        continue
	      }

	      // 2 leads in a row
	      if (codePoint < 0xDC00) {
	        if ((units -= 3) > -1) bytes.push(0xEF, 0xBF, 0xBD)
	        leadSurrogate = codePoint
	        continue
	      }

	      // valid surrogate pair
	      codePoint = (leadSurrogate - 0xD800 << 10 | codePoint - 0xDC00) + 0x10000
	    } else if (leadSurrogate) {
	      // valid bmp char, but last char was a lead
	      if ((units -= 3) > -1) bytes.push(0xEF, 0xBF, 0xBD)
	    }

	    leadSurrogate = null

	    // encode utf8
	    if (codePoint < 0x80) {
	      if ((units -= 1) < 0) break
	      bytes.push(codePoint)
	    } else if (codePoint < 0x800) {
	      if ((units -= 2) < 0) break
	      bytes.push(
	        codePoint >> 0x6 | 0xC0,
	        codePoint & 0x3F | 0x80
	      )
	    } else if (codePoint < 0x10000) {
	      if ((units -= 3) < 0) break
	      bytes.push(
	        codePoint >> 0xC | 0xE0,
	        codePoint >> 0x6 & 0x3F | 0x80,
	        codePoint & 0x3F | 0x80
	      )
	    } else if (codePoint < 0x110000) {
	      if ((units -= 4) < 0) break
	      bytes.push(
	        codePoint >> 0x12 | 0xF0,
	        codePoint >> 0xC & 0x3F | 0x80,
	        codePoint >> 0x6 & 0x3F | 0x80,
	        codePoint & 0x3F | 0x80
	      )
	    } else {
	      throw new Error('Invalid code point')
	    }
	  }

	  return bytes
	}

	function asciiToBytes (str) {
	  var byteArray = []
	  for (var i = 0; i < str.length; i++) {
	    // Node's code seems to be doing this and not & 0x7F..
	    byteArray.push(str.charCodeAt(i) & 0xFF)
	  }
	  return byteArray
	}

	function utf16leToBytes (str, units) {
	  var c, hi, lo
	  var byteArray = []
	  for (var i = 0; i < str.length; i++) {
	    if ((units -= 2) < 0) break

	    c = str.charCodeAt(i)
	    hi = c >> 8
	    lo = c % 256
	    byteArray.push(lo)
	    byteArray.push(hi)
	  }

	  return byteArray
	}

	function base64ToBytes (str) {
	  return base64.toByteArray(base64clean(str))
	}

	function blitBuffer (src, dst, offset, length) {
	  for (var i = 0; i < length; i++) {
	    if ((i + offset >= dst.length) || (i >= src.length)) break
	    dst[i + offset] = src[i]
	  }
	  return i
	}

	/* WEBPACK VAR INJECTION */}.call(exports, __webpack_require__(28).Buffer, (function() { return this; }())))

/***/ },
/* 29 */
/***/ function(module, exports, __webpack_require__) {

	var lookup = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

	;(function (exports) {
		'use strict';

	  var Arr = (typeof Uint8Array !== 'undefined')
	    ? Uint8Array
	    : Array

		var PLUS   = '+'.charCodeAt(0)
		var SLASH  = '/'.charCodeAt(0)
		var NUMBER = '0'.charCodeAt(0)
		var LOWER  = 'a'.charCodeAt(0)
		var UPPER  = 'A'.charCodeAt(0)
		var PLUS_URL_SAFE = '-'.charCodeAt(0)
		var SLASH_URL_SAFE = '_'.charCodeAt(0)

		function decode (elt) {
			var code = elt.charCodeAt(0)
			if (code === PLUS ||
			    code === PLUS_URL_SAFE)
				return 62 // '+'
			if (code === SLASH ||
			    code === SLASH_URL_SAFE)
				return 63 // '/'
			if (code < NUMBER)
				return -1 //no match
			if (code < NUMBER + 10)
				return code - NUMBER + 26 + 26
			if (code < UPPER + 26)
				return code - UPPER
			if (code < LOWER + 26)
				return code - LOWER + 26
		}

		function b64ToByteArray (b64) {
			var i, j, l, tmp, placeHolders, arr

			if (b64.length % 4 > 0) {
				throw new Error('Invalid string. Length must be a multiple of 4')
			}

			// the number of equal signs (place holders)
			// if there are two placeholders, than the two characters before it
			// represent one byte
			// if there is only one, then the three characters before it represent 2 bytes
			// this is just a cheap hack to not do indexOf twice
			var len = b64.length
			placeHolders = '=' === b64.charAt(len - 2) ? 2 : '=' === b64.charAt(len - 1) ? 1 : 0

			// base64 is 4/3 + up to two characters of the original data
			arr = new Arr(b64.length * 3 / 4 - placeHolders)

			// if there are placeholders, only get up to the last complete 4 chars
			l = placeHolders > 0 ? b64.length - 4 : b64.length

			var L = 0

			function push (v) {
				arr[L++] = v
			}

			for (i = 0, j = 0; i < l; i += 4, j += 3) {
				tmp = (decode(b64.charAt(i)) << 18) | (decode(b64.charAt(i + 1)) << 12) | (decode(b64.charAt(i + 2)) << 6) | decode(b64.charAt(i + 3))
				push((tmp & 0xFF0000) >> 16)
				push((tmp & 0xFF00) >> 8)
				push(tmp & 0xFF)
			}

			if (placeHolders === 2) {
				tmp = (decode(b64.charAt(i)) << 2) | (decode(b64.charAt(i + 1)) >> 4)
				push(tmp & 0xFF)
			} else if (placeHolders === 1) {
				tmp = (decode(b64.charAt(i)) << 10) | (decode(b64.charAt(i + 1)) << 4) | (decode(b64.charAt(i + 2)) >> 2)
				push((tmp >> 8) & 0xFF)
				push(tmp & 0xFF)
			}

			return arr
		}

		function uint8ToBase64 (uint8) {
			var i,
				extraBytes = uint8.length % 3, // if we have 1 byte left, pad 2 bytes
				output = "",
				temp, length

			function encode (num) {
				return lookup.charAt(num)
			}

			function tripletToBase64 (num) {
				return encode(num >> 18 & 0x3F) + encode(num >> 12 & 0x3F) + encode(num >> 6 & 0x3F) + encode(num & 0x3F)
			}

			// go through the array every three bytes, we'll deal with trailing stuff later
			for (i = 0, length = uint8.length - extraBytes; i < length; i += 3) {
				temp = (uint8[i] << 16) + (uint8[i + 1] << 8) + (uint8[i + 2])
				output += tripletToBase64(temp)
			}

			// pad the end with zeros, but make sure to not forget the extra bytes
			switch (extraBytes) {
				case 1:
					temp = uint8[uint8.length - 1]
					output += encode(temp >> 2)
					output += encode((temp << 4) & 0x3F)
					output += '=='
					break
				case 2:
					temp = (uint8[uint8.length - 2] << 8) + (uint8[uint8.length - 1])
					output += encode(temp >> 10)
					output += encode((temp >> 4) & 0x3F)
					output += encode((temp << 2) & 0x3F)
					output += '='
					break
			}

			return output
		}

		exports.toByteArray = b64ToByteArray
		exports.fromByteArray = uint8ToBase64
	}( false ? (this.base64js = {}) : exports))


/***/ },
/* 30 */
/***/ function(module, exports) {

	exports.read = function (buffer, offset, isLE, mLen, nBytes) {
	  var e, m
	  var eLen = nBytes * 8 - mLen - 1
	  var eMax = (1 << eLen) - 1
	  var eBias = eMax >> 1
	  var nBits = -7
	  var i = isLE ? (nBytes - 1) : 0
	  var d = isLE ? -1 : 1
	  var s = buffer[offset + i]

	  i += d

	  e = s & ((1 << (-nBits)) - 1)
	  s >>= (-nBits)
	  nBits += eLen
	  for (; nBits > 0; e = e * 256 + buffer[offset + i], i += d, nBits -= 8) {}

	  m = e & ((1 << (-nBits)) - 1)
	  e >>= (-nBits)
	  nBits += mLen
	  for (; nBits > 0; m = m * 256 + buffer[offset + i], i += d, nBits -= 8) {}

	  if (e === 0) {
	    e = 1 - eBias
	  } else if (e === eMax) {
	    return m ? NaN : ((s ? -1 : 1) * Infinity)
	  } else {
	    m = m + Math.pow(2, mLen)
	    e = e - eBias
	  }
	  return (s ? -1 : 1) * m * Math.pow(2, e - mLen)
	}

	exports.write = function (buffer, value, offset, isLE, mLen, nBytes) {
	  var e, m, c
	  var eLen = nBytes * 8 - mLen - 1
	  var eMax = (1 << eLen) - 1
	  var eBias = eMax >> 1
	  var rt = (mLen === 23 ? Math.pow(2, -24) - Math.pow(2, -77) : 0)
	  var i = isLE ? 0 : (nBytes - 1)
	  var d = isLE ? 1 : -1
	  var s = value < 0 || (value === 0 && 1 / value < 0) ? 1 : 0

	  value = Math.abs(value)

	  if (isNaN(value) || value === Infinity) {
	    m = isNaN(value) ? 1 : 0
	    e = eMax
	  } else {
	    e = Math.floor(Math.log(value) / Math.LN2)
	    if (value * (c = Math.pow(2, -e)) < 1) {
	      e--
	      c *= 2
	    }
	    if (e + eBias >= 1) {
	      value += rt / c
	    } else {
	      value += rt * Math.pow(2, 1 - eBias)
	    }
	    if (value * c >= 2) {
	      e++
	      c /= 2
	    }

	    if (e + eBias >= eMax) {
	      m = 0
	      e = eMax
	    } else if (e + eBias >= 1) {
	      m = (value * c - 1) * Math.pow(2, mLen)
	      e = e + eBias
	    } else {
	      m = value * Math.pow(2, eBias - 1) * Math.pow(2, mLen)
	      e = 0
	    }
	  }

	  for (; mLen >= 8; buffer[offset + i] = m & 0xff, i += d, m /= 256, mLen -= 8) {}

	  e = (e << mLen) | m
	  eLen += mLen
	  for (; eLen > 0; buffer[offset + i] = e & 0xff, i += d, e /= 256, eLen -= 8) {}

	  buffer[offset + i - d] |= s * 128
	}


/***/ },
/* 31 */
/***/ function(module, exports) {

	var toString = {}.toString;

	module.exports = Array.isArray || function (arr) {
	  return toString.call(arr) == '[object Array]';
	};


/***/ },
/* 32 */
/***/ function(module, exports, __webpack_require__) {

	
	/*
	  backbone-orm.js 0.7.14
	  Copyright (c) 2013-2016 Vidigami
	  License: MIT (http://www.opensource.org/licenses/mit-license.php)
	  Source: https://github.com/vidigami/backbone-orm
	  Dependencies: Backbone.js and Underscore.js.
	 */
	var BackboneORM, DatabaseURL, SUPPORTED_KEYS, URL, _;

	_ = __webpack_require__(1);

	URL = __webpack_require__(25);

	BackboneORM = __webpack_require__(3);

	SUPPORTED_KEYS = ['protocol', 'slashes', 'auth', 'host', 'hostname', 'port', 'search', 'query', 'hash', 'href'];

	module.exports = DatabaseURL = (function() {
	  function DatabaseURL(url, parse_query_string, slashes_denote_host) {
	    var database, database_parts, databases, databases_string, host, i, j, k, key, len, len1, len2, parts, path_paths, ref, start_parts, start_url, url_parts;
	    url_parts = URL.parse(url, parse_query_string, slashes_denote_host);
	    parts = url_parts.pathname.split(',');
	    if (parts.length > 1) {
	      start_parts = _.pick(url_parts, 'protocol', 'auth', 'slashes');
	      start_parts.host = '{1}';
	      start_parts.pathname = '{2}';
	      start_url = URL.format(start_parts);
	      start_url = start_url.replace('{1}/{2}', '');
	      path_paths = url_parts.pathname.split('/');
	      url_parts.pathname = "/" + path_paths[path_paths.length - 2] + "/" + path_paths[path_paths.length - 1];
	      databases_string = url.replace(start_url, '');
	      databases_string = databases_string.substring(0, databases_string.indexOf(url_parts.pathname));
	      databases = databases_string.split(',');
	      ref = ['host', 'hostname', 'port'];
	      for (i = 0, len = ref.length; i < len; i++) {
	        key = ref[i];
	        delete url_parts[key];
	      }
	      this.hosts = [];
	      for (j = 0, len1 = databases.length; j < len1; j++) {
	        database = databases[j];
	        host = database.split(':');
	        this.hosts.push(host.length === 1 ? {
	          host: host[0],
	          hostname: host[0]
	        } : {
	          host: host[0],
	          hostname: host[0] + ":" + host[1],
	          port: host[1]
	        });
	      }
	    }
	    database_parts = _.compact(url_parts.pathname.split('/'));
	    this.table = database_parts.pop();
	    this.database = database_parts.join('/');
	    for (k = 0, len2 = SUPPORTED_KEYS.length; k < len2; k++) {
	      key = SUPPORTED_KEYS[k];
	      if (url_parts.hasOwnProperty(key)) {
	        this[key] = url_parts[key];
	      }
	    }
	  }

	  DatabaseURL.prototype.format = function(options) {
	    var host_strings, url, url_parts;
	    if (options == null) {
	      options = {};
	    }
	    url_parts = _.pick(this, SUPPORTED_KEYS);
	    url_parts.pathname = '';
	    if (this.hosts) {
	      host_strings = _.map(this.hosts, function(host) {
	        return "" + host.host + (host.port ? ':' + host.port : '');
	      });
	      url_parts.pathname += host_strings.join(',');
	      url_parts.host = "{1}";
	    }
	    if (this.database) {
	      url_parts.pathname += "/" + this.database;
	    }
	    if (this.table && !options.exclude_table) {
	      url_parts.pathname += "/" + this.table;
	    }
	    if (options.exclude_search || options.exclude_query) {
	      delete url_parts.search;
	      delete url_parts.query;
	    }
	    url = URL.format(url_parts);
	    if (this.hosts) {
	      url = url.replace("{1}/" + url_parts.pathname, url_parts.pathname);
	    }
	    return url;
	  };

	  DatabaseURL.prototype.parseAuth = function() {
	    var auth_parts, result;
	    if (!this.auth) {
	      return null;
	    }
	    auth_parts = this.auth.split(':');
	    result = {
	      user: auth_parts[0]
	    };
	    result.password = auth_parts.length > 1 ? auth_parts[1] : null;
	    return result;
	  };

	  DatabaseURL.prototype.modelName = function() {
	    if (this.table) {
	      return BackboneORM.naming_conventions.modelName(this.table, false);
	    } else {
	      return null;
	    }
	  };

	  return DatabaseURL;

	})();


/***/ },
/* 33 */
/***/ function(module, exports, __webpack_require__) {

	
	/*
	  backbone-orm.js 0.7.14
	  Copyright (c) 2013-2016 Vidigami
	  License: MIT (http://www.opensource.org/licenses/mit-license.php)
	  Source: https://github.com/vidigami/backbone-orm
	  Dependencies: Backbone.js and Underscore.js.
	 */
	var IterationUtils, JSONUtils, Queue, _;

	_ = __webpack_require__(1);

	Queue = __webpack_require__(11);

	IterationUtils = __webpack_require__(34);

	module.exports = JSONUtils = (function() {
	  function JSONUtils() {}

	  JSONUtils.stringify = function(json) {
	    var err, error;
	    try {
	      return JSON.stringify(json);
	    } catch (error) {
	      err = error;
	      return 'Failed to stringify';
	    }
	  };

	  JSONUtils.isEmptyObject = function(obj) {
	    var key;
	    for (key in obj) {
	      return false;
	    }
	    return true;
	  };

	  JSONUtils.parseDates = function(json) {
	    var date, key, value;
	    if (_.isString(json)) {
	      if ((json.length >= 20) && json[json.length - 1] === 'Z' && !_.isNaN((date = new Date(json)).getTime())) {
	        return date;
	      }
	    } else if (_.isObject(json) || _.isArray(json)) {
	      for (key in json) {
	        value = json[key];
	        json[key] = JSONUtils.parseDates(value);
	      }
	    }
	    return json;
	  };

	  JSONUtils.parseField = function(value, model_type, key) {
	    var integer_value;
	    if ((model_type != null ? model_type.schema().idType(key) : void 0) !== 'Integer') {
	      return JSONUtils.parseDates(value);
	    }
	    if (!_.isNaN(integer_value = +value)) {
	      return integer_value;
	    }
	    console.log("Warning: failed to convert key: " + key + " value: " + value + " to integer. Model: " + model_type.model_name);
	    return value;
	  };

	  JSONUtils.parse = function(obj, model_type) {
	    var key, result, value;
	    if (!_.isObject(obj)) {
	      return JSONUtils.parseDates(obj);
	    }
	    if (_.isArray(obj)) {
	      return (function() {
	        var i, len, results1;
	        results1 = [];
	        for (i = 0, len = obj.length; i < len; i++) {
	          value = obj[i];
	          results1.push(JSONUtils.parse(value, model_type));
	        }
	        return results1;
	      })();
	    }
	    result = {};
	    for (key in obj) {
	      value = obj[key];
	      result[key] = JSONUtils.parseField(value, model_type, key);
	    }
	    return result;
	  };

	  JSONUtils.parseQuery = function(query) {
	    var json, key, value;
	    json = {};
	    for (key in query) {
	      value = query[key];
	      json[key] = value;
	      if (_.isString(value) && value.length) {
	        try {
	          value = JSON.parse(value);
	        } catch (undefined) {}
	        json[key] = JSONUtils.parseDates(value);
	      }
	    }
	    return json;
	  };

	  JSONUtils.querify = function(json) {
	    var key, query, value;
	    query = {};
	    for (key in json) {
	      value = json[key];
	      query[key] = JSON.stringify(value);
	    }
	    return query;
	  };

	  JSONUtils.toQuery = function(json) {
	    return console.log("JSONUtils.toQuery has been deprecated. Use JSONUtils.querify instead");
	  };

	  JSONUtils.renderTemplate = function(models, template, options, callback) {
	    var results;
	    if (arguments.length === 3) {
	      callback = options;
	      options = {};
	    }
	    if (!_.isArray(models)) {
	      if (!models) {
	        return callback(null, null);
	      }
	      if (_.isString(template)) {
	        return JSONUtils.renderKey(models, template, options, callback);
	      }
	      if (_.isArray(template)) {
	        return JSONUtils.renderKeys(models, template, options, callback);
	      }
	      if (_.isFunction(template)) {
	        return template(models, options, callback);
	      }
	      return JSONUtils.renderDSL(models, template, options, callback);
	    } else {
	      results = [];
	      return IterationUtils.each(models, ((function(_this) {
	        return function(model, callback) {
	          return JSONUtils.renderTemplate(model, template, options, function(err, related_json) {
	            err || results.push(related_json);
	            return callback(err);
	          });
	        };
	      })(this)), function(err) {
	        if (err) {
	          return callback(err);
	        } else {
	          return callback(null, results);
	        }
	      });
	    }
	  };

	  JSONUtils.renderDSL = function(model, dsl, options, callback) {
	    var args, fn, key, queue, result;
	    if (arguments.length === 3) {
	      callback = options;
	      options = {};
	    }
	    queue = new Queue();
	    result = {};
	    fn = function(key, args) {
	      return queue.defer(function(callback) {
	        var field, fn_args, query, relation, template;
	        field = args.key || key;
	        if (relation = model.relation(field)) {
	          if (args.query) {
	            query = args.query;
	            template = args.template;
	          } else if (args.$count) {
	            query = _.clone(args);
	            delete query.key;
	          } else if (_.isFunction(args)) {
	            template = args;
	          } else if (args.template) {
	            if (_.isObject(args.template) && !_.isFunction(args.template)) {
	              query = args.template;
	            } else {
	              template = args.template;
	              query = _.clone(args);
	              delete query.key;
	              delete query.template;
	              if (JSONUtils.isEmptyObject(query)) {
	                query = null;
	              }
	            }
	          } else {
	            template = _.clone(args);
	            delete template.key;
	          }
	          if (template) {
	            if (query) {
	              return relation.cursor(model, field, query).toModels(function(err, models) {
	                if (err) {
	                  return callback(err);
	                }
	                return JSONUtils.renderTemplate(models, template, options, function(err, json) {
	                  result[key] = json;
	                  return callback(err);
	                });
	              });
	            } else {
	              return model.get(field, function(err, related_model) {
	                if (err) {
	                  return callback(err);
	                }
	                return JSONUtils.renderTemplate(related_model, template, options, function(err, json) {
	                  result[key] = json;
	                  return callback(err);
	                });
	              });
	            }
	          } else {
	            return relation.cursor(model, field, query).toJSON(function(err, json) {
	              result[key] = json;
	              return callback(err);
	            });
	          }
	        } else {
	          if (key.length > 1 && key[key.length - 1] === '_') {
	            key = key.slice(0, +(key.length - 2) + 1 || 9e9);
	          }
	          if (key === '$select') {
	            if (_.isString(args)) {
	              return JSONUtils.renderKey(model, args, options, function(err, json) {
	                result[args] = json;
	                return callback(err);
	              });
	            } else {
	              return JSONUtils.renderKeys(model, args, options, function(err, json) {
	                _.extend(result, json);
	                return callback(err);
	              });
	            }
	          } else if (_.isString(args)) {
	            return JSONUtils.renderKey(model, args, options, function(err, json) {
	              result[key] = json;
	              return callback(err);
	            });
	          } else if (_.isFunction(args)) {
	            return args(model, options, function(err, json) {
	              result[key] = json;
	              return callback(err);
	            });
	          } else if (_.isString(args.method)) {
	            fn_args = _.isArray(args.args) ? args.args.slice() : (args.args ? [args.args] : []);
	            fn_args.push(function(err, json) {
	              result[key] = json;
	              return callback(err);
	            });
	            return model[args.method].apply(model, fn_args);
	          } else {
	            console.trace("Unknown DSL action: " + key + ": ", args);
	            return callback(new Error("Unknown DSL action: " + key + ": ", args));
	          }
	        }
	      });
	    };
	    for (key in dsl) {
	      args = dsl[key];
	      fn(key, args);
	    }
	    return queue.await(function(err) {
	      return callback(err, err ? void 0 : result);
	    });
	  };

	  JSONUtils.renderKeys = function(model, keys, options, callback) {
	    var fn, i, key, len, queue, result;
	    if (arguments.length === 3) {
	      callback = options;
	      options = {};
	    }
	    result = {};
	    queue = new Queue();
	    fn = function(key) {
	      return queue.defer(function(callback) {
	        return JSONUtils.renderKey(model, key, options, function(err, value) {
	          if (err) {
	            return callback(err);
	          }
	          result[key] = value;
	          return callback();
	        });
	      });
	    };
	    for (i = 0, len = keys.length; i < len; i++) {
	      key = keys[i];
	      fn(key);
	    }
	    return queue.await(function(err) {
	      return callback(err, err ? void 0 : result);
	    });
	  };

	  JSONUtils.renderKey = function(model, key, options, callback) {
	    if (arguments.length === 3) {
	      callback = options;
	      options = {};
	    }
	    return model.get(key, function(err, value) {
	      var item;
	      if (err) {
	        return callback(err);
	      }
	      if (model.relation(key)) {
	        if (_.isArray(value)) {
	          return callback(null, (function() {
	            var i, len, results1;
	            results1 = [];
	            for (i = 0, len = value.length; i < len; i++) {
	              item = value[i];
	              results1.push(item.toJSON());
	            }
	            return results1;
	          })());
	        }
	        if (value && value.toJSON) {
	          return callback(null, value = value.toJSON());
	        }
	      }
	      return callback(null, value);
	    });
	  };

	  JSONUtils.renderRelated = function(models, attribute_name, template, options, callback) {
	    var fn, i, len, model, queue, results;
	    if (arguments.length === 4) {
	      callback = options;
	      options = {};
	    }
	    if (!_.isArray(models)) {
	      return models.get(attribute_name, function(err, related_models) {
	        if (err) {
	          callback(err);
	        }
	        return JSONUtils.renderTemplate(related_models, template, options, callback);
	      });
	    } else {
	      results = [];
	      queue = new Queue();
	      fn = function(model) {
	        return queue.defer(function(callback) {
	          return model.get(attribute_name, function(err, related_models) {
	            if (err) {
	              callback(err);
	            }
	            return JSONUtils.renderTemplate(related_models, template, options, function(err, related_json) {
	              if (err) {
	                return callback(err);
	              }
	              results.push(related_json);
	              return callback();
	            });
	          });
	        });
	      };
	      for (i = 0, len = models.length; i < len; i++) {
	        model = models[i];
	        fn(model);
	      }
	      return queue.await(function(err) {
	        return callback(err, err ? void 0 : results);
	      });
	    }
	  };

	  JSONUtils.deepClone = function(obj, depth) {
	    var clone, key;
	    if (!obj || (typeof obj !== 'object')) {
	      return obj;
	    }
	    if (_.isString(obj)) {
	      return String.prototype.slice.call(obj);
	    }
	    if (_.isDate(obj)) {
	      return new Date(obj.getTime());
	    }
	    if (_.isFunction(obj.clone)) {
	      return obj.clone();
	    }
	    if (_.isArray(obj)) {
	      clone = Array.prototype.slice.call(obj);
	    } else if (obj.constructor !== {}.constructor) {
	      return obj;
	    } else {
	      clone = _.extend({}, obj);
	    }
	    if (!_.isUndefined(depth) && (depth > 0)) {
	      for (key in clone) {
	        clone[key] = JSONUtils.deepClone(clone[key], depth - 1);
	      }
	    }
	    return clone;
	  };

	  return JSONUtils;

	})();


/***/ },
/* 34 */
/***/ function(module, exports, __webpack_require__) {

	/* WEBPACK VAR INJECTION */(function(process) {
	/*
	  backbone-orm.js 0.7.14
	  Copyright (c) 2013-2016 Vidigami
	  License: MIT (http://www.opensource.org/licenses/mit-license.php)
	  Source: https://github.com/vidigami/backbone-orm
	  Dependencies: Backbone.js and Underscore.js.
	 */
	var IterationUtils, nextTick;

	nextTick = (typeof process !== "undefined" && process !== null ? process.nextTick : void 0) || (__webpack_require__(1)).defer;

	module.exports = IterationUtils = (function() {
	  function IterationUtils() {}

	  IterationUtils.MAX_ITERATION_COUNT = 300;

	  IterationUtils.eachDone = function(array, iterator, callback) {
	    var count, index, iterate;
	    if (!(count = array.length)) {
	      return callback();
	    }
	    index = 0;
	    iterate = function() {
	      return iterator(array[index++], function(err, done) {
	        if (err || (index >= count) || done) {
	          return callback(err);
	        }
	        if (index && (index % IterationUtils.MAX_ITERATION_COUNT === 0)) {
	          return nextTick(iterate);
	        } else {
	          return iterate();
	        }
	      });
	    };
	    return iterate();
	  };

	  IterationUtils.each = function(array, iterator, callback) {
	    var count, index, iterate;
	    if (!(count = array.length)) {
	      return callback();
	    }
	    index = 0;
	    iterate = function() {
	      return iterator(array[index++], function(err) {
	        if (err || (index >= count)) {
	          return callback(err);
	        }
	        if (index && (index % IterationUtils.MAX_ITERATION_COUNT === 0)) {
	          return nextTick(iterate);
	        } else {
	          return iterate();
	        }
	      });
	    };
	    return iterate();
	  };

	  IterationUtils.popEach = function(array, iterator, callback) {
	    var count, index, iterate;
	    if (!(count = array.length)) {
	      return callback();
	    }
	    index = 0;
	    iterate = function() {
	      index++;
	      return iterator(array.pop(), function(err) {
	        if (err || (index >= count) || (array.length === 0)) {
	          return callback(err);
	        }
	        if (index && (index % IterationUtils.MAX_ITERATION_COUNT === 0)) {
	          return nextTick(iterate);
	        } else {
	          return iterate();
	        }
	      });
	    };
	    return iterate();
	  };

	  return IterationUtils;

	})();

	/* WEBPACK VAR INJECTION */}.call(exports, __webpack_require__(15)))

/***/ },
/* 35 */
/***/ function(module, exports, __webpack_require__) {

	
	/*
	  backbone-orm.js 0.7.14
	  Copyright (c) 2013-2016 Vidigami
	  License: MIT (http://www.opensource.org/licenses/mit-license.php)
	  Source: https://github.com/vidigami/backbone-orm
	  Dependencies: Backbone.js and Underscore.js.
	 */
	var Backbone, DatabaseURL, JSONUtils, ModelStream, Queue, Utils, _, modelEach, modelInterval;

	_ = __webpack_require__(1);

	Backbone = __webpack_require__(2);

	Queue = __webpack_require__(11);

	Utils = __webpack_require__(24);

	JSONUtils = __webpack_require__(33);

	DatabaseURL = __webpack_require__(32);

	ModelStream = __webpack_require__(36);

	modelEach = __webpack_require__(38);

	modelInterval = __webpack_require__(39);

	__webpack_require__(41);

	module.exports = function(model_type) {
	  var BackboneModelExtensions, _findOrClone, fn, key, overrides, results;
	  BackboneModelExtensions = (function() {
	    function BackboneModelExtensions() {}

	    return BackboneModelExtensions;

	  })();
	  model_type.createSync = function(target_model_type) {
	    return model_type.prototype.sync('createSync', target_model_type);
	  };
	  model_type.resetSchema = function(options, callback) {
	    var ref;
	    if (arguments.length === 1) {
	      ref = [{}, options], options = ref[0], callback = ref[1];
	    }
	    return model_type.prototype.sync('resetSchema', options, callback);
	  };
	  model_type.cursor = function(query) {
	    if (query == null) {
	      query = {};
	    }
	    return model_type.prototype.sync('cursor', query);
	  };
	  model_type.destroy = function(query, callback) {
	    var ref;
	    if (arguments.length === 1) {
	      ref = [{}, query], query = ref[0], callback = ref[1];
	    }
	    if (!_.isObject(query)) {
	      query = {
	        id: query
	      };
	    }
	    return model_type.prototype.sync('destroy', query, callback);
	  };
	  model_type.db = function() {
	    return model_type.prototype.sync('db');
	  };
	  model_type.exists = function(query, callback) {
	    var ref;
	    if (arguments.length === 1) {
	      ref = [{}, query], query = ref[0], callback = ref[1];
	    }
	    return model_type.prototype.sync('cursor', query).exists(callback);
	  };
	  model_type.count = function(query, callback) {
	    var ref;
	    if (arguments.length === 1) {
	      ref = [{}, query], query = ref[0], callback = ref[1];
	    }
	    return model_type.prototype.sync('cursor', query).count(callback);
	  };
	  model_type.all = function(callback) {
	    return model_type.prototype.sync('cursor', {}).toModels(callback);
	  };
	  model_type.find = function(query, callback) {
	    var ref;
	    if (arguments.length === 1) {
	      ref = [{}, query], query = ref[0], callback = ref[1];
	    }
	    return model_type.prototype.sync('cursor', query).toModels(callback);
	  };
	  model_type.findOne = function(query, callback) {
	    var ref;
	    if (arguments.length === 1) {
	      ref = [{}, query], query = ref[0], callback = ref[1];
	    }
	    query = _.isObject(query) ? _.extend({
	      $one: true
	    }, query) : {
	      id: query,
	      $one: true
	    };
	    return model_type.prototype.sync('cursor', query).toModels(callback);
	  };
	  model_type.findOrCreate = function(data, callback) {
	    var query;
	    if (!_.isObject(data) || Utils.isModel(data) || Utils.isCollection(data)) {
	      throw 'findOrCreate requires object data';
	    }
	    query = _.extend({
	      $one: true
	    }, data);
	    return model_type.prototype.sync('cursor', query).toModels(function(err, model) {
	      if (err) {
	        return callback(err);
	      }
	      if (model) {
	        return callback(null, model);
	      }
	      return (new model_type(data)).save(callback);
	    });
	  };
	  model_type.findOneNearestDate = function(date, options, query, callback) {
	    var functions, key, ref, ref1;
	    if (!(key = options.key)) {
	      throw new Error("Missing options key");
	    }
	    if (arguments.length === 2) {
	      ref = [{}, query], query = ref[0], callback = ref[1];
	    } else if (arguments.length === 3) {
	      ref1 = [new Date(), {}, query], options = ref1[0], query = ref1[1], callback = ref1[2];
	    } else {
	      query = _.clone(query);
	    }
	    query.$one = true;
	    functions = [
	      ((function(_this) {
	        return function(callback) {
	          query[key] = {
	            $lte: date
	          };
	          return model_type.cursor(query).sort("-" + key).toModels(callback);
	        };
	      })(this)), ((function(_this) {
	        return function(callback) {
	          query[key] = {
	            $gte: date
	          };
	          return model_type.cursor(query).sort(key).toModels(callback);
	        };
	      })(this))
	    ];
	    if (options.reverse) {
	      functions = [functions[1], functions[0]];
	    }
	    return functions[0](function(err, model) {
	      if (err) {
	        return callback(err);
	      }
	      if (model) {
	        return callback(null, model);
	      }
	      return functions[1](callback);
	    });
	  };
	  model_type.each = function(query, iterator, callback) {
	    var ref;
	    if (arguments.length === 2) {
	      ref = [{}, query, iterator], query = ref[0], iterator = ref[1], callback = ref[2];
	    }
	    return modelEach(model_type, query, iterator, callback);
	  };
	  model_type.eachC = function(query, callback, iterator) {
	    var ref;
	    if (arguments.length === 2) {
	      ref = [{}, query, callback], query = ref[0], callback = ref[1], iterator = ref[2];
	    }
	    return modelEach(model_type, query, iterator, callback);
	  };
	  model_type.stream = function(query) {
	    if (query == null) {
	      query = {};
	    }
	    if (!_.isFunction(ModelStream)) {
	      throw new Error('Stream is a large dependency so you need to manually include "stream.js" in the browser.');
	    }
	    return new ModelStream(model_type, query);
	  };
	  model_type.interval = function(query, iterator, callback) {
	    return modelInterval(model_type, query, iterator, callback);
	  };
	  model_type.intervalC = function(query, callback, iterator) {
	    return modelInterval(model_type, query, iterator, callback);
	  };
	  model_type.prototype.modelName = function() {
	    return model_type.model_name;
	  };
	  model_type.prototype.cache = function() {
	    return model_type.cache;
	  };
	  model_type.prototype.schema = model_type.schema = function() {
	    return model_type.prototype.sync('schema');
	  };
	  model_type.prototype.tableName = model_type.tableName = function() {
	    return model_type.prototype.sync('tableName');
	  };
	  model_type.prototype.relation = model_type.relation = function(key) {
	    var schema;
	    if (schema = model_type.prototype.sync('schema')) {
	      return schema.relation(key);
	    } else {
	      return void 0;
	    }
	  };
	  model_type.prototype.relationIsEmbedded = model_type.relationIsEmbedded = function(key) {
	    var relation;
	    if (relation = model_type.relation(key)) {
	      return !!relation.embed;
	    } else {
	      return false;
	    }
	  };
	  model_type.prototype.reverseRelation = model_type.reverseRelation = function(key) {
	    var schema;
	    if (schema = model_type.prototype.sync('schema')) {
	      return schema.reverseRelation(key);
	    } else {
	      return void 0;
	    }
	  };
	  model_type.prototype.isLoaded = function(key) {
	    if (arguments.length === 0) {
	      key = '__model__';
	    }
	    return !Utils.orSet(this, 'needs_load', {})[key];
	  };
	  model_type.prototype.setLoaded = function(key, is_loaded) {
	    var needs_load, ref;
	    if (arguments.length === 1) {
	      ref = ['__model__', key], key = ref[0], is_loaded = ref[1];
	    }
	    needs_load = Utils.orSet(this, 'needs_load', {});
	    if (is_loaded && Utils.get(this, 'is_initialized')) {
	      delete needs_load[key];
	      return;
	    }
	    return needs_load[key] = !is_loaded;
	  };
	  model_type.prototype.isLoadedExists = function(key) {
	    if (arguments.length === 0) {
	      key = '__model__';
	    }
	    return Utils.orSet(this, 'needs_load', {}).hasOwnProperty(key);
	  };
	  model_type.prototype.isPartial = function() {
	    return !!Utils.get(this, 'partial');
	  };
	  model_type.prototype.setPartial = function(is_partial) {
	    if (is_partial) {
	      return Utils.set(this, 'partial', true);
	    } else {
	      return Utils.unset(this, 'partial');
	    }
	  };
	  model_type.prototype.addUnset = function(key) {
	    var unsets;
	    unsets = Utils.orSet(this, 'unsets', []);
	    if (unsets.indexOf(key) < 0) {
	      return unsets.push(key);
	    }
	  };
	  model_type.prototype.removeUnset = function(key) {
	    var index, unsets;
	    if (!(unsets = Utils.get(this, 'unsets', null))) {
	      return;
	    }
	    if ((index = unsets.indexOf(key)) >= 0) {
	      return unsets.splice(index, 1);
	    }
	  };
	  model_type.prototype.fetchRelated = function(relations, callback) {
	    var queue, ref;
	    if (arguments.length === 1) {
	      ref = [null, relations], relations = ref[0], callback = ref[1];
	    }
	    queue = new Queue(1);
	    queue.defer((function(_this) {
	      return function(callback) {
	        if (_this.isLoaded()) {
	          return callback();
	        } else {
	          return _this.fetch(callback);
	        }
	      };
	    })(this));
	    queue.defer((function(_this) {
	      return function(callback) {
	        var keys;
	        keys = _.keys(Utils.orSet(_this, 'needs_load', {}));
	        if (relations && !_.isArray(relations)) {
	          relations = [relations];
	        }
	        if (_.isArray(relations)) {
	          keys = _.intersection(keys, relations);
	        }
	        return Utils.each(keys, (function(key, callback) {
	          return _this.get(key, callback);
	        }), callback);
	      };
	    })(this));
	    return queue.await(callback);
	  };
	  model_type.prototype.patchAdd = function(key, relateds, callback) {
	    var relation;
	    if (!(relation = this.relation(key))) {
	      return callback(new Error("patchAdd: relation '" + key + "' unrecognized"));
	    }
	    if (!relateds) {
	      return callback(new Error("patchAdd: missing relateds for '" + key + "'"));
	    }
	    return relation.patchAdd(this, relateds, callback);
	  };
	  model_type.prototype.patchRemove = function(key, relateds, callback) {
	    var fn1, queue, ref, relation, schema;
	    if (arguments.length === 1) {
	      callback = key;
	      schema = model_type.schema();
	      queue = new Queue(1);
	      ref = schema.relations;
	      fn1 = (function(_this) {
	        return function(relation) {
	          return queue.defer(function(callback) {
	            return relation.patchRemove(_this, callback);
	          });
	        };
	      })(this);
	      for (key in ref) {
	        relation = ref[key];
	        fn1(relation);
	      }
	      return queue.await(callback);
	    } else {
	      if (!(relation = this.relation(key))) {
	        return callback(new Error("patchRemove: relation '" + key + "' unrecognized"));
	      }
	      if (arguments.length === 2) {
	        callback = relateds;
	        return relation.patchRemove(this, callback);
	      } else {
	        if (!relateds) {
	          return callback(new Error("patchRemove: missing relateds for '" + key + "'"));
	        }
	        return relation.patchRemove(this, relateds, callback);
	      }
	    }
	  };
	  model_type.prototype.cursor = function(key, query) {
	    var relation, schema;
	    if (query == null) {
	      query = {};
	    }
	    if (model_type.schema) {
	      schema = model_type.schema();
	    }
	    if (schema && (relation = schema.relation(key))) {
	      return relation.cursor(this, key, query);
	    } else {
	      throw new Error(schema.model_name + "::cursor: Unexpected key: " + key + " is not a relation");
	    }
	  };
	  _findOrClone = function(model, options) {
	    var base, cache, clone, name;
	    if (model.isNew() || !model.modelName) {
	      return model.clone(options);
	    }
	    cache = (base = options._cache)[name = model.modelName()] || (base[name] = {});
	    if (!(clone = cache[model.id])) {
	      clone = model.clone(options);
	      if (model.isLoaded()) {
	        cache[model.id] = clone;
	      }
	    }
	    return clone;
	  };
	  overrides = {
	    initialize: function(attributes) {
	      var key, needs_load, ref, relation, schema, value;
	      if (model_type.schema && (schema = model_type.schema())) {
	        ref = schema.relations;
	        for (key in ref) {
	          relation = ref[key];
	          relation.initializeModel(this);
	        }
	        needs_load = Utils.orSet(this, 'needs_load', {});
	        for (key in needs_load) {
	          value = needs_load[key];
	          if (!value) {
	            delete needs_load[key];
	          }
	        }
	        Utils.set(this, 'is_initialized', true);
	      }
	      return model_type.prototype._orm_original_fns.initialize.apply(this, arguments);
	    },
	    fetch: function(options) {
	      var callback;
	      if (_.isFunction(callback = arguments[arguments.length - 1])) {
	        switch (arguments.length) {
	          case 1:
	            options = Utils.wrapOptions({}, callback);
	            break;
	          case 2:
	            options = Utils.wrapOptions(options, callback);
	        }
	      } else {
	        options || (options = {});
	      }
	      return model_type.prototype._orm_original_fns.fetch.call(this, Utils.wrapOptions(options, (function(_this) {
	        return function(err, model, resp, options) {
	          if (err) {
	            return typeof options.error === "function" ? options.error(_this, resp, options) : void 0;
	          }
	          _this.setLoaded(true);
	          return typeof options.success === "function" ? options.success(_this, resp, options) : void 0;
	        };
	      })(this)));
	    },
	    unset: function(key) {
	      var id;
	      this.addUnset(key);
	      id = this.id;
	      model_type.prototype._orm_original_fns.unset.apply(this, arguments);
	      if (key === 'id' && model_type.cache && id && (model_type.cache.get(id) === this)) {
	        return model_type.cache.destroy(id);
	      }
	    },
	    set: function(key, value, options) {
	      var attributes, relation, relational_attributes, schema, simple_attributes;
	      if (!(model_type.schema && (schema = model_type.schema()))) {
	        return model_type.prototype._orm_original_fns.set.apply(this, arguments);
	      }
	      if (_.isString(key)) {
	        (attributes = {})[key] = value;
	      } else {
	        attributes = key;
	        options = value;
	      }
	      simple_attributes = {};
	      relational_attributes = {};
	      for (key in attributes) {
	        value = attributes[key];
	        if (relation = schema.relation(key)) {
	          relational_attributes[key] = relation;
	        } else {
	          simple_attributes[key] = value;
	        }
	      }
	      if (!JSONUtils.isEmptyObject(simple_attributes)) {
	        model_type.prototype._orm_original_fns.set.call(this, simple_attributes, options);
	      }
	      for (key in relational_attributes) {
	        relation = relational_attributes[key];
	        relation.set(this, key, attributes[key], options);
	      }
	      return this;
	    },
	    get: function(key, callback) {
	      var relation, schema, value;
	      if (model_type.schema) {
	        schema = model_type.schema();
	      }
	      if (schema && (relation = schema.relation(key))) {
	        return relation.get(this, key, callback);
	      }
	      value = model_type.prototype._orm_original_fns.get.call(this, key);
	      if (callback) {
	        callback(null, value);
	      }
	      return value;
	    },
	    toJSON: function(options) {
	      var base, i, json, key, keys, len, relation, schema, value;
	      if (options == null) {
	        options = {};
	      }
	      if (model_type.schema) {
	        schema = model_type.schema();
	      }
	      this._orm || (this._orm = {});
	      if (this._orm.json > 0) {
	        return this.id;
	      }
	      (base = this._orm).json || (base.json = 0);
	      this._orm.json++;
	      json = {};
	      keys = options.keys || this.whitelist || _.keys(this.attributes);
	      for (i = 0, len = keys.length; i < len; i++) {
	        key = keys[i];
	        value = this.attributes[key];
	        if (schema && (relation = schema.relation(key))) {
	          relation.appendJSON(json, this);
	        } else if (Utils.isCollection(value)) {
	          json[key] = _.map(value.models, function(model) {
	            if (model) {
	              return model.toJSON(options);
	            } else {
	              return null;
	            }
	          });
	        } else if (Utils.isModel(value)) {
	          json[key] = value.toJSON(options);
	        } else {
	          json[key] = value;
	        }
	      }
	      --this._orm.json;
	      return json;
	    },
	    save: function(key, value, options) {
	      var attributes, base, callback;
	      if (_.isFunction(callback = arguments[arguments.length - 1])) {
	        switch (arguments.length) {
	          case 1:
	            attributes = {};
	            options = Utils.wrapOptions({}, callback);
	            break;
	          case 2:
	            attributes = key;
	            options = Utils.wrapOptions({}, callback);
	            break;
	          case 3:
	            attributes = key;
	            options = Utils.wrapOptions(value, callback);
	            break;
	          case 4:
	            (attributes = {})[key] = value;
	            options = Utils.wrapOptions(options, callback);
	        }
	      } else {
	        if (arguments.length === 0) {
	          attributes = {};
	          options = {};
	        } else if (key === null || _.isObject(key)) {
	          attributes = key;
	          options = value;
	        } else {
	          (attributes = {})[key] = value;
	        }
	      }
	      if (!this.isLoaded()) {
	        return typeof options.error === "function" ? options.error(this, new Error("An unloaded model is trying to be saved: " + model_type.model_name)) : void 0;
	      }
	      this._orm || (this._orm = {});
	      if (this._orm.save > 0) {
	        if (this.id) {
	          return typeof options.success === "function" ? options.success(this, {}, options) : void 0;
	        }
	        return typeof options.error === "function" ? options.error(this, new Error("Model is in a save loop: " + model_type.model_name)) : void 0;
	      }
	      (base = this._orm).save || (base.save = 0);
	      this._orm.save++;
	      this.set(attributes, options);
	      attributes = {};
	      return Utils.presaveBelongsToRelationships(this, (function(_this) {
	        return function(err) {
	          if (err) {
	            return typeof options.error === "function" ? options.error(_this, err) : void 0;
	          }
	          return model_type.prototype._orm_original_fns.save.call(_this, attributes, Utils.wrapOptions(options, function(err, model, resp, options) {
	            var fn1, queue, ref, relation, schema;
	            Utils.unset(_this, 'unsets');
	            --_this._orm.save;
	            if (err) {
	              return typeof options.error === "function" ? options.error(_this, resp, options) : void 0;
	            }
	            queue = new Queue(1);
	            if (model_type.schema) {
	              schema = model_type.schema();
	              ref = schema.relations;
	              fn1 = function(relation) {
	                return queue.defer(function(callback) {
	                  return relation.save(_this, callback);
	                });
	              };
	              for (key in ref) {
	                relation = ref[key];
	                fn1(relation);
	              }
	            }
	            return queue.await(function(err) {
	              var cache;
	              if (err) {
	                return typeof options.error === "function" ? options.error(_this, Error("Failed to save relations. " + err, options)) : void 0;
	              }
	              if (cache = model_type.cache) {
	                cache.set(_this.id, _this);
	              }
	              return typeof options.success === "function" ? options.success(_this, resp, options) : void 0;
	            });
	          }));
	        };
	      })(this));
	    },
	    destroy: function(options) {
	      var base, cache, callback, schema;
	      if (_.isFunction(callback = arguments[arguments.length - 1])) {
	        switch (arguments.length) {
	          case 1:
	            options = Utils.wrapOptions({}, callback);
	            break;
	          case 2:
	            options = Utils.wrapOptions(options, callback);
	        }
	      }
	      if (cache = this.cache()) {
	        cache.destroy(this.id);
	      }
	      if (!(model_type.schema && (schema = model_type.schema()))) {
	        return model_type.prototype._orm_original_fns.destroy.call(this, options);
	      }
	      this._orm || (this._orm = {});
	      if (this._orm.destroy > 0) {
	        throw new Error("Model is in a destroy loop: " + model_type.model_name);
	      }
	      (base = this._orm).destroy || (base.destroy = 0);
	      this._orm.destroy++;
	      return model_type.prototype._orm_original_fns.destroy.call(this, Utils.wrapOptions(options, (function(_this) {
	        return function(err, model, resp, options) {
	          --_this._orm.destroy;
	          if (err) {
	            return typeof options.error === "function" ? options.error(_this, resp, options) : void 0;
	          }
	          return _this.patchRemove(function(err) {
	            if (err) {
	              return typeof options.error === "function" ? options.error(_this, new Error("Failed to destroy relations. " + err, options)) : void 0;
	            }
	            return typeof options.success === "function" ? options.success(_this, resp, options) : void 0;
	          });
	        };
	      })(this)));
	    },
	    clone: function(options) {
	      var base, base1, cache, clone, i, key, keys, len, model, name, ref, value;
	      if (!model_type.schema) {
	        return model_type.prototype._orm_original_fns.clone.apply(this, arguments);
	      }
	      options || (options = {});
	      options._cache || (options._cache = {});
	      cache = (base = options._cache)[name = this.modelName()] || (base[name] = {});
	      this._orm || (this._orm = {});
	      if (this._orm.clone > 0) {
	        if (this.id) {
	          return cache[this.id];
	        } else {
	          return model_type.prototype._orm_original_fns.clone.apply(this, arguments);
	        }
	      }
	      (base1 = this._orm).clone || (base1.clone = 0);
	      this._orm.clone++;
	      if (this.id) {
	        if (!(clone = cache[this.id])) {
	          clone = new this.constructor();
	          if (this.isLoaded()) {
	            cache[this.id] = clone;
	          }
	        }
	      } else {
	        clone = new this.constructor();
	      }
	      if (this.attributes.id) {
	        clone.id = this.attributes.id;
	      }
	      keys = options.keys || _.keys(this.attributes);
	      for (i = 0, len = keys.length; i < len; i++) {
	        key = keys[i];
	        value = this.attributes[key];
	        if (Utils.isCollection(value)) {
	          if (!((ref = clone.attributes[key]) != null ? ref.values : void 0)) {
	            clone.attributes[key] = new value.constructor();
	          }
	          clone.attributes[key].reset((function() {
	            var j, len1, ref1, results;
	            ref1 = value.models;
	            results = [];
	            for (j = 0, len1 = ref1.length; j < len1; j++) {
	              model = ref1[j];
	              results.push(_findOrClone(model, options));
	            }
	            return results;
	          })());
	        } else if (Utils.isModel(value)) {
	          clone.attributes[key] = _findOrClone(value, options);
	        } else {
	          clone.attributes[key] = value;
	        }
	      }
	      --this._orm.clone;
	      return clone;
	    }
	  };
	  if (!model_type.prototype._orm_original_fns) {
	    model_type.prototype._orm_original_fns = {};
	    results = [];
	    for (key in overrides) {
	      fn = overrides[key];
	      model_type.prototype._orm_original_fns[key] = model_type.prototype[key];
	      results.push(model_type.prototype[key] = fn);
	    }
	    return results;
	  }
	};


/***/ },
/* 36 */
/***/ function(module, exports, __webpack_require__) {

	
	/*
	  backbone-orm.js 0.7.14
	  Copyright (c) 2013-2016 Vidigami
	  License: MIT (http://www.opensource.org/licenses/mit-license.php)
	  Source: https://github.com/vidigami/backbone-orm
	  Dependencies: Backbone.js and Underscore.js.
	 */
	var ModelStream, stream,
	  extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
	  hasProp = {}.hasOwnProperty;

	try {
	  stream = __webpack_require__(37);
	} catch (undefined) {}

	if (stream != null ? stream.Readable : void 0) {
	  module.exports = ModelStream = (function(superClass) {
	    extend(ModelStream, superClass);

	    function ModelStream(model_type, query) {
	      this.model_type = model_type;
	      this.query = query != null ? query : {};
	      ModelStream.__super__.constructor.call(this, {
	        objectMode: true
	      });
	    }

	    ModelStream.prototype._read = function() {
	      var done;
	      if (this.ended || this.started) {
	        return;
	      }
	      this.started = true;
	      done = (function(_this) {
	        return function(err) {
	          _this.ended = true;
	          if (err) {
	            _this.emit('error', err);
	          }
	          return _this.push(null);
	        };
	      })(this);
	      return this.model_type.each(this.query, ((function(_this) {
	        return function(model, callback) {
	          _this.push(model);
	          return callback();
	        };
	      })(this)), done);
	    };

	    return ModelStream;

	  })(stream.Readable);
	}


/***/ },
/* 37 */
/***/ function(module, exports) {

	if(typeof __WEBPACK_EXTERNAL_MODULE_37__ === 'undefined') {var e = new Error("Cannot find module \"stream\""); e.code = 'MODULE_NOT_FOUND'; throw e;}
	module.exports = __WEBPACK_EXTERNAL_MODULE_37__;

/***/ },
/* 38 */
/***/ function(module, exports, __webpack_require__) {

	
	/*
	  backbone-orm.js 0.7.14
	  Copyright (c) 2013-2016 Vidigami
	  License: MIT (http://www.opensource.org/licenses/mit-license.php)
	  Source: https://github.com/vidigami/backbone-orm
	  Dependencies: Backbone.js and Underscore.js.
	 */
	var Cursor, Queue, _;

	_ = __webpack_require__(1);

	Queue = __webpack_require__(11);

	Cursor = null;

	module.exports = function(model_type, query, iterator, callback) {
	  var method, model_limit, options, parsed_query, processed_count, runBatch;
	  if (!Cursor) {
	    Cursor = __webpack_require__(23);
	  }
	  options = query.$each || {};
	  method = options.json ? 'toJSON' : 'toModels';
	  processed_count = 0;
	  parsed_query = Cursor.parseQuery(_.omit(query, '$each'));
	  _.defaults(parsed_query.cursor, {
	    $offset: 0,
	    $sort: 'id'
	  });
	  model_limit = parsed_query.cursor.$limit || Infinity;
	  if (options.fetch) {
	    parsed_query.cursor.$limit = options.fetch;
	  }
	  runBatch = function() {
	    var cursor;
	    cursor = model_type.cursor(parsed_query);
	    return cursor[method].call(cursor, function(err, models) {
	      var fn, i, len, model, queue;
	      if (err || !models) {
	        return callback(new Error("Failed to get models. Error: " + err));
	      }
	      if (!models.length) {
	        return callback(null, processed_count);
	      }
	      queue = new Queue(options.threads);
	      fn = function(model) {
	        return queue.defer(function(callback) {
	          return iterator(model, callback);
	        });
	      };
	      for (i = 0, len = models.length; i < len; i++) {
	        model = models[i];
	        if (processed_count++ >= model_limit) {
	          break;
	        }
	        fn(model);
	      }
	      return queue.await(function(err) {
	        if (err) {
	          return callback(err);
	        }
	        if ((processed_count >= model_limit) || (models.length < parsed_query.cursor.$limit) || !parsed_query.cursor.$limit) {
	          return callback(null, processed_count);
	        }
	        parsed_query.cursor.$offset += parsed_query.cursor.$limit;
	        return runBatch();
	      });
	    });
	  };
	  return runBatch();
	};


/***/ },
/* 39 */
/***/ function(module, exports, __webpack_require__) {

	
	/*
	  backbone-orm.js 0.7.14
	  Copyright (c) 2013-2016 Vidigami
	  License: MIT (http://www.opensource.org/licenses/mit-license.php)
	  Source: https://github.com/vidigami/backbone-orm
	  Dependencies: Backbone.js and Underscore.js.
	 */
	var DateUtils, INTERVAL_TYPES, JSONUtils, Queue, Utils, _;

	_ = __webpack_require__(1);

	Queue = __webpack_require__(11);

	Utils = __webpack_require__(24);

	JSONUtils = __webpack_require__(33);

	DateUtils = __webpack_require__(40);

	INTERVAL_TYPES = ['milliseconds', 'seconds', 'minutes', 'hours', 'days', 'weeks', 'months', 'years'];

	module.exports = function(model_type, query, iterator, callback) {
	  var iteration_info, key, no_models, options, queue, range;
	  options = query.$interval || {};
	  if (!(key = options.key)) {
	    throw new Error('missing option: key');
	  }
	  if (!options.type) {
	    throw new Error('missing option: type');
	  }
	  if (!_.contains(INTERVAL_TYPES, options.type)) {
	    throw new Error("type is not recognized: " + options.type + ", " + (_.contains(INTERVAL_TYPES, options.type)));
	  }
	  iteration_info = _.clone(options);
	  if (!iteration_info.range) {
	    iteration_info.range = {};
	  }
	  range = iteration_info.range;
	  no_models = false;
	  queue = new Queue(1);
	  queue.defer(function(callback) {
	    var start;
	    if (!(start = range.$gte || range.$gt)) {
	      return model_type.cursor(query).limit(1).sort(key).toModels(function(err, models) {
	        if (err) {
	          return callback(err);
	        }
	        if (!models.length) {
	          no_models = true;
	          return callback();
	        }
	        range.start = iteration_info.first = models[0].get(key);
	        return callback();
	      });
	    } else {
	      range.start = start;
	      return model_type.findOneNearestDate(start, {
	        key: key,
	        reverse: true
	      }, query, function(err, model) {
	        if (err) {
	          return callback(err);
	        }
	        if (!model) {
	          no_models = true;
	          return callback();
	        }
	        iteration_info.first = model.get(key);
	        return callback();
	      });
	    }
	  });
	  queue.defer(function(callback) {
	    var end;
	    if (no_models) {
	      return callback();
	    }
	    if (!(end = range.$lte || range.$lt)) {
	      return model_type.cursor(query).limit(1).sort("-" + key).toModels(function(err, models) {
	        if (err) {
	          return callback(err);
	        }
	        if (!models.length) {
	          no_models = true;
	          return callback();
	        }
	        range.end = iteration_info.last = models[0].get(key);
	        return callback();
	      });
	    } else {
	      range.end = end;
	      return model_type.findOneNearestDate(end, {
	        key: key
	      }, query, function(err, model) {
	        if (err) {
	          return callback(err);
	        }
	        if (!model) {
	          no_models = true;
	          return callback();
	        }
	        iteration_info.last = model.get(key);
	        return callback();
	      });
	    }
	  });
	  return queue.await(function(err) {
	    var length_ms, processed_count, runInterval, start_ms;
	    if (err) {
	      return callback(err);
	    }
	    if (no_models) {
	      return callback();
	    }
	    start_ms = range.start.getTime();
	    length_ms = DateUtils.durationAsMilliseconds((_.isUndefined(options.length) ? 1 : options.length), options.type);
	    if (!length_ms) {
	      throw Error("length_ms is invalid: " + length_ms + " for range: " + (JSONUtils.stringify(range)));
	    }
	    query = _.omit(query, '$interval');
	    query.$sort = [key];
	    processed_count = 0;
	    iteration_info.index = 0;
	    runInterval = function(current) {
	      if (DateUtils.isAfter(current, range.end)) {
	        return callback();
	      }
	      query[key] = {
	        $gte: current,
	        $lte: iteration_info.last
	      };
	      return model_type.findOne(query, function(err, model) {
	        var next;
	        if (err) {
	          return callback(err);
	        }
	        if (!model) {
	          return callback();
	        }
	        next = model.get(key);
	        iteration_info.index = Math.floor((next.getTime() - start_ms) / length_ms);
	        current = new Date(range.start.getTime() + iteration_info.index * length_ms);
	        iteration_info.start = current;
	        next = new Date(current.getTime() + length_ms);
	        iteration_info.end = next;
	        query[key] = {
	          $gte: current,
	          $lt: next
	        };
	        return iterator(query, iteration_info, function(err) {
	          if (err) {
	            return callback(err);
	          }
	          return runInterval(next);
	        });
	      });
	    };
	    return runInterval(range.start);
	  });
	};


/***/ },
/* 40 */
/***/ function(module, exports, __webpack_require__) {

	
	/*
	  backbone-orm.js 0.7.14
	  Copyright (c) 2013-2016 Vidigami
	  License: MIT (http://www.opensource.org/licenses/mit-license.php)
	  Source: https://github.com/vidigami/backbone-orm
	  Dependencies: Backbone.js and Underscore.js.
	 */
	var DateUtils, UNITS_TO_MS, _;

	_ = __webpack_require__(1);

	UNITS_TO_MS = {
	  milliseconds: {
	    milliseconds: 1
	  },
	  seconds: {
	    milliseconds: 1000
	  },
	  minutes: {
	    milliseconds: 60 * 1000
	  },
	  hours: {
	    milliseconds: 24 * 60 * 1000
	  },
	  days: {
	    days: 1
	  },
	  weeks: {
	    days: 7
	  },
	  months: {
	    months: 1
	  },
	  years: {
	    years: 1
	  }
	};

	module.exports = DateUtils = (function() {
	  function DateUtils() {}

	  DateUtils.durationAsMilliseconds = function(count, units) {
	    var lookup;
	    if (!(lookup = UNITS_TO_MS[units])) {
	      throw new Error("DateUtils.durationAsMilliseconds :Unrecognized units: " + units);
	    }
	    if (lookup.milliseconds) {
	      return count * lookup.milliseconds;
	    }
	    if (lookup.days) {
	      return count * 864e5 * lookup.days;
	    }
	    if (lookup.months) {
	      return count * lookup.months * 2592e6;
	    }
	    if (lookup.years) {
	      return count * lookup.years * 31536e6;
	    }
	  };

	  DateUtils.isBefore = function(mv, tv) {
	    return mv.valueOf() < tv.valueOf();
	  };

	  DateUtils.isAfter = function(mv, tv) {
	    return mv.valueOf() > tv.valueOf();
	  };

	  DateUtils.isEqual = function(mv, tv) {
	    return +mv === +tv;
	  };

	  return DateUtils;

	})();


/***/ },
/* 41 */
/***/ function(module, exports, __webpack_require__) {

	
	/*
	  backbone-orm.js 0.7.14
	  Copyright (c) 2013-2016 Vidigami
	  License: MIT (http://www.opensource.org/licenses/mit-license.php)
	  Source: https://github.com/vidigami/backbone-orm
	  Dependencies: Backbone.js and Underscore.js.
	 */
	var Backbone, Utils, _, collection_type, fn, key, overrides;

	_ = __webpack_require__(1);

	Backbone = __webpack_require__(2);

	Utils = __webpack_require__(24);

	collection_type = Backbone.Collection;

	overrides = {
	  fetch: function(options) {
	    var callback;
	    if (_.isFunction(callback = arguments[arguments.length - 1])) {
	      switch (arguments.length) {
	        case 1:
	          options = Utils.wrapOptions({}, callback);
	          break;
	        case 2:
	          options = Utils.wrapOptions(options, callback);
	      }
	    }
	    return collection_type.prototype._orm_original_fns.fetch.call(this, Utils.wrapOptions(options, (function(_this) {
	      return function(err, model, resp, options) {
	        if (err) {
	          return typeof options.error === "function" ? options.error(_this, resp, options) : void 0;
	        }
	        return typeof options.success === "function" ? options.success(model, resp, options) : void 0;
	      };
	    })(this)));
	  },
	  _prepareModel: function(attrs, options) {
	    var id, is_new, model;
	    if (!Utils.isModel(attrs) && (id = Utils.dataId(attrs))) {
	      if (this.model.cache) {
	        is_new = !!this.model.cache.get(id);
	      }
	      model = Utils.updateOrNew(attrs, this.model);
	      if (is_new && !model._validate(attrs, options)) {
	        this.trigger('invalid', this, attrs, options);
	        return false;
	      }
	      return model;
	    }
	    return collection_type.prototype._orm_original_fns._prepareModel.call(this, attrs, options);
	  }
	};

	if (!collection_type.prototype._orm_original_fns) {
	  collection_type.prototype._orm_original_fns = {};
	  for (key in overrides) {
	    fn = overrides[key];
	    collection_type.prototype._orm_original_fns[key] = collection_type.prototype[key];
	    collection_type.prototype[key] = fn;
	  }
	}


/***/ },
/* 42 */
/***/ function(module, exports, __webpack_require__) {

	
	/*
	  backbone-orm.js 0.7.14
	  Copyright (c) 2013-2016 Vidigami
	  License: MIT (http://www.opensource.org/licenses/mit-license.php)
	  Source: https://github.com/vidigami/backbone-orm
	  Dependencies: Backbone.js and Underscore.js.
	 */
	var CURSOR_KEYS, Cursor, JSONUtils, Utils, _,
	  bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

	_ = __webpack_require__(1);

	Utils = __webpack_require__(24);

	JSONUtils = __webpack_require__(33);

	CURSOR_KEYS = ['$count', '$exists', '$zero', '$one', '$offset', '$limit', '$page', '$sort', '$unique', '$whitelist', '$select', '$include', '$values', '$ids', '$or'];

	module.exports = Cursor = (function() {
	  function Cursor(query, options) {
	    this.relatedModelTypesInQuery = bind(this.relatedModelTypesInQuery, this);
	    var i, key, len, parsed_query, ref, value;
	    for (key in options) {
	      value = options[key];
	      this[key] = value;
	    }
	    parsed_query = Cursor.parseQuery(query, this.model_type);
	    this._find = parsed_query.find;
	    this._cursor = parsed_query.cursor;
	    ref = ['$whitelist', '$select', '$values', '$unique'];
	    for (i = 0, len = ref.length; i < len; i++) {
	      key = ref[i];
	      if (this._cursor[key] && !_.isArray(this._cursor[key])) {
	        this._cursor[key] = [this._cursor[key]];
	      }
	    }
	  }

	  Cursor.validateQuery = function(query, memo, model_type) {
	    var full_key, key, results, value;
	    results = [];
	    for (key in query) {
	      value = query[key];
	      if (!(_.isUndefined(value) || _.isObject(value))) {
	        continue;
	      }
	      full_key = memo ? memo + "." + key : key;
	      if (_.isUndefined(value)) {
	        throw new Error("Unexpected undefined for query key '" + full_key + "' on " + (model_type != null ? model_type.model_name : void 0));
	      }
	      if (_.isObject(value)) {
	        results.push(Cursor.validateQuery(value, full_key, model_type));
	      } else {
	        results.push(void 0);
	      }
	    }
	    return results;
	  };

	  Cursor.parseQuery = function(query, model_type) {
	    var e, error, key, parsed_query, value;
	    if (!query) {
	      return {
	        find: {},
	        cursor: {}
	      };
	    } else if (!_.isObject(query)) {
	      return {
	        find: {
	          id: query
	        },
	        cursor: {
	          $one: true
	        }
	      };
	    } else if (query.find || query.cursor) {
	      return {
	        find: query.find || {},
	        cursor: query.cursor || {}
	      };
	    } else {
	      try {
	        Cursor.validateQuery(query, null, model_type);
	      } catch (error) {
	        e = error;
	        throw new Error("Error: " + e + ". Query: ", query);
	      }
	      parsed_query = {
	        find: {},
	        cursor: {}
	      };
	      for (key in query) {
	        value = query[key];
	        if (key[0] !== '$') {
	          parsed_query.find[key] = value;
	        } else {
	          parsed_query.cursor[key] = value;
	        }
	      }
	      return parsed_query;
	    }
	  };

	  Cursor.prototype.offset = function(offset) {
	    this._cursor.$offset = offset;
	    return this;
	  };

	  Cursor.prototype.limit = function(limit) {
	    this._cursor.$limit = limit;
	    return this;
	  };

	  Cursor.prototype.sort = function(sort) {
	    this._cursor.$sort = sort;
	    return this;
	  };

	  Cursor.prototype.whiteList = function(args) {
	    var keys;
	    keys = _.flatten(arguments);
	    this._cursor.$whitelist = this._cursor.$whitelist ? _.intersection(this._cursor.$whitelist, keys) : keys;
	    return this;
	  };

	  Cursor.prototype.select = function(args) {
	    var keys;
	    keys = _.flatten(arguments);
	    this._cursor.$select = this._cursor.$select ? _.intersection(this._cursor.$select, keys) : keys;
	    return this;
	  };

	  Cursor.prototype.include = function(args) {
	    var keys;
	    keys = _.flatten(arguments);
	    this._cursor.$include = this._cursor.$include ? _.intersection(this._cursor.$include, keys) : keys;
	    return this;
	  };

	  Cursor.prototype.values = function(args) {
	    var keys;
	    keys = _.flatten(arguments);
	    this._cursor.$values = this._cursor.$values ? _.intersection(this._cursor.$values, keys) : keys;
	    return this;
	  };

	  Cursor.prototype.unique = function(args) {
	    var keys;
	    keys = _.flatten(arguments);
	    this._cursor.$unique = this._cursor.$unique ? _.intersection(this._cursor.$unique, keys) : keys;
	    return this;
	  };

	  Cursor.prototype.ids = function() {
	    this._cursor.$values = ['id'];
	    return this;
	  };

	  Cursor.prototype.count = function(callback) {
	    return this.execWithCursorQuery('$count', 'toJSON', callback);
	  };

	  Cursor.prototype.exists = function(callback) {
	    return this.execWithCursorQuery('$exists', 'toJSON', callback);
	  };

	  Cursor.prototype.toModel = function(callback) {
	    return this.execWithCursorQuery('$one', 'toModels', callback);
	  };

	  Cursor.prototype.toModels = function(callback) {
	    if (this._cursor.$values) {
	      return callback(new Error("Cannot call toModels on cursor with values for model " + this.model_type.model_name + ". Values: " + (JSONUtils.stringify(this._cursor.$values))));
	    }
	    return this.toJSON((function(_this) {
	      return function(err, json) {
	        if (err) {
	          return callback(err);
	        }
	        if (_this._cursor.$one && !json) {
	          return callback(null, null);
	        }
	        if (!_.isArray(json)) {
	          json = [json];
	        }
	        return _this.prepareIncludes(json, function(err, json) {
	          var can_cache, item, model, models;
	          if (can_cache = !(_this._cursor.$select || _this._cursor.$whitelist)) {
	            models = (function() {
	              var i, len, results;
	              results = [];
	              for (i = 0, len = json.length; i < len; i++) {
	                item = json[i];
	                results.push(Utils.updateOrNew(item, this.model_type));
	              }
	              return results;
	            }).call(_this);
	          } else {
	            models = (function() {
	              var i, len, results;
	              results = [];
	              for (i = 0, len = json.length; i < len; i++) {
	                item = json[i];
	                results.push((model = new this.model_type(this.model_type.prototype.parse(item)), model.setPartial(true), model));
	              }
	              return results;
	            }).call(_this);
	          }
	          return callback(null, _this._cursor.$one ? models[0] : models);
	        });
	      };
	    })(this));
	  };

	  Cursor.prototype.toJSON = function(callback) {
	    return this.queryToJSON(callback);
	  };

	  Cursor.prototype.queryToJSON = function(callback) {
	    throw new Error('queryToJSON must be implemented by a concrete cursor for a Backbone Sync type');
	  };

	  Cursor.prototype.hasCursorQuery = function(key) {
	    return this._cursor[key] || (this._cursor[key] === '');
	  };

	  Cursor.prototype.execWithCursorQuery = function(key, method, callback) {
	    var value;
	    value = this._cursor[key];
	    this._cursor[key] = true;
	    return this[method]((function(_this) {
	      return function(err, json) {
	        if (_.isUndefined(value)) {
	          delete _this._cursor[key];
	        } else {
	          _this._cursor[key] = value;
	        }
	        return callback(err, json);
	      };
	    })(this));
	  };

	  Cursor.prototype.relatedModelTypesInQuery = function() {
	    var i, key, len, ref, ref1, ref2, related_fields, related_model_types, relation, relation_key, reverse_relation, value;
	    related_fields = [];
	    related_model_types = [];
	    ref = this._find;
	    for (key in ref) {
	      value = ref[key];
	      if (key.indexOf('.') > 0) {
	        ref1 = key.split('.'), relation_key = ref1[0], key = ref1[1];
	        related_fields.push(relation_key);
	      } else if ((reverse_relation = this.model_type.reverseRelation(key)) && reverse_relation.join_table) {
	        related_model_types.push(reverse_relation.model_type);
	        related_model_types.push(reverse_relation.join_table);
	      }
	    }
	    if ((ref2 = this._cursor) != null ? ref2.$include : void 0) {
	      related_fields = related_fields.concat(this._cursor.$include);
	    }
	    for (i = 0, len = related_fields.length; i < len; i++) {
	      relation_key = related_fields[i];
	      if (relation = this.model_type.relation(relation_key)) {
	        related_model_types.push(relation.reverse_model_type);
	        if (relation.join_table) {
	          related_model_types.push(relation.join_table);
	        }
	      }
	    }
	    return related_model_types;
	  };

	  Cursor.prototype.selectResults = function(json) {
	    var $select, $values, item, key;
	    if (this._cursor.$one) {
	      json = json.slice(0, 1);
	    }
	    if (this._cursor.$values) {
	      $values = this._cursor.$whitelist ? _.intersection(this._cursor.$values, this._cursor.$whitelist) : this._cursor.$values;
	      if (this._cursor.$values.length === 1) {
	        key = this._cursor.$values[0];
	        json = $values.length ? (function() {
	          var i, len, results;
	          results = [];
	          for (i = 0, len = json.length; i < len; i++) {
	            item = json[i];
	            results.push(item.hasOwnProperty(key) ? item[key] : null);
	          }
	          return results;
	        })() : _.map(json, function() {
	          return null;
	        });
	      } else {
	        json = (function() {
	          var i, len, results;
	          results = [];
	          for (i = 0, len = json.length; i < len; i++) {
	            item = json[i];
	            results.push((function() {
	              var j, len1, results1;
	              results1 = [];
	              for (j = 0, len1 = $values.length; j < len1; j++) {
	                key = $values[j];
	                if (item.hasOwnProperty(key)) {
	                  results1.push(item[key]);
	                }
	              }
	              return results1;
	            })());
	          }
	          return results;
	        })();
	      }
	    } else if (this._cursor.$select) {
	      $select = this._cursor.$whitelist ? _.intersection(this._cursor.$select, this._cursor.$whitelist) : this._cursor.$select;
	      json = (function() {
	        var i, len, results;
	        results = [];
	        for (i = 0, len = json.length; i < len; i++) {
	          item = json[i];
	          results.push(_.pick(item, $select));
	        }
	        return results;
	      })();
	    } else if (this._cursor.$whitelist) {
	      json = (function() {
	        var i, len, results;
	        results = [];
	        for (i = 0, len = json.length; i < len; i++) {
	          item = json[i];
	          results.push(_.pick(item, this._cursor.$whitelist));
	        }
	        return results;
	      }).call(this);
	    }
	    if (this.hasCursorQuery('$page')) {
	      return json;
	    }
	    if (this._cursor.$one) {
	      return json[0] || null;
	    } else {
	      return json;
	    }
	  };

	  Cursor.prototype.selectFromModels = function(models, callback) {
	    var $select, item, model;
	    if (this._cursor.$select) {
	      $select = this._cursor.$whitelist ? _.intersection(this._cursor.$select, this._cursor.$whitelist) : this._cursor.$select;
	      models = ((function() {
	        var i, len, results;
	        model = new this.model_type(_.pick(model.attributes, $select));
	        model.setPartial(true);
	        results = [];
	        for (i = 0, len = models.length; i < len; i++) {
	          item = models[i];
	          results.push(model);
	        }
	        return results;
	      }).call(this));
	    } else if (this._cursor.$whitelist) {
	      models = ((function() {
	        var i, len, results;
	        model = new this.model_type(_.pick(model.attributes, this._cursor.$whitelist));
	        model.setPartial(true);
	        results = [];
	        for (i = 0, len = models.length; i < len; i++) {
	          item = models[i];
	          results.push(model);
	        }
	        return results;
	      }).call(this));
	    }
	    return models;
	  };

	  Cursor.prototype.prepareIncludes = function(json, callback) {
	    var findOrNew, i, include, item, j, len, len1, model_json, ref, related_json, relation, schema, shared_related_models;
	    if (!_.isArray(this._cursor.$include) || _.isEmpty(this._cursor.$include)) {
	      return callback(null, json);
	    }
	    schema = this.model_type.schema();
	    shared_related_models = {};
	    findOrNew = (function(_this) {
	      return function(related_json, reverse_model_type) {
	        var related_id;
	        related_id = related_json[reverse_model_type.prototype.idAttribute];
	        if (!shared_related_models[related_id]) {
	          if (reverse_model_type.cache) {
	            if (!(shared_related_models[related_id] = reverse_model_type.cache.get(related_id))) {
	              reverse_model_type.cache.set(related_id, shared_related_models[related_id] = new reverse_model_type(related_json));
	            }
	          } else {
	            shared_related_models[related_id] = new reverse_model_type(related_json);
	          }
	        }
	        return shared_related_models[related_id];
	      };
	    })(this);
	    ref = this._cursor.$include;
	    for (i = 0, len = ref.length; i < len; i++) {
	      include = ref[i];
	      relation = schema.relation(include);
	      shared_related_models = {};
	      for (j = 0, len1 = json.length; j < len1; j++) {
	        model_json = json[j];
	        if (_.isArray(related_json = model_json[include])) {
	          model_json[include] = (function() {
	            var k, len2, results;
	            results = [];
	            for (k = 0, len2 = related_json.length; k < len2; k++) {
	              item = related_json[k];
	              results.push(findOrNew(item, relation.reverse_model_type));
	            }
	            return results;
	          })();
	        } else if (related_json) {
	          model_json[include] = findOrNew(related_json, relation.reverse_model_type);
	        }
	      }
	    }
	    return callback(null, json);
	  };

	  return Cursor;

	})();


/***/ },
/* 43 */
/***/ function(module, exports, __webpack_require__) {

	
	/*
	  backbone-orm.js 0.7.14
	  Copyright (c) 2013-2016 Vidigami
	  License: MIT (http://www.opensource.org/licenses/mit-license.php)
	  Source: https://github.com/vidigami/backbone-orm
	  Dependencies: Backbone.js and Underscore.js.
	 */
	var Backbone, BackboneORM, DatabaseURL, JSONUtils, Many, One, RELATION_VARIANTS, Schema, Utils, _,
	  extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
	  hasProp = {}.hasOwnProperty;

	_ = __webpack_require__(1);

	Backbone = __webpack_require__(2);

	BackboneORM = __webpack_require__(3);

	One = __webpack_require__(44);

	Many = __webpack_require__(46);

	DatabaseURL = __webpack_require__(32);

	Utils = __webpack_require__(24);

	JSONUtils = __webpack_require__(33);

	RELATION_VARIANTS = {
	  'hasOne': 'hasOne',
	  'has_one': 'hasOne',
	  'HasOne': 'hasOne',
	  'belongsTo': 'belongsTo',
	  'belongs_to': 'belongsTo',
	  'BelongsTo': 'belongsTo',
	  'hasMany': 'hasMany',
	  'has_many': 'hasMany',
	  'HasMany': 'hasMany'
	};

	module.exports = Schema = (function() {
	  function Schema(model_type, type_overrides) {
	    this.model_type = model_type;
	    this.type_overrides = type_overrides != null ? type_overrides : {};
	    this.raw = _.clone(_.result(new this.model_type(), 'schema') || {});
	    this.fields = {};
	    this.relations = {};
	    this.virtual_accessors = {};
	    if (this.raw.id) {
	      this._parseField('id', this.raw.id);
	    }
	  }

	  Schema.prototype.initialize = function() {
	    var info, key, ref, ref1, relation;
	    if (this.is_initialized) {
	      return;
	    }
	    this.is_initialized = true;
	    ref = this.raw;
	    for (key in ref) {
	      info = ref[key];
	      this._parseField(key, info);
	    }
	    ref1 = this.relations;
	    for (key in ref1) {
	      relation = ref1[key];
	      relation.initialize();
	    }
	  };

	  Schema.prototype.type = function(key, type) {
	    var base, index, other, ref, ref1, ref2, ref3;
	    if (arguments.length === 2) {
	      ((base = this.type_overrides)[key] || (base[key] = {}))['type'] = type;
	      return this;
	    }
	    if ((index = key.indexOf('.')) >= 0) {
	      other = key.substr(index + 1);
	      key = key.substr(0, index);
	    }
	    if (!(type = ((ref = this.type_overrides[key]) != null ? ref.type : void 0) || ((ref1 = this.fields[key]) != null ? ref1.type : void 0) || ((ref2 = this.relation(key)) != null ? ref2.reverse_model_type : void 0) || ((ref3 = this.reverseRelation(key)) != null ? ref3.model_type : void 0))) {
	      return;
	    }
	    if (this.virtual_accessors[key]) {
	      if (other) {
	        console.log("Unexpected other for virtual id key: " + key + "." + other);
	        return;
	      }
	      return (typeof type.schema === "function" ? type.schema().type('id') : void 0) || type;
	    }
	    if (other) {
	      return typeof type.schema === "function" ? type.schema().type(other) : void 0;
	    } else {
	      return type;
	    }
	  };

	  Schema.prototype.idType = function(key) {
	    var type;
	    if (!key) {
	      return this.type('id');
	    }
	    if (type = this.type(key)) {
	      return (typeof type.schema === "function" ? type.schema().type('id') : void 0) || type;
	    }
	  };

	  Schema.prototype.field = function(key) {
	    return this.fields[key] || this.relation(key);
	  };

	  Schema.prototype.relation = function(key) {
	    return this.relations[key] || this.virtual_accessors[key];
	  };

	  Schema.prototype.reverseRelation = function(reverse_key) {
	    var key, ref, relation;
	    ref = this.relations;
	    for (key in ref) {
	      relation = ref[key];
	      if (relation.reverse_relation && (relation.reverse_relation.join_key === reverse_key)) {
	        return relation.reverse_relation;
	      }
	    }
	    return null;
	  };

	  Schema.prototype.columns = function() {
	    var columns, key, ref, relation;
	    columns = _.keys(this.fields);
	    if (!_.find(columns, function(column) {
	      return column === 'id';
	    })) {
	      columns.push('id');
	    }
	    ref = this.relations;
	    for (key in ref) {
	      relation = ref[key];
	      if ((relation.type === 'belongsTo') && !relation.isVirtual() && !relation.isEmbedded()) {
	        columns.push(relation.foreign_key);
	      }
	    }
	    return columns;
	  };

	  Schema.prototype.joinTables = function() {
	    var key, relation;
	    return (function() {
	      var ref, results;
	      ref = this.relations;
	      results = [];
	      for (key in ref) {
	        relation = ref[key];
	        if (!relation.isVirtual() && relation.join_table) {
	          results.push(relation.join_table);
	        }
	      }
	      return results;
	    }).call(this);
	  };

	  Schema.prototype.relatedModels = function() {
	    var key, ref, related_model_types, relation;
	    related_model_types = [];
	    ref = this.relations;
	    for (key in ref) {
	      relation = ref[key];
	      related_model_types.push(relation.reverse_model_type);
	      if (relation.join_table) {
	        related_model_types.push(relation.join_table);
	      }
	    }
	    return related_model_types;
	  };

	  Schema.prototype.allColumns = function() {
	    return this.columns();
	  };

	  Schema.prototype.allRelations = function() {
	    return this.relatedModels();
	  };

	  Schema.prototype.generateBelongsTo = function(reverse_model_type) {
	    var key, relation;
	    key = BackboneORM.naming_conventions.attribute(reverse_model_type.model_name);
	    if (relation = this.relations[key]) {
	      return relation;
	    }
	    if (this.raw[key]) {
	      relation = this._parseField(key, this.raw[key]);
	      relation.initialize();
	      return relation;
	    }
	    relation = this._parseField(key, this.raw[key] = [
	      'belongsTo', reverse_model_type, {
	        manual_fetch: true
	      }
	    ]);
	    relation.initialize();
	    return relation;
	  };

	  Schema.joinTableURL = function(relation) {
	    var table_name1, table_name2;
	    table_name1 = BackboneORM.naming_conventions.tableName(relation.model_type.model_name);
	    table_name2 = BackboneORM.naming_conventions.tableName(relation.reverse_relation.model_type.model_name);
	    if (table_name1.localeCompare(table_name2) < 0) {
	      return table_name1 + "_" + table_name2;
	    } else {
	      return table_name2 + "_" + table_name1;
	    }
	  };

	  Schema.prototype.generateJoinTable = function(relation) {
	    var JoinTable, error, name, ref, schema, type, url;
	    schema = {};
	    schema[relation.join_key] = [
	      type = relation.model_type.schema().type('id'), {
	        indexed: true
	      }
	    ];
	    schema[relation.reverse_relation.join_key] = [
	      ((ref = relation.reverse_model_type) != null ? ref.schema().type('id') : void 0) || type, {
	        indexed: true
	      }
	    ];
	    url = Schema.joinTableURL(relation);
	    name = BackboneORM.naming_conventions.modelName(url, true);
	    try {
	      JoinTable = (function(superClass) {
	        extend(JoinTable, superClass);

	        function JoinTable() {
	          return JoinTable.__super__.constructor.apply(this, arguments);
	        }

	        JoinTable.prototype.model_name = name;

	        JoinTable.prototype.urlRoot = ((new DatabaseURL(_.result(new relation.model_type, 'url'))).format({
	          exclude_table: true
	        })) + "/" + url;

	        JoinTable.prototype.schema = schema;

	        JoinTable.prototype.sync = relation.model_type.createSync(JoinTable);

	        return JoinTable;

	      })(Backbone.Model);
	    } catch (error) {
	      JoinTable = (function(superClass) {
	        extend(JoinTable, superClass);

	        function JoinTable() {
	          return JoinTable.__super__.constructor.apply(this, arguments);
	        }

	        JoinTable.prototype.model_name = name;

	        JoinTable.prototype.urlRoot = "/" + url;

	        JoinTable.prototype.schema = schema;

	        JoinTable.prototype.sync = relation.model_type.createSync(JoinTable);

	        return JoinTable;

	      })(Backbone.Model);
	    }
	    return JoinTable;
	  };

	  Schema.prototype._parseField = function(key, info) {
	    var options, relation, type;
	    options = this._fieldInfoToOptions(_.isFunction(info) ? info() : info);
	    if (!options.type) {
	      return this.fields[key] = options;
	    }
	    if (!(type = RELATION_VARIANTS[options.type])) {
	      if (!_.isString(options.type)) {
	        throw new Error("Unexpected type name is not a string: " + (JSONUtils.stringify(options)));
	      }
	      return this.fields[key] = options;
	    }
	    options.type = type;
	    relation = this.relations[key] = type === 'hasMany' ? new Many(this.model_type, key, options) : new One(this.model_type, key, options);
	    if (relation.virtual_id_accessor) {
	      this.virtual_accessors[relation.virtual_id_accessor] = relation;
	    }
	    if (type === 'belongsTo') {
	      this.virtual_accessors[relation.foreign_key] = relation;
	    }
	    return relation;
	  };

	  Schema.prototype._fieldInfoToOptions = function(options) {
	    var result;
	    if (_.isString(options)) {
	      return {
	        type: options
	      };
	    }
	    if (!_.isArray(options)) {
	      return options;
	    }
	    result = {};
	    if (_.isString(options[0])) {
	      result.type = options[0];
	      options = options.slice(1);
	      if (options.length === 0) {
	        return result;
	      }
	    }
	    if (_.isFunction(options[0])) {
	      result.reverse_model_type = options[0];
	      options = options.slice(1);
	    }
	    if (options.length > 1) {
	      throw new Error("Unexpected field options array: " + (JSONUtils.stringify(options)));
	    }
	    if (options.length === 1) {
	      _.extend(result, options[0]);
	    }
	    return result;
	  };

	  return Schema;

	})();


/***/ },
/* 44 */
/***/ function(module, exports, __webpack_require__) {

	
	/*
	  backbone-orm.js 0.7.14
	  Copyright (c) 2013-2016 Vidigami
	  License: MIT (http://www.opensource.org/licenses/mit-license.php)
	  Source: https://github.com/vidigami/backbone-orm
	  Dependencies: Backbone.js and Underscore.js.
	 */
	var Backbone, BackboneORM, One, Queue, Utils, _,
	  extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
	  hasProp = {}.hasOwnProperty;

	_ = __webpack_require__(1);

	Backbone = __webpack_require__(2);

	BackboneORM = __webpack_require__(3);

	Queue = __webpack_require__(11);

	Utils = __webpack_require__(24);

	module.exports = One = (function(superClass) {
	  extend(One, superClass);

	  function One(model_type, key1, options) {
	    var key, value;
	    this.model_type = model_type;
	    this.key = key1;
	    for (key in options) {
	      value = options[key];
	      this[key] = value;
	    }
	    this.virtual_id_accessor || (this.virtual_id_accessor = BackboneORM.naming_conventions.foreignKey(this.key));
	    if (!this.join_key) {
	      this.join_key = this.foreign_key || BackboneORM.naming_conventions.foreignKey(this.model_type.model_name);
	    }
	    if (!this.foreign_key) {
	      this.foreign_key = BackboneORM.naming_conventions.foreignKey(this.type === 'belongsTo' ? this.key : this.as || this.model_type.model_name);
	    }
	  }

	  One.prototype.initialize = function() {
	    var ref, ref1, ref2;
	    this.reverse_relation = this._findOrGenerateReverseRelation(this);
	    if (this.embed && this.reverse_relation && this.reverse_relation.embed) {
	      throw new Error("Both relationship directions cannot embed (" + this.model_type.model_name + " and " + this.reverse_model_type.model_name + "). Choose one or the other.");
	    }
	    if (this.embed) {
	      this.model_type.schema().type('id', this.reverse_model_type.schema().type('id'));
	    }
	    return (ref = this.reverse_model_type) != null ? ref.schema().type(this.foreign_key, ((ref1 = this.model_type) != null ? (ref2 = ref1.schema()) != null ? ref2.type('id') : void 0 : void 0) || this.model_type) : void 0;
	  };

	  One.prototype.initializeModel = function(model) {
	    if (!model.isLoadedExists(this.key)) {
	      model.setLoaded(this.key, this.isEmbedded());
	    }
	    return this._bindBacklinks(model);
	  };

	  One.prototype.releaseModel = function(model) {
	    this._unbindBacklinks(model);
	    return delete model._orm;
	  };

	  One.prototype.set = function(model, key, value, options) {
	    var is_model, merge_into_existing, new_related_id, previous_related_id, previous_related_model;
	    if (!((key === this.key) || (key === this.virtual_id_accessor) || (key === this.foreign_key))) {
	      throw new Error("One.set: Unexpected key " + key + ". Expecting: " + this.key + " or " + this.virtual_id_accessor + " or " + this.foreign_key);
	    }
	    if (_.isArray(value)) {
	      throw new Error("One.set: cannot set an array for attribute " + this.key + " on " + this.model_type.model_name);
	    }
	    if (_.isUndefined(value)) {
	      value = null;
	    }
	    if (value === (previous_related_model = model.get(this.key))) {
	      return this;
	    }
	    is_model = Utils.isModel(value);
	    new_related_id = Utils.dataId(value);
	    previous_related_id = Utils.dataId(previous_related_model);
	    Utils.orSet(model, 'rel_dirty', {})[this.key] = true;
	    if ((previous_related_id !== new_related_id) || !model.isLoaded(this.key)) {
	      if ((is_model && (value.isLoaded())) && (new_related_id !== value)) {
	        model.setLoaded(this.key, true);
	      } else {
	        model.setLoaded(this.key, _.isNull(value));
	      }
	    }
	    if (value && !is_model) {
	      if (!(merge_into_existing = previous_related_id === new_related_id)) {
	        value = Utils.updateOrNew(value, this.reverse_model_type);
	      }
	    }
	    if (!merge_into_existing) {
	      Backbone.Model.prototype.set.call(model, this.key, value, options);
	    }
	    if (merge_into_existing) {
	      Utils.updateModel(previous_related_model, value);
	    } else if ((value === null) && this.reverse_relation && (this.reverse_relation.type === 'hasOne' || this.reverse_relation.type === 'belongsTo')) {
	      if (!(this.embed || this.reverse_relation.embed)) {
	        if (model.isLoaded(this.key) && previous_related_model && (previous_related_model.get(this.reverse_relation.key) === model)) {
	          previous_related_model.set(this.reverse_relation.key, null);
	        }
	      }
	    }
	    return this;
	  };

	  One.prototype.get = function(model, key, callback) {
	    var is_loaded, result, returnValue;
	    if (!((key === this.key) || (key === this.virtual_id_accessor) || (key === this.foreign_key))) {
	      throw new Error("One.get: Unexpected key " + key + ". Expecting: " + this.key + " or " + this.virtual_id_accessor + " or " + this.foreign_key);
	    }
	    returnValue = (function(_this) {
	      return function() {
	        var related_model;
	        if (!(related_model = model.attributes[_this.key])) {
	          return null;
	        }
	        if (key === _this.virtual_id_accessor) {
	          return related_model.id;
	        } else {
	          return related_model;
	        }
	      };
	    })(this);
	    if (callback && !this.isVirtual() && !this.manual_fetch && !(is_loaded = model.isLoaded(this.key))) {
	      this.cursor(model, key).toJSON((function(_this) {
	        return function(err, json) {
	          var previous_related_model, related_model;
	          if (err) {
	            return callback(err);
	          }
	          if (key !== _this.virtual_id_accessor) {
	            model.setLoaded(_this.key, true);
	          }
	          previous_related_model = model.get(_this.key);
	          if (previous_related_model && (previous_related_model.id === (json != null ? json.id : void 0))) {
	            Utils.updateModel(previous_related_model, json);
	          } else {
	            related_model = json ? Utils.updateOrNew(json, _this.reverse_model_type) : null;
	            model.set(_this.key, related_model);
	          }
	          return callback(null, returnValue());
	        };
	      })(this));
	    }
	    result = returnValue();
	    if (callback && (is_loaded || this.manual_fetch)) {
	      callback(null, result);
	    }
	    return result;
	  };

	  One.prototype.save = function(model, callback) {
	    var related_model;
	    if (!this._hasChanged(model)) {
	      return callback();
	    }
	    delete Utils.orSet(model, 'rel_dirty', {})[this.key];
	    if (!(related_model = model.attributes[this.key])) {
	      return callback();
	    }
	    return this._saveRelated(model, [related_model], callback);
	  };

	  One.prototype.patchAdd = function(model, related, callback) {
	    var found_related, related_id;
	    if (!model.id) {
	      return callback(new Error("One.patchAdd: model has null id for: " + this.key));
	    }
	    if (!related) {
	      return callback(new Error("One.patchAdd: missing model for: " + this.key));
	    }
	    if (_.isArray(related)) {
	      return callback(new Error("One.patchAdd: should be provided with one model only for key: " + this.key));
	    }
	    if (!(related_id = Utils.dataId(related))) {
	      return callback(new Error("One.patchAdd: cannot add a new model. Please save first."));
	    }
	    if (this.reverse_model_type.cache && !Utils.isModel(related)) {
	      if (found_related = this.reverse_model_type.cache.get(related_id)) {
	        Utils.updateModel(found_related, related);
	        related = found_related;
	      }
	    }
	    model.set(this.key, related);
	    if (this.type === 'belongsTo') {
	      return this.model_type.cursor({
	        id: model.id,
	        $one: true
	      }).toJSON((function(_this) {
	        return function(err, model_json) {
	          if (err) {
	            return callback(err);
	          }
	          if (!model_json) {
	            return callback(new Error("Failed to fetch model with id: " + model.id));
	          }
	          model_json[_this.foreign_key] = related_id;
	          return model.save(model_json, callback);
	        };
	      })(this));
	    } else {
	      return this.cursor(model, this.key).toJSON((function(_this) {
	        return function(err, current_related_json) {
	          var queue;
	          if (err) {
	            return callback(err);
	          }
	          if (current_related_json && (related_id === current_related_json[_this.reverse_model_type.prototype.idAttribute])) {
	            return callback();
	          }
	          queue = new Queue(1);
	          if (current_related_json) {
	            queue.defer(function(callback) {
	              return _this.patchRemove(model, current_related_json, callback);
	            });
	          }
	          queue.defer(function(callback) {
	            var query, related_json;
	            if (Utils.isModel(related)) {
	              if (related.isLoaded()) {
	                related_json = related.toJSON();
	              }
	            } else if (related_id !== related) {
	              related_json = related;
	            }
	            if (related_json) {
	              related_json[_this.reverse_relation.foreign_key] = model.id;
	              return Utils.modelJSONSave(related_json, _this.reverse_model_type, callback);
	            } else {
	              query = {
	                $one: true
	              };
	              query.id = related_id;
	              return _this.reverse_model_type.cursor(query).toJSON(function(err, related_json) {
	                if (err) {
	                  return callback(err);
	                }
	                if (!related_json) {
	                  return callback();
	                }
	                related_json[_this.reverse_relation.foreign_key] = model.id;
	                return Utils.modelJSONSave(related_json, _this.reverse_model_type, callback);
	              });
	            }
	          });
	          return queue.await(callback);
	        };
	      })(this));
	    }
	  };

	  One.prototype.patchRemove = function(model, relateds, callback) {
	    var cache, i, json, len, ref, ref1, related, related_ids, related_model;
	    if (arguments.length === 2) {
	      ref = [null, relateds], relateds = ref[0], callback = ref[1];
	    }
	    if (!model.id) {
	      return callback(new Error("One.patchRemove: model has null id for: " + this.key));
	    }
	    if (arguments.length === 2) {
	      if (!this.reverse_relation) {
	        return callback();
	      }
	      if (Utils.isModel(model)) {
	        delete Utils.orSet(model, 'rel_dirty', {})[this.key];
	        related_model = model.get(this.key);
	        model.set(this.key, null);
	      } else {
	        if (json = model[this.key]) {
	          related_model = new this.reverse_model_type(json);
	        }
	      }
	      if (related_model) {
	        if (((ref1 = related_model.get(this.foreign_key)) != null ? ref1.id : void 0) === model.id) {
	          related_model.set(this.foreign_key, null);
	        }
	        if (cache = related_model.cache()) {
	          cache.set(related_model.id, related_model);
	        }
	      }
	      if (this.embed) {
	        return callback();
	      }
	      if (this.type === 'belongsTo') {
	        this.model_type.cursor({
	          id: model.id,
	          $one: true
	        }).toJSON((function(_this) {
	          return function(err, model_json) {
	            if (err) {
	              return callback(err);
	            }
	            if (!model_json) {
	              return callback();
	            }
	            model_json[_this.foreign_key] = null;
	            return Utils.modelJSONSave(model_json, _this.model_type, callback);
	          };
	        })(this));
	      } else {
	        this.cursor(model, this.key).toJSON((function(_this) {
	          return function(err, related_json) {
	            if (err) {
	              return callback(err);
	            }
	            if (!related_json) {
	              return callback();
	            }
	            if (related_json[_this.reverse_relation.foreign_key] !== model.id) {
	              return callback();
	            }
	            related_json[_this.reverse_relation.foreign_key] = null;
	            return Utils.modelJSONSave(related_json, _this.reverse_model_type, callback);
	          };
	        })(this));
	      }
	      return;
	    }
	    if (!relateds) {
	      return callback(new Error('One.patchRemove: missing model for remove'));
	    }
	    if (!_.isArray(relateds)) {
	      relateds = [relateds];
	    }
	    if (related_model = model.get(this.key)) {
	      for (i = 0, len = relateds.length; i < len; i++) {
	        related = relateds[i];
	        if (Utils.dataIsSameModel(related_model, related)) {
	          model.set(this.key, null);
	          break;
	        }
	      }
	    }
	    related_ids = (function() {
	      var j, len1, results;
	      results = [];
	      for (j = 0, len1 = relateds.length; j < len1; j++) {
	        related = relateds[j];
	        results.push(Utils.dataId(related));
	      }
	      return results;
	    })();
	    if (this.embed) {
	      return callback();
	    }
	    if (this.type === 'belongsTo') {
	      return this.model_type.cursor({
	        id: model.id,
	        $one: true
	      }).toJSON((function(_this) {
	        return function(err, model_json) {
	          if (err) {
	            return callback(err);
	          }
	          if (!model_json) {
	            return callback();
	          }
	          if (!_.contains(related_ids, model_json[_this.foreign_key])) {
	            return callback();
	          }
	          model_json[_this.foreign_key] = null;
	          return Utils.modelJSONSave(model_json, _this.model_type, callback);
	        };
	      })(this));
	    } else {
	      return this.cursor(model, this.key).toJSON((function(_this) {
	        return function(err, related_json) {
	          if (err) {
	            return callback(err);
	          }
	          if (!related_json) {
	            return callback();
	          }
	          if (!_.contains(related_ids, related_json[_this.reverse_model_type.prototype.idAttribute])) {
	            return callback();
	          }
	          related_json[_this.reverse_relation.foreign_key] = null;
	          return Utils.modelJSONSave(related_json, _this.reverse_model_type, callback);
	        };
	      })(this));
	    }
	  };

	  One.prototype.appendJSON = function(json, model) {
	    var json_key, related_model;
	    if (this.isVirtual()) {
	      return;
	    }
	    json_key = this.embed ? this.key : this.foreign_key;
	    if (!(related_model = model.attributes[this.key])) {
	      if (this.embed || this.type === 'belongsTo') {
	        json[json_key] = null;
	      }
	      return;
	    }
	    if (this.embed) {
	      return json[json_key] = related_model.toJSON();
	    }
	    if (this.type === 'belongsTo') {
	      return json[json_key] = related_model.id;
	    }
	  };

	  One.prototype.cursor = function(model, key, query) {
	    var ref;
	    query = _.extend({
	      $one: true
	    }, query || {});
	    if (Utils.isModel(model)) {
	      if (this.type === 'belongsTo') {
	        if (!(query.id = (ref = model.attributes[this.key]) != null ? ref.id : void 0)) {
	          query.$zero = true;
	          delete query.id;
	        }
	      } else {
	        if (!model.id) {
	          throw new Error('Cannot create cursor for non-loaded model');
	        }
	        query[this.reverse_relation.foreign_key] = model.id;
	      }
	    } else {
	      if (this.type === 'belongsTo') {
	        if (!(query.id = model[this.foreign_key])) {
	          query.$zero = true;
	          delete query.id;
	        }
	      } else {
	        if (!model.id) {
	          throw new Error('Cannot create cursor for non-loaded model');
	        }
	        query[this.reverse_relation.foreign_key] = model.id;
	      }
	    }
	    if (key === this.virtual_id_accessor) {
	      query.$values = ['id'];
	    }
	    return this.reverse_model_type.cursor(query);
	  };

	  One.prototype._bindBacklinks = function(model) {
	    var events, related_model, setBacklink;
	    if (!this.reverse_relation) {
	      return;
	    }
	    events = Utils.set(model, 'events', {});
	    setBacklink = (function(_this) {
	      return function(related_model) {
	        if (_this.reverse_relation.add) {
	          return _this.reverse_relation.add(related_model, model);
	        } else {
	          return related_model.set(_this.reverse_relation.key, model);
	        }
	      };
	    })(this);
	    events.change = (function(_this) {
	      return function(model) {
	        var current_model, previous_related_model, related_model;
	        related_model = model.get(_this.key);
	        previous_related_model = model.previous(_this.key);
	        if (Utils.dataId(related_model) === Utils.dataId(previous_related_model)) {
	          return;
	        }
	        Utils.orSet(model, 'rel_dirty', {})[_this.key] = true;
	        if (previous_related_model && (_this.reverse_relation && _this.reverse_relation.type !== 'belongsTo')) {
	          if (_this.reverse_relation.remove) {
	            if (!_this.isVirtual() || !related_model) {
	              _this.reverse_relation.remove(previous_related_model, model);
	            }
	          } else {
	            current_model = previous_related_model.get(_this.reverse_relation.key);
	            if (Utils.dataId(current_model) === model.id) {
	              previous_related_model.set(_this.reverse_relation.key, null);
	            }
	          }
	        }
	        if (related_model) {
	          return setBacklink(related_model);
	        }
	      };
	    })(this);
	    model.on("change:" + this.key, events.change);
	    if (related_model = model.get(this.key)) {
	      setBacklink(related_model);
	    } else {
	      model.attributes[this.key] = null;
	    }
	    return model;
	  };

	  One.prototype._unbindBacklinks = function(model) {
	    var events;
	    if (!(events = Utils.get(model, 'events'))) {
	      return;
	    }
	    Utils.unset(model, 'events');
	    model.attributes[this.key] = null;
	    model.off("change:" + this.key, events.change);
	    events.change = null;
	  };

	  One.prototype._hasChanged = function(model) {
	    return !!Utils.orSet(model, 'rel_dirty', {})[this.key] || model.hasChanged(this.key);
	  };

	  return One;

	})(__webpack_require__(45));


/***/ },
/* 45 */
/***/ function(module, exports, __webpack_require__) {

	
	/*
	  backbone-orm.js 0.7.14
	  Copyright (c) 2013-2016 Vidigami
	  License: MIT (http://www.opensource.org/licenses/mit-license.php)
	  Source: https://github.com/vidigami/backbone-orm
	  Dependencies: Backbone.js and Underscore.js.
	 */
	var Backbone, BackboneORM, Queue, Relation, Utils, _;

	_ = __webpack_require__(1);

	Backbone = __webpack_require__(2);

	BackboneORM = __webpack_require__(3);

	Queue = __webpack_require__(11);

	Utils = __webpack_require__(24);

	module.exports = Relation = (function() {
	  function Relation() {}

	  Relation.prototype.isEmbedded = function() {
	    return !!(this.embed || (this.reverse_relation && this.reverse_relation.embed));
	  };

	  Relation.prototype.isVirtual = function() {
	    return !!(this.virtual || (this.reverse_relation && this.reverse_relation.virtual));
	  };

	  Relation.prototype.findOrGenerateJoinTable = function() {
	    var join_table;
	    if (join_table = this.join_table || this.reverse_relation.join_table) {
	      return join_table;
	    }
	    return this.model_type.schema().generateJoinTable(this);
	  };

	  Relation.prototype._findOrGenerateReverseRelation = function() {
	    var model_type, reverse_model_type, reverse_relation;
	    model_type = this.model_type;
	    reverse_model_type = this.reverse_model_type;
	    if (!_.isFunction(reverse_model_type.schema)) {
	      reverse_model_type.sync = model_type.createSync(reverse_model_type);
	    }
	    reverse_relation = reverse_model_type.relation(this.as);
	    if (!reverse_relation) {
	      reverse_relation = reverse_model_type.relation(BackboneORM.naming_conventions.attribute(model_type.model_name, false));
	    }
	    if (!reverse_relation) {
	      reverse_relation = reverse_model_type.relation(BackboneORM.naming_conventions.attribute(model_type.model_name, true));
	    }
	    if (!reverse_relation && (this.type !== 'belongsTo')) {
	      reverse_relation = reverse_model_type.schema().generateBelongsTo(model_type);
	    }
	    if (reverse_relation && !reverse_relation.reverse_relation) {
	      reverse_relation.reverse_relation = this;
	    }
	    return reverse_relation;
	  };

	  Relation.prototype._saveRelated = function(model, related_models, callback) {
	    if (this.embed || !this.reverse_relation || (this.type === 'belongsTo')) {
	      return callback();
	    }
	    if (this.isVirtual()) {
	      return callback();
	    }
	    return this.cursor(model, this.key).toJSON((function(_this) {
	      return function(err, json) {
	        var added_ids, changes, queue, related_ids, test;
	        if (err) {
	          return callback(err);
	        }
	        if (!_.isArray(json)) {
	          json = (json ? [json] : []);
	        }
	        queue = new Queue(1);
	        related_ids = _.pluck(related_models, 'id');
	        changes = _.groupBy(json, function(test) {
	          if (_.contains(related_ids, test.id)) {
	            return 'kept';
	          } else {
	            return 'removed';
	          }
	        });
	        added_ids = changes.kept ? _.difference(related_ids, (function() {
	          var i, len, ref, results;
	          ref = changes.kept;
	          results = [];
	          for (i = 0, len = ref.length; i < len; i++) {
	            test = ref[i];
	            results.push(test.id);
	          }
	          return results;
	        })()) : related_ids;
	        if (changes.removed) {
	          if (_this.join_table) {
	            queue.defer(function(callback) {
	              var query, related_json;
	              query = {};
	              query[_this.join_key] = model.id;
	              query[_this.reverse_relation.join_key] = {
	                $in: (function() {
	                  var i, len, ref, results;
	                  ref = changes.removed;
	                  results = [];
	                  for (i = 0, len = ref.length; i < len; i++) {
	                    related_json = ref[i];
	                    results.push(related_json[this.reverse_model_type.prototype.idAttribute]);
	                  }
	                  return results;
	                }).call(_this)
	              };
	              return _this.join_table.destroy(query, callback);
	            });
	          } else {
	            queue.defer(function(callback) {
	              return Utils.each(changes.removed, (function(related_json, callback) {
	                related_json[_this.reverse_relation.foreign_key] = null;
	                return Utils.modelJSONSave(related_json, _this.reverse_model_type, callback);
	              }), callback);
	            });
	          }
	        }
	        if (added_ids.length) {
	          if (_this.join_table) {
	            queue.defer(function(callback) {
	              return Utils.each(added_ids, (function(related_id, callback) {
	                var attributes, join;
	                attributes = {};
	                attributes[_this.foreign_key] = model.id;
	                attributes[_this.reverse_relation.foreign_key] = related_id;
	                join = new _this.join_table(attributes);
	                return join.save(callback);
	              }), callback);
	            });
	          } else {
	            queue.defer(function(callback) {
	              return Utils.each(added_ids, (function(added_id, callback) {
	                var related_model;
	                related_model = _.find(related_models, function(test) {
	                  return test.id === added_id;
	                });
	                if (!_this.reverse_relation._hasChanged(related_model)) {
	                  return callback();
	                }
	                return related_model.save(function(err, saved_model) {
	                  var cache;
	                  if (!err && (cache = _this.reverse_model_type.cache)) {
	                    cache.set(saved_model.id, saved_model);
	                  }
	                  return callback(err);
	                });
	              }), callback);
	            });
	          }
	        }
	        return queue.await(callback);
	      };
	    })(this));
	  };

	  return Relation;

	})();


/***/ },
/* 46 */
/***/ function(module, exports, __webpack_require__) {

	
	/*
	  backbone-orm.js 0.7.14
	  Copyright (c) 2013-2016 Vidigami
	  License: MIT (http://www.opensource.org/licenses/mit-license.php)
	  Source: https://github.com/vidigami/backbone-orm
	  Dependencies: Backbone.js and Underscore.js.
	 */
	var Backbone, BackboneORM, JSONUtils, Many, Queue, Utils, _,
	  extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
	  hasProp = {}.hasOwnProperty;

	Backbone = __webpack_require__(2);

	_ = __webpack_require__(1);

	BackboneORM = __webpack_require__(3);

	Queue = __webpack_require__(11);

	Utils = __webpack_require__(24);

	JSONUtils = __webpack_require__(33);

	module.exports = Many = (function(superClass) {
	  extend(Many, superClass);

	  function Many(model_type, key1, options) {
	    var Collection, key, reverse_model_type, value;
	    this.model_type = model_type;
	    this.key = key1;
	    for (key in options) {
	      value = options[key];
	      this[key] = value;
	    }
	    this.virtual_id_accessor || (this.virtual_id_accessor = BackboneORM.naming_conventions.foreignKey(this.key, true));
	    if (!this.join_key) {
	      this.join_key = this.foreign_key || BackboneORM.naming_conventions.foreignKey(this.model_type.model_name);
	    }
	    if (!this.foreign_key) {
	      this.foreign_key = BackboneORM.naming_conventions.foreignKey(this.as || this.model_type.model_name);
	    }
	    this._adding_ids = {};
	    if (!this.collection_type) {
	      reverse_model_type = this.reverse_model_type;
	      Collection = (function(superClass1) {
	        extend(Collection, superClass1);

	        function Collection() {
	          return Collection.__super__.constructor.apply(this, arguments);
	        }

	        Collection.prototype.model = reverse_model_type;

	        return Collection;

	      })(Backbone.Collection);
	      this.collection_type = Collection;
	    }
	  }

	  Many.prototype.initialize = function() {
	    var ref, ref1, ref2, ref3;
	    this.reverse_relation = this._findOrGenerateReverseRelation(this);
	    if (this.embed && this.reverse_relation && this.reverse_relation.embed) {
	      throw new Error("Both relationship directions cannot embed (" + this.model_type.model_name + " and " + this.reverse_model_type.model_name + "). Choose one or the other.");
	    }
	    if (((ref = this.reverse_relation) != null ? ref.type : void 0) === 'hasOne') {
	      throw new Error("The reverse of a hasMany relation should be `belongsTo`, not `hasOne` (" + this.model_type.model_name + " and " + this.reverse_model_type.model_name + ").");
	    }
	    if (this.embed) {
	      this.model_type.schema().type('id', this.reverse_model_type.schema().type('id'));
	    }
	    if ((ref1 = this.reverse_model_type) != null) {
	      ref1.schema().type(this.foreign_key, ((ref2 = this.model_type) != null ? (ref3 = ref2.schema()) != null ? ref3.type('id') : void 0 : void 0) || this.model_type);
	    }
	    if (this.reverse_relation.type === 'hasMany') {
	      return this.join_table = this.findOrGenerateJoinTable(this);
	    }
	  };

	  Many.prototype.initializeModel = function(model) {
	    if (!model.isLoadedExists(this.key)) {
	      model.setLoaded(this.key, false);
	    }
	    return this._bindBacklinks(model);
	  };

	  Many.prototype.releaseModel = function(model) {
	    this._unbindBacklinks(model);
	    return delete model._orm;
	  };

	  Many.prototype.set = function(model, key, value, options) {
	    var collection, i, item, len, model_ids, models, previous_models, related_model;
	    if (!((key === this.key) || (key === this.virtual_id_accessor) || (key === this.foreign_key))) {
	      throw new Error("Many.set: Unexpected key " + key + ". Expecting: " + this.key + " or " + this.virtual_id_accessor + " or " + this.foreign_key);
	    }
	    collection = this._bindBacklinks(model);
	    if (Utils.isCollection(value)) {
	      value = value.models;
	    }
	    if (_.isUndefined(value)) {
	      value = [];
	    }
	    if (!_.isArray(value)) {
	      throw new Error("HasMany.set: Unexpected type to set " + key + ". Expecting array: " + (JSONUtils.stringify(value)));
	    }
	    Utils.orSet(model, 'rel_dirty', {})[this.key] = true;
	    model.setLoaded(this.key, _.all(value, function(item) {
	      return Utils.dataId(item) !== item;
	    }));
	    models = (function() {
	      var i, len, results;
	      results = [];
	      for (i = 0, len = value.length; i < len; i++) {
	        item = value[i];
	        results.push((related_model = collection.get(Utils.dataId(item))) ? Utils.updateModel(related_model, item) : Utils.updateOrNew(item, this.reverse_model_type));
	      }
	      return results;
	    }).call(this);
	    model.setLoaded(this.key, _.all(models, function(model) {
	      return model.isLoaded();
	    }));
	    previous_models = _.clone(collection.models);
	    collection.reset(models);
	    if (this.reverse_relation.type === 'belongsTo') {
	      model_ids = _.pluck(models, 'id');
	      for (i = 0, len = previous_models.length; i < len; i++) {
	        related_model = previous_models[i];
	        if (!_.contains(model_ids, related_model.id)) {
	          related_model.set(this.foreign_key, null);
	        }
	      }
	    }
	    return this;
	  };

	  Many.prototype.get = function(model, key, callback) {
	    var collection, is_loaded, result, returnValue;
	    if (!((key === this.key) || (key === this.virtual_id_accessor) || (key === this.foreign_key))) {
	      throw new Error("Many.get: Unexpected key " + key + ". Expecting: " + this.key + " or " + this.virtual_id_accessor + " or " + this.foreign_key);
	    }
	    collection = this._ensureCollection(model);
	    returnValue = (function(_this) {
	      return function() {
	        var i, len, ref, related_model, results;
	        if (key === _this.virtual_id_accessor) {
	          ref = collection.models;
	          results = [];
	          for (i = 0, len = ref.length; i < len; i++) {
	            related_model = ref[i];
	            results.push(related_model.id);
	          }
	          return results;
	        } else {
	          return collection;
	        }
	      };
	    })(this);
	    if (callback && !this.isVirtual() && !this.manual_fetch && !(is_loaded = model.isLoaded(this.key))) {
	      this.cursor(model, this.key).toJSON((function(_this) {
	        return function(err, json) {
	          var cache, i, j, len, len1, model_json, ref, related_model, result;
	          if (err) {
	            return callback(err);
	          }
	          model.setLoaded(_this.key, true);
	          for (i = 0, len = json.length; i < len; i++) {
	            model_json = json[i];
	            if (related_model = collection.get(model_json[_this.reverse_model_type.prototype.idAttribute])) {
	              related_model.set(model_json);
	            } else {
	              collection.add(related_model = Utils.updateOrNew(model_json, _this.reverse_model_type));
	            }
	          }
	          if (cache = _this.reverse_model_type.cache) {
	            ref = collection.models;
	            for (j = 0, len1 = ref.length; j < len1; j++) {
	              related_model = ref[j];
	              cache.set(related_model.id, related_model);
	            }
	          }
	          result = returnValue();
	          return callback(null, result.models ? result.models : result);
	        };
	      })(this));
	    }
	    result = returnValue();
	    if (callback && (is_loaded || this.manual_fetch)) {
	      callback(null, result.models ? result.models : result);
	    }
	    return result;
	  };

	  Many.prototype.save = function(model, callback) {
	    var collection;
	    if (!this._hasChanged(model)) {
	      return callback();
	    }
	    delete Utils.orSet(model, 'rel_dirty', {})[this.key];
	    collection = this._ensureCollection(model);
	    return this._saveRelated(model, _.clone(collection.models), callback);
	  };

	  Many.prototype.appendJSON = function(json, model) {
	    var collection, json_key;
	    if (this.isVirtual()) {
	      return;
	    }
	    collection = this._ensureCollection(model);
	    json_key = this.embed ? this.key : this.virtual_id_accessor;
	    if (this.embed) {
	      return json[json_key] = collection.toJSON();
	    }
	  };

	  Many.prototype.add = function(model, related_model) {
	    var adding_count, collection, current_related_model, return_value;
	    if (related_model.id) {
	      adding_count = this._adding_ids[related_model.id] = (this._adding_ids[related_model.id] || 0) + 1;
	    }
	    collection = this._ensureCollection(model);
	    current_related_model = collection.get(related_model.id);
	    if (current_related_model === related_model) {
	      return;
	    }
	    if (current_related_model) {
	      collection.remove(current_related_model);
	    }
	    if (this.reverse_model_type.cache && related_model.id) {
	      this.reverse_model_type.cache.set(related_model.id, related_model);
	    }
	    return_value = collection.add(related_model, {
	      silent: adding_count > 1
	    });
	    if (related_model.id) {
	      this._adding_ids[related_model.id]--;
	    }
	    return return_value;
	  };

	  Many.prototype.remove = function(model, related_model) {
	    var collection, current_related_model;
	    collection = this._ensureCollection(model);
	    if (!(current_related_model = collection.get(related_model.id))) {
	      return;
	    }
	    Utils.orSet(model, 'rel_dirty', {})[this.key] = true;
	    return collection.remove(current_related_model);
	  };

	  Many.prototype.patchAdd = function(model, relateds, callback) {
	    var collection, i, item, len, query, related, related_ids, related_model;
	    if (!model.id) {
	      return callback(new Error("Many.patchAdd: model has null id for: " + this.key));
	    }
	    if (!relateds) {
	      return callback(new Error("Many.patchAdd: missing model for: " + this.key));
	    }
	    if (!_.isArray(relateds)) {
	      relateds = [relateds];
	    }
	    collection = this._ensureCollection(model);
	    relateds = (function() {
	      var i, len, results;
	      results = [];
	      for (i = 0, len = relateds.length; i < len; i++) {
	        item = relateds[i];
	        results.push((related_model = collection.get(Utils.dataId(item))) ? Utils.updateModel(related_model, item) : Utils.updateOrNew(item, this.reverse_model_type));
	      }
	      return results;
	    }).call(this);
	    related_ids = (function() {
	      var i, len, results;
	      results = [];
	      for (i = 0, len = relateds.length; i < len; i++) {
	        related = relateds[i];
	        results.push(Utils.dataId(related));
	      }
	      return results;
	    })();
	    collection.add(relateds);
	    if (model.isLoaded(this.key)) {
	      for (i = 0, len = relateds.length; i < len; i++) {
	        related = relateds[i];
	        if (!related.isLoaded()) {
	          model.setLoaded(this.key, false);
	          break;
	        }
	      }
	    }
	    if (this.join_table) {
	      return Utils.each(related_ids, ((function(_this) {
	        return function(related_id, callback) {
	          var add, query;
	          if (!related_id) {
	            return callback(new Error("Many.patchAdd: cannot add an new model. Please save first."));
	          }
	          add = function(callback) {
	            var attributes;
	            (attributes = {})[_this.foreign_key] = model.id;
	            attributes[_this.reverse_relation.foreign_key] = related_id;
	            return _this.join_table.exists(attributes, function(err, exists) {
	              if (err) {
	                return callback(err);
	              }
	              if (exists) {
	                return callback(new Error("Join already exists: " + (JSON.stringify(attributes))));
	              }
	              return new _this.join_table(attributes).save(callback);
	            });
	          };
	          if (_this.reverse_relation.type === 'hasMany') {
	            return add(callback);
	          }
	          (query = {
	            $one: true
	          })[_this.reverse_relation.foreign_key] = related_id;
	          return _this.join_table.cursor(query).toJSON(function(err, join_table_json) {
	            if (err) {
	              return callback(err);
	            }
	            if (!join_table_json) {
	              return add(callback);
	            }
	            if (join_table_json[_this.foreign_key] === model.id) {
	              return callback();
	            }
	            join_table_json[_this.foreign_key] = model.id;
	            return Utils.modelJSONSave(join_table_json, _this.join_table, callback);
	          });
	        };
	      })(this)), callback);
	    } else {
	      query = {
	        id: {
	          $in: related_ids
	        }
	      };
	      return this.reverse_model_type.cursor(query).toJSON((function(_this) {
	        return function(err, related_jsons) {
	          return Utils.each(related_jsons, (function(related_json, callback) {
	            related_json[_this.reverse_relation.foreign_key] = model.id;
	            return Utils.modelJSONSave(related_json, _this.reverse_model_type, callback);
	          }), callback);
	        };
	      })(this));
	    }
	  };

	  Many.prototype.patchRemove = function(model, relateds, callback) {
	    var cache, collection, i, j, json, k, len, len1, len2, query, ref, ref1, ref2, related, related_ids, related_model, related_models;
	    if (arguments.length === 2) {
	      ref = [null, relateds], relateds = ref[0], callback = ref[1];
	    }
	    if (!model.id) {
	      return callback(new Error("Many.patchRemove: model has null id for: " + this.key));
	    }
	    if (arguments.length === 2) {
	      if (!this.reverse_relation) {
	        return callback();
	      }
	      if (Utils.isModel(model)) {
	        delete Utils.orSet(model, 'rel_dirty', {})[this.key];
	        collection = this._ensureCollection(model);
	        related_models = _.clone(collection.models);
	      } else {
	        related_models = (function() {
	          var i, len, ref1, results;
	          ref1 = model[this.key] || [];
	          results = [];
	          for (i = 0, len = ref1.length; i < len; i++) {
	            json = ref1[i];
	            results.push(new this.reverse_model_type(json));
	          }
	          return results;
	        }).call(this);
	      }
	      for (i = 0, len = related_models.length; i < len; i++) {
	        related_model = related_models[i];
	        if (((ref1 = related_model.get(this.foreign_key)) != null ? ref1.id : void 0) === model.id) {
	          related_model.set(this.foreign_key, null);
	        }
	        if (cache = related_model.cache()) {
	          cache.set(related_model.id, related_model);
	        }
	      }
	      if (this.embed) {
	        return callback();
	      }
	      if (this.join_table) {
	        (query = {})[this.join_key] = model.id;
	        return this.join_table.destroy(query, callback);
	      } else if (this.type === 'belongsTo') {
	        this.model_type.cursor({
	          id: model.id,
	          $one: true
	        }).toJSON((function(_this) {
	          return function(err, model_json) {
	            if (err) {
	              return callback(err);
	            }
	            if (!model_json) {
	              return callback();
	            }
	            model_json[_this.foreign_key] = null;
	            return Utils.modelJSONSave(model_json, _this.model_type, callback);
	          };
	        })(this));
	      } else {
	        (query = {})[this.reverse_relation.foreign_key] = model.id;
	        this.reverse_model_type.cursor(query).toJSON((function(_this) {
	          return function(err, json) {
	            if (err) {
	              return callback(err);
	            }
	            return Utils.each(json, (function(related_json, callback) {
	              related_json[_this.reverse_relation.foreign_key] = null;
	              return Utils.modelJSONSave(related_json, _this.reverse_model_type, callback);
	            }), callback);
	          };
	        })(this));
	      }
	      return;
	    }
	    if (!relateds) {
	      return callback(new Error('Many.patchRemove: missing model for remove'));
	    }
	    if (!_.isArray(relateds)) {
	      relateds = [relateds];
	    }
	    collection = this._ensureCollection(model);
	    for (j = 0, len1 = relateds.length; j < len1; j++) {
	      related = relateds[j];
	      ref2 = collection.models;
	      for (k = 0, len2 = ref2.length; k < len2; k++) {
	        related_model = ref2[k];
	        if (Utils.dataIsSameModel(related_model, related)) {
	          collection.remove(related_model);
	          break;
	        }
	      }
	    }
	    related_ids = (function() {
	      var l, len3, results;
	      results = [];
	      for (l = 0, len3 = relateds.length; l < len3; l++) {
	        related = relateds[l];
	        results.push(Utils.dataId(related));
	      }
	      return results;
	    })();
	    if (this.embed) {
	      return callback();
	    }
	    if (this.join_table) {
	      query = {};
	      query[this.join_key] = model.id;
	      query[this.reverse_relation.join_key] = {
	        $in: related_ids
	      };
	      return this.join_table.destroy(query, callback);
	    } else if (this.type === 'belongsTo') {
	      return this.model_type.cursor({
	        id: model.id,
	        $one: true
	      }).toJSON((function(_this) {
	        return function(err, model_json) {
	          if (err) {
	            return callback(err);
	          }
	          if (!model_json) {
	            return callback();
	          }
	          if (!_.contains(related_ids, model_json[_this.foreign_key])) {
	            return callback();
	          }
	          model_json[_this.foreign_key] = null;
	          return Utils.modelJSONSave(model_json, _this.model_type, callback);
	        };
	      })(this));
	    } else {
	      query = {};
	      query[this.reverse_relation.foreign_key] = model.id;
	      query.id = {
	        $in: related_ids
	      };
	      return this.reverse_model_type.cursor(query).toJSON((function(_this) {
	        return function(err, json) {
	          if (err) {
	            return callback(err);
	          }
	          return Utils.each(json, (function(related_json, callback) {
	            if (related_json[_this.reverse_relation.foreign_key] !== model.id) {
	              return callback();
	            }
	            related_json[_this.reverse_relation.foreign_key] = null;
	            return Utils.modelJSONSave(related_json, _this.reverse_model_type, callback);
	          }), callback);
	        };
	      })(this));
	    }
	  };

	  Many.prototype.cursor = function(model, key, query) {
	    var json;
	    json = Utils.isModel(model) ? model.attributes : model;
	    (query = _.clone(query || {}))[this.join_table ? this.join_key : this.reverse_relation.foreign_key] = json[this.model_type.prototype.idAttribute];
	    if (key === this.virtual_id_accessor) {
	      (query.$values || (query.$values = [])).push('id');
	    }
	    return this.reverse_model_type.cursor(query);
	  };

	  Many.prototype._bindBacklinks = function(model) {
	    var collection, events, i, len, method, ref;
	    if ((collection = model.attributes[this.key]) instanceof this.collection_type) {
	      return collection;
	    }
	    collection = model.attributes[this.key] = new this.collection_type();
	    if (!this.reverse_relation) {
	      return collection;
	    }
	    events = Utils.set(collection, 'events', {});
	    events.add = (function(_this) {
	      return function(related_model) {
	        var current_model, is_current;
	        if (_this.reverse_relation.add) {
	          return _this.reverse_relation.add(related_model, model);
	        } else {
	          current_model = related_model.get(_this.reverse_relation.key);
	          is_current = model.id && (Utils.dataId(current_model) === model.id);
	          if (!is_current || (is_current && !current_model.isLoaded())) {
	            return related_model.set(_this.reverse_relation.key, model);
	          }
	        }
	      };
	    })(this);
	    events.remove = (function(_this) {
	      return function(related_model) {
	        var current_model;
	        Utils.orSet(model, 'rel_dirty', {})[_this.key] = true;
	        if (_this.reverse_relation.remove) {
	          return _this.reverse_relation.remove(related_model, model);
	        } else {
	          current_model = related_model.get(_this.reverse_relation.key);
	          if (Utils.dataId(current_model) === model.id) {
	            return related_model.set(_this.reverse_relation.key, null);
	          }
	        }
	      };
	    })(this);
	    events.reset = (function(_this) {
	      return function(collection, options) {
	        var added, changes, current_models, i, j, len, len1, previous_models, ref, related_model;
	        Utils.orSet(model, 'rel_dirty', {})[_this.key] = true;
	        current_models = collection.models;
	        previous_models = options.previousModels || [];
	        changes = _.groupBy(previous_models, function(test) {
	          if (!!_.find(current_models, function(current_model) {
	            return current_model.id === test.id;
	          })) {
	            return 'kept';
	          } else {
	            return 'removed';
	          }
	        });
	        added = changes.kept ? _.select(current_models, function(test) {
	          return !_.find(changes.kept, function(keep_model) {
	            return keep_model.id === test.id;
	          });
	        }) : current_models;
	        if (changes.removed) {
	          ref = changes.removed;
	          for (i = 0, len = ref.length; i < len; i++) {
	            related_model = ref[i];
	            events.remove(related_model);
	          }
	        }
	        for (j = 0, len1 = added.length; j < len1; j++) {
	          related_model = added[j];
	          events.add(related_model);
	        }
	      };
	    })(this);
	    ref = ['add', 'remove', 'reset'];
	    for (i = 0, len = ref.length; i < len; i++) {
	      method = ref[i];
	      collection.on(method, events[method]);
	    }
	    return collection;
	  };

	  Many.prototype._unbindBacklinks = function(model) {
	    var collection, events, i, len, method, ref;
	    if (!(events = Utils.get(model, 'events'))) {
	      return;
	    }
	    Utils.unset(model, 'events');
	    collection = model.attributes[this.key];
	    collection.models.splice();
	    ref = ['add', 'remove', 'reset'];
	    for (i = 0, len = ref.length; i < len; i++) {
	      method = ref[i];
	      collection.off(method, events[method]);
	      events[method] = null;
	    }
	  };

	  Many.prototype._ensureCollection = function(model) {
	    return this._bindBacklinks(model);
	  };

	  Many.prototype._hasChanged = function(model) {
	    return !!Utils.orSet(model, 'rel_dirty', {})[this.key] || model.hasChanged(this.key);
	  };

	  return Many;

	})(__webpack_require__(45));


/***/ },
/* 47 */
/***/ function(module, exports, __webpack_require__) {

	
	/*
	  backbone-orm.js 0.7.14
	  Copyright (c) 2013-2016 Vidigami
	  License: MIT (http://www.opensource.org/licenses/mit-license.php)
	  Source: https://github.com/vidigami/backbone-orm
	  Dependencies: Backbone.js and Underscore.js.
	 */
	var BackboneORM, CAPABILITIES, DESTROY_BATCH_LIMIT, JSONUtils, MemoryCursor, MemorySync, Queue, Schema, Utils, _,
	  bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

	_ = __webpack_require__(1);

	BackboneORM = __webpack_require__(3);

	Queue = __webpack_require__(11);

	MemoryCursor = __webpack_require__(23);

	Schema = __webpack_require__(43);

	Utils = __webpack_require__(24);

	JSONUtils = __webpack_require__(33);

	DESTROY_BATCH_LIMIT = 2000;

	CAPABILITIES = {
	  embed: true,
	  json: true,
	  unique: true,
	  manual_ids: true,
	  dynamic: true,
	  self_reference: true
	};

	MemorySync = (function() {
	  function MemorySync(model_type1) {
	    var base, ref;
	    this.model_type = model_type1;
	    this.deleteCB = bind(this.deleteCB, this);
	    this.model_type.model_name = Utils.findOrGenerateModelName(this.model_type);
	    this.schema = new Schema(this.model_type);
	    if (!((ref = this.schema.field('id')) != null ? ref.type : void 0)) {
	      this.schema.type('id', 'Integer');
	    }
	    this.store = (base = this.model_type).store || (base.store = []);
	    this.id = 0;
	    this.id_attribute = this.model_type.prototype.idAttribute;
	  }

	  MemorySync.prototype.initialize = function() {
	    var ref;
	    if (this.is_initialized) {
	      return;
	    }
	    this.is_initialized = true;
	    this.schema.initialize();
	    if ((ref = this.schema.field('id')) != null ? ref.manual : void 0) {
	      this.manual_id = true;
	    }
	    return this.id_type = this.schema.idType();
	  };

	  MemorySync.prototype.read = function(model, options) {
	    var model_json;
	    if (model.models) {
	      return options.success((function() {
	        var i, len, ref, results;
	        ref = this.store;
	        results = [];
	        for (i = 0, len = ref.length; i < len; i++) {
	          model_json = ref[i];
	          results.push(JSONUtils.deepClone(model_json));
	        }
	        return results;
	      }).call(this));
	    } else {
	      if (!(model_json = this.get(model.id))) {
	        return options.error(new Error("Model not found with id: " + model.id));
	      }
	      return options.success(JSONUtils.deepClone(model_json));
	    }
	  };

	  MemorySync.prototype.create = function(model, options) {
	    var model_json;
	    if (this.manual_id) {
	      return options.error(new Error("Create should not be called for a manual id. Set an id before calling save. Model name: " + this.model_type.model_name + ". Model: " + (JSONUtils.stringify(model.toJSON()))));
	    }
	    model.set(this.id_attribute, this.id_type === 'String' ? "" + (++this.id) : ++this.id);
	    this.store.splice(this.insertIndexOf(model.id), 0, model_json = model.toJSON());
	    return options.success(JSONUtils.deepClone(model_json));
	  };

	  MemorySync.prototype.update = function(model, options) {
	    var create, index, model_json;
	    create = (index = this.insertIndexOf(model.id)) >= this.store.length || this.store[index].id !== model.id;
	    if (!this.manual_id && create) {
	      return options.error(new Error("Update cannot create a new model without manual option. Set an id before calling save. Model name: " + this.model_type.model_name + ". Model: " + (JSONUtils.stringify(model.toJSON()))));
	    }
	    model_json = model.toJSON();
	    if (create) {
	      this.store.splice(index, 0, model_json);
	    } else {
	      this.store[index] = model_json;
	    }
	    return options.success(JSONUtils.deepClone(model_json));
	  };

	  MemorySync.prototype["delete"] = function(model, options) {
	    return this.deleteCB(model, (function(_this) {
	      return function(err) {
	        if (err) {
	          return options.error(err);
	        } else {
	          return options.success();
	        }
	      };
	    })(this));
	  };

	  MemorySync.prototype.deleteCB = function(model, callback) {
	    var index, model_json;
	    if ((index = this.indexOf(model.id)) < 0) {
	      return callback(new Error("Model not found. Type: " + this.model_type.model_name + ". Id: " + model.id));
	    }
	    model_json = this.store.splice(index, 1);
	    return Utils.patchRemove(this.model_type, model, callback);
	  };

	  MemorySync.prototype.resetSchema = function(options, callback) {
	    return this.destroy(callback);
	  };

	  MemorySync.prototype.cursor = function(query) {
	    if (query == null) {
	      query = {};
	    }
	    return new MemoryCursor(query, _.pick(this, ['model_type', 'store']));
	  };

	  MemorySync.prototype.destroy = function(query, callback) {
	    var cursor, is_done, next, ref;
	    if (arguments.length === 1) {
	      ref = [{}, query], query = ref[0], callback = ref[1];
	    }
	    if (JSONUtils.isEmptyObject(query)) {
	      return Utils.popEach(this.store, ((function(_this) {
	        return function(model_json, callback) {
	          return Utils.patchRemove(_this.model_type, model_json, callback);
	        };
	      })(this)), callback);
	    } else {
	      is_done = false;
	      cursor = this.model_type.cursor(query).limit(DESTROY_BATCH_LIMIT);
	      next = (function(_this) {
	        return function() {
	          return cursor.toJSON(function(err, models_json) {
	            if (err) {
	              return callback(err);
	            }
	            if (models_json.length === 0) {
	              return callback();
	            }
	            is_done = models_json.length < DESTROY_BATCH_LIMIT;
	            return Utils.each(models_json, _this.deleteCB, function(err) {
	              if (err || is_done) {
	                return callback(err);
	              } else {
	                return next();
	              }
	            });
	          });
	        };
	      })(this);
	      return next();
	    }
	  };

	  MemorySync.prototype.get = function(id) {
	    var index, model;
	    if ((index = _.sortedIndex(this.store, {
	      id: id
	    }, this.id_attribute)) >= this.store.length || (model = this.store[index]).id !== id) {
	      return null;
	    } else {
	      return model;
	    }
	  };

	  MemorySync.prototype.indexOf = function(id) {
	    var index;
	    if ((index = _.sortedIndex(this.store, {
	      id: id
	    }, this.id_attribute)) >= this.store.length || this.store[index].id !== id) {
	      return -1;
	    } else {
	      return index;
	    }
	  };

	  MemorySync.prototype.insertIndexOf = function(id) {
	    return _.sortedIndex(this.store, {
	      id: id
	    }, this.id_attribute);
	  };

	  return MemorySync;

	})();

	module.exports = function(type) {
	  var model_type, sync, sync_fn;
	  if (Utils.isCollection(new type())) {
	    model_type = Utils.configureCollectionModelType(type, module.exports);
	    return type.prototype.sync = model_type.prototype.sync;
	  }
	  sync = new MemorySync(type);
	  type.prototype.sync = sync_fn = function(method, model, options) {
	    if (options == null) {
	      options = {};
	    }
	    sync.initialize();
	    if (method === 'createSync') {
	      return module.exports.apply(null, Array.prototype.slice.call(arguments, 1));
	    }
	    if (method === 'sync') {
	      return sync;
	    }
	    if (method === 'isRemote') {
	      return false;
	    }
	    if (method === 'schema') {
	      return sync.schema;
	    }
	    if (method === 'tableName') {
	      return void 0;
	    }
	    if (sync[method]) {
	      return sync[method].apply(sync, Array.prototype.slice.call(arguments, 1));
	    } else {
	      return void 0;
	    }
	  };
	  Utils.configureModelType(type);
	  return BackboneORM.model_cache.configureSync(type, sync_fn);
	};

	module.exports.Sync = MemorySync;

	module.exports.Cursor = MemoryCursor;

	module.exports.capabilities = function(url) {
	  return CAPABILITIES;
	};


/***/ },
/* 48 */
/***/ function(module, exports) {

	var TestUtils;

	module.exports = TestUtils = (function() {
	  function TestUtils() {}

	  TestUtils.optionSets = function() {
	    return [
	      {
	        'cache': false,
	        'embed': false,
	        '$tags': '@no_cache @no_embed @quick'
	      }, {
	        'cache': true,
	        'embed': false,
	        '$tags': '@cache @no_embed'
	      }, {
	        'cache': false,
	        'embed': true,
	        '$tags': '@no_cache @embed'
	      }, {
	        'cache': true,
	        'embed': true,
	        '$tags': '@cache @embed'
	      }
	    ];
	  };

	  return TestUtils;

	})();


/***/ },
/* 49 */
/***/ function(module, exports, __webpack_require__) {

	var Fabricator, Queue, _;

	_ = __webpack_require__(1);

	Queue = __webpack_require__(11);

	module.exports = Fabricator = (function() {
	  function Fabricator() {}

	  Fabricator["new"] = function(model_type, count, attributes_info) {
	    var attributes, key, results, value;
	    results = [];
	    while (count-- > 0) {
	      attributes = {};
	      for (key in attributes_info) {
	        value = attributes_info[key];
	        attributes[key] = _.isFunction(value) ? value() : value;
	      }
	      results.push(new model_type(attributes));
	    }
	    return results;
	  };

	  Fabricator.create = function(model_type, count, attributes_info, callback) {
	    var fn, i, len, model, models, queue;
	    models = Fabricator["new"](model_type, count, attributes_info);
	    queue = new Queue();
	    fn = function(model) {
	      return queue.defer(function(callback) {
	        return model.save(callback);
	      });
	    };
	    for (i = 0, len = models.length; i < len; i++) {
	      model = models[i];
	      fn(model);
	    }
	    return queue.await(function(err) {
	      return callback(err, models);
	    });
	  };

	  Fabricator.value = function(value) {
	    if (arguments.length === 0) {
	      return void 0;
	    }
	    return function() {
	      return value;
	    };
	  };

	  Fabricator.increment = function(value) {
	    if (arguments.length === 0) {
	      return void 0;
	    }
	    return function() {
	      return value++;
	    };
	  };

	  Fabricator.uniqueId = function(prefix) {
	    if (arguments.length === 0) {
	      return _.uniqueId();
	    }
	    return function() {
	      return _.uniqueId(prefix);
	    };
	  };

	  Fabricator.uniqueString = Fabricator.uniqueId;

	  Fabricator.date = function(start, step_ms) {
	    var current_ms, now, ref;
	    now = new Date();
	    if (arguments.length === 0) {
	      return now;
	    }
	    if (arguments.length === 1) {
	      ref = [now, start], start = ref[0], step_ms = ref[1];
	    }
	    current_ms = start.getTime();
	    return function() {
	      var current;
	      current = new Date(current_ms);
	      current_ms += step_ms;
	      return current;
	    };
	  };

	  return Fabricator;

	})();


/***/ },
/* 50 */
/***/ function(module, exports, __webpack_require__) {

	
	/*
	  backbone-orm.js 0.7.14
	  Copyright (c) 2013-2016 Vidigami
	  License: MIT (http://www.opensource.org/licenses/mit-license.php)
	  Source: https://github.com/vidigami/backbone-orm
	  Dependencies: Backbone.js and Underscore.js.
	 */
	var MemoryStore;

	MemoryStore = __webpack_require__(12);

	module.exports = new MemoryStore({
	  destroy: function(url, connection) {
	    return connection.destroy();
	  }
	});


/***/ },
/* 51 */
/***/ function(module, exports, __webpack_require__) {

	
	/*
	  backbone-orm.js 0.7.14
	  Copyright (c) 2013-2016 Vidigami
	  License: MIT (http://www.opensource.org/licenses/mit-license.php)
	  Source: https://github.com/vidigami/backbone-orm
	  Dependencies: Backbone.js and Underscore.js.
	 */
	var Backbone, major, minor, ref;

	Backbone = __webpack_require__(3).Backbone;

	ref = Backbone.VERSION.split('.'), major = ref[0], minor = ref[1];

	if ((+major >= 1) && (+minor >= 2)) {
	  
	  // Internal method called by both remove and set.
	  // Returns removed models, or false if nothing is removed.
	  Backbone.Collection.prototype._removeModels = function(models, options) {
	    var removed = [];
	    for (var i = 0; i < models.length; i++) {
	      var model = this.get(models[i]);
	      if (!model) continue;

	      // MONKEY PATCH
	      var id = this.modelId(model.attributes);
	      if (id != null) delete this._byId[id];
	      delete this._byId[model.cid];

	      var index = this.indexOf(model);
	      this.models.splice(index, 1);
	      this.length--;

	      if (!options.silent) {
	        options.index = index;
	        model.trigger('remove', model, this, options);
	      }

	      removed.push(model);
	      this._removeReference(model, options);
	    }
	    return removed.length ? removed : false;
	  }
	  ;
	}


/***/ }
/******/ ])
});
;