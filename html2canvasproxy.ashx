<%@ WebHandler Language="C#" Debug="true" Class="Html2CanvasProxy" %>
/*
 * html2canvas-csharp-proxy 0.0.6
 * Copyright (c) 2014 Guilherme Nascimento (brcontainer@yahoo.com.br)
 * 
 * Released under the MIT license
 */

using System;
using System.IO;
using System.Web;
using System.Net;
using System.Text;
using System.Security.Cryptography;
using System.Text.RegularExpressions;

public class Html2CanvasProxy : IHttpHandler {
    //Setup
    private string defaultCallback = "console.log";  //Set default callback
    private string PATH = "images";                  //Path relative
    private int CCACHE = 60 * 5 * 1000;              //Limit access-control and cache
    private bool CROSSDOMAIN = false;                //Enable cross-domain for use proxy with a sub-domain

    private static string JsonEncodeString (string s, bool onlyEncode) {
        string[] vetor = new string[127];
        vetor[0]  = "\\0";
        vetor[8]  = "\\b";
        vetor[9]  = "\\t";
        vetor[10] = "\\n";
        vetor[12] = "\\f";
        vetor[13] = "\\r";
        vetor[34] = "\\\"";
        vetor[47] = "\\/";
        vetor[92] = "\\";

        int i = 0;
        int c;
        string d;
        string[] e = new string[s.Length];

        foreach (string j in e) {
            e[i] = s.Substring(i, 1);
            c = (int) Convert.ToChar(e[i]);
            if (c > 126) {
                d = "000" + c.ToString("X");
                e[i] = "\\u" + d.Substring(d.Length - 4);
            } else {
                if (!String.IsNullOrEmpty(vetor[c])) {
                    e[i] = vetor[c];
                } else if (!(c > 31)) {
                    d = "000" + c.ToString("X");
                    e[i] = "\\u" + d.Substring(d.Length - 4);
                }
            }
            i++;
        }

        if (onlyEncode) {
            return String.Join("", e);
        } else {
            return "\"" + String.Join("", e) + "\"";
        }
    }

    private static string Ascii2Inline (string str) {
        string[] x = {
            "\n",
            "\r",
            " ",
            "\"",
            "#",
            "&",
            "/",
            "\\",
            ":",
            "?",
            "\0",
            "\b",
            "\t"
        };

        string[] y = {
            "%0A",
            "%0D",
            "%20",
            "%22",
            "%23",
            "%26",
            "%2F",
            "%5C",
            "%3A",
            "%3F",
            "%00",
            "",
            "%09"
        };

        int i = 0;

        foreach (string j in x) {
            str = str.Replace(j, y[i]);
            i++;
        }
        return str;
    }

    private static string ReadFileEnconding (string file, bool base64) {
        FileStream fs = new FileStream(file, FileMode.Open, FileAccess.Read);

        byte[] filebytes = new byte[fs.Length];

        fs.Read(filebytes, 0, Convert.ToInt32(fs.Length));
        fs.Close();

        if (base64) {
            return Convert.ToBase64String(filebytes);
        }
        return Html2CanvasProxy.Ascii2Inline(System.Text.Encoding.Default.GetString(filebytes));
    }

