(function() {
  angular.module('stassets.main', ['stassets.main.controller', 'main.template']);

}).call(this);

(function() {
  var MainCtrl;

  MainCtrl = (function() {
    function MainCtrl() {}

    return MainCtrl;

  })();

  angular.module('stassets.main.controller', []).controller('MainCtrl', MainCtrl);

}).call(this);

angular.module('stassets.main.nav.service', [
]).service('NavSvc', function NavSvc(){
    this.started = new Date();
});

(function() {
  angular.module('stassets.main.nav.directive', ['main.nav.template']);

}).call(this);
