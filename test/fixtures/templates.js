angular.module('main.template', [])
.run(function($templateCache){
    $templateCache.put('main', '<div class="main"></div>');
});
angular.module('main.nav.template', [])
.run(function($templateCache){
    $templateCache.put('main/nav', '<nav role="navigation"></nav>');
});