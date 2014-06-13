angular.module('main', [])
.run(function($templateCache){
    $templateCache.put('main', '<div class="main"></div>');
});
angular.module('main.nav', [])
.run(function($templateCache){
    $templateCache.put('main/nav', '<nav role="navigation"></nav>');
});