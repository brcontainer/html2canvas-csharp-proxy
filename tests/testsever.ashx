<%@ WebHandler Language="C#" Debug="true" Class="FireTest" %>

using System;
using System.IO;
using System.Web;
using System.Net;
using System.Text;
using System.Security.Cryptography;

public class FireTest : IHttpHandler {
	public void ProcessRequest (HttpContext context) {
		string geturl = context.Request.QueryString["url"];
		string PATH = "images";//Path relative

		HttpResponse HS = context.Response;
		HS.ContentType = "text/plain";

		if(geturl==""){
			HS.Write("url var not defined");
			HS.Close();
		}
		
		string realpath = HttpContext.Current.Server.MapPath("./"+PATH);

		HashAlgorithm sha = SHA1.Create();
		byte[] shafilebyte = sha.ComputeHash(Encoding.UTF8.GetBytes(geturl));
		string shafile = BitConverter.ToString(shafilebyte).Replace("-", "").ToLowerInvariant();
		
		string realPathFile = realpath+"\\"+shafile;


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

		HS.Write("realpath: \""+realpath+"\"");
		HS.Write("\r\nrealPathFile: \""+realPathFile+"\"");
		HS.Write("\r\nfullurl: \""+fullurl+"\"");
	}

	public bool IsReusable {
		get {
			return false;
		}
	}
}
