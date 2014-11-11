angular.module('main.template', []).run(function($templateCache){$templateCache.put('main', '<div class="main cascade"></div>');});
angular.module('main.content.template', []).run(function($templateCache){$templateCache.put('main/content', '<p>This is some text.\nSpread across two lines.</p>');});
angular.module('main.login.html.template', []).run(function($templateCache){$templateCache.put('main/login.html', '<div><form><input type="email" /></form></div>');});
angular.module('main.nav.template', []).run(function($templateCache){$templateCache.put('main/nav', '<nav role="navigation"></nav>');});
