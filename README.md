html2canvas-proxy-csharp 0.0.4
=====================

#### C# Proxy html2canvas ####


This script allows you to use **html2canvas.js** with different servers, ports and protocols (http, https),
preventing to occur "tainted" when exporting the `<canvas>` for image.

###Problem and Solution###
When adding an image that belongs to another domain in `<canvas>` and after that try to export the canvas
for a new image, a security error occurs (actually occurs is a security lock), which can return the error:

> SecurityError: DOM Exception 18
>
> Error: An attempt was made to break through the security policy of the user agent.

### Usage ###

```html
<!DOCTYPE html>
<html>
    <head>
        <meta charset="utf-8">
        <title>html2canvas ashx (c#) proxy</title>
        <script src="html2canvas.js"></script>
        <script>
        window.onload = function(){
          html2canvas( [ document.body ], {
                "proxy":"html2canvasproxy.ashx",
                "onrendered": function(canvas) {
                    var uridata = canvas.toDataURL("image/png");
                    window.open(uridata);
                }
            });
        };
        </script>
    </head>
    <body>
        <p>
            <img alt="google maps static" src="http://maps.googleapis.com/maps/api/staticmap?center=40.714728,-73.998672&zoom=12&size=400x400&maptype=roadmap&sensor=false">
        </p>
    </body>
</html>
```

### .NET Framework compatibility ###
From version 0.0.4 has become the code compatible with older versions of the .net framework, being compatible with version .net framework 2.0+

### Alternatives for C#(C Sharp) ###
You are not using html2canvas but need a similar solution?
See **simpleHttpProxy**:

*c#* https://github.com/brcontainer/simple-http-proxy-csharp



### Others scripting language ###

You do not use PHP, but need html2canvas working with proxy, see other proxies:

* [html2canvas proxy in php](https://github.com/brcontainer/html2canvas-php-proxy)
* [html2canvas proxy in asp classiv (vbscript)](https://github.com/brcontainer/html2canvas-asp-vbscript-proxy)
