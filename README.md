html2canvas-proxy-csharp 0.0.5
=====================

#### C# Proxy html2canvas ####

This script allows you to use **html2canvas.js** with different servers, ports and protocols (http, https),
preventing to occur "tainted" when exporting the `<canvas>` for image.

### Others scripting language ###

You do not use ASP.NET, but need html2canvas working with proxy, see other proxies:

* [html2canvas proxy in php](https://github.com/brcontainer/html2canvas-php-proxy)
* [html2canvas proxy in asp classic (vbscript)](https://github.com/brcontainer/html2canvas-asp-vbscript-proxy)
* [html2canvas proxy in python (work any framework)](https://github.com/brcontainer/html2canvas-proxy-python)

###Problem and Solution###
When adding an image that belongs to another domain in `<canvas>` and after that try to export the canvas
for a new image, a security error occurs (actually occurs is a security lock), which can return the error:

> SecurityError: DOM Exception 18
>
> Error: An attempt was made to break through the security policy of the user agent.

### Follow ###

I ask you to follow me or "star" my repository to track updates

### Usage ###

```html
<!DOCTYPE html>
<html>
    <head>
        <meta charset="utf-8">
        <title>html2canvas ashx (c#) proxy</title>
        <script src="html2canvas.js"></script>
		<script>
		//<![CDATA[
		(function() {
			window.onload = function() {
				html2canvas(document.body, {
					"logging": true, //Enable log (use Web Console for get Errors and Warings)
					"proxy":"html2canvasproxy.ashx",
					"onrendered": function(canvas) {
			                        var img = new Image();
			                        img.onload = function() {
			                            document.body.appendChild(img);
			                        };
			                        img.error = function() {
			                            if(window.console.log) {
			                                window.console.log("Not loaded image from canvas.toDataURL");
			                            } else {
			                                alert("Not loaded image from canvas.toDataURL");
			                            }
			                        };
			                        img.src = canvas.toDataURL("image/png");
					}
				});
			};
		})();
		//]]>
		</script>
    </head>
    <body>
        <p>
            <img alt="google maps static" src="http://maps.googleapis.com/maps/api/staticmap?center=40.714728,-73.998672&amp;zoom=12&amp;size=400x400&amp;maptype=roadmap&amp;sensor=false">
        </p>
    </body>
</html>
```

#### Using Web Console ####

If you have any problems with the script recommend to analyze the log using the Web Console from your browser:
* Firefox: https://developer.mozilla.org/en-US/docs/Tools/Browser_Console
* Chrome: https://developers.google.com/chrome-developer-tools/docs/console
* InternetExplorer: http://msdn.microsoft.com/en-us/library/gg589530%28v=vs.85%29.aspx

Get NetWork results:
* Firefox: https://hacks.mozilla.org/2013/05/firefox-developer-tool-features-for-firefox-23/
* Chrome: https://developers.google.com/chrome-developer-tools/docs/network
* InternetExplorer: http://msdn.microsoft.com/en-us/library/gg130952%28v=vs.85%29.aspx

An alternative is to diagnose problems accessing the link directly:

`http://[DOMAIN]/[PATH]/html2canvasproxy.php?url=http%3A%2F%2Fmaps.googleapis.com%2Fmaps%2Fapi%2Fstaticmap%3Fcenter%3D40.714728%2C-73.998672%26zoom%3D12%26size%3D800x600%26maptype%3Droadmap%26sensor%3Dfalse%261&callback=html2canvas_0`

Replace `[DOMAIN]` by your domain (eg. 127.0.0.1) and replace `[PATH]` by your project folder (eg. project-1/test), something like:

`http://localhost/project-1/test/html2canvasproxy.php?url=http%3A%2F%2Fmaps.googleapis.com%2Fmaps%2Fapi%2Fstaticmap%3Fcenter%3D40.714728%2C-73.998672%26zoom%3D12%26size%3D800x600%26maptype%3Droadmap%26sensor%3Dfalse%261&callback=html2canvas_0`

### .NET Framework compatibility ###
From version 0.0.4 has become the code compatible with older versions of the .net framework, being compatible with version .net framework 2.0+

### Alternatives for C#(C Sharp) ###
You are not using html2canvas but need a similar solution?
See **simpleHttpProxy**:

*c#* https://github.com/brcontainer/simple-http-proxy-csharp

### Changlog ###

#### html2canvas-csharp-proxy 0.0.5 ####

 * Added support to HTTP Basic access authentication 
 * Added support to use data URI scheme in callback
 * Added support to SVG images
 * Added support to requests/response without "Content-Length"
 * Added detection if the "Content-Length" header is equal to "0" (Content-Length: 0)
 * Moved "setup vars" to "Class"
 * Removed unecessary "fullurl = fullurl"
 * Removed "must-revalidate" header
 * Remove charset in "mimetype"
 * Fixed bug in detecting if "callback" and "url" are undefined (GET params)
