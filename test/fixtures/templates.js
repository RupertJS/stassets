angular.module('main.template', [])
.run(function($templateCache){
    $templateCache.put('main/template', '<div class="main"></div>');
});
angular.module('main.nav.template', [])
.run(function($templateCache){
    $templateCache.put('main/nav/template', '<nav role="navigation"></nav>');
});