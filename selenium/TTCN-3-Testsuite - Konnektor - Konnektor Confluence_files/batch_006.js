WRMCB=function(e){var c=console;if(c&&c.log&&c.error){c.log('Error running batched script.');c.error(e);}}
;
try {
/* module-key = 'com.atlassian.confluence.plugins.confluence-sortable-tables:sortable-table-resources', location = 'js/SortableTables.js' */
define("confluence-sortable-tables/sortable-tables",["jquery","ajs","document","confluence-sortable-tables/hooks"],function(c,f,h,i){function j(){var a=f.Meta.get("date.format"),b;a&&0!==a.length&&(a=a.toLowerCase()[0],"m"===a?b="mmddyyyy":"d"===a?b="ddmmyyyy":"y"===a&&(b="yyyymmdd"));return b}var g;return{init:function(){g=c("table").filter(function(){var a=c(this),b=a.find("td, th"),e=this.rows.length&&c(this.rows[0].cells),d;if("false"===a.attr("data-sortable")||-1<this.className.indexOf("tablesorter"))return!1;
d=c.Event("makeSortable.SortableTables");a.trigger(d);if(d.isDefaultPrevented()||!e||0===e.length)return!1;d=0;for(var f=b.length;d<f;d++)if(a=b[d],1!=a.rowSpan||1!=a.colSpan)return!1;return c(this.rows[0]).find("table").length||e.filter("th").length!==e.length||e.hasClass("nohighlight")?!1:this.rows[1]})},enable:function(){g.each(function(){if(-1<this.className.indexOf("tablesorter")||c(this).find("> thead:first").is(":visible"))return!0;var a=this.removeChild(this.tBodies[0]),b=c(a.children),b=
Array.prototype.shift.call(b),e=h.createDocumentFragment(),d=h.createElement("thead");e.appendChild(d);d.appendChild(b);e.appendChild(a);this.appendChild(e)});i.beforeInitHooks().forEach(function(a){if(a&&"function"===typeof a)try{a(c.tablesorter)}catch(b){f.info("Failed to run tablesorter beforeInit hook.",b)}});g.tablesorter({cssHeader:"sortableHeader",delayInit:!0,textExtraction:function(a){return f.trim(c(a).text())},dateFormat:j()})},refresh:function(){this.init();this.enable()}}});
require("confluence/module-exporter").safeRequire("confluence-sortable-tables/sortable-tables",function(c){require("ajs").toInit(function(){c.init();setTimeout(c.enable,100)})});
}catch(e){WRMCB(e)};