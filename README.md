html2canvas-proxy-php 0.0.1
=====================

#### PHP Proxy html2canvas ( php 5.0+ ) ####

This script allows you to use html2canvas.js with different servers, ports and protocols (http, https), preventing to occur "tainted" when exporting the "canvas" for image.

### Usage ###

```javascript
html2canvas( [ document.body ], {
    "proxy":"html2canvasproxy.ashx",
	"useCORS":true,
	"onrendered": function(canvas) {
		var uridata = canvas.toDataURL("image/jpeg");
		window.open(uridata);
	}
});
```
