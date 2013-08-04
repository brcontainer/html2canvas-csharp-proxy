<%@ WebHandler Language="C#" Debug="true" Class="Html2CanvasProxy" %>
/*
  html2canvas-csharp-proxy 0.0.1
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
		return new System.Web.Script.Serialization.JavaScriptSerializer().Serialize(s);
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
			}

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
					if("|image/jpeg|image/jpg|image/png|image/gif|text/html|application/xhtml|".IndexOf("|"+MIME+"|")==-1){
						ERR = MIME+" mime is invalid";
					} else {
						HashAlgorithm sha = SHA1.Create();
						byte[] shafilebyte = sha.ComputeHash(Encoding.UTF8.GetBytes(geturl));
						string shafile = BitConverter.ToString(shafilebyte).Replace("-", "").ToLowerInvariant();

						Stream receiveStream = response.GetResponseStream();
						
						using (System.IO.FileStream fs = System.IO.File.Create(realpath+"/"+shafile)) {
							int bytesRead;
							byte[] buffer = new byte[response.ContentLength];

							while((bytesRead = receiveStream.Read(buffer, 0, buffer.Length)) != 0) {
								fs.Write(buffer, 0, bytesRead);
							}
						}

						if(System.IO.File.Exists(realpath+"/"+shafile)){
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
							fullurl += "images/"+shafile;
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
		HS.Write(getcallback+"("+Html2CanvasProxy.JSON_ENCODE("error:"+ERR)+")");
	}

	public bool IsReusable {
		get {
			return false;
		}
	}
}
