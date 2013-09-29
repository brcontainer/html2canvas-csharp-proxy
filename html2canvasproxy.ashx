<%@ WebHandler Language="C#" Debug="true" Class="Html2CanvasProxy" %>
/*
  html2canvas-csharp-proxy 0.0.4
  Copyright (c) 2013 Guilherme Nascimento (brcontainer@yahoo.com.br)

  Released under the MIT license
*/

using System;
using System.IO;
using System.Web;
using System.Net;
using System.Text;
using System.Security.Cryptography;

public class Html2CanvasProxy : IHttpHandler {
	private static string JSON_ENCODE (string s) {
		//return new System.Web.Script.Serialization.JavaScriptSerializer().Serialize(s);
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

		int i=0;
		int c;
		string d;
		string[] e = new string[s.Length];

		foreach (string j in e) {
			e[i] = s.Substring(i, 1);
			c = (int) Convert.ToChar(e[i]);
			if(c < 127){
				if (!String.IsNullOrEmpty(vetor[c])) {
					e[i] = vetor[c];
				} else if (c < 32) {
					d = "000"+c.ToString("X");
					e[i] = "\\u"+d.Substring(d.Length-4);
				}
			} else {
				d = "000"+c.ToString("X");
				e[i] = "\\u"+d.Substring(d.Length-4);
			}
			i++;
		}
		return "\""+String.Join("",e)+"\"";
	}
	public void ProcessRequest (HttpContext context) {
		//Setup
		string PATH = "images";//Path relative
		int CCACHE = 60 * 5 * 1000;//Limit access-control and cache

		string GMDATECACHE = DateTime.UtcNow.ToString();
		string ERR = "";
		string MIME = "";

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

		if(geturl!="" && getcallback!=""){
			string realpath = HttpContext.Current.Server.MapPath("./"+PATH);
			bool isExists = System.IO.Directory.Exists(realpath);
			if(!isExists) {
				System.IO.Directory.CreateDirectory(realpath);
				isExists = System.IO.Directory.Exists(realpath);
				if(!isExists) {
					ERR = "\""+realpath+"\" folder can not be created.";
				}
			}

			if(ERR=="") {
				WebRequest request = WebRequest.Create (geturl);
				((HttpWebRequest)request).UserAgent = context.Request.UserAgent;

				// If required by the server, set the credentials.
				request.Credentials = CredentialCache.DefaultCredentials;

				try {
					HttpWebResponse response = (HttpWebResponse)request.GetResponse();

					if(!(response.StatusCode == HttpStatusCode.OK && response.ContentLength>0)){
						ERR = response.StatusCode.ToString();
					} else {
						MIME = response.ContentType.ToLower().Trim();
						if("|image/jpeg|image/jpg|image/png|image/gif|text/html|application/xhtml|application/xhtml+xml|".IndexOf("|"+MIME+"|")==-1){
							ERR = MIME+" mime is invalid";
						} else {
							HashAlgorithm sha = SHA1.Create();
							byte[] shafilebyte = sha.ComputeHash(Encoding.UTF8.GetBytes(geturl));
							string shafile = BitConverter.ToString(shafilebyte).Replace("-", "").ToLowerInvariant();

							string extesionFile = MIME.Replace("image/", "").Replace("text/", "").Replace("application/", "").Replace("x-", "").Replace("jpeg", "jpg").Replace("xhtml+xml", "xhtml");
							shafile = shafile+"."+extesionFile;

							Stream receiveStream = response.GetResponseStream();

							using (System.IO.FileStream fs = System.IO.File.Create(realpath+"\\"+shafile)) {
								int bytesRead;
								byte[] buffer = new byte[response.ContentLength];

								while((bytesRead = receiveStream.Read(buffer, 0, buffer.Length)) != 0) {
									fs.Write(buffer, 0, bytesRead);
								}
							}

							if(System.IO.File.Exists(realpath+"\\"+shafile)){
								string fullurl = "http://";
								if(context.Request.Url.Port==443){
									fullurl = "https://";
								}
								fullurl += context.Request.Url.Host;
								if(context.Request.Url.Port!=80 && context.Request.Url.Port!=443){
									fullurl += ":"+context.Request.Url.Port.ToString();
								}

								string[] uri = context.Request.Url.Segments;
								uri[uri.Length-1]="";

								fullurl += String.Join("/", uri).Replace("//","/");
								fullurl += PATH+"/"+shafile;
								fullurl = fullurl;

								HS.AddHeader("Last-Modified", DateTime.UtcNow.ToString("R"));
								HS.AddHeader("Cache-Control", "max-age="+(CCACHE-1)+", must-revalidate");
								HS.AddHeader("Pragma", "max-age="+(CCACHE-1));
								HS.AddHeader("Expires", new DateTime(DateTime.UtcNow.Ticks).AddSeconds(CCACHE-1).ToString("R"));

								HS.Write(getcallback+"("+Html2CanvasProxy.JSON_ENCODE(fullurl)+")");
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

		HS.Write(getcallback+"("+Html2CanvasProxy.JSON_ENCODE("error:"+ERR)+")");
	}

	public bool IsReusable {
		get {
			return false;
		}
	}
}