    public void ProcessRequest (HttpContext context) {
        string GMDATECACHE = DateTime.UtcNow.ToString();
        string ERR = "";
        string MIME = "";
        string CHARSET = "";
        string[] tmp;
        string[] makeAdress;
        string username = "";
        string password = "";
        string httpType = "http";
        string basicAuth = "";

        HttpResponse HS = context.Response;

        //set access-control
        HS.AddHeader("Access-Control-Max-Age", CCACHE.ToString());
        HS.AddHeader("Access-Control-Allow-Origin", "*");
        HS.AddHeader("Access-Control-Request-Method", "*");
        HS.AddHeader("Access-Control-Allow-Methods", "OPTIONS, GET");
        HS.AddHeader("Access-Control-Allow-Headers", "*");

        //mime
        HS.ContentType = "application/javascript";

        //GET
        string geturl = context.Request.QueryString["url"];
        string getcallback = context.Request.QueryString["callback"];

        if (getcallback == "" || getcallback == null) {
            ERR = "get param callback is undefined";
            getcallback = defaultCallback;
        } else if (geturl == "" || geturl == null) {
            ERR = "get param url is undefined";
        } else {
            string realpath = HttpContext.Current.Server.MapPath("./" + PATH);
            bool isExists = System.IO.Directory.Exists(realpath);
            if (!isExists) {
                System.IO.Directory.CreateDirectory(realpath);
                isExists = System.IO.Directory.Exists(realpath);

                if (!isExists) {
                    ERR = "\"" + realpath + "\" folder can not be created.";
                }
            }

            if (geturl.IndexOf("https") == 0) {
                httpType = "https";
            }

            geturl = Regex.Replace(geturl, "^(https|http)[:]//", "");

            if (ERR == "") {
                tmp = geturl.Split('/');

                if (tmp[0].IndexOf("@") != -1) {
                    makeAdress = tmp[0].Split('@');
                    makeAdress = makeAdress[0].Split(':');

                    if (makeAdress.Length > 1) {
                        username = makeAdress[0];
                        password = makeAdress[1];
                    } else {
                        username = makeAdress[0];
                    }

                    //Basic authentication
                    basicAuth = Convert.ToBase64String(
                        System.Text.Encoding.GetEncoding("ISO-8859-1").GetBytes(username + ":" + password)
                    );
                }

                WebRequest request = WebRequest.Create(httpType + "://" + geturl);

                // If required by the server, set the credentials.
                request.Credentials = CredentialCache.DefaultCredentials;

                //Set same user agent
                ((HttpWebRequest) request).UserAgent = context.Request.UserAgent;

                //Auth basic
                request.Headers["Authorization"] = "Basic " + basicAuth;

                try {
                    HttpWebResponse response = (HttpWebResponse) request.GetResponse();

                    if (response.StatusCode != HttpStatusCode.OK) {
                        ERR = response.StatusCode.ToString();
                    } else if (response.Headers["Content-Length"] == "0") {
                        ERR = "source is blank (Content-length: 0)";
                    } else {
                        MIME = response.ContentType.ToLower().Trim();

                        if (MIME.IndexOf(";") != -1) {
                            tmp = MIME.Split(';');
                            MIME = tmp[0].Trim();

                            tmp[0] = "";
                            CHARSET = string.Join(" ", tmp).Remove(0, 1).Trim();
                        }

                        //Some servers use image/svg-xml (minus signal) instead of image/svg+xml (plus signal)
                        if ("|image/jpeg|image/jpg|image/png|image/gif|image/svg+xml|image/svg-xml|text/html|application/xhtml|application/xhtml+xml|".IndexOf("|" + MIME + "|")== - 1) {
                            ERR = MIME + " mime is invalid";
                        } else {
                            HashAlgorithm sha = SHA1.Create();
                            byte[] shafilebyte = sha.ComputeHash(Encoding.UTF8.GetBytes(geturl));
                            string shafile = BitConverter.ToString(shafilebyte).Replace("-", "").ToLowerInvariant();

                            string extesionFile = MIME.Replace("image/", "")
                                                        .Replace("text/", "")
                                                        .Replace("application/", "")
                                                        .Replace("x-", "")
                                                        .Replace("jpeg", "jpg")
                                                        .Replace("xhtml+xml", "xhtml")
                                                        .Replace("svg+xml", "svg").Replace("svg-xml", "svg");

                            shafile = shafile + "." + extesionFile;

                            Stream receiveStream = response.GetResponseStream();

                            using (System.IO.FileStream fs = System.IO.File.Create(realpath + "\\" + shafile)) {
                                int bytesRead;
                                long sizeBytes = response.ContentLength;

                                if (sizeBytes < 1) {
                                    sizeBytes = Int32.MaxValue / 2;
                                }

                                byte[] buffer = new byte[sizeBytes];

                                while((bytesRead = receiveStream.Read(buffer, 0, buffer.Length)) != 0) {
                                    fs.Write(buffer, 0, bytesRead);
                                }
                            }

                            if (System.IO.File.Exists(realpath + "\\" + shafile)) {
                                HS.AddHeader("Last-Modified", DateTime.UtcNow.ToString("R"));
                                HS.AddHeader("Cache-Control", "max-age=" + (CCACHE - 1));
                                HS.AddHeader("Pragma", "max-age=" + (CCACHE - 1));
                                HS.AddHeader("Expires", new DateTime(DateTime.UtcNow.Ticks).AddSeconds(CCACHE - 1).ToString("R"));

                                if (CROSSDOMAIN) {
                                    bool isBase64 = MIME.IndexOf("image/svg") == -1 && MIME.IndexOf("text/") == -1;
                                    string dataURI = "data:" + Html2CanvasProxy.JsonEncodeString(MIME, true);

                                    if (CHARSET != "" && CHARSET != null) {
                                        dataURI += ";" + Html2CanvasProxy.JsonEncodeString(CHARSET, true);
                                    }

                                    if (isBase64) {
                                        dataURI += ";base64";
                                    }

                                    HS.Write(
                                        getcallback + "(\"" +
                                            dataURI + "," +
                                            Html2CanvasProxy.ReadFileEnconding(realpath + "\\" + shafile, isBase64) +
                                        "\")"
                                    );
                                } else {
                                    string fullurl = "http://";
                                    if (context.Request.Url.Port == 443) {
                                        fullurl = "https://";
                                    }

                                    fullurl += context.Request.Url.Host;
                                    if (context.Request.Url.Port != 80 && context.Request.Url.Port != 443) {
                                        fullurl += ":" + context.Request.Url.Port.ToString();
                                    }

                                    string[] uri = context.Request.Url.Segments;
                                    uri[uri.Length - 1]="";

                                    fullurl += String.Join("/", uri).Replace("//","/");
                                    fullurl += PATH + "/" + shafile;

                                    HS.Write(getcallback + "(" + Html2CanvasProxy.JsonEncodeString(fullurl, false) + ")");
                                }
                                return;
                            } else {
                                ERR = "no such file";
                            }
                        }
                    }
                } catch (WebException e) {
                    ERR = e.ToString();
                }
            }
        }

        HS.Cache.SetExpires(DateTime.UtcNow.AddDays(-1));
        HS.Cache.SetValidUntilExpires(false);
        HS.Cache.SetRevalidation(HttpCacheRevalidation.AllCaches);
        HS.Cache.SetCacheability(HttpCacheability.NoCache);
        HS.Cache.SetNoStore();

        HS.Write(getcallback + "(" + Html2CanvasProxy.JsonEncodeString("error:" + ERR, false) + ")");
    }

    public bool IsReusable {
        get {
            return false;
        }
    }
}
