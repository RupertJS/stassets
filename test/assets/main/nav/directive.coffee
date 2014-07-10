angular.module('stassets.main.nav.directive', [
    'main.nav.template'
    'main.nav.service'
]).directive 'stassetNav', ->
    restrict: 'AE'
    templateUrl: 'main/nav'
